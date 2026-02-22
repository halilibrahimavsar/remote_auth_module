# Remote Auth Module

A premium, multi-platform Firebase authentication module for Flutter designed with **Clean Architecture** and **BLoC**. It provides a complete, production-ready auth system with stunning visual aesthetics and flexible integration patterns.

## ✨ Features

- **Multi-Platform Support**: Ready for Web, Android, iOS, macOS, Windows, and Linux.
- **Multiple Auth Methods**:
  - **Email/Password**: Including registration and password reset.
  - **Google Sign-In**: Seamless integration across platforms.
  - **Anonymous Sign-In**: Let users explore your app before committing.
  - **Phone Authentication**: SMS-based verification with a smooth UI flow.
- **Ready-to-Use Template**: The `RemoteAuthFlow` widget handles the entire lifecycle with zero boilerplate.
- **Architectural Excellence**: Clean separation of Domain, Data, and Presentation layers.
- **Security First**:
  - Automatic email verification gate.
  - Firestore user profile synchronization.
  - Pre-configured secure Firestore rules.
- **Premium UI**: Modern design with glassmorphism, gradients, and micro-animations.

---

## 🚀 Getting Started

### 1. Installation

Add the module and its core dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  remote_auth_module:
    path: ../remote_auth_module # Adjust path as needed
  flutter_bloc: ^9.1.0
  firebase_core: ^4.3.0
  firebase_auth: ^6.1.3
  cloud_firestore: ^6.1.2
```

### 2. Firebase Setup

The module requires a configured Firebase project. Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) for the easiest setup:

```bash
flutterfire config \
  --project=your-project-id \
  --platforms=android,ios,macos,web,windows,linux
```

#### Platform Specifics:
- **Android**: To use Google Sign-In, you must provide your `serverClientId` (from Google Cloud Console) to the repository.
- **Phone Auth**: Ensure you have enabled Phone Provider in the Firebase Console. For Android, add your SHA-1 and SHA-256 fingerprints.

### 3. Firestore Permissions

If you enable `createUserCollection`, ensure your Firestore rules allow users to manage their own profiles. Use the blueprint provided in `example_app/firestore.rules`.

---

## 🛠 Usage Patterns

### Pattern A: The "Easy" Way (RemoteAuthFlow)

The `RemoteAuthFlow` widget manages everything: loading states, login, registration, phone verification, and email gates.

```dart
RemoteAuthFlow(
  authBloc: myAuthBloc, // Optional if provided via context
  logo: MyLogoWidget(),
  loginTitle: 'Welcome Back',
  showGoogleSignIn: true,
  showPhoneSignIn: true,
  showAnonymousSignIn: true,
  authenticatedBuilder: (context, user) {
    return MainAppScreen(user: user);
  },
)
```

### Pattern B: Manual Integration (Custom Layouts)

For full control, wrap your UI in a `BlocBuilder`.

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthenticatedState) {
      return HomeScreen(user: state.user);
    }
    
    // Use individual module pages or your own
    return LoginPage(
      showPhoneSignIn: true,
      showAnonymousSignIn: true,
      onRegisterTap: () => /* navigate to RegisterPage */,
    );
  },
)
```

---

## 🏗 Component Configuration

### AuthRepository
The `FirebaseAuthRepository` is the core implementation. Configure it during dependency injection:

```dart
final authRepository = FirebaseAuthRepository(
  auth: FirebaseAuth.instance,
  firestore: FirebaseFirestore.instance,
  createUserCollection: true, // Syncs user data to 'users' collection
  serverClientId: 'your-google-client-id.apps.googleusercontent.com',
);
```

### AuthBloc
The BLoC handles all logic and state transitions.

```dart
final authBloc = AuthBloc(repository: authRepository);
authBloc.add(const InitializeAuthEvent());
```

---

## 📁 Project Structure

- `lib/src/domain`: Entities (`AuthUser`) and Repository interfaces.
- `lib/src/data`: Firebase implementation, DTOs, and Mappers.
- `lib/src/bloc`: Auth state management (`AuthBloc`, `AuthEvent`, `AuthState`).
- `lib/src/presentation`:
    - `pages/`: Login, Register, ForgotPassword, EmailVerification.
    - `templates/`: `RemoteAuthFlow` (the main gate).
    - `widgets/`: Atomic UI components like `AuthActionButton` and `PhoneAuthDialog`.
- `lib/src/services`: Low-level services for Phone, Google, and Firestore.

---

## 🧪 Testing

The module is verified with a robust test suite:

```bash
# Run unit tests for BLoCs and Repositories
flutter test
```

For Firestore security rules, see the integration tests in `example_app/security_rules_test_firestore/`.

---

## 💡 Troubleshooting

- **Phone Auth reCAPTCHA**: On Web, ensure your domain is whitelisted. On Android/iOS, the module uses "invisible" verification where possible.
- **Google Sign-In mismatch**: Check that the `serverClientId` matches the Web Client ID in your Google Cloud project (not the Android one).
- **Infinite Loading**: Ensure you've called `InitializeAuthEvent` to restore the user session on startup.
