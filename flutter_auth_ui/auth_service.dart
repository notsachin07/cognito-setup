import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  /// Sign in a user with email and password
  static Future<SignInResult> signIn(String email, String password) async {
    return await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
  }

  /// Sign up a new user
  static Future<SignUpResult> signUp(String username, String password,
      {Map<AuthUserAttributeKey, String>? userAttributes}) async {
    return await Amplify.Auth.signUp(
      username: username,
      password: password,
      options: SignUpOptions(
        userAttributes: userAttributes ?? {},
      ),
    );
  }

  /// Confirm user signup with OTP code
  static Future<SignUpResult> confirmSignUp(String email, String code) async {
    return await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  /// Resend confirmation code
  static Future<ResendSignUpCodeResult> resendSignUpCode(String email) async {
    return await Amplify.Auth.resendSignUpCode(username: email);
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  /// Request password reset code
  static Future<ResetPasswordResult> resetPassword(String email) async {
    return await Amplify.Auth.resetPassword(username: email);
  }

  /// Confirm new password with code
  static Future<ResetPasswordResult> confirmResetPassword(
      String email, String newPassword, String confirmationCode) async {
    return await Amplify.Auth.confirmResetPassword(
      username: email,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );
  }

  /// Check current auth session
  static Future<bool> isUserSignedIn() async {
    final session = await Amplify.Auth.fetchAuthSession();
    return session.isSignedIn;
  }
}
