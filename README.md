<div align="center">
<h1>AWS Cognito Managed Login (Website Integration)</h1>
<p><strong>A simple, dependency-free vanilla JS integration for AWS Cognito Hosted UI</strong></p>
<p>
    <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" />
    <img src="https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white" />
    <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
</p>

Welcome to the **website** branch of the AWS Cognito Setup repository! 
</div>

This branch focuses on integrating AWS Cognito's **Managed Login (Hosted UI)** into a standard web application. It uses the **OAuth Implicit Grant** flow, which means you do **not** need a backend server, Node.js, or complex SDKs like `aws-amplify` or React. It relies purely on standard browser redirects and Javascript.

---
# Table of Contents
- [Features](#features)
- [Prerequisites (AWS Console Setup)](#prerequisites-aws-console-setup)
- [Understanding Callback & Sign Out URLs](#understanding-callback--sign-out-urls)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [How it Works (JWT Tokens)](#how-it-works-jwt-tokens)

---

## Features

- **Zero Dependencies**: Uses standard vanilla JavaScript (`window.location`) to handle OAuth redirects and JWT parsing. No NPM, Webpack, or large libraries required.
- **Immediate Setup**: A simple `setup.sh` script generates a ready-to-use HTML and JS file configured specifically for your User Pool.
- **Secure**: Authentication occurs on Amazon's highly secure, hosted login pages.

## Prerequisites (AWS Console Setup)

Before running the script, you must configure your AWS Cognito App Client to support the Implicit Grant flow and allow your local URLs.

1. Go to the **AWS Console** -> **Cognito** -> **User Pools** -> Select your User Pool.
2. Go to the **App integration** tab.
3. Scroll down to **App client list** and select your Web App Client.
4. Under **Hosted UI**, click **Edit**.
5. Add your **Allowed callback URLs** (e.g., `http://localhost:8000/` for local testing).
6. Ensure your **Callback URL(s)** matches the URLs you will test with (e.g., `http://localhost:8000/`).
7. Ensure your **Sign out URL(s)** match as well.
> [!IMPORTANT]
> **Enable Implicit Grant!** You must explicitly enable the Implicit Grant for this to work. Under **OAuth 2.0 grant types**, check the box for **Implicit grant**.

> [!WARNING]
> **No Client Secret!** Because this is a frontend-only Vanilla JS website, web browsers cannot securely hold secrets. When you create your App Client in AWS Cognito, you **MUST** configure it without a client secret (select "Don't generate a client secret"). If your App Client has a secret, Cognito will block the Implicit Grant and throw an "Invalid Request" error.

9. Under **OpenID Connect scopes**, check **email**, **openid**, and **profile**.
10. Click **Save changes**.

## Getting Started

To instantly inject AWS Cognito Authentication into your existing website, run this command in your project directory:

```bash
bash <(curl -s https://raw.githubusercontent.com/notsachin07/cognito-setup/website/setup.sh)
```

The script will ask for your Cognito details and automatically generate and inject `auth.js` into your `index.html`!

## API Documentation

Once `auth.js` is generated and included in your project via `<script src="auth.js"></script>`, you have access to a powerful set of global utility functions.

The script automatically detects unauthenticated users and redirects them to the Cognito login page. After authentication, the tokens are securely stored in **`Secure; SameSite=Strict` HTTP Cookies** (a highly secure frontend practice that prevents bots and Cross-Site Request Forgery).

### `getUser()`
Returns the decoded JWT payload as a JavaScript object (e.g., email, username). Returns `null` if the user is not authenticated.
```javascript
const user = getUser();
if (user) {
    console.log("Logged in as:", user.email);
}
```

### `getIdToken()`
Returns the raw AWS Cognito JWT ID Token from the secure cookie. Use this token in the `Authorization` header when making API requests to your backend to verify the user.
```javascript
const token = getIdToken();
fetch("https://api.yourdomain.com/data", {
    headers: { "Authorization": `Bearer ${token}` }
});
```

### `getAccessToken()`
Returns the raw AWS Cognito Access Token. 

### `login()`
Manually triggers a redirect to the Cognito Hosted UI for login. (This is called automatically if a user visits the page without a valid token).
```html
<button onclick="login()">Log In</button>
```

## Handling Sign Out

To securely log a user out of your application and clear their active session with AWS Cognito, call the `logout()` function.

```html
<button onclick="logout()">Sign Out</button>
```

When called, this function will:
1. Instantly destroy the JWT tokens stored in your secure browser cookies.
2. Redirect the user to the Cognito Hosted UI logout endpoint (to kill the active AWS session).
3. Automatically return the user back to your configured **Sign Out URL** (which, due to the auto-login logic, will instantly bounce them back to the login screen).

## Understanding Callback & Sign Out URLs

When integrating AWS Cognito with a website, authentication happens on a separate Amazon-hosted domain (e.g., `https://your-domain.auth.us-east-1.amazoncognito.com`). 

Once the user successfully enters their credentials on that page, AWS needs to know where to send them back to.

- **Callback URL**: The exact webpage URL AWS will redirect the user to *after a successful login*. AWS will append the authentication tokens (JWT) directly to this URL as a hash (e.g., `http://localhost:8000/#id_token=ey...`). Your JavaScript reads this URL, extracts the token, and logs the user in on the frontend.
- **Sign Out URL**: The exact webpage URL AWS will redirect the user to *after they log out*. When your user clicks logout, your script redirects them to Cognito's `/logout` endpoint to clear the Amazon session cookie, and Cognito subsequently bounces them back to your Sign Out URL.

> [!IMPORTANT]
> For security, AWS strictly validates these URLs. The URLs you provide in the setup script must perfectly match the URLs you configured in the AWS Console. A trailing slash matters! `http://localhost:8000/` is completely different from `http://localhost:8000` to AWS.
