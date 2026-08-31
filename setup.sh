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

echo ""
echo "--- UI Configuration ---"
echo "Select your primary login method:"
echo "1) Email (Default)"
echo "2) Username"
echo "3) Phone Number"
echo "4) Preferred Username"
read -p "Enter choice (1-4) [1]: " LOGIN_CHOICE

case $LOGIN_CHOICE in
  2)
    LOGIN_LABEL="Username"
    LOGIN_ICON="Icons.person"
    LOGIN_KEYBOARD="TextInputType.text"
    ;;
  3)
    LOGIN_LABEL="Phone Number"
    LOGIN_ICON="Icons.phone"
    LOGIN_KEYBOARD="TextInputType.phone"
    ;;
  4)
    LOGIN_LABEL="Preferred Username"
    LOGIN_ICON="Icons.badge"
    LOGIN_KEYBOARD="TextInputType.text"
    ;;
  *)
    LOGIN_LABEL="Email"
    LOGIN_ICON="Icons.email"
    LOGIN_KEYBOARD="TextInputType.emailAddress"
    ;;
esac

echo ""
echo "Select additional mandatory signup fields (comma separated numbers, e.g., 1,4,9):"
echo " 1) address            7) locale              13) preferred_username"
echo " 2) birthdate          8) middle_name         14) profile"
echo " 3) email              9) name                15) updated_at"
echo " 4) family_name       10) nickname            16) website"
echo " 5) gender            11) phone_number        17) zoneinfo"
echo " 6) given_name        12) picture             18) Custom Field..."
read -p "Enter choices []: " SIGNUP_SELECTIONS

SIGNUP_FIELDS_INPUT=""
IFS=',' read -ra SEL_ADDR <<< "$SIGNUP_SELECTIONS"
for SEL in "${SEL_ADDR[@]}"; do
    SEL=$(echo "$SEL" | xargs)
    case $SEL in
        1) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT address," ;;
        2) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT birthdate," ;;
        3) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT email," ;;
        4) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT family_name," ;;
        5) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT gender," ;;
        6) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT given_name," ;;
        7) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT locale," ;;
        8) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT middle_name," ;;
        9) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT name," ;;
       10) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT nickname," ;;
       11) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT phone_number," ;;
       12) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT picture," ;;
       13) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT preferred_username," ;;
       14) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT profile," ;;
       15) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT updated_at," ;;
       16) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT website," ;;
       17) SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT zoneinfo," ;;
       18)
          read -p "Enter exact name of custom field (e.g. custom:role): " CUSTOM_FLD
          if [ -n "$CUSTOM_FLD" ]; then
              SIGNUP_FIELDS_INPUT="$SIGNUP_FIELDS_INPUT $CUSTOM_FLD,"
          fi
          ;;
    esac
done

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

# 2.5 Process UI files
echo "Configuring Native UI Templates..."

# Replace placeholders
for FILE in lib/auth/*.dart; do
    sed -i "s/__LOGIN_LABEL__/$LOGIN_LABEL/g" "$FILE"
    sed -i "s/__LOGIN_ICON__/$LOGIN_ICON/g" "$FILE"
    sed -i "s/__LOGIN_KEYBOARD__/$LOGIN_KEYBOARD/g" "$FILE"
done

# Generate dynamic signup fields
if [ -n "$SIGNUP_FIELDS_INPUT" ]; then
    > .tmp_controllers
    > .tmp_ui_fields
    echo "        userAttributes: {" > .tmp_attrs
    
    IFS=',' read -ra ADDR <<< "$SIGNUP_FIELDS_INPUT"
    for FIELD in "${ADDR[@]}"; do
        FIELD=$(echo "$FIELD" | xargs)
        if [ -z "$FIELD" ]; then continue; fi
        
        CTRL_NAME="_${FIELD}Controller"
        LABEL=$(echo "$FIELD" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        
        echo "  final $CTRL_NAME = TextEditingController();" >> .tmp_controllers
        
        cat <<EOF >> .tmp_ui_fields
                  TextFormField(
                    controller: $CTRL_NAME,
                    decoration: InputDecoration(labelText: '$LABEL', border: const OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? '$LABEL is required' : null,
                  ),
                  const SizedBox(height: 16),
EOF
        
        echo "          CognitoUserAttributeKey.parse('$FIELD'): $CTRL_NAME.text.trim()," >> .tmp_attrs
    done
    echo "        }" >> .tmp_attrs

    # Inject using sed
    sed -i -e '/final _passwordController/r .tmp_controllers' lib/auth/signup_screen.dart
    sed -i -e '/\/\/ __SIGNUP_FIELDS__/r .tmp_ui_fields' lib/auth/signup_screen.dart
    sed -i -e '/\/\/ __SIGNUP_ATTRIBUTES__/{' -e 'r .tmp_attrs' -e 'd' -e '}' lib/auth/signup_screen.dart

    rm -f .tmp_controllers .tmp_ui_fields .tmp_attrs
else
    sed -i "s/\/\/ __SIGNUP_ATTRIBUTES__//" lib/auth/signup_screen.dart
    sed -i "s/\/\/ __SIGNUP_FIELDS__//" lib/auth/signup_screen.dart
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
