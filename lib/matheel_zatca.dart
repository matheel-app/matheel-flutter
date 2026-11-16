/// Shows a Saudi ZATCA e-invoice in a Flutter app: decodes the TLV QR and draws an invoice card with the QR.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// The fields a ZATCA Phase 2 QR carries (tags 1–5 as text, 6–9 as raw values).
class ZatcaQrData {
  /// Creates the decoded fields; normally made by [ZatcaQrData.decode].
  const ZatcaQrData({
    required this.sellerName,
    required this.vatNumber,
    required this.timestamp,
    required this.total,
    required this.vatAmount,
    this.invoiceHash,
    this.signature,
    this.publicKey,
    this.certificateSignature,
  });

  /// Tag 1: the seller's name.
  final String sellerName;

  /// Tag 2: the seller's VAT registration number.
  final String vatNumber;

  /// Tag 3: the issue timestamp as written in the invoice.
  final String timestamp;

  /// Tag 4: the invoice total with VAT.
  final String total;

  /// Tag 5: the VAT amount.
  final String vatAmount;

  /// Tag 6: the invoice hash (base64), Phase 2 only.
  final String? invoiceHash;

  /// Tag 7: the ECDSA signature (base64), Phase 2 only.
  final String? signature;

  /// Tag 8: the public key, Phase 2 only.
  final Uint8List? publicKey;

  /// Tag 9: ZATCA's signature of the stamp certificate (simplified invoices).
  final Uint8List? certificateSignature;

  /// Decodes the base64 TLV text that Matheel returns as `qr` (and that is printed in the invoice QR).
  factory ZatcaQrData.decode(String base64Tlv) {
    final bytes = base64.decode(base64Tlv.trim());
    final tags = <int, Uint8List>{};
    var i = 0;
    while (i + 2 <= bytes.length) {
      final tag = bytes[i++];
      var length = bytes[i++];
      if (length & 0x80 != 0) {
        // BER long form: the low bits say how many length bytes follow (ZATCA keys and signatures exceed 127).
        final count = length & 0x7f;
        length = 0;
        for (var k = 0; k < count; k++) {
          length = (length << 8) | bytes[i++];
        }
      }
      if (i + length > bytes.length) throw const FormatException('Truncated ZATCA QR');
      tags[tag] = Uint8List.sublistView(bytes, i, i + length);
      i += length;
    }
    String text(int tag) => tags[tag] == null ? '' : utf8.decode(tags[tag]!);
    if (text(1).isEmpty || text(2).isEmpty) throw const FormatException('Not a ZATCA QR: tags 1 and 2 are required');
    return ZatcaQrData(
      sellerName: text(1),
      vatNumber: text(2),
      timestamp: text(3),
      total: text(4),
      vatAmount: text(5),
      invoiceHash: tags[6] == null ? null : text(6),
      signature: tags[7] == null ? null : text(7),
      publicKey: tags[8],
      certificateSignature: tags[9],
    );
  }
}

/// An invoice card for a ZATCA invoice: the QR (scannable by ZATCA's app), the decoded figures and a PDF button.
///
/// Pass the `qr` your server got from Matheel. The Matheel key never belongs in the app: fetch `qr` and the
/// PDF URL from your own backend.
class ZatcaInvoiceCard extends StatelessWidget {
  /// Creates a card for one invoice.
  const ZatcaInvoiceCard({super.key, required this.qr, this.onOpenPdf, this.arabic = true, this.qrSize = 168});

  /// The base64 TLV `qr` from Matheel's response.
  final String qr;

  /// Called when the PDF button is pressed, e.g. `() => launchUrl(Uri.parse(pdfUrl))`. No button when null.
  final VoidCallback? onOpenPdf;

  /// Arabic labels (right to left) when true, English otherwise.
  final bool arabic;

  /// The QR's side in logical pixels.
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    final data = ZatcaQrData.decode(qr);
    final theme = Theme.of(context);
    String l(String ar, String en) => arabic ? ar : en;
    // Numbers, dates and amounts keep left-to-right order inside Arabic text ("15.00 SAR", not "SAR 15.00").
    Widget row(String label, String value, {bool bold = false, bool ltr = true}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            Text(value,
                textDirection: ltr ? TextDirection.ltr : null,
                style: bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium),
          ]),
        );
    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l('فاتورة ضريبية مبسطة', 'Simplified tax invoice'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Center(child: ZatcaQrImage(qr: qr, size: qrSize)),
            const SizedBox(height: 12),
            row(l('البائع', 'Seller'), data.sellerName, ltr: false),
            row(l('الرقم الضريبي', 'VAT number'), data.vatNumber),
            row(l('التاريخ', 'Date'), data.timestamp.replaceFirst('T', ' ')),
            row(l('ضريبة القيمة المضافة', 'VAT'), '${data.vatAmount} SAR'),
            row(l('الإجمالي شامل الضريبة', 'Total incl. VAT'), '${data.total} SAR', bold: true),
            if (onOpenPdf != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpenPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l('عرض الفاتورة PDF', 'View invoice PDF')),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// The ZATCA QR drawn natively (no image download), black on white with a quiet zone.
class ZatcaQrImage extends StatelessWidget {
  /// Draws [qr] as a QR code [size] logical pixels wide.
  const ZatcaQrImage({super.key, required this.qr, this.size = 168});

  /// The base64 TLV text to encode, exactly as returned by Matheel.
  final String qr;

  /// The side in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(QrCode(payload: QrPayload.fromString(qr), errorCorrectLevel: QrErrorCorrectLevel.medium));
    return Semantics(
      label: 'ZATCA QR',
      image: true,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(size / 16),
        child: CustomPaint(size: Size.square(size), painter: _QrPainter(image)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / image.moduleCount;
    final paint = Paint()..color = Colors.black;
    for (var y = 0; y < image.moduleCount; y++) {
      for (var x = 0; x < image.moduleCount; x++) {
        if (image.isDark(y, x)) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.3, cell + 0.3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}
