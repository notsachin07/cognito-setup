<div align="center">
<h1>AWS Cognito Native UI Setup</h1>
<p><strong>Highly Customizable Native Login & Signup UI for Flutter</strong></p>
<p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-01758F?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
</p>

Welcome to the **Native UI** branch of the AWS Cognito Setup repository! 
</div>

While Managed Login (Hosted UI) provides a fast web-based authentication flow, many applications require a fully customized, natively built authentication experience. This branch is dedicated to providing a **highly customizable Native UI** for AWS Cognito in Flutter.

---
# Table of Contents
- [Features](#features)
- [Getting Started](#getting-started)
- [Customization](#customization)
- [Setting up a Sign Out Button](#setting-up-a-sign-out-button)
- [Accessing User Tokens](#accessing-user-tokens)
- [Security Tip: Prevent User Existence Errors](#security-tip-prevent-user-existence-errors)
---
## Features

- **Fully Native Widgets**: Login, Sign Up, and Password Reset flows built entirely with Flutter widgets—no webviews or custom Chrome tabs.
- **Highly Customizable**: Easily tweak colors, fonts, and layouts to match your application's exact branding.
- **One-Command Setup**: A simple automated script handles the boilerplate so you can integrate the entire Native UI authentication flow directly into any existing Flutter application in seconds!
- **Secure**: Powered by the official `amplify_flutter` and `amplify_auth_cognito` AWS packages.

## Getting Started

You can directly inject this entire Native UI into your Flutter application by running the following command in the root of your Flutter project:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/notsachin07/cognito-setup/native-ui/setup.sh)"
```

The script will ask you for your AWS Cognito `Pool ID`, `App Client ID`, and `Region`. It will then inject the Native UI source files into `lib/auth/`, add the required Amplify dependencies, and wrap your `main.dart`!

## Customization

Because this flow does not rely on the AWS Hosted UI, you have 100% control over the user experience. You can modify the provided text fields, validation logic, and buttons directly within your Flutter Dart code to create the perfect onboarding experience.

## Setting up a Sign Out Button

Since `AuthWrapper` handles the login natively in the background, you just need to provide a way for users to sign out from within your app's UI. To sign a user out, call `AuthWrapper.of(context).signOut()`. This method will handle signing the user out via Amplify and then instantly reset the app's state, returning the user to the Native Login screen.

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

## Accessing User Tokens

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

## Security Tip: Prevent User Existence Errors

By default, Amazon Cognito prevents malicious scrapers and bots from discovering which users exist in your pool. If an attacker attempts to log in with or recover an account for an email that doesn't exist, Cognito will intentionally return a generic authentication failure (or send a fake code) instead of confirming that the user was not found.

If you would prefer to display specific "User does not exist" errors in your Native UI, you can disable this security feature:
1. Go to the **AWS Console** -> **Cognito** -> **User Pools**
2. Select your User Pool and go to the **App integration** tab.
3. Select your **App client** from the list at the bottom.
4. Click the **Edit** button in the top right.
5. Scroll down and uncheck **Prevent user existence errors**.
6. Save your changes.
