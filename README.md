

````markdown
# uaepass_official

Unofficial UAE PASS Flutter package enabling seamless national digital identity authentication with support for **installed** and **non-installed** UAEPass app scenarios.

---

## 🚀 Why `uaepass_official`?

- ✅ **Simple & Developer-Friendly API**
- 🧩 Supports both installed and browser-based UAEPass login
- 📲 Fullscreen OAuth2 flow
- 🛡️ Null safety compliant
- 🔄 Easily integrates with **Riverpod**, **Bloc**, or any other state management
- 🌐 Multilingual support (English / Arabic)
- 🔒 SOP1 user type blocking (optional)
- ⚠️ This package only supports **Android** and **iOS**. Other platforms like web, Windows, or macOS are not supported.


---

## 📦 Installation

### 1. Add to `pubspec.yaml`

```yaml
dependencies:
  uaepass_official: ^0.0.5
````

### 2. Fetch dependencies

```bash
flutter pub get
```

### 3. Import the package

```dart
import 'package:uaepass_official/uaepass_official.dart';';
```

---

## ⚙️ Basic Usage

### 🧑‍💻 Initialization

```dart
UaePassAPI uaePassAPI = UaePassAPI(
  clientId: "<clientId>",
  callbackUrl: "<callbackUrl>",
  clientSecrete: "<clientSecrete>",
  language: "en", // or 'ar'
  isProduction: false,
);
```


## 🧱 Class: `UaePassAPI`

### Constructor Parameters:

* `clientId` – Client ID provided by UAE Pass.
* `callbackUrl` – URL the user is redirected to after authentication. Should use your app's URL scheme.
* `clientSecrete` – Client secret issued by UAE Pass.
* `isProduction` – If `true`, production URLs are used; otherwise, sandbox.
* `language` – "en" or "ar" to toggle the UAE Pass page language.
* `blockSOP1` – Blocks login for users of type `SOP1` (unauthorized).
* `serviceProviderEnglishName` – Name shown in messages (English).
* `serviceProviderArabicName` – Name shown in messages (Arabic).

---

## 🔐 Authentication Flow

### `signIn(BuildContext context)`

* Opens a `CustomWebView` to authenticate via UAE Pass.
* Stores the returned code in `MemoryService.instance.accessCode`.

### `_getURL()` *(private)*

* Constructs a valid authorization URL depending on whether UAE Pass app is available or not.

---

## 🔄 Access Token

### `getAccessToken(String code)`

* Exchanges the code for a JWT access token.
* Returns the token string on success, or `null` on failure.

---

## 👤 Get User Profile

### `getUserProfile(String token, {required context})`

* Fetches user's profile from UAE Pass.
* If `blockSOP1 = true` and user is SOP1, shows a localized `SnackBar` and blocks further access.

---

## 🔓 Logout

### `logout(BuildContext context)`

* Opens logout URL in a `CustomWebView`.

---

## 📲 Example with Riverpod 2.0

```dart
@riverpod
class UaePassController extends _$UaePassController {
  UAEPASSUserProfile? _user;
  String? _token;
  late final UaePassAPI uaePassAPI;

  @override
  FutureOr<UAEPASSUserProfile?> build() {
    uaePassAPI = UaePassAPI(
      clientId: UAEPassConstant.uaePassClientId,
      callbackUrl: UAEPassConstant.uaePassCallbackUrl,
      clientSecrete: UAEPassConstant.uaePassClientSecret,
      isProduction: !UAEPassConstant.uaePassIsStagingEnvironment,
      blockSOP1: true,
      isVisitor: false,
      language: 'en',
      serviceProviderArabicName: UAEPassConstant.serviceProviderArabicName,
      serviceProviderEnglishName: UAEPassConstant.serviceProviderEnglishName,
    );
    return null;
  }

  Future<void> signIn(BuildContext context) async {
    try {
      if (_token != null) {
        await signOut(context);
        return;
      }

      final code = await uaePassAPI.signIn(context);
      if (code == null) return;

      _token = await uaePassAPI.getAccessToken(code);
      if (_token == null) return;

      _user = await uaePassAPI.getUserProfile(_token!, context: context);
      state = AsyncValue.data(_user);
    } catch (e, s) {
      debugPrint('UAEPass Sign-In Error: $e\n$s');
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signOut(BuildContext context) async {
    await uaePassAPI.logout(context);
    _clearState();
  }

  void reset() => _clearState();

  void _clearState() {
    _token = null;
    _user = null;
    state = const AsyncValue.data(null);
  }

  String? get token => _token;
  UAEPASSUserProfile? get user => _user;
}
```

---

## 📱 Platform Setup

### ✅ Android

#### 1. Set `launchMode="singleTask"` in `AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTask"
    android:exported="true"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    ...
</activity>
```

#### 2. Add intent filter

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:host="auth"
        android:scheme="<your_app_scheme>" />
</intent-filter>
```
 

### ✅ iOS

#### Add the following in `Info.plist`

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>uaepass</string>
  <string>uaepassqa</string>
  <string>uaepassdev</string>
  <string>uaepassstg</string>
</array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string><your_app_scheme></string>
    </array>
  </dict>
</array>
```

---

## 🔍 Notes

* Ensure that the **callback scheme** (e.g., `<your_app_scheme>://auth`) is **registered/whitelisted** in the UAEPass admin panel in production.
* Ensure that <your_app_scheme> name doesn't end with "uaepass"
* SOP1 users are automatically rejected when `blockSOP1: true`.
* Make sure `callbackUrl` and `clientId` are configured correctly in the UAEPass dashboard.
* This package assumes use of a shared in-memory service (`MemoryService`) to store the temporary access code.

---

## 📚 Example Staging Configuration for UAEPASS

```
class UAEPassConstant {
  static const bool uaePassIsProductionEnvironment = false;
  static const bool blockSOP1Users = true;
  static const bool isVisitor = false;
  static const String serviceProviderEnglishName = 'My Application';
  static const String serviceProviderArabicName = 'تطبيقي';
  static const String uaePassClientId = uaePassIsStagingEnvironment ? 'sandbox_stage' : 'xxxxxxx';
  static const String uaePassClientSecret = uaePassIsStagingEnvironment ? 'sandbox_stage' : 'xxxxxxxx';
  //Scheme must be lowercase and doesnt end with uaepass
  static const String uaePassScheme =  'yourappscheme';
  static const String uaePassCallbackUrl = '$uaePassScheme://auth';
}
...

final uaePassAPI = UaePassAPI(
  clientId: UAEPassConstant.uaePassClientId,
  callbackUrl: UAEPassConstant.uaePassCallbackUrl,
  clientSecrete: UAEPassConstant.uaePassClientSecret,
  isProduction: UAEPassConstant.uaePassIsProductionEnvironment,
  blockSOP1: UAEPassConstant.blockSOP1Users,
  isVisitor: UAEPassConstant.isVisitor,
  language: 'en',//or 'ar'
  serviceProviderArabicName: UAEPassConstant.serviceProviderArabicName,
  serviceProviderEnglishName: UAEPassConstant.serviceProviderEnglishName,
    );
```


---

## 📚 Resources

* [UAEPass Developer Portal](https://docs.uaepass.ae/)
* [Common Integration Issues](https://docs.uaepass.ae/faq/common-integration-issues)
* [Riverpod Docs](https://riverpod.dev/)

---

## 💡 Contributions

Feel free to fork, improve and contribute via PR.

---

## 🧑‍💼 Maintainer

**Midlaj Nazar**
[GitHub](https://github.com/midhlajnazar) | Dubai, UAE

```

Let me know if you want a downloadable `.md` file or need additional sections like **License**, **FAQ**, or **Troubleshooting**.
```
