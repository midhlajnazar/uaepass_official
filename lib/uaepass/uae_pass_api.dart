import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uaepass_official/model/uaepass_user_token_model.dart';
import 'package:uaepass_official/uaepass/constant.dart';
import 'package:uaepass_official/service/memory_service.dart';
import 'package:uaepass_official/model/uaepass_user_profile_model.dart';
import 'package:uaepass_official/uaepass/uaepass_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// The [UaePassAPI] class provides a high-level interface for integrating
/// with UAE Pass — the official digital identity solution of the UAE government.
///
/// This class facilitates authentication by handling redirect flows, token exchanges,
/// and profile fetching. It supports both installed-app and browser-based login scenarios.
class UaePassAPI {
  final String _clientId;
  final String _callbackUrl;
  final String _clientSecrete;
  final String _language;
  final String _serviceProviderEnglishName;
  final String _serviceProviderArabicName;
  final bool _isProduction;
  final bool _blockSOP1;

  /// Creates an instance of [UaePassAPI].
  ///
  /// - [clientId] – The client ID issued by UAE Pass.
  /// - [callbackUrl] – The redirect URI used after authentication. This must match
  ///   the URI registered in your UAE Pass dashboard and include your app's custom scheme.
  /// - [clientSecrete] – The client secret assigned by UAE Pass.
  /// - [isProduction] – Set to `true` for production; otherwise, use `false` for staging/testing.
  /// - [blockSOP1] – (Optional) If `true`, blocks SOP1 (Self-Onboarded) users from logging in.
  /// - [language] – Specifies the language for the login page UI. Accepts `'en'` or `'ar'`.
  /// - [serviceProviderEnglishName] – (Optional) Display name of your entity in English.
  /// - [serviceProviderArabicName] – (Optional) Display name of your entity in Arabic.
  UaePassAPI({
    required String clientId,
    required String callbackUrl,
    required String clientSecrete,
    String serviceProviderEnglishName = 'Service Provider',
    String serviceProviderArabicName = 'مزود الخدمة',
    required bool isProduction,
    bool blockSOP1 = false,
    String language = 'en',
  })  : _clientId = clientId,
        _callbackUrl = callbackUrl,
        _clientSecrete = clientSecrete,
        _serviceProviderEnglishName = serviceProviderEnglishName,
        _serviceProviderArabicName = serviceProviderArabicName,
        _isProduction = isProduction,
        _blockSOP1 = blockSOP1,
        _language = language;

  /// Constructs the authorization URL used to initiate the UAE Pass login flow.
  ///
  /// This URL is dynamically adjusted depending on whether the UAE Pass mobile app
  /// is installed on the device. If not, a web-based ACR flow is used instead.
  ///
  /// Returns a [String] containing the full authorization URL.
  Future<String> _getURL() async {
    // Default ACR for mobile app scenario.
    String acr = Const.uaePassMobileACR;
    String acrWeb = Const.uaePassWebACR;

    // Check if UAE Pass mobile app is available.
    bool withApp = await canLaunchUrlString('${Const.uaePassScheme(_isProduction)}digitalid-users-ids');
    if (!withApp) {
      acr = acrWeb; // Fallback to web ACR
    }

    // Build the final authorization URL with required query parameters.
    return "${Const.baseUrl(_isProduction)}/idshub/authorize?"
        "response_type=code"
        "&client_id=$_clientId"
        "&scope=urn:uae:digitalid:profile:general"
        "&state=HnlHOJTkTb66Y5H"
        "&redirect_uri=$_callbackUrl"
        "&ui_locales=$_language"
        "&acr_values=$acr";
  }

  /// Starts the UAE Pass sign-in process by launching the embedded webview.
  ///
  /// [context]: Required to push the login webview onto the navigation stack.
  ///
  /// Returns the authorization [String] code upon successful login.
  Future<String?> signIn(BuildContext context) async {
    await MemoryService.instance.initialize();
    String url = await _getURL();
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
      return MemoryService.instance.accessCode;
    }
    return MemoryService.instance.accessCode;
  }

  /// Exchanges the authorization code for an access token.
  ///
  /// [code]: Authorization code received after successful login.
  ///
  /// Returns the access token as a [String], or null on failure.
  Future<String?> getAccessToken(String code) async {
    try {
      const String url = "/idshub/token";

      var data = {'redirect_uri': _callbackUrl, 'client_id': _clientId, 'client_secret': _clientSecrete, 'grant_type': 'authorization_code', 'code': code};

      final response = await http.post(
        Uri.parse(Const.baseUrl(_isProduction) + url),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        return UAEPASSUserToken.fromJson(jsonDecode(response.body)).accessToken;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    return null;
  }

  /// Fetches the authenticated user's profile using the given access token.
  ///
  /// [token]: Bearer token received from the token exchange.
  /// [context]: Used to show unauthorized messages if the user is SOP1 and access is blocked.
  ///
  /// Returns a [UAEPASSUserProfile] or `null` if unauthorized or failed.
  Future<UAEPASSUserProfile?> getUserProfile(String token, {required context}) async {
    try {
      const String url = "/idshub/userinfo";

      final response = await http.get(
        Uri.parse(Const.baseUrl(_isProduction) + url),
        headers: <String, String>{'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final profile = UAEPASSUserProfile.fromJson(jsonDecode(response.body));

        if (_blockSOP1 && profile.userType == 'SOP1') {
          debugPrint('UAEPASS >> UNAUTHORISED >> ${profile.userType} ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _language == 'ar'
                    ? 'أنت غير مؤهل للوصول إلى هذه الخدمة. إما أن حسابك لم تتم ترقيته أو لديك حساب زائر. يرجى الاتصال بـ $_serviceProviderArabicName لتتمكن من الوصول إلى الخدمة.'
                    : 'You are not eligible to access this service. Your account is either not upgraded or you have a visitor account. Please contact $_serviceProviderEnglishName to access the services.',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );

          return null;
        }
        return profile;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    return null;
  }

  /// Performs UAE Pass logout by opening the logout endpoint in a webview.
  ///
  /// [context]: The [BuildContext] required to navigate to the logout view.
  Future logout(BuildContext context) async {
    String url = "${Const.baseUrl(_isProduction)}/idshub/logout?redirect_uri=$_callbackUrl";

    if (context.mounted) {
      return await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
    }

    return null;
  }
}
