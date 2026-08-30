<div align="center">
<h1>AWS Cognito Managed Login</h1>
<p><strong>Setup Guide for Flutter Application using Cognito Managed login UI</strong></p>
<p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-01758F?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
</p>
</div>

AWS provides official Flutter packages [`amplify_flutter`](https://pub.dev/packages/amplify_flutter) and [`amplify_auth_cognito`](https://pub.dev/packages/amplify_auth_cognito) that handle complex native browser routing entirely behind the scenes. We have provided a fully automated setup script to integrate AWS Cognito Managed Login seamlessly into any Flutter application!

# Table of Content
- [Prerequisites](#1-prerequisites-aws-console)
- [Automated Setup via Script](#2-automated-setup-via-script)
  1. [Remote Execution](#1-remote-execution-recommended)
  2. [Manual Execution](#2-manual-execution)
  3. [What the script does](#3-what-the-script-does)
- [Security Overview](#3-security-overview)
  1. [How safe is this authentication system?](#how-safe-is-this-authentication-system)
  2. [Is the AuthWrapper secure?](#is-the-authwrapper-secure)
  3. [Can it be compromised?](#can-it-be-compromised)
- [How Background Authentication Works](#4-how-background-authentication-works)
- [What to do next?](#5-what-to-do-next)
  1. [Setting up a Sign Out Button](#setting-up-a-sign-out-button)
  2. [Accessing User Tokens](#accessing-user-tokens)
- [Test Example](#6-test-example-libtest_pagedart)

## 1. Prerequisites (AWS Console)

Before running the setup script, you will need the following values from your AWS Cognito Console:
- **Pool ID**: Go to *Cognito > User Pools > [Your Pool]*. The Pool ID is shown at the top of the pool overview (e.g., `us-east-1_xxxxxxxxx`).
- **Client ID**: Go to *App integration* > scroll down to *App client list*. Copy the Client ID.
- **Region**: This is the AWS region your User Pool is deployed in (e.g., `us-east-1`).
- **Web Domain**: Go to *App integration* > *Domain*. If you set up a Cognito domain, it looks like `https://your-domain.auth.us-east-1.amazoncognito.com`.
- **Redirect URLs**: These must exactly match the "Allowed callback URLs" and "Allowed sign-out URLs" you configured in your App Client. Mobile apps typically use custom URI schemes (e.g., `myapp://callback/` and `myapp://signout/`).

## 2. Automated Setup via Script

Instead of manually configuring Android Manifests, dependency injection, and boilerplate Amplify configs, simply run the provided setup script from the root of your Flutter project.

### 1. Remote Execution (Recommended)
You can directly fetch and run the setup script from GitHub without manually downloading it to your machine:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/notsachin07/cognito-setup/main/setup.sh)"
```

### 2. Manual Execution
If you downloaded the script manually to your project root:
```bash
chmod +x setup.sh
./setup.sh
```

### 3. What the script does 
- Adds the required Amplify packages to your `pubspec.yaml`.
- Parses your custom URI schemes and injects Intent Filters directly into your `AndroidManifest.xml` (ensuring the browser closes properly after login/logout).
- Generates your `lib/auth/amplifyconfiguration.dart`.
- Generates a `lib/auth/auth_wrapper.dart` widget.
- Automatically wraps your `runApp()` entry point in `lib/main.dart` with the new `AuthWrapper`.

## 3. Security Overview

### How safe is this authentication system?

This setup leverages AWS Cognito, which is an industry-standard, highly secure authentication provider used by millions of applications globally.

### Is the AuthWrapper secure?

Yes. The `AuthWrapper` acts as a UI gatekeeper, but it does not handle any sensitive cryptography or token storage directly. All cryptographic operations (like PKCE for OAuth2), token validation, and secure storage (using Android EncryptedSharedPreferences and iOS Keychain) are handled natively by the official `amplify_flutter` packages behind the scenes.

### Can it be compromised?

Because this solution relies entirely on Cognito Hosted UI (Managed Login), your Flutter app never directly handles the user's password in plain text. It is extremely secure. The system could only be compromised if someone gains unauthorized access to your AWS Console, or if the user's physical device is severely compromised (e.g., rooted/jailbroken with malicious software reading protected memory). For standard production environments, this is considered a best-practice, enterprise-grade architecture.

## 4. How Background Authentication Works

The generated `AuthWrapper` acts as an invisible shield for your application. When your app launches:
1. `AuthWrapper` initializes Amplify.
2. It silently checks the user's authentication session in the background.
3. If the user **is not** logged in, it will automatically launch the Cognito Hosted UI browser tab.
4. Once the user signs in (or if they were already signed in), `AuthWrapper` dismisses itself and renders your original application.

## 5. What to do next?

### Setting up a Sign Out Button
Since `AuthWrapper` handles the login natively in the background, you just need to provide a way for users to sign out from within your app's UI.

> [!WARNING]
> **"Invalid Request" Error on Logout?**
> If you click Sign Out and the browser shows an "invalid request" screen, it means the *Sign-Out Redirect URL* in your app does not **perfectly** match the *Allowed sign-out URLs* in your AWS Cognito Console. Even a single missing trailing slash (e.g. `myapp://signout` instead of `myapp://signout/`) will trigger this error! Fix this in the AWS Console.

To sign a user out, call `AuthWrapper.of(context).signOut()`. This method will handle signing the user out via Amplify and then instantly reset the app's state, returning the user to the Hosted UI login screen.

**Example usage on a button:**
```dart
ElevatedButton(
  onPressed: () async {
    // IMPORTANT: Make sure to wrap it in an async function!
    await AuthWrapper.of(context).signOut();
  },
  child: const Text('Sign Out'),
)
```

### Accessing User Tokens
If your app needs the JWT tokens to authenticate with your backend APIs, you can fetch the current session anywhere in your app:

```dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

Future<void> printTokens() async {
  try {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final idToken = session.userPoolTokensResult.value.idToken.raw;
    final accessToken = session.userPoolTokensResult.value.accessToken.raw;
    print('ID Token: $idToken');
  } on AuthException catch (e) {
    safePrint('Could not fetch tokens: ${e.message}');
  }
}
```

## 6. Test Example (`lib/test_page.dart`)

Here is a complete, drop-in example of a simple test page you can use to verify the login/sign-out functionality and see your User ID. 

### How to use this example:
1. **Create the file**: Copy the code below into a new file located at `lib/test_page.dart`.
2. **Update your `main.dart`**: Make sure your `main.dart` is set up to import both `test_page.dart` and `auth_wrapper.dart`.
3. **Wrap the widget**: In your `MaterialApp`, set the `home` property to `AuthWrapper(child: TestAuthPage())`.

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'auth/auth_wrapper.dart';
import 'test_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Auth Test App',
      // The AuthWrapper sits transparently on top of TestAuthPage
      home: AuthWrapper(child: TestAuthPage()), 
    );
  }
}
```

```dart
// lib/test_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class TestAuthPage extends StatefulWidget {
  const TestAuthPage({super.key});

  @override
  State<TestAuthPage> createState() => _TestAuthPageState();
}

class _TestAuthPageState extends State<TestAuthPage> {
  String _userInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() {
        _userInfo = 'User ID: ${user.userId}';
      });
    } catch (e) {
      setState(() {
        _userInfo = 'Error fetching user: $e';
      });
    }
  }

  // Trigger Sign Out
  Future<void> _handleSignOut() async {
    // Calling AuthWrapper.of(context).signOut() handles the logout 
    // AND synchronously resets the UI state back to the login screen.
    await AuthWrapper.of(context).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Successfully Authenticated!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(_userInfo, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
  }
}
```