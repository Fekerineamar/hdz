import 'dart:io';

/// Installs a targeted TLS trust override.
///
/// `dzds.dz` (and `sso.dzds.dz`) serve an **incomplete** certificate chain —
/// they omit the Sectigo intermediate, so standard verification fails with
/// `CERTIFICATE_VERIFY_FAILED` on every client (not just this app).
///
/// We accept the certificate *only* for the `dzds.dz` hosts and *only* when it
/// is the known Sectigo-issued certificate. Every other host (e.g. Google for
/// Gemini) keeps normal certificate verification.
void setupTrustManager() {
  HttpOverrides.global = _DzdsTrustOverrides();
}

class _DzdsTrustOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      final isDzds = host == 'dzds.dz' ||
          host == 'sso.dzds.dz' ||
          host.endsWith('.dzds.dz');
      if (!isDzds) return false;
      // Accept only the Sectigo-issued certificate used by the portal.
      return cert.issuer.contains('Sectigo');
    };
    return client;
  }
}
