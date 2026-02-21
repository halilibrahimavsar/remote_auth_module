# Remote Auth Module

A premium, multi-platform Firebase authentication module for Flutter designed with **Clean Architecture** and **BLoC**. It provides a complete, production-ready auth system with stunning visual aesthetics (Glassmorphism, Gradients) and flexible integration patterns.

## ✨ Highlights

- **Multi-Platform Ready**: Fully configured for Web, Android, iOS, macOS, Windows, and Linux.
- **Ready-to-Use Template**: Drop the `RemoteAuthFlow` widget into your app for a zero-boilerplate auth experience.
- **Architectural Flexibility**: Clean separate layers (Domain/Data/Presentation). Works seamlessly with **DI/Injectable**, **GetIt**, and custom routing.
- **Premium Aesthetics**: High-end UI system with animations, glassmorphism, and responsive design.
- **Strict Verification Gate**: Automatic email verification handling for improved security.
- **Firestore Sync**: Automatic user profile management in Firestore with pre-configured secure rules.

---

## 🚀 Getting Started

### 1. Installation

Add the module as a local dependency in your `pubspec.yaml`:

```yaml
dependencies:
  remote_auth_module:
    path: YOUR_PATH_TO_MODULE
  flutter_bloc: ^9.1.0
  firebase_core: ^4.3.0
  firebase_auth: ^6.1.3
  cloud_firestore: ^6.1.2
  google_sign_in: ^7.0.0
```

### 2. Firebase Configuration

The module is designed to be multi-platform. Ensure you have registered your apps in the Firebase Console and generated the configuration.

For the easiest setup, use the FlutterFire CLI:
```bash
flutterfire config \
  --project=your-project-id \
  --platforms=android,ios,macos,web,windows,linux \
  --yes
```

### 3. Firestore Security Rules

Ensure your Firestore is protected. Use the provided rules in `example_app/firestore.rules`:
- **Default Deny**: Blocks all unauthorized access.
- **Ownership Based**: Users can only read/write their own profiles.
- **Data Validation**: Enforces structure for `uid`, `createdAt`, and `updatedAt`.

---

## 🛠 Usage Patterns

### Pattern A: Ready-to-Use (Recommended)

Use the `RemoteAuthFlow` template to handle the entire lifecycle (Login, Register, Forgot Password, Verification, Loading) with a single widget. It integrates perfectly with your existing DI.

```dart
// Example with GetIt/Injectable
return RemoteAuthFlow(
  authBloc: getIt<AuthBloc>(), // Optional: Pass your DI instance
  logo: Image.asset('assets/logo.png'),
  loginTitle: 'Welcome to MyApp',
  authenticatedBuilder: (context, user) {
    // Return your main app screen here
    return MainScreen(user: user);
  },
);
```

### Pattern B: Manual Integration (Custom UI/Logic)

If you need a highly custom UI while using our BLoC logic:

```dart
return BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthenticatedState) return HomeScreen(user: state.user);
    if (state is UnauthenticatedState) return MyCustomLoginPage();
    // ... handle other states
  },
);
```

---

## 🏗 Architecture Support

### Dependency Injection (DI)
The module is constructor-injection friendly. You can easily register it in your `injectable` configuration or `GetIt`.

```dart
// Dependency Registration Example
@module
abstract class AuthModule {
  @lazySingleton
  AuthRepository get authRepository => FirebaseAuthRepository(
    serverClientId: '...', // Required for Google Sign-In on Android
    createUserCollection: true,
  );

  @injectable
  AuthBloc get authBloc => AuthBloc(repository: getIt<AuthRepository>());
}
```

### Routing
The prebuilt `RemoteAuthFlow` uses an internal navigator for auth sub-pages (Login -> Register). This keeps your main app router (like `go_router`) clean. Once authenticated, the `authenticatedBuilder` is triggered, allowing you to transition to your main application routes.

---

## 🔒 Security & Data

### User Document Sync
If initialized with `createUserCollection: true`, the module automatically maintains a `users` collection in Firestore:
- **ID**: User's Firebase UID
- **Fields**: `email`, `displayName`, `photoURL`, `createdAt`, `updatedAt`, `lastLoginAt`.

### Security Rules Validation
The provided `firestore.rules` have been validated against:
1. Unauthorized profile reading/writing.
2. UID hijacking (ensures `request.auth.uid == userId`).
3. Immutable field protection (e.g., preventing modification of `createdAt`).

---

## 📂 Project Structure

- `lib/src/domain`: Entities and Repository interfaces (Pure Dart).
- `lib/src/data`: Repository implementations and DTOs.
- `lib/src/bloc`: Auth state management.
- `lib/src/presentation`:
    - `pages/`: Full screen pages (Login, Register, etc.).
    - `templates/`: High-level flow components (RemoteAuthFlow).
    - `widgets/`: Atomic design components.

---

## 🧪 Testing

The module comes with a comprehensive test suite:
- **Unit Tests**: Coverage for Repositories and BLoCs (`test/`).
- **Security Tests**: Node.js based tests for Firestore rules (`example_app/security_rules_test_firestore/`).

Run Flutter tests:
```bash
flutter test
```

---

## 💡 Troubleshooting

- **Google Sign-In on Web**: Ensure your `authDomain` is correctly configured in `FirebaseOptions`.
- **Google Sign-In on Android**: You **must** provide the `serverClientId` (from the Google Cloud Console) to `FirebaseAuthRepository`.
- **Email not arriving**: Verify your Firebase Email templates are active and the domain is verified in the Firebase Console.
