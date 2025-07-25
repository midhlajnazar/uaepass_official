/// The [Const] class provides UAE Pass-specific constants and utility methods
/// to support authentication flows and environment-based configurations.
class Const {
  /// Authentication Context Class Reference (ACR) for UAE Pass mobile authentication.
  /// This is used to identify the mobile on-device flow during login.
  static const String uaePassMobileACR = "urn:digitalid:authentication:flow:mobileondevice";

  /// Authentication Context Class Reference (ACR) for UAE Pass web authentication.
  /// This is used to identify the web-based low-assurance authentication flow.
  static const String uaePassWebACR = "urn:safelayer:tws:policies:authentication:level:low";

  /// URL scheme for redirecting back from UAE Pass app in the production environment.
  static String uaePassProdScheme = 'uaepass://';

  /// URL scheme for redirecting back from UAE Pass app in the staging/test environment.
  static String uaePassStgScheme = 'uaepassstg://';

  /// Base URL for the UAE Pass identity provider API in the **production** environment.
  static const String _uaePassProdBaseUrl = 'https://id.uaepass.ae';

  /// Base URL for the UAE Pass identity provider API in the **staging/test** environment.
  static const String _uaePassStgBaseUrl = 'https://stg-id.uaepass.ae';

  /// Returns the appropriate UAE Pass API base URL depending on the environment.
  ///
  /// [isProduction] - Set to `true` to retrieve the production URL,
  /// or `false` to retrieve the staging URL.
  static String baseUrl(bool isProduction) {
    return isProduction ? _uaePassProdBaseUrl : _uaePassStgBaseUrl;
  }

  /// Returns the correct URL scheme used by the UAE Pass app based on environment.
  ///
  /// [isProduction] - Set to `true` to retrieve the production scheme (`uaepass://`),
  /// or `false` to retrieve the staging scheme (`uaepassstg://`).
  static String uaePassScheme(bool isProduction) {
    return isProduction ? uaePassProdScheme : uaePassStgScheme;
  }
}
