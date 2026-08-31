import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'amplifyconfiguration.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  const AuthWrapper({super.key, required this.child});

  static _AuthWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<_AuthWrapperState>()!;
  }

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAmplifyConfigured = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);
      setState(() {
        _isAmplifyConfigured = true;
      });
      _checkAuthStatus();
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
      // Already configured exceptions can safely be ignored on hot restart
      setState(() {
        _isAmplifyConfigured = true;
      });
      _checkAuthStatus();
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isSignedIn = await AuthService.isUserSignedIn();
      setState(() {
        _isAuthenticated = isSignedIn;
      });
    } on AuthException catch (e) {
      safePrint('Auth status check failed: ${e.message}');
    }
  }

  /// Called after successful login/signup to update the UI
  void setAuthenticated(bool authenticated) {
    setState(() {
      _isAuthenticated = authenticated;
    });
  }

  /// Triggers sign out and updates UI
  Future<void> signOut() async {
    try {
      await AuthService.signOut();
      setState(() {
        _isAuthenticated = false;
      });
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAmplifyConfigured) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If authenticated, render the main app
    if (_isAuthenticated) {
      return widget.child;
    }
    
    // If not authenticated, render the Native Login Screen
    return const LoginScreen();
  }
}
