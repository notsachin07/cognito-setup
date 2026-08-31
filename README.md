<div align="center">
<h1>AWS Cognito Native UI Setup</h1>
<p><strong>Highly Customizable Native Login & Signup UI for Flutter</strong></p>
<p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-01758F?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
</p>
</div>

Welcome to the **Native UI** branch of the AWS Cognito Setup repository! 

While Managed Login (Hosted UI) provides a fast web-based authentication flow, many applications require a fully customized, natively built authentication experience. This branch is dedicated to providing a **highly customizable Native UI** for AWS Cognito in Flutter.

## ✨ Features

- **Fully Native Widgets**: Login, Sign Up, and Password Reset flows built entirely with Flutter widgets—no webviews or custom Chrome tabs.
- **Highly Customizable**: Easily tweak colors, fonts, and layouts to match your application's exact branding.
- **One-Command Setup**: A simple automated script handles the boilerplate so you can integrate the entire Native UI authentication flow directly into any existing Flutter application in seconds!
- **Secure**: Powered by the official `amplify_flutter` and `amplify_auth_cognito` AWS packages.

## 🚀 Getting Started

You can directly inject this entire Native UI into your Flutter application by running the following command in the root of your Flutter project:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/notsachin07/cognito-setup/native-ui/setup.sh)"
```

The script will ask you for your AWS Cognito `Pool ID`, `App Client ID`, and `Region`. It will then inject the Native UI source files into `lib/auth/`, add the required Amplify dependencies, and wrap your `main.dart`!

## 🛠 Customization

Because this flow does not rely on the AWS Hosted UI, you have 100% control over the user experience. You can modify the provided text fields, validation logic, and buttons directly within your Flutter Dart code to create the perfect onboarding experience.
