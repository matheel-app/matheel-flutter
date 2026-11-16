# matheel_zatca

Show a Saudi **ZATCA (Fatoora) e-invoice** in a Flutter app.

- `ZatcaQrData.decode(qr)` reads the Phase 2 TLV QR (seller, VAT number, time, total, VAT, hash, signature, key).
- `ZatcaInvoiceCard(qr: …, onOpenPdf: …)` draws the scannable QR natively with the decoded figures, in Arabic (RTL) or English, and a PDF button.
- `ZatcaQrImage(qr: …)` is the QR alone.

<img src="https://matheel.app/img/flutter-card-en.png" width="300" alt="English invoice card"> <img src="https://matheel.app/img/flutter-card-ar.png" width="300" alt="Arabic invoice card">

```dart
ZatcaInvoiceCard(
  qr: invoice['qr'],                                  // from your backend
  onOpenPdf: () => launchUrl(Uri.parse(invoice['pdf_url'])),
)
```

The `qr` and the PDF come from [Matheel](https://matheel.app), which signs the invoice, files it with ZATCA and
returns both in one call. Call Matheel from your server, never from the app: your Matheel key stays server-side.
Ready server functions in PHP, Laravel, Node.js, Python, Java, C#, Go, Ruby, Elixir and Rust:
https://matheel.app/en/zatca-integration

## عربي

اعرض فاتورة زاتكا داخل تطبيق فلاتر: فك رمز QR (المرحلة الثانية) وبطاقة فاتورة عربي فيها الرمز والإجمالي والضريبة وزر عرض الـ PDF.
الـ QR والـ PDF يجون من سيرفرك بعد ما يرسل الفاتورة عن طريق [ماثل](https://matheel.app/rabt).
