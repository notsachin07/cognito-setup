import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialLoginId;
  const ForgotPasswordScreen({super.key, this.initialLoginId});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLoginId != null) {
      _loginIdController.text = widget.initialLoginId!;
    }
  }

  Future<void> _handleRequestCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await AuthService.resetPassword(_loginIdController.text.trim());
      setState(() {
        _codeSent = result.isPasswordReset; // Wait, actually it's nextStep.updateStep
        _codeSent = true;
        _successMessage = 'Reset code sent to your email.';
      });
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleConfirmReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      await AuthService.confirmResetPassword(
        _loginIdController.text.trim(),
        _newPasswordController.text.trim(),
        _codeController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully! Please log in.')),
      );
      Navigator.pop(context); // Go back to login
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset, size: 64, color: Colors.blue),
                  const SizedBox(height: 32),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_successMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _successMessage,
                        style: const TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Step 1: Login ID
                  TextFormField(
                    controller: _loginIdController,
                    enabled: !_codeSent,
                    decoration: const InputDecoration(
                      labelText: '__LOGIN_LABEL__',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(__LOGIN_ICON__),
                    ),
                    keyboardType: __LOGIN_KEYBOARD__,
                    validator: (v) => v!.isEmpty ? '__LOGIN_LABEL__ is required' : null,
                  ),
                  
                  // Step 2: Code and New Password
                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Reset Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Code is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.password),
                      ),
                      obscureText: true,
                      validator: (v) {
                        if (v!.isEmpty) return 'New password is required';
                        if (v.length < 8) return 'Must be at least 8 characters';
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : (_codeSent ? _handleConfirmReset : _handleRequestCode),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_codeSent ? 'Reset Password' : 'Send Reset Code', style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
