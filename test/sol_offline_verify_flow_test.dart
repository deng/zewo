import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';

class _FakeSolOfflineSignVerifyService extends OfflineSignVerifyService {
  _FakeSolOfflineSignVerifyService();

  static const address = '5nX1signatureLikeAddress';
  static const publicKey = '0xabcdef';
  static const signature = '0x1234';

  @override
  Future<VerifyPayloadResult> verify(VerifyPayloadRequest request) async {
    return VerifyPayloadResult(
      signatureValid: request.signature == signature,
      signerMatched:
          request.expectedSignerAddress == null ||
          request.expectedSignerAddress == address,
      resolvedSignerAddress: address,
      resolvedSignerPublicKey: publicKey,
      warnings: const <String>['fake warning'],
    );
  }
}

void main() {
  testWidgets('SOL offline verify page shows verify result', (
    WidgetTester tester,
  ) async {
    final service = _FakeSolOfflineSignVerifyService();

    await tester.pumpWidget(
      MaterialApp(home: SolOfflineVerifyPage(service: service)),
    );

    await tester.enterText(
      find.byKey(const Key('sol_offline_verify_payload_field')),
      'hello sol',
    );
    await tester.enterText(
      find.byKey(const Key('sol_offline_verify_signature_field')),
      _FakeSolOfflineSignVerifyService.signature,
    );
    await tester.enterText(
      find.byKey(const Key('sol_offline_verify_public_key_field')),
      _FakeSolOfflineSignVerifyService.publicKey,
    );
    await tester.enterText(
      find.byKey(const Key('sol_offline_verify_expected_address_field')),
      _FakeSolOfflineSignVerifyService.address,
    );
    await tester.tap(find.byKey(const Key('sol_offline_verify_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('SOL 验签结果'), findsOneWidget);
    expect(find.text('true'), findsWidgets);
    expect(find.text(_FakeSolOfflineSignVerifyService.address), findsOneWidget);
    expect(
      find.text(_FakeSolOfflineSignVerifyService.publicKey),
      findsOneWidget,
    );
  });
}
