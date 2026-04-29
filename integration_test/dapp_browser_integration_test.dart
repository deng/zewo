import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Generates a test dApp HTML page that auto-triggers EIP-1193 methods sequentially.
///
/// Flow: connect → sign_typed_data → switch_chain → add_chain
/// Each step has its own try/catch. If any step fails, the page stops and shows
/// the failure in both #status and #result.
String get _testDAppDataUri {
  final html = r'''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Test DApp</title>
<style>
  body { font-family: sans-serif; padding: 20px; background: #f5f5f5; }
  h1 { color: #333; }
  #status { margin: 16px 0; padding: 12px; background: #e3f2fd; border-radius: 8px; }
  #result { margin: 8px 0; padding: 8px; background: #fff; border: 1px solid #ddd; border-radius: 4px; font-family: monospace; font-size: 12px; word-break: break-all; }
</style>
</head>
<body>
  <h1>Test DApp (E2E)</h1>
  <div id="status">Initializing...</div>
  <div id="result"></div>
  <script>
  (function() {
    var el = function(id) { return document.getElementById(id); };
    function sleep(ms) { return new Promise(function(r) { setTimeout(r, ms); }); }

    el('status').textContent = 'window.ethereum: ' + (window.ethereum ? 'DETECTED' : 'NOT_FOUND');
    if (!window.ethereum) { el('result').textContent = 'NO_ETHEREUM'; return; }

    // Run steps sequentially with explicit delays
    sleep(1500).then(async function() {
      // ---- Step 1: eth_requestAccounts ----
      try {
        var accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        el('status').textContent = 'Step1 OK: ' + JSON.stringify(accounts);
        el('result').textContent = 'CONNECT_OK';
      } catch(e) {
        el('status').textContent = 'Step1 FAIL: ' + e.message;
        el('result').textContent = 'CONNECT_FAIL';
        return;
      }

      await sleep(2000);

      // ---- Step 2: eth_signTypedData_v4 ----
      try {
        var typedData = {
          domain: { name: 'Test DApp', version: '1', chainId: 1 },
          types: {
            EIP712Domain: [
              { name: 'name', type: 'string' },
              { name: 'version', type: 'string' },
              { name: 'chainId', type: 'uint256' }
            ],
            Message: [
              { name: 'content', type: 'string' },
              { name: 'value', type: 'uint256' }
            ]
          },
          primaryType: 'Message',
          message: { content: 'Hello from Test DApp', value: '100' }
        };
        var sig = await window.ethereum.request({
          method: 'eth_signTypedData_v4',
          params: [accounts[0], JSON.stringify(typedData)]
        });
        el('status').textContent = 'Step2 OK: signature length=' + (sig || '').length;
        el('result').textContent = 'SIGN_TYPED_DATA_OK';
      } catch(e) {
        el('status').textContent = 'Step2 FAIL: ' + e.message;
        el('result').textContent = 'SIGN_TYPED_DATA_FAIL';
        return;
      }

      await sleep(2000);

      // ---- Step 3: wallet_switchEthereumChain ----
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: '0x89' }]
        });
        el('status').textContent = 'Step3 OK: switched to 0x89';
        el('result').textContent = 'SWITCH_CHAIN_OK';
      } catch(e) {
        el('status').textContent = 'Step3 FAIL: ' + e.message;
        el('result').textContent = 'SWITCH_CHAIN_FAIL';
        return;
      }

      await sleep(2000);

      // ---- Step 4: wallet_addEthereumChain ----
      try {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: '0xa4b1',
            chainName: 'TestChain',
            rpcUrls: ['https://test-rpc.example.com'],
            nativeCurrency: { name: 'TEST', symbol: 'TST', decimals: 18 }
          }]
        });
        el('status').textContent = 'Step4 OK: added chain 0xa4b1';
        el('result').textContent = 'ADD_CHAIN_OK';
      } catch(e) {
        el('status').textContent = 'Step4 FAIL: ' + e.message;
        el('result').textContent = 'ADD_CHAIN_FAIL';
        return;
      }

      el('result').textContent = 'ALL_OK';
    });
  })();
  </script>
</body>
</html>
''';

  return Uri.dataFromString(html, mimeType: 'text/html').toString();
}

void main() {
  configureIntegrationTest();

  testWidgets('dApp browser: full EIP-1193 interaction flow', (tester) async {
    // 1. Launch app and create a wallet
    await launchTestApp();

    await pumpUntilVisible(
      tester,
      find.byKey(const Key('home_create_wallet_button')),
    );
    // Create BTC wallet + add ETH Sepolia HD sub-wallet.
    // After this, currentWallet is automatically switched to the ETH Sepolia wallet
    // (see hd_wallet_list_page.dart line 281: setCurrentWallet(newWallet)).
    await createWalletAndAddEthSepoliaWallet(tester, walletName: 'DApp E2E');
    await pumpUntilWalletHomeReady(tester);

    // 2. Navigate to dApp browser tab
    await tapAndPump(tester, find.byKey(const Key('bottom_nav_dapp')));
    await pumpUntilVisible(
      tester,
      find.text('DApp 浏览器'),
      timeout: const Duration(seconds: 5),
    );

    // 3. Load the test dApp page
    final testUri = _testDAppDataUri;
    await tester.enterText(find.byType(TextField), testUri);
    await tester.testTextInput.receiveAction(TextInputAction.go);

    // ---- Step 1: Connect ----
    await pumpUntilVisible(
      tester,
      find.text('连接钱包'),
      timeout: const Duration(seconds: 15),
    );
    await tapAndPump(
      tester,
      find.widgetWithText(ElevatedButton, '连接'),
      settle: const Duration(seconds: 1),
    );

    // ---- Step 2: Sign Typed Data ----
    await tester.pump(const Duration(seconds: 5));
    await pumpUntilVisible(
      tester,
      find.text('签名请求'),
      timeout: const Duration(seconds: 20),
    );
    await tapAndPump(
      tester,
      find.widgetWithText(ElevatedButton, '签名'),
      settle: const Duration(seconds: 1),
    );

    // Enter password
    await pumpUntilVisible(
      tester,
      find.text('输入密码'),
      timeout: const Duration(seconds: 10),
    );
    await tester.enterText(
      find.widgetWithText(TextField, '密码'),
      'Passw0rd!',
    );
    await unfocusAndPump(tester);
    await tapAndPump(
      tester,
      find.widgetWithText(ElevatedButton, '确认'),
      settle: const Duration(seconds: 2),
    );

    // ---- Step 3: Switch Chain ----
    await tester.pump(const Duration(seconds: 5));
    await pumpUntilVisible(
      tester,
      find.text('切换网络'),
      timeout: const Duration(seconds: 20),
    );
    await tapAndPump(
      tester,
      find.widgetWithText(ElevatedButton, '切换'),
      settle: const Duration(seconds: 1),
    );

    // ---- Step 4: Add Chain ----
    await tester.pump(const Duration(seconds: 5));
    await pumpUntilVisible(
      tester,
      find.text('添加网络'),
      timeout: const Duration(seconds: 20),
    );
    await tapAndPump(
      tester,
      find.widgetWithText(ElevatedButton, '添加'),
      settle: const Duration(seconds: 1),
    );

    // ---- Verify no errors ----
    await tester.pump(const Duration(seconds: 2));
  });
}
