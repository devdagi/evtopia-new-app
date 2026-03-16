import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Certificate pinning configuration.
/// Set [enabled] to true and [sha256Fingerprints] to your server certificate's
/// SHA-256 fingerprint(s) for production to mitigate MITM attacks.
/// Get fingerprint: openssl s_client -servername evtopia.co -connect evtopia.co:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -sha256 -noout
class SslPinningConfig {
  SslPinningConfig._();

  static const bool enabled = bool.fromEnvironment(
    'SSL_PINNING_ENABLED',
    defaultValue: false,
  );

  /// Comma-separated SHA-256 fingerprints in hex (with or without colons).
  static const String sha256Fingerprints = String.fromEnvironment(
    'SSL_PIN_SHA256',
    defaultValue: '',
  );
}

/// Returns a Dio HttpClientAdapter with optional certificate pinning.
HttpClientAdapter createHttpClientAdapter() {
  if (!SslPinningConfig.enabled || SslPinningConfig.sha256Fingerprints.isEmpty) {
    return IOHttpClientAdapter();
  }
  final fingerprints = SslPinningConfig.sha256Fingerprints
      .split(',')
      .map((s) => s.trim().toLowerCase().replaceAll(':', ''))
      .where((s) => s.length == 64)
      .toSet();
  if (fingerprints.isEmpty) {
    return IOHttpClientAdapter();
  }
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient(context: SecurityContext(withTrustedRoots: true));
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        final digest = sha256.convert(cert.der);
        final hex = digest.toString();
        return fingerprints.contains(hex);
      };
      return client;
    },
  );
}
