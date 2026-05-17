/// Platform-conditional network interceptor setup.
///
/// On io platforms (mobile, desktop): registers HttpOverrides to enforce
/// hot/cold wallet mode on all HTTP requests.
/// On web: no-op (dart:io is not available).
import 'network_setup_stub.dart'
    if (dart.library.io) 'network_setup_io.dart';

export 'network_setup_stub.dart'
    if (dart.library.io) 'network_setup_io.dart';
