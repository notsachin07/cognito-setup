#!/bin/bash
set -e

echo "======================================================="
echo " AWS Cognito Native UI Setup (Flutter) - Auto Setup"
echo "======================================================="
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

CONFIG_FILE="lib/auth/amplifyconfiguration.dart"
if [ -f "$CONFIG_FILE" ]; then
    echo "Found existing amplifyconfiguration.dart. Loading defaults..."
    DEFAULT_POOL_ID=$(grep '"PoolId":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
    DEFAULT_CLIENT_ID=$(grep '"AppClientId":' "$CONFIG_FILE" | head -n 1 | awk -F'"' '{print $4}')
    DEFAULT_REGION=$(grep '"Region":' "$CONFIG_FILE" | awk -F'"' '{print $4}')
fi

read -p "Enter Cognito User Pool ID [${DEFAULT_POOL_ID}]: " POOL_ID
POOL_ID=${POOL_ID:-$DEFAULT_POOL_ID}

read -p "Enter Cognito App Client ID [${DEFAULT_CLIENT_ID}]: " CLIENT_ID
CLIENT_ID=${CLIENT_ID:-$DEFAULT_CLIENT_ID}

read -p "Enter AWS Region [${DEFAULT_REGION}]: " REGION
REGION=${REGION:-$DEFAULT_REGION}

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

# 1. Generate amplifyconfiguration.dart
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
                        "authenticationFlowType": "USER_SRP_AUTH"
                    }
                }
            }
        }
    }
}''';
EOF

# 2. Inject Native UI Template Files
echo "Injecting Native UI components..."
GITHUB_RAW_URL="https://raw.githubusercontent.com/notsachin07/cognito-setup/native-ui/flutter_auth_ui"

FILES=(
  "auth_wrapper.dart"
  "auth_service.dart"
  "login_screen.dart"
  "signup_screen.dart"
  "confirm_screen.dart"
  "forgot_password_screen.dart"
)

# If the script is run locally inside the cloned repo (for testing), copy files. Otherwise, fetch them.
if [ -d "../flutter_auth_ui" ]; then
    cp ../flutter_auth_ui/*.dart lib/auth/
elif [ -d "flutter_auth_ui" ]; then
    cp flutter_auth_ui/*.dart lib/auth/
else
    for FILE in "${FILES[@]}"; do
        echo "  -> Downloading $FILE"
        curl -sL "$GITHUB_RAW_URL/$FILE" -o "lib/auth/$FILE"
    done
fi

# 3. Add INTERNET permission to AndroidManifest.xml
MANIFEST_PATH="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST_PATH" ]; then
    if ! grep -q "android.permission.INTERNET" "$MANIFEST_PATH"; then
        sed -i '/<manifest/a \
    <uses-permission android:name="android.permission.INTERNET" />\
' "$MANIFEST_PATH"
    fi
fi

# 4. Wrap home property with AuthWrapper in main.dart
MAIN_FILE="lib/main.dart"
echo "Attempting to wrap MaterialApp home in main.dart..."

if [ -f "$MAIN_FILE" ]; then
    # Add imports if they don't exist
    if ! grep -q "import 'auth/auth_wrapper.dart';" "$MAIN_FILE"; then
        sed -i '1i import '\''auth/auth_wrapper.dart'\'';\n' "$MAIN_FILE"
    fi

    # Replace `home: Something(...)` with `home: const AuthWrapper(child: Something(...))`
    # We use sed to match `home:` followed by anything up to `,` or end of line.
    if grep -q "home:" "$MAIN_FILE"; then
        sed -i -E 's/home:\s*(.*),/home: const AuthWrapper(child: \1),/' "$MAIN_FILE"
    else
        echo "Warning: Could not find 'home:' property in lib/main.dart. You must manually wrap your home widget with AuthWrapper(child: ...)."
    fi
else
    echo "Warning: lib/main.dart not found. You must manually wrap your home widget with AuthWrapper(child: ...)."
fi

echo ""
echo "=========================================================="
echo " Setup Complete! 🎉"
echo " Native Login UI has been injected into 'lib/auth'."
echo ""
echo " How to use:"
echo " 1. Run your app: flutter run"
echo " 2. The AuthWrapper will intercept unauthenticated users and show the Native Login Screen."
echo " 3. Customize the UI in lib/auth/login_screen.dart, signup_screen.dart, etc."
echo " 4. To manually log a user out from anywhere, call: await AuthWrapper.of(context).signOut();"
echo "=========================================================="
