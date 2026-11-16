// Example: show a ZATCA invoice that your server filed through Matheel (https://matheel.app).
import 'package:flutter/material.dart';
import 'package:matheel_zatca/matheel_zatca.dart';

void main() => runApp(const ExampleApp());

/// A one-screen app showing an invoice card for a QR your backend returned.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  // In a real app this comes from your server's response after filing (never call Matheel from the app).
  static const qr =
      'ARPYtNix2YPYqSDYqtis2LHYqNipAg8zMDAwMDAwMDAwMDAwMDMDEzIwMjYtMTEtMTZUMTA6MDA6MDAEBjExNS4wMAUFMTUuMDA=';

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('ZATCA invoice')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ZatcaInvoiceCard(qr: qr),
          ),
        ),
      );
}
