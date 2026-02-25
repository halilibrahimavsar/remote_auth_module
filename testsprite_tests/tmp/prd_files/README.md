# Remote Auth Module

A premium, multi-platform Firebase authentication module for Flutter designed with **Clean Architecture** and **BLoC**. This module provides a production-ready authentication system with elite aesthetics, functional error handling, and flexible integration patterns.

---

## 📋 Table of Contents
- [✨ Features](#-features)
- [🚀 Quick Start](#-quick-start)
- [📱 Platform Configuration](#-platform-configuration)
- [🔐 Authentication Providers](#-authentication-providers)
- [🏗 Integration Patterns](#-integration-patterns)
  - [1. Ready-to-Use (The Gate Template)](#1-ready-to-use-the-gate-template)
  - [2. Full Control (Manual Building)](#2-full-control-manual-building)
  - [3. Professional (DI & Environment Setup)](#3-professional-di--environment-setup)
- [🎨 Theming & UI Customization](#-theming--ui-customization)
- [🔥 Firestore & Security](#-firestore--security)
- [🧪 Testing](#-testing)

---

## ✨ Features

- **True Multi-Platform**: First-class support for Web, Mobile, and Desktop.
- **Pure Domain Logic**: All business rules are in pure Dart (Zero Flutter dependencies).
- **Elite UI/UX**: Custom-designed screens with glassmorphism, smooth transitions, and premium typography.
- **Smart Session Recovery**: Intelligent "Remember Me" and automatic session restoration.
- **User Sync**: Optional automatic user profile creation in Firestore.

---

## 🚀 Quick Start

Add to your `pubspec.yaml`:
```yaml
dependencies:
  remote_auth_module:
    path: path/to/module
```

Initialize with zero configuration:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

---

## 📱 Platform Configuration

### Android
- **SHA Fingerprints**: Add SHA-1 and SHA-256 to Firebase Console.
- **Config**: Place `google-services.json` in `android/app/`.

### iOS & macOS
- **URL Schemes**: Add `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` to Xcode URL Types.
- **Capabilities**: Enable "Keychain Sharing" and "App Sandbox" (Network) for macOS.

### Web
- **Meta Tag**: Add to `web/index.html` `<head>`:
  ```html
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
  ```
- **Domains**: Whitelist `localhost` and your domain in Firebase Console.

---

## 🏗 Integration Patterns

### 1. Ready-to-Use (The Gate Template)
The `RemoteAuthFlow` is a high-level widget that manages the entire auth lifecycle (loading, login, registration, phone verification, and email gates).

```dart
RemoteAuthFlow(
  logo: Image.asset('assets/logo.png'),
  loginTitle: 'Welcome Back',
  showGoogleSignIn: true,
  showPhoneSignIn: true,
  authenticatedBuilder: (context, user) {
    return MainDashboard(user: user);
  },
)
```

### 2. Full Control (Manual Building)
Use this if you want to use the module's pre-built pages but control the navigation flow yourself.

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthenticatedState) return HomeScreen(user: state.user);
    if (state is EmailVerificationRequiredState) return EmailVerificationPage(user: state.user);
    
    return LoginPage(
      title: 'Custom Layout',
      onRegisterTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => RegisterPage(onLoginTap: () => Navigator.pop(context)),
      )),
    );
  },
)
```

### 3. Professional (DI & Environment Setup)
For serious applications, use a Dependency Injection pattern to configure the repository based on the environment.

```dart
// di_container.dart
final getIt = GetIt.instance;

void setupDI() {
  getIt.registerSingleton<AuthRepository>(
    FirebaseAuthRepository(
      createUserCollection: true, // Auto-sync profiles
      usersCollectionName: 'members', // Custom collection
      serverClientId: 'YOUR_WEB_CLIENT_ID', // Reqd for Android Google Sign-In
    ),
  );
}

// main.dart
BlocProvider(
  create: (_) => AuthBloc(repository: getIt<AuthRepository>())
    ..add(const InitializeAuthEvent()),
  child: const AppView(),
)
```

---

## 🎨 Theming & UI Customization

All primary UI components (Login, Register, Phone Dialogs) support:
- **`logo`**: Standard `Widget` for branding.
- **`title`**: String for header text.
- **`primaryColor`**: Overrides the theme color for action buttons.
- **Visibility Toggles**: `showGoogleSignIn`, `showPhoneSignIn`, `showAnonymousSignIn`.

---

## 🔐 Authentication Providers

### Email & Password
Includes registration, login, and password reset. Enforces email verification via a specialized gate state.

### Google Sign-In
Web uses `signInWithPopup` (no extra configuration). Mobile use native SDKs. **Important**: Always pass the *Web Client ID* to `serverClientId` for cross-platform compatibility.

### Phone Authentication
Full SMS verification flow. Supports reCAPTCHA on Web and native silent verification on mobile.

---

## 🔥 Firestore & Security

When `createUserCollection` is `true`, the module maintains:
- `uid`, `email`, `displayName`, `photoURL`
- `createdAt`, `updatedAt`, `lastLoginAt` (Server Timestamps)

**Security Rules Blueprint:**
```javascript
match /users/{userId} {
  allow read, update: if request.auth.uid == userId;
  allow create: if request.auth.uid == userId && request.resource.data.uid == userId;
}
```

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Clean imports and format
dart format .
```
