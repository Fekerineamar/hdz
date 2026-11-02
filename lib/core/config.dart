/// Central configuration for the DZDS agent app.
///
/// The Gemini API key can be provided at build time via
/// `--dart-define=GEMINI_API_KEY=...` or at runtime through the settings UI
/// (stored in secure storage). Base URLs and OAuth constants mirror the real
/// portal captured in the traffic.
class AppConfig {
  AppConfig._();

  /// Primary citizen-services portal.
  static const String dzdsBase = 'https://dzds.dz';

  /// SSO identity provider.
  static const String ssoBase = 'https://sso.dzds.dz';

  /// OAuth2 client used by the public web portal.
  static const String clientId = 'PublicWeb';
  static const String scope = 'openid';
  static const String state = 'cms';
  static const String redirectUri =
      'https://dzds.dz/api/auth/callback/cms';
  static const String lang = 'ar';

  /// Gemini model used for both the agent brain and document extraction.
  ///
  /// Defaults to `gemini-3.6-flash`, which works on free-tier keys. The old
  /// default `gemini-3.1-pro-preview` has zero free-tier quota (always 429),
  /// so it is kept only as a last-resort fallback. Override at build time with
  /// `--dart-define=GEMINI_MODEL=...`.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.6-flash',
  );

  /// Build-time API key (optional). Runtime key wins if set.
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  /// Header used by the portal form engine for the encrypted payload key.
  static const String hooxDataKeyHeader = 'Hoox-Data-Key';

  /// Default language header sent to the portal.
  static const String contentLanguage = 'ar-DZ';
}
