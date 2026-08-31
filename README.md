<div align="center">
<h1>cognito-setup</h1>
<p><strong>AWS cognito setup guide</strong></p>
<p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img src="https://img.shields.io/badge/Dart-01758F?style=for-the-badge&logo=dart&logoColor=white" />
    <img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
</p>

In this branch of [`cognito-setup`](https://github.com/notsachin07/cognito-setup) repo I will setup [`Hosted Managed Login`](#key-features) for flutter application. Follow [`Managed_Login.md`](./Managed_Login.md) for detailed steps.  

To setup Native UI with Cognito switch to [`native-ui`](https://github.com/notsachin07/cognito-setup/tree/native-ui) branch.   

To setup Web Application with Cognito switch to [`website`](https://github.com/notsachin07/cognito-setup/tree/website) branch.
</div>

For basic understading of Cognito and it features refer to [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)

---
# Table of content 
- [AWS Cognito Overview](#aws-cognito-overview)
  1. [Key Features](#key-features)
  2. [Manage Login vs Native UI](#managed-login-vs-native-ui)
- [What is callback URL](#what-is-callback-url)
- [What is sign out URL](#what-is-sign-out-url)
- [What is JWT](#what-is-jwt)

---

# AWS Cognito Overview
AWS Cognito provides user authentication and access control for web and mobile applications, supporting both AWS-hosted and custom user interfaces.

## Key Features

* **Hosted Managed Login:** Easily customize the AWS-hosted authentication UI without writing front-end code. Changes propagate immediately.
* **Mobile Authentication:** Uses system-wide browsers for safe, secure authentication before seamlessly redirecting users back to your mobile app.
* **Custom UI Support:** Allows full control over the user experience by letting you build custom login interfaces while Cognito securely handles the backend authentication flow.

---

## Managed Login vs. Native UI

| Feature | Managed Login (Hosted UI) | Native UI (Custom) |
| --- | --- | --- |
| **UI Control** | Low (Configured via AWS Console) | Full (Custom code written by developer) |
| **Development Effort** | Minimal | High (Requires building and maintaining all auth pages) |
| **Authentication Flow** | Handled entirely by AWS via browser redirect | Managed via application API integration |
| **Potential Downsides** | Relies on browser functionality; if the browser fails, users cannot log in. | Requires ongoing UI maintenance and state management. |
---
# What is callback URL
In traditional web app, `callback URL` is webpage where user is redirected after authentication.  
But in mobile apps we don't have website or webpage so why do we will use **URL** there too? The answer is URL doesn't have to point to website on Internet. URL is just an address.  

> **For  Example**    
When you type [`https://google.com`](https://google.com) into your phone, the `https://` part tells your phone's operating system (Android/iOS): *"Hey, this is a web address, open the web browser."*   
But you can invent your own prefix for your app. For example, you can tell Android and iOS: "If you ever see a link that starts with `myapp://`, don't open the web browser. Open my app instead."  
This is called a **Custom URI Scheme** (or a `deep link`). 

Learn more about [`callback URL`](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-terms.html#term-callbackurl). In all of your project you have to handle callback received after authentication as it contains the [`JWT tokens`](#what-is-jwt) required by your backend application to identify the user and it session.   

---
# What is sign out URL
The sign-out URL is a redirect page sent by Cognito when your application signs users out. This is needed only if you want Cognito to direct signed-out users to a page other than the callback URL.  
Learn more about [`sign out URL`](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-terms.html)

---
# What is JWT 
To learn what is JWT token is and how it work refer [`JWT`](https://www.jwt.io/introduction).  

JWT self content, it contain header, payload and signature. So if you place an AWS API Gateway in front of your backend services, you can attach a **Cognito Authorizer**. The gateway will automatically verify the signature and the token's expiration before the request ever reaches your code. And if API requests hit your server directly, you must use a library to verify the signature and expiration time of JWT token on every incoming request.
> **Note**: Any one can decode JWT token hence we don't put any sensitive information in JWT token.  
---
# What to look for in the JWT
The JWT payload of Cognito contain lot of information but you need to carefully look at those.
- `sub`: The unique identifier (UUID) for this user in your Cognito pool. This is what you should save in your database.
- `email`: The user's email address.
- `exp`: The expiration time (in Unix epoch seconds).
- `cognito:username`: How the user is identified inside AWS.