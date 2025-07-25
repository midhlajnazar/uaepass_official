import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uaepass_official/uaepass_official.dart';

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UAE PASS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'UAE PASS Demo'),
    );
  }
}

/// The home screen of the application.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  /// The title of the app bar.
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Stores the access token received after successful login.
  String? _token;

  /// Stores the user profile information after successful login.
  UAEPASSUserProfile? _user;

  // ---------------- UAE PASS Credentials ----------------

  /// Client ID for staging environment (for development/testing).
  final String stagingClientId = 'ClientIdStaging';

  /// Client secret for staging environment.
  final String stagingClientSecret = '123456789';

  /// Client ID for production environment.
  final String productionClientId = 'ClientIdProduction';

  /// Client secret for production environment.
  final String prodClientSecret = '123456789';

  /// The name of the service provider (must be registered with UAE PASS).
  final String spcName = 'ServiceProviderName';

  /// The callback URI registered for your app with UAE PASS.
  final String callbackUrl = 'someapp://auth';

  /// Instance of UAE PASS API.
  late UaePassAPI uaePassAPI;

  /// Toggles login and logout with UAE PASS.
  ///
  /// If already logged in, this will log the user out.
  /// Otherwise, it will initiate the UAE PASS login flow.
  void _loginOrLogout() async {
    // Initialize the UAE PASS API client
    uaePassAPI = UaePassAPI(
      clientId: productionClientId,
      callbackUrl: callbackUrl,
      clientSecrete: prodClientSecret,
      language: 'en',
      serviceProviderEnglishName: spcName,
      serviceProviderArabicName: spcName,
      isProduction: true, // Set to false to use staging environment
    );

    try {
      // Logout if already authenticated
      if (_token != null) {
        await uaePassAPI.logout(context);
        _token = null;
        _user = null;
        setState(() {});
        return;
      }

      // Initiate sign-in and obtain authorization code
      String? code = await uaePassAPI.signIn(context);
      if (code != null) {
        // Exchange code for access token
        _token = await uaePassAPI.getAccessToken(code);

        // Fetch user profile using access token
        if (_token != null) {
          _user = await uaePassAPI.getUserProfile(_token!, context: context);
        }
      }
    } catch (e, s) {
      // Log any errors that occur during the authentication flow
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }

    // Refresh UI after login/logout
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _token == null ? 'Press the button below to login with UAE PASS.' : 'You are logged in. Press the button below to logout.',
            ),
            const SizedBox(height: 10),
            if (_token != null)
              ListTile(
                title: const Text("Access Token:"),
                subtitle: Text(_token ?? ""),
              ),
            if (_user != null)
              Column(
                children: [
                  ListTile(
                    title: const Text("Full Name:"),
                    subtitle: Text("${_user?.firstNameEN} ${_user?.lastNameEN}"),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loginOrLogout,
        tooltip: _token == null ? 'Login with UAE PASS' : 'Logout',
        child: const Icon(Icons.login),
      ),
    );
  }
}
