// Renders the card with real fonts into screenshots/ (pub.dev gallery + matheel.app):
// flutter test test/screenshot_test.dart --update-goldens
@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matheel_zatca/matheel_zatca.dart';

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  final qr = File('test/sample_qr.txt').readAsStringSync().trim();

  setUpAll(() async {
    final home = Platform.environment['HOME']!;
    await _font('Plex', [
      '../../../priv/invoice_pdf/IBMPlexSansArabic-Regular.otf',
      '../../../priv/invoice_pdf/IBMPlexSansArabic-Bold.otf',
    ]);
    await _font('MaterialIcons', ['$home/opt/flutter-3.50/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  for (final arabic in [true, false]) {
    testWidgets('screenshot ${arabic ? 'ar' : 'en'}', (tester) async {
      tester.view.physicalSize = const Size(1170, 2100);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Plex', colorSchemeSeed: const Color(0xFF0D5C54), scaffoldBackgroundColor: const Color(0xFFF4F4F5)),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ZatcaInvoiceCard(qr: qr, arabic: arabic, onOpenPdf: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('../screenshots/card_${arabic ? 'ar' : 'en'}.png'));
    });
  }
}
