// Decodes a real QR returned by Matheel's sandbox and renders the invoice card in both languages.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matheel_zatca/matheel_zatca.dart';

void main() {
  final qr = File('test/sample_qr.txt').readAsStringSync().trim();

  test('decodes the TLV fields of a real ZATCA QR', () {
    final data = ZatcaQrData.decode(qr);
    expect(data.vatNumber, hasLength(15));
    expect(data.sellerName, isNotEmpty);
    expect(double.parse(data.total), greaterThan(double.parse(data.vatAmount)));
    expect(data.timestamp, contains('T'));
    expect(data.invoiceHash, isNotEmpty);
    expect(data.publicKey, isNotNull);
  });

  test('refuses text that is not a ZATCA QR', () {
    expect(() => ZatcaQrData.decode('aGVsbG8='), throwsFormatException);
  });

  testWidgets('the card shows the figures, the QR and the PDF button', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: ZatcaInvoiceCard(qr: qr, onOpenPdf: () => opened = true)))));
    final data = ZatcaQrData.decode(qr);
    expect(find.text('${data.total} SAR'), findsOneWidget);
    expect(find.byType(ZatcaQrImage), findsOneWidget);
    await tester.tap(find.text('عرض الفاتورة PDF'));
    expect(opened, isTrue);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ZatcaInvoiceCard(qr: qr, arabic: false)))));
    expect(find.text('Total incl. VAT'), findsOneWidget);
    expect(find.text('View invoice PDF'), findsNothing);
  });
}
