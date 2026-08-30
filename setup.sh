#!/bin/bash
set -e

echo "====================================================="
echo " AWS Cognito Managed Login Setup (Flutter) - Feature"
echo "====================================================="
echo ""

if [ -f "pubspec.yaml" ]; then
    echo "Detected existing Flutter project in current directory."
    PROJECT_EXISTS=true
else
    echo "No pubspec.yaml detected in current directory."
    read -p "Enter Application Name for a new Flutter project (e.g., my_app): " APP_NAME
    if [ -z "$APP_NAME" ]; then
        echo "Application name is required!"
        exit 1
    fi
    PROJECT_EXISTS=false
fi

DEFAULT_POOL_ID=""
DEFAULT_CLIENT_ID=""
DEFAULT_REGION=""
DEFAULT_WEB_DOMAIN=""
DEFAULT_SIGN_IN=""
DEFAULT_SIGN_OUT=""
DEFAULT_SCOPES="openid,email,profile"

CONFIG_FILE="lib/auth/amplifyconfiguration.dart"
if [ -f "$CONFIG_FILE" ]; then
    echo "Found existing amplifyconfiguration.dart. Loading defaults..."
    DEFAULT_POOL_ID=$(grep '"PoolId":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    DEFAULT_CLIENT_ID=$(grep '"AppClientId":' "$CONFIG_FILE" | head -n 1 | awk -F'"' '{print $4}')
    DEFAULT_REGION=$(grep '"Region":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    DEFAULT_WEB_DOMAIN=$(grep '"WebDomain":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    DEFAULT_SIGN_IN=$(grep '"SignInRedirectURI":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    DEFAULT_SIGN_OUT=$(grep '"SignOutRedirectURI":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    # Extract scopes: ["openid","email","profile"] -> openid,email,profile
    DEFAULT_SCOPES=$(grep '"Scopes":' "$CONFIG_FILE" | sed -E 's/.*\[(.*)\].*/\1/' | sed 's/"//g')
fi

read -p "Enter Cognito User Pool ID [${DEFAULT_POOL_ID}]: " POOL_ID
POOL_ID=${POOL_ID:-$DEFAULT_POOL_ID}

read -p "Enter Cognito App Client ID [${DEFAULT_CLIENT_ID}]: " CLIENT_ID
CLIENT_ID=${CLIENT_ID:-$DEFAULT_CLIENT_ID}

read -p "Enter AWS Region [${DEFAULT_REGION}]: " REGION
REGION=${REGION:-$DEFAULT_REGION}

read -p "Enter Cognito Web Domain (e.g., my-domain.auth...) [${DEFAULT_WEB_DOMAIN}]: " WEB_DOMAIN
WEB_DOMAIN=${WEB_DOMAIN:-$DEFAULT_WEB_DOMAIN}
# Strip any http:// or https:// from the domain
WEB_DOMAIN=$(echo "$WEB_DOMAIN" | sed -E 's|^https?://||')

read -p "Enter Sign-In Redirect URL [${DEFAULT_SIGN_IN}]: " SIGN_IN_REDIRECT_URL
SIGN_IN_REDIRECT_URL=${SIGN_IN_REDIRECT_URL:-$DEFAULT_SIGN_IN}

read -p "Enter Sign-Out Redirect URL [${DEFAULT_SIGN_OUT}]: " SIGN_OUT_REDIRECT_URL
SIGN_OUT_REDIRECT_URL=${SIGN_OUT_REDIRECT_URL:-$DEFAULT_SIGN_OUT}

read -p "Enter Scopes (comma separated) [${DEFAULT_SCOPES}]: " SCOPES
SCOPES=${SCOPES:-$DEFAULT_SCOPES}

# Scopes string manipulation: we need an array of strings in dart.
# e.g., openid,email,profile -> "openid", "email", "profile"
SCOPES_FORMATTED=$(echo "$SCOPES" | sed 's/,/","/g')
SCOPES_FORMATTED="\"$SCOPES_FORMATTED\""

if [ "$PROJECT_EXISTS" = false ]; then
    echo ""
    echo "Creating new Flutter app: $APP_NAME..."
    flutter create "$APP_NAME"
    cd "$APP_NAME"
fi

echo "Adding Amplify dependencies..."
flutter pub add amplify_flutter amplify_auth_cognito

echo "Creating lib/auth directory..."
mkdir -p lib/auth

echo "Generating lib/auth/amplifyconfiguration.dart..."
cat <<EOF > lib/auth/amplifyconfiguration.dart
const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "IdentityManager": {
                    "Default": {}
                },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "$POOL_ID",
                        "AppClientId": "$CLIENT_ID",
                        "Region": "$REGION"
                    }
                },
                "Auth": {
                    "Default": {
                        "OAuth": {
                            "WebDomain": "$WEB_DOMAIN",
                            "AppClientId": "$CLIENT_ID",
                            "SignInRedirectURI": "$SIGN_IN_REDIRECT_URL",
                            "SignOutRedirectURI": "$SIGN_OUT_REDIRECT_URL",
                            "Scopes": [$SCOPES_FORMATTED]
                        }
                    }
                }
            }
        }
    }
}''';
EOF

echo "Parsing redirect URLs for AndroidManifest.xml..."
# Function to extract scheme and host
parse_url() {
    local url=$1
    if [[ "$url" =~ ^([a-zA-Z0-9+.-]+)://([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
    else
        # Fallback
        local s=$(echo "$url" | awk -F'://' '{print $1}')
        local h=$(echo "$url" | awk -F'://' '{print $2}' | awk -F'/' '{print $1}')
        echo "$s:$h"
    fi
}

SIGN_IN_PARSED=$(parse_url "$SIGN_IN_REDIRECT_URL")
SIGN_IN_SCHEME=$(echo "$SIGN_IN_PARSED" | cut -d: -f1)
SIGN_IN_HOST=$(echo "$SIGN_IN_PARSED" | cut -d: -f2)

SIGN_OUT_PARSED=$(parse_url "$SIGN_OUT_REDIRECT_URL")
SIGN_OUT_SCHEME=$(echo "$SIGN_OUT_PARSED" | cut -d: -f1)
SIGN_OUT_HOST=$(echo "$SIGN_OUT_PARSED" | cut -d: -f2)

echo "Sign In Scheme: $SIGN_IN_SCHEME, Host: $SIGN_IN_HOST"
echo "Sign Out Scheme: $SIGN_OUT_SCHEME, Host: $SIGN_OUT_HOST"

MANIFEST_PATH="android/app/src/main/AndroidManifest.xml"

# Update AndroidManifest.xml to include queries and intent-filters
if [ -f "$MANIFEST_PATH" ]; then
    # Add Internet permission if not present
    if ! grep -q "android.permission.INTERNET" "$MANIFEST_PATH"; then
        sed -i '/<manifest/a \
    <uses-permission android:name="android.permission.INTERNET" />\
' "$MANIFEST_PATH"
    fi

    # Insert queries block for browser interactions before <application> if not already there
    if ! grep -q "<queries>" "$MANIFEST_PATH"; then
        sed -i '/<application/i \
    <queries>\
        <intent>\
            <action android:name="android.intent.action.VIEW" />\
            <category android:name="android.intent.category.BROWSABLE" />\
            <data android:scheme="https" />\
        </intent>\
    </queries>\
' "$MANIFEST_PATH"
    fi

    INTENT_FILTERS="\
            <!-- Deep link for Amplify Auth Redirect (Sign In) -->\
            <intent-filter>\
                <action android:name=\"android.intent.action.VIEW\" />\
                <category android:name=\"android.intent.category.DEFAULT\" />\
                <category android:name=\"android.intent.category.BROWSABLE\" />\
                <data android:scheme=\"$SIGN_IN_SCHEME\" android:host=\"$SIGN_IN_HOST\" />\
            </intent-filter>\
\
            <!-- Deep link for Amplify Auth Redirect (Sign Out) -->\
            <intent-filter>\
                <action android:name=\"android.intent.action.VIEW\" />\
                <category android:name=\"android.intent.category.DEFAULT\" />\
                <category android:name=\"android.intent.category.BROWSABLE\" />\
                <data android:scheme=\"$SIGN_OUT_SCHEME\" android:host=\"$SIGN_OUT_HOST\" />\
            </intent-filter>\
"
    
    # Insert it before the first </activity> tag.
    # Only insert if it's not already there
    if ! grep -q "android:scheme=\"$SIGN_IN_SCHEME\"" "$MANIFEST_PATH"; then
        awk -v filter="$INTENT_FILTERS" '/<\/activity>/ && !done { print filter; done=1 } 1' "$MANIFEST_PATH" > "${MANIFEST_PATH}.tmp" && mv "${MANIFEST_PATH}.tmp" "$MANIFEST_PATH"
    fi
else
    echo "Warning: AndroidManifest.xml not found at $MANIFEST_PATH. Could not add intent filters."
fi

echo "Generating lib/auth/auth_wrapper.dart for Background Managed Login..."
cat <<EOF > lib/auth/auth_wrapper.dart
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'amplifyconfiguration.dart';

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
      safePrint('An error occurred configuring Amplify: \$e');
      // Already configured exceptions can safely be ignored on hot restart
      setState(() {
        _isAmplifyConfigured = true;
      });
      _checkAuthStatus();
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        setState(() {
          _isAuthenticated = true;
        });
      } else {
        // Trigger background Managed Login
        _signInWithWebUI();
      }
    } on AuthException catch (e) {
      safePrint('Auth status check failed: \${e.message}');
    }
  }

  Future<void> _signInWithWebUI() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI();
      if (result.isSignedIn) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    } on AuthException catch (e) {
      safePrint('Error signing in: \${e.message}');
      setState(() {
        _isAuthenticated = false;
      });
      // Automatically retry if user closes the browser
      _signInWithWebUI();
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      setState(() {
        _isAuthenticated = false;
      });
      _signInWithWebUI();
    } on AuthException catch (e) {
      safePrint('Error signing out: \${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAmplifyConfigured) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (!_isAuthenticated) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Authenticating...'),
          ),
        ),
      );
    }
    
    // Once authenticated, render the child app.
    // Call \`AuthWrapper.of(context).signOut()\` from any child widget to log out natively.
    return widget.child;
  }
}
EOF

# Try to automatically modify main.dart
MAIN_DART_PATH="lib/main.dart"
if [ -f "$MAIN_DART_PATH" ]; then
    echo "Attempting to wrap runApp in main.dart..."
    
    # Add import if missing
    if ! grep -q "auth_wrapper.dart" "$MAIN_DART_PATH"; then
        sed -i "1i import 'auth/auth_wrapper.dart';" "$MAIN_DART_PATH"
    fi
    
    # Simple regex to wrap runApp content
    if grep -q "runApp(AuthWrapper" "$MAIN_DART_PATH"; then
        echo "main.dart is already wrapped."
    else
        sed -i -E 's/runApp\(([^;]+)\)/runApp(AuthWrapper(child: \1))/' "$MAIN_DART_PATH"
    fi
else
    echo "Warning: lib/main.dart not found."
fi

echo ""
echo "Setup complete!"
echo "Authentication wrapper generated at lib/auth/auth_wrapper.dart"
echo "Your app's entry point has been updated to use AuthWrapper."
if [ "$PROJECT_EXISTS" = false ]; then
    echo "To run the application:"
    echo "  cd $APP_NAME"
    echo "  flutter run"
else
    echo "Run your application with 'flutter run'"
fi
