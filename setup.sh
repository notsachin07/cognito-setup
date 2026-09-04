#!/bin/bash
set -e

echo "======================================================="
echo " AWS Cognito Managed Login Setup (Website)"
echo "======================================================="
echo ""

# Extract existing values if auth.js is present
DEFAULT_DOMAIN=""
DEFAULT_CLIENT_ID=""
DEFAULT_CALLBACK=""
DEFAULT_SIGNOUT=""
DEFAULT_SCOPES=""

if [ -f "auth.js" ]; then
    DEFAULT_DOMAIN=$(grep 'const COGNITO_DOMAIN' auth.js | cut -d'"' -f2 || true)
    DEFAULT_CLIENT_ID=$(grep 'const CLIENT_ID' auth.js | cut -d'"' -f2 || true)
    DEFAULT_CALLBACK=$(grep 'const CALLBACK_URL' auth.js | cut -d'"' -f2 || true)
    DEFAULT_SIGNOUT=$(grep 'const SIGNOUT_URL' auth.js | cut -d'"' -f2 || true)
fi

read -p "Enter Cognito Web Domain (e.g., https://my-app.auth.us-east-1.amazoncognito.com) [$DEFAULT_DOMAIN]: " COGNITO_DOMAIN
COGNITO_DOMAIN=${COGNITO_DOMAIN:-$DEFAULT_DOMAIN}
if [[ $COGNITO_DOMAIN == */ ]]; then
  COGNITO_DOMAIN=${COGNITO_DOMAIN%?}
fi

read -p "Enter Cognito App Client ID [$DEFAULT_CLIENT_ID]: " CLIENT_ID
CLIENT_ID=${CLIENT_ID:-$DEFAULT_CLIENT_ID}

read -p "Enter Callback URL [$DEFAULT_CALLBACK]: " CALLBACK_URL
CALLBACK_URL=${CALLBACK_URL:-$DEFAULT_CALLBACK}

read -p "Enter Sign Out URL [$DEFAULT_SIGNOUT]: " SIGNOUT_URL
SIGNOUT_URL=${SIGNOUT_URL:-$DEFAULT_SIGNOUT}

read -p "Enter OAuth Scopes (space separated, e.g., email openid profile) [$DEFAULT_SCOPES]: " SCOPES
SCOPES=${SCOPES:-$DEFAULT_SCOPES}
# Convert commas to spaces, squeeze multiple spaces to one, then convert spaces to +
FORMATTED_SCOPES=$(echo "$SCOPES" | tr ',' ' ' | tr -s ' ' | tr ' ' '+')

echo ""

echo "Generating auth.js..."
cat << EOF > auth.js
const COGNITO_DOMAIN = "$COGNITO_DOMAIN";
const CLIENT_ID = "$CLIENT_ID";
const CALLBACK_URL = "$CALLBACK_URL";
const SIGNOUT_URL = "$SIGNOUT_URL";

// Decode a JWT token (Base64Url decode)
function parseJwt(token) {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    } catch (e) {
        console.error("Failed to parse JWT", e);
        return null;
    }
}

// Set a secure cookie
function setSecureCookie(name, value, days) {
    let expires = "";
    if (days) {
        const date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "")  + expires + "; path=/; Secure; SameSite=Strict";
}

// Get a cookie by name
function getCookie(name) {
    const nameEQ = name + "=";
    const ca = document.cookie.split(';');
    for(let i=0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}

// Clear a cookie
function eraseCookie(name) {
    document.cookie = name + '=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT; Secure; SameSite=Strict';
}

// Redirect to Cognito Hosted UI for login
function login() {
    const loginUrl = \`\${COGNITO_DOMAIN}/login?client_id=\${CLIENT_ID}&response_type=token&scope=$FORMATTED_SCOPES&redirect_uri=\${encodeURIComponent(CALLBACK_URL)}\`;
    window.location.href = loginUrl;
}

// Redirect to Cognito to clear session, then return to signout URL
function logout() {
    eraseCookie("id_token");
    eraseCookie("access_token");
    const logoutUrl = \`\${COGNITO_DOMAIN}/logout?client_id=\${CLIENT_ID}&logout_uri=\${encodeURIComponent(SIGNOUT_URL)}\`;
    window.location.href = logoutUrl;
}

// Check if URL contains tokens (Implicit Grant callback)
function handleCallback() {
    const hash = window.location.hash.substring(1);
    if (hash) {
        const params = new URLSearchParams(hash);
        
        // Prevent infinite loops if AWS returns an error
        if (params.get("error")) {
            console.error("Cognito Error:", params.get("error_description"));
            // Clear the hash so it doesn't try again
            window.history.replaceState(null, null, window.location.pathname);
            return false; // Error occurred
        }

        const idToken = params.get("id_token");
        const accessToken = params.get("access_token");

        if (idToken && accessToken) {
            // Securely store tokens in cookies (1 hour expiration)
            setSecureCookie("id_token", idToken, 1/24); 
            setSecureCookie("access_token", accessToken, 1/24);
            
            // Clear the hash from the URL for a cleaner look
            window.history.replaceState(null, null, window.location.pathname);
            return true; // Success
        }
    }
    return true; // No hash, proceed normally
}

// Public API
function getIdToken() {
    return getCookie("id_token");
}

function getAccessToken() {
    return getCookie("access_token");
}

function getUser() {
    const token = getIdToken();
    if (!token) return null;
    return parseJwt(token);
}

// Initialize on page load
window.onload = () => {
    const isClean = handleCallback();
    if (!isClean) return; // Stop if there was an OAuth error
    
    if (!getIdToken()) {
        // Automatically redirect to login if user is not authenticated
        login();
    }
};
EOF

echo ""
echo "=========================================================="
echo " Setup Complete! 🎉"
echo " 'auth.js' has been successfully injected into your project."
echo "=========================================================="
