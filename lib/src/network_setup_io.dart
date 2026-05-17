import 'dart:io';

import 'package:zero_wallet/wallet.dart' show WalletNetworkManager, NetworkInterceptor;

/// Register network interceptor for hot/cold wallet mode switching.
///
/// Await ready so persisted mode is loaded before any network activity.
/// Only available on platforms with dart:io (not web).
Future<void> setupNetworkInterceptor() async {
  await WalletNetworkManager.instance.ready;
  HttpOverrides.global = NetworkInterceptor(
    WalletNetworkManager.instance,
  );
}
