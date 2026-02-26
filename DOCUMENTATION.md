# Comprehensive Documentation

This is the complete technical reference for the **Remote Auth Module**. It covers every public API surface: BLoC events and states, repository configuration, Firestore sync, entity fields, failure types, and reusable widgets.

For a tutorial-style introduction, see [README.md](README.md).

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [AuthUser Entity](#2-authuser-entity)
3. [AuthBloc — Events & States](#3-authbloc--events--states)
4. [AuthRepository Interface](#4-authrepository-interface)
5. [FirebaseAuthRepository — Configuration](#5-firebaseauthrepository--configuration)
6. [AuthTemplateConfig — Full Reference](#6-authtemplateconfig--full-reference)
7. [Template Flows — Detailed Guide](#7-template-flows--detailed-guide)
8. [Firestore User Sync](#8-firestore-user-sync)
9. [Phone Authentication — Deep Dive](#9-phone-authentication--deep-dive)
10. [Remember Me Service](#10-remember-me-service)
11. [AuthFailure Types — Complete Reference](#11-authfailure-types--complete-reference)
12. [Reusable Widgets](#12-reusable-widgets)
13. [Security Rules Blueprint](#13-security-rules-blueprint)
14. [Testing Guide](#14-testing-guide)

---

## 1. Architecture Overview

The module follows strict Clean Architecture:

```
lib/
├── remote_auth_module.dart          # Public barrel file (only import this)
└── src/
    ├── core/                        # Cross-cutting infrastructure
    │   ├── exceptions/              # Firebase error code → AuthFailure mapping
    │   ├── logging/                 # AppLogger wrapper (logger package)
    │   ├── storage/                 # SecureStorageService (flutter_secure_storage)
    │   └── utils/                   # AuthValidators (email, password rules)
    ├── domain/                      # Pure Dart — zero Flutter imports
    │   ├── entities/                # AuthUser (immutable, Equatable)
    │   ├── failures/                # Sealed AuthFailure hierarchy
    │   └── repositories/           # Abstract AuthRepository interface
    ├── data/                        # Firebase implementation
    │   ├── models/                  # AuthUserDto (fromFirebaseUser, toEntity)
    │   └── repositories/           # FirebaseAuthRepository
    ├── services/                    # Internal services
    │   ├── auth_providers.dart      # EmailAuthProvider, GoogleAuthService
    │   ├── phone_auth_service.dart  # Phone/SMS verification
    │   ├── firestore_user_service.dart # Firestore profile sync
    │   └── remember_me_service.dart # Encrypted preference persistence
    └── presentation/
        ├── bloc/                    # AuthBloc, AuthEvent, AuthState
        ├── templates/               # Self-contained auth flows (Aurora, Nova, etc.)
        ├── pages/                   # Individual screens (Login, Register, etc.)
        └── widgets/                 # Reusable UI components
```

### Import Rule

> [!IMPORTANT]
> **Always import from the barrel file.** Never import internal `src/` paths.
> ```dart
> // ✅ CORRECT
> import 'package:remote_auth_module/remote_auth_module.dart';
>
> // ❌ WRONG — breaks encapsulation and may change without notice
> import 'package:remote_auth_module/src/services/auth_providers.dart';
> ```

---

## 2. AuthUser Entity

`AuthUser` is the **only** user type your app should use. It is a plain Dart class with no Flutter or Firebase dependencies.

```dart
class AuthUser extends Equatable {
  final String id;                    // Firebase UID
  final String email;                 // User's email address
  final String? displayName;          // Display name (nullable)
  final String? photoURL;             // Profile photo URL (nullable)
  final bool isEmailVerified;         // Whether email has been verified
  final bool isAnonymous;             // Whether user signed in anonymously
  final List<String> providerIds;     // e.g., ['password', 'google.com']

  // Computed properties
  bool get isOAuthUser;               // true if signed in via Google/Apple/etc.
  String get remoteId;                // Alias for `id` (compatibility)

  AuthUser copyWith({...});           // Immutable copy
}
```

### How `AuthUser` is created

The module maps Firebase's internal `User` to `AuthUser` via a private DTO. You never interact with this mapping — the BLoC emits `AuthUser` instances directly.

### Key behaviors

| Scenario | `isEmailVerified` | `isAnonymous` | `providerIds` |
|---|---|---|---|
| Email/password (just registered) | `false` | `false` | `['password']` |
| Email/password (verified) | `true` | `false` | `['password']` |
| Google Sign-In | `true` | `false` | `['google.com']` |
| Anonymous Sign-In | `false` | `true` | `[]` |
| Phone Sign-In | `true` | `false` | `['phone']` |

---

## 3. AuthBloc — Events & States

The `AuthBloc` is the state engine. It processes events and emits states.

### Events (What you dispatch)

| Event | Parameters | When to use |
|---|---|---|
| `InitializeAuthEvent` | — | **Required.** Dispatch immediately after BLoC creation to restore session. |
| `SignInWithEmailEvent` | `email`, `password` | User taps "Sign In" with email/password form. |
| `RegisterWithEmailEvent` | `email`, `password` | User taps "Create Account" with email/password form. |
| `SignInWithGoogleEvent` | — | User taps the Google button. |
| `SignInAnonymouslyEvent` | — | User taps the Guest/Anonymous button. |
| `VerifyPhoneNumberEvent` | `phoneNumber` | User enters phone number and taps "Send Code". |
| `SignInWithSmsCodeEvent` | `verificationId`, `smsCode` | User enters the OTP code. |
| `SignOutEvent` | — | User taps "Sign Out". |
| `SendEmailVerificationEvent` | — | User taps "Resend verification email". |
| `RefreshCurrentUserEvent` | `isSilent` (default `false`) | User taps "I verified, refresh" on email verification screen. |
| `SendPasswordResetEvent` | `email` | User enters email on "Forgot Password" screen. |
| `UpdateDisplayNameEvent` | `name` | User edits their profile name. |
| `UpdatePasswordEvent` | `currentPassword`, `newPassword` | User changes their password. |

> [!IMPORTANT]
> **Internal events** (`AuthStateChangedEvent`, `PhoneCodeSentInternalEvent`, `PhoneVerificationFailedInternalEvent`) are dispatched automatically by the BLoC. **Never dispatch these yourself.**

### States (What you listen to)

| State | Data | Meaning |
|---|---|---|
| `AuthInitialState` | — | BLoC just created, nothing checked yet. |
| `AuthLoadingState` | — | An auth operation is in progress. Show a spinner. |
| `AuthenticatedState` | `user: AuthUser` | ✅ User is fully authenticated. Show your app. |
| `UnauthenticatedState` | — | No user session. Show login screen. |
| `AuthErrorState` | `message: String` | An error occurred. Show an error snackbar/banner. |
| `EmailVerificationRequiredState` | `user: AuthUser` | User registered but hasn't verified email. Show verification screen. |
| `EmailVerificationSentState` | `user: AuthUser` | Verification email was sent. Show success feedback. |
| `PhoneCodeSentState` | `verificationId`, `resendToken` | SMS code sent. Show OTP input field. |
| `PasswordResetSentState` | — | Password reset email sent. Show success feedback. |
| `DisplayNameUpdatedState` | `newName: String` | Profile name updated. Show confirmation. |
| `PasswordUpdatedState` | — | Password changed. Show confirmation. |

### State flow diagram

```
InitializeAuthEvent
    ├─ Has valid session?
    │   ├─ Email verified?     → AuthenticatedState(user)
    │   └─ Not verified?       → EmailVerificationRequiredState(user)
    └─ No session              → UnauthenticatedState

SignInWithEmailEvent
    ├─ Success + email verified → AuthenticatedState(user)
    ├─ Success + not verified   → EmailVerificationRequiredState(user)
    └─ Failure                  → AuthErrorState(message)

SignInWithGoogleEvent / SignInAnonymouslyEvent
    ├─ Success                  → AuthenticatedState(user)
    └─ Failure                  → AuthErrorState(message)

RegisterWithEmailEvent
    ├─ Success                  → EmailVerificationRequiredState(user)
    └─ Failure                  → AuthErrorState(message)
```

> [!WARNING]
> **Critical:** `AuthErrorState` is **transient**. The BLoC emits it once and then remains in that state until a new event is dispatched. Always capture the error in a `BlocListener` (not `BlocBuilder`), because `BlocBuilder` may miss it if a rebuild happens.

---

## 4. AuthRepository Interface

The abstract contract that any auth implementation must fulfill:

```dart
abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<Either<AuthFailure, AuthUser?>> getCurrentUser();
  Future<Either<AuthFailure, AuthUser?>> initializeSession();
  Future<Either<AuthFailure, AuthUser?>> reloadCurrentUser();

  Future<Either<AuthFailure, AuthUser>> signInWithEmailAndPassword({...});
  Future<Either<AuthFailure, AuthUser>> signUpWithEmailAndPassword({...});
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle();
  Future<Either<AuthFailure, AuthUser>> signInAnonymously();
  Future<Either<AuthFailure, AuthUser>> signInWithSmsCode({...});

  Future<void> verifyPhoneNumber({...});

  Future<Either<AuthFailure, Unit>> signOut();
  Future<Either<AuthFailure, Unit>> sendEmailVerification();
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({...});
  Future<Either<AuthFailure, Unit>> updateDisplayName({...});
  Future<Either<AuthFailure, Unit>> updatePassword({...});
}
```

Every method returns `Either<AuthFailure, T>` — raw exceptions **never** escape the repository boundary.

---

## 5. FirebaseAuthRepository — Configuration

The provided Firebase implementation. This is the only class you need to instantiate for a Firebase-backed app.

```dart
FirebaseAuthRepository({
  FirebaseAuth? auth,                      // Default: FirebaseAuth.instance
  FirebaseFirestore? firestore,            // Required if createUserCollection is true
  String? serverClientId,                  // Web Client ID for Google Sign-In (Android)
  String? clientId,                        // Client ID for Google Sign-In (iOS/macOS)
  bool createUserCollection = false,       // Auto-create Firestore user documents
  String usersCollectionName = 'users',    // Firestore collection name
})
```

### Parameter details

| Parameter | Required? | Details |
|---|---|---|
| `auth` | No | Defaults to `FirebaseAuth.instance`. Pass a custom instance if using multi-Firebase-app. |
| `firestore` | Only if `createUserCollection` is `true` | The Firestore instance to write user documents to. |
| `serverClientId` | Yes for Android Google Sign-In | The **Web application** OAuth Client ID from Google Cloud Console. |
| `clientId` | Yes for iOS/macOS Google Sign-In | The iOS/macOS OAuth Client ID. |
| `createUserCollection` | No | When `true`, automatically creates/updates user documents in Firestore on sign-in. |
| `usersCollectionName` | No | Defaults to `'users'`. Change to any string (e.g., `'members'`, `'app_users'`). |

> [!CAUTION]
> **Do NOT create multiple instances** of `FirebaseAuthRepository`. It internally initializes `GoogleSignIn` and `PhoneAuthService`. Multiple instances will cause initialization race conditions.

---

## 6. AuthTemplateConfig — Full Reference

```dart
const AuthTemplateConfig({
  bool showGoogleSignIn = true,
  bool showPhoneSignIn = true,
  bool showAnonymousSignIn = true,
  bool showRegister = true,
  bool showForgotPassword = true,
  bool showRememberMe = true,
  String loginTitle = 'Welcome Back',
  String loginSubtitle = 'Sign in to continue',
  String registerTitle = 'Create Account',
  String registerSubtitle = 'Create your account to continue',
  Widget? logo,
})
```

> [!TIP]
> Use `const` for `AuthTemplateConfig` to make it compile-time constant and allow Flutter's tree shaking to optimize.

---

## 7. Template Flows — Detailed Guide

Each template is a `StatefulWidget` that encapsulates:
- `BlocProvider<AuthBloc>` (creates or reuses existing)
- Login page (themed)
- Register page (themed)
- Forgot Password page
- Email Verification gate page
- Navigation between all sub-pages

### Constructor signature (common to all templates)

```dart
XxxAuthFlow({
  AuthTemplateConfig config,                            // Default: AuthTemplateConfig()
  Widget Function(BuildContext, AuthUser) authenticatedBuilder, // REQUIRED
})
```

### Template-specific features

| Template | Unique visual element |
|---|---|
| `AuroraAuthFlow` | Animated mesh gradient background with orbiting light particles |
| `WaveAuthFlow` | Animated sine-wave water header with color transitions |
| `NeonAuthFlow` | Pulsing neon border glow, dark grid background |
| `NovaAuthFlow` | Rotating starfield canvas with twinkling star particles |
| `PrismaAuthFlow` | Morphing colored blobs behind frosted glass card |
| `ZenAuthFlow` | Falling cherry blossom petals, warm earth gradient |
| `RetroAuthFlow` | CRT scanline overlay, pixel glitch text effects |
| `RemoteAuthFlow` | Gradient scaffold with glassmorphic card (Material 3 default) |

---

## 8. Firestore User Sync

When `createUserCollection: true`, the module auto-manages a Firestore document per user.

### Document structure

```json
{
  "uid": "firebase-user-id",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoURL": "https://...",
  "createdAt": "<server timestamp>",        // Set once on first sign-in
  "updatedAt": "<server timestamp>",        // Updated on profile changes
  "lastLoginAt": "<server timestamp>"       // Updated on each subsequent sign-in
}
```

### Behavior

| Action | What happens |
|---|---|
| User signs in for the **first time** | Document created with `createdAt` and `updatedAt` |
| User signs in **again** | Only `lastLoginAt` is updated (merge) — other fields preserved |
| User updates display name | `displayName` and `updatedAt` updated |
| User deletes account | Document is **not** auto-deleted (design choice for data retention) |

### Restricted fields

The `FirestoreUserService` **blocks** updates to:
- `uid` — immutable identity
- `email` — must be changed via Firebase Auth, not Firestore
- `createdAt` — immutable timestamp

Attempting to update these throws `ArgumentError`.

### Accessing the Firestore service

The `FirestoreUserService` is created internally by `FirebaseAuthRepository`. If you need direct Firestore access to the user document from your app, use the service's helper methods:

```dart
// These are available on FirestoreUserService (internal, but accessible via the repository)
getUserDocRef(uid);                  // DocumentReference for the user
getUserSubcollection(uid, 'posts');  // CollectionReference for a subcollection
getUserStream(uid);                  // Real-time snapshot stream
```

---

## 9. Phone Authentication — Deep Dive

Phone auth follows a two-step flow:

### Step 1: Send verification code

```dart
context.read<AuthBloc>().add(
  VerifyPhoneNumberEvent(phoneNumber: '+1234567890'),
);
```

The BLoC emits:
- `AuthLoadingState` → while sending
- `PhoneCodeSentState(verificationId, resendToken)` → when SMS is sent
- `AuthErrorState(message)` → on failure

### Step 2: Verify the code

```dart
context.read<AuthBloc>().add(
  SignInWithSmsCodeEvent(
    verificationId: state.verificationId,
    smsCode: '123456',
  ),
);
```

The BLoC emits:
- `AuthLoadingState` → while verifying
- `AuthenticatedState(user)` → on success
- `AuthErrorState(message)` → on wrong code

### Built-in PhoneAuthDialog

The module ships a `PhoneAuthDialog` that handles both steps with a polished UI.

```dart
showDialog(
  context: context,
  builder: (_) => BlocProvider.value(
    value: context.read<AuthBloc>(),  // ← CRITICAL
    child: const PhoneAuthDialog(),
  ),
);
```

> [!WARNING]
> **The `BlocProvider.value` wrapper is mandatory.** The dialog needs access to the same `AuthBloc` that your app uses. Without it, events will be dispatched to a non-existent BLoC.

### Platform differences

| Platform | Behavior |
|---|---|
| Android | Native silent verification may auto-complete without user typing |
| iOS | Standard SMS flow |
| Web | reCAPTCHA widget shown automatically by Firebase |

---

## 10. Remember Me Service

The `RememberMeService` uses `flutter_secure_storage` to persist the user's "Remember Me" preference.

| Method | Behavior |
|---|---|
| `save(value: true)` | Persist "keep me logged in" |
| `save(value: false)` | Persist "log me out on next cold start" |
| `load()` | Returns saved value. Defaults to `true` if never set. |
| `clear()` | Remove the preference (used on explicit sign-out) |

### How it works

Firebase **always** persists auth tokens on mobile. "Remember Me = false" doesn't disable Firebase persistence — instead, on the next cold-launch, `initializeSession()` signs the user out before the app starts.

---

## 11. AuthFailure Types — Complete Reference

All failures are `sealed` subclasses of `AuthFailure`. Each has a human-readable `message` field.

| Failure Class | Triggered When |
|---|---|
| `UserDisabledFailure` | Account is disabled in Firebase Console |
| `WrongPasswordFailure` | Incorrect password during email sign-in |
| `UserNotFoundFailure` | No account exists with the provided email |
| `TooManyRequestsFailure` | Rate limit exceeded (too many sign-in attempts) |
| `WeakPasswordFailure` | Password doesn't meet Firebase's minimum requirements |
| `EmailAlreadyInUseFailure` | Email is already registered |
| `InvalidEmailFailure` | Email format is invalid |
| `UserNotLoggedInFailure` | Operation requires a signed-in user but none exists |
| `InvalidCredentialFailure` | Provided credential is incorrect or expired |
| `AccountExistsWithDifferentCredentialFailure` | Email linked to another sign-in method |
| `OperationNotAllowedFailure` | Auth provider not enabled in Firebase Console |
| `RequiresRecentLoginFailure` | Sensitive action needs re-authentication |
| `PasswordChangeNotSupportedFailure` | Non-password account trying to change password |
| `PasswordResetFailure` | Error sending password reset email |
| `GoogleSignInCancelledFailure` | User cancelled the Google sign-in dialog |
| `GoogleSignInInterruptedFailure` | Google sign-in was interrupted (concurrent request) |
| `GoogleSignInConfigurationFailure` | OAuth client IDs or SHA keys misconfigured |
| `GoogleSignInUnavailableFailure` | Google Play Services unavailable on this device |
| `GoogleSignInUserMismatchFailure` | Google account changed unexpectedly |
| `UnexpectedAuthFailure` | Any uncategorized error (includes raw message) |
| `SignOutFailure` | Error during sign-out process |

### Usage in your app

```dart
// In BlocListener
if (state is AuthErrorState) {
  // state.message contains the human-readable failure message.
  // You can show it directly in a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(state.message)),
  );
}
```

---

## 12. Reusable Widgets

These widgets are exported and can be used in your custom UI:

| Widget | Purpose |
|---|---|
| `AuthActionButton` | Primary/secondary CTA button with loading state and icon support |
| `PhoneAuthDialog` | Complete phone OTP dialog (send code → verify code) |
| `AuthGlassCard` | Glassmorphic card with frosted background |
| `AuthGradientScaffold` | Full-screen gradient background scaffold |
| `AuthInputField` | Styled text input with icon, label, and password toggle |
| `AuthStatusBanner` | Info/error/warning banner for inline messaging |
| `ConfirmDialog` | A themed confirmation dialog for destructive actions |

---

## 13. Security Rules Blueprint

When using Firestore user sync, protect the collection with these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profiles — each user can only read/write their own document.
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.uid == userId;
      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && !request.resource.data.diff(resource.data).affectedKeys()
                        .hasAny(['uid', 'createdAt', 'email']);
      allow delete: if false;  // Prevent accidental deletion
    }
  }
}
```

### Rule explanation

| Rule | Why |
|---|---|
| `allow read: auth.uid == userId` | Users can only read their own profile |
| `allow create: data.uid == userId` | Prevents creating documents for other users |
| `allow update: !affectedKeys().hasAny(...)` | Blocks modification of `uid`, `createdAt`, `email` |
| `allow delete: false` | Prevents accidental profile deletion from client |

---

## 14. Testing Guide

### Run module tests

```fish
cd /path/to/remote_auth_module
flutter test
```

### Test structure

```
test/
├── data/repositories/
│   └── firebase_auth_repository_test.dart   # Repository tests with mocked services
├── domain/entities/
│   └── auth_user_test.dart                  # Entity equality and copyWith
├── domain/failures/
│   └── auth_failure_test.dart               # Failure message verification
└── presentation/bloc/
    └── auth_bloc_test.dart                  # BLoC state transition tests
```

### Writing BLoC tests

```dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoadingState, AuthenticatedState] on successful email sign-in',
  build: () {
    when(() => mockRepo.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => Right(testUser));
    return AuthBloc(repository: mockRepo);
  },
  act: (bloc) => bloc.add(
    const SignInWithEmailEvent(email: 'test@test.com', password: 'pass123'),
  ),
  expect: () => [
    const AuthLoadingState(),
    AuthenticatedState(testUser),
  ],
);
```

---

*For planned features and future direction, see [ROADMAP.md](ROADMAP.md).*
