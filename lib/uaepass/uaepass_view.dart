import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:uaepass_official/service/memory_service.dart';
import 'package:uaepass_official/uaepass/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  final String callbackUrl;
  final bool isProduction;
  final String locale;

  const CustomWebView(
      {super.key,
      required this.url,
      required this.callbackUrl,
      required this.isProduction,
      this.locale = 'en'});

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late WebViewController controller;
  String? successUrl;
  late StreamSubscription<FGBGType> subscription;

  Future<void> _initialize() async { 

    // ✅ Setup controller only after storage ready
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..clearCache()
      ..clearLocalStorage()
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: onNavigationRequest),
      )
      ..loadRequest(Uri.parse(widget.url));

    // ✅ Handle app foreground event
    subscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.foreground && successUrl != null) {
        final decoded = Uri.decodeFull(successUrl!);
        controller.loadRequest(Uri.parse(decoded));
      }
    });
        // ✅ Ensure GetStorage is ready before any UAEPASS interaction
    await MemoryService.instance.initialize();
 
  }

  @override
  void dispose() {
    subscription.cancel();
    controller.clearLocalStorage();
    controller.clearCache();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<NavigationDecision> onNavigationRequest(
      NavigationRequest request) async {
    String url = request.url.toString();
    debugPrint('UAEPASS url: $url');
    if (url.contains('uaepass://') || url.contains('uaepassstg://')) {
      Uri uri = Uri.parse(url);
      String? successURL = uri.queryParameters['successurl'];
      setState(() => successUrl = successURL);
      final newUrl =
          '${Const.uaePassScheme(widget.isProduction)}${uri.host}${uri.path}';
      String u = "$newUrl?successurl=${widget.callbackUrl}"
          "&failureurl=${widget.callbackUrl}"
          "&closeondone=true";
      await launchUrl(Uri.parse(u));
      return NavigationDecision.prevent;
    }

    if (url.contains('code=')) {
      final memoryService = MemoryService.instance;

      memoryService.accessCode = Uri.parse(url).queryParameters['code']!;
      debugPrint('UAEPASS code: ${memoryService.accessCode}');
      try {
        if (context.mounted) {
          Navigator.of(context).maybePop(memoryService.accessCode);
        }
      } catch (e) {
        debugPrint('Poping error: $e');
      }
      return NavigationDecision.prevent;
    } else if (url.contains('error=invalid_request') ||
        url.contains('error=login_required') ||
        url.contains('error=access_denied') ||
        url.contains('error=cancelledOnApp')) {
      debugPrint('UAEPASS >> User cancelled the login << ');

      // ✅ Show the SnackBar here as per the uaepass use-case documentation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.locale == 'ar'
              ? 'قام المستخدم بإلغاء تسجيل الدخول'
              : 'User cancelled the login'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );

      if (!url.contains('logout')) {
        Navigator.pop(context);
        return NavigationDecision.prevent;
      }
    } else if (url == widget.callbackUrl && widget.url.contains('logout')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.locale == 'ar'
              ? 'تم تسجيل الخروج بنجاح'
              : 'Logout successful'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
