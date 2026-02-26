# Remote Auth Module

A **production-ready**, multi-platform Firebase authentication module for Flutter.
Built with **Clean Architecture**, **BLoC state management**, and **functional error handling** (`Either<Failure, T>`).

Drop one widget into your app and get a complete, animated, and premium authentication flow — or wire it into your own custom UI using the exposed BLoC engine.

---

## 📋 Table of Contents

1. [Why This Module?](#-why-this-module)
2. [Quick Start (5 Minutes)](#-quick-start-5-minutes)
3. [Platform Setup (Do This First!)](#-platform-setup-do-this-first)
4. [Three Ways to Integrate](#-three-ways-to-integrate)
5. [Template Gallery](#-template-gallery)
6. [AuthManagerPage — Post-Login Profile Management](#-authmanagerpage--post-login-profile-management)
7. [AuthTemplateConfig — The Control Panel](#-authtemplateconfig--the-control-panel)
8. [Do's and Don'ts](#-dos-and-donts)
9. [Troubleshooting & Common Mistakes](#-troubleshooting--common-mistakes)
10. [Further Reading](#-further-reading)

---

## ✨ Why This Module?

| What you get | Details |
|---|---|
| **7 premium UI templates** | Aurora, Wave, Neon, Nova, Prisma, Zen, Retro — each with unique animations |
| **5 auth providers** | Email/Password, Google, Phone (SMS OTP), Anonymous, + email verification gate |
| **Zero Firebase leakage** | Your app receives `AuthUser`, never `firebase_auth.User` |
| **Firestore user sync** | Optionally auto-creates user profiles in Firestore on sign-up |
| **Smart session recovery** | "Remember Me" toggle with `flutter_secure_storage` persistence |
| **Functional errors** | Every failure is a typed `AuthFailure` — no raw exceptions escape |
| **Fully configurable** | Toggle any auth method, customize titles, inject logos — all via `AuthTemplateConfig` |

---

## 🚀 Quick Start (5 Minutes)

### 1. Add the dependency

```yaml
# pubspec.yaml
dependencies:
  remote_auth_module:
    path: ../remote_auth_module   # adjust to your directory layout
```

### 2. Initialize Firebase in your app

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

### 3. Drop in a template

```dart
import 'package:remote_auth_module/remote_auth_module.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NovaAuthFlow(
        config: const AuthTemplateConfig(
          loginTitle: 'Welcome, Explorer',
          showGoogleSignIn: true,
          showPhoneSignIn: false,       // ← hide phone auth
          showAnonymousSignIn: false,   // ← hide guest login
        ),
        authenticatedBuilder: (context, user) {
          return MyDashboard(user: user);  // ← your app starts here
        },
      ),
    );
  }
}
```

**Done.** The template handles sign-in, registration, forgot password, email verification, and returns `AuthUser` when the user is fully authenticated.

---

## 📱 Platform Setup (Do This First!)

> [!CAUTION]
> **Skipping platform configuration is the #1 cause of "it doesn't work" issues.** Complete ALL steps for your target platform BEFORE running the app.

### Android

| Step | How |
|---|---|
| Generate SHA keys | Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |
| Add SHA-1 **and** SHA-256 | Firebase Console → Project Settings → Your Android App → Add Fingerprint |
| Download config | Download `google-services.json` → place in `android/app/` |
| Google Sign-In | `serverClientId` is **mandatory** — it's your **Web** Client ID from Google Cloud Console (NOT the Android one) |

> [!WARNING]
> **Common mistake:** Using the Android Client ID instead of the Web Client ID for `serverClientId`. This will cause `DEVELOPER_ERROR` on Android Google Sign-In. Always use the **Web application** OAuth Client ID.

### iOS & macOS

| Step | How |
|---|---|
| Config file | Download `GoogleService-Info.plist` → drag into Xcode's `Runner` folder |
| URL Schemes | Xcode → Runner → Info → URL Types → add the `REVERSED_CLIENT_ID` value from the plist |
| macOS capabilities | Enable "Keychain Sharing" and "Outgoing Connections" under App Sandbox |

### Web

| Step | How |
|---|---|
| Meta tag | Add `<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">` to `web/index.html` `<head>` |
| Authorized domains | Firebase Console → Authentication → Settings → Authorized domains → add `localhost` and your production domain |

> [!IMPORTANT]
> **Phone Auth on Web** requires reCAPTCHA verification. Firebase handles this automatically, but you must whitelist your domains.

---

## 🏗 Three Ways to Integrate

Choose the integration pattern that matches your project's needs:

### Pattern 1: Template Flow (Zero Boilerplate)

**Best for:** New projects, prototypes, apps that want a beautiful auth screen immediately.

The `*AuthFlow` widgets are fully self-contained. They create their own `AuthBloc`, handle all navigation (login → register → forgot password → email verification), and call your `authenticatedBuilder` when done.

```dart
// That's literally it. One widget.
PrismaAuthFlow(
  config: const AuthTemplateConfig(
    loginTitle: 'My App',
    showGoogleSignIn: true,
    showPhoneSignIn: true,
    showAnonymousSignIn: false,
  ),
  authenticatedBuilder: (context, user) => HomePage(user: user),
)
```

> [!NOTE]
> When using a template flow **without** providing a parent `BlocProvider<AuthBloc>`, the template creates its own default `FirebaseAuthRepository` internally. This works but **does not** support `createUserCollection` or `serverClientId`. For those features, use Pattern 2 or 3.

---

### Pattern 2: Template Flow + Your Own Repository

**Best for:** Apps that need Firestore user sync, custom collection names, or Google Sign-In on Android.

Create the repository and BLoC yourself, wrap them around the template.

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthRepository _repo;
  late final AuthBloc _bloc;

  @override
  void initState() {
    super.initState();
    _repo = FirebaseAuthRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      createUserCollection: true,              // ← auto-sync to Firestore
      usersCollectionName: 'app_users',        // ← custom collection name
      serverClientId: 'YOUR_WEB_CLIENT_ID',    // ← REQUIRED for Android Google Sign-In
    );
    _bloc = AuthBloc(repository: _repo)
      ..add(const InitializeAuthEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: MaterialApp(
        // The template will detect the existing BlocProvider and use YOUR bloc.
        home: AuroraAuthFlow(
          config: const AuthTemplateConfig(showGoogleSignIn: true),
          authenticatedBuilder: (ctx, user) => Dashboard(user: user),
        ),
      ),
    );
  }
}
```

---

### Pattern 3: Fully Custom UI (Manual)

**Best for:** Apps with unique designs that only need the BLoC engine and Firebase logic.

You build all the screens yourself and dispatch events to the `AuthBloc`.

```dart
// Step 1: Provide the BLoC
BlocProvider(
  create: (_) => AuthBloc(repository: myRepo)
    ..add(const InitializeAuthEvent()),
  child: const AppRouter(),
)

// Step 2: React to auth state changes
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthErrorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    return switch (state) {
      AuthLoadingState()                  => const LoadingScreen(),
      AuthenticatedState(:final user)     => HomeScreen(user: user),
      EmailVerificationRequiredState()    => const VerifyEmailScreen(),
      _                                   => const MyCustomLoginScreen(),
    };
  },
)

// Step 3: Dispatch events from your custom UI
// Email login
context.read<AuthBloc>().add(SignInWithEmailEvent(email: e, password: p));

// Google login
context.read<AuthBloc>().add(const SignInWithGoogleEvent());

// Register
context.read<AuthBloc>().add(RegisterWithEmailEvent(email: e, password: p));

// Phone — use the built-in dialog OR trigger events manually
showDialog(
  context: context,
  builder: (_) => BlocProvider.value(
    value: context.read<AuthBloc>(),   // ← CRITICAL: pass the existing bloc
    child: const PhoneAuthDialog(),
  ),
);

// Sign out
context.read<AuthBloc>().add(const SignOutEvent());
```

---

## 🎨 Template Gallery

Every template is a `StatefulWidget` that wraps the full auth lifecycle.

| Template | Style | Best For |
|---|---|---|
| `RemoteAuthFlow` | Clean Material 3 glassmorphism | Business, SaaS, general |
| `AuroraAuthFlow` | Dark mesh gradient with glowing orbs | Creative tools, dark-themed apps |
| `WaveAuthFlow` | Liquid/water animated header | Clean, modern apps |
| `NeonAuthFlow` | Cyberpunk neon glow aesthetic | Gaming, entertainment |
| `NovaAuthFlow` | Rotating starfield, gold accents | Elegant, premium apps |
| `PrismaAuthFlow` | Morphing pastel blobs, frosted glass | Fashion, design, lifestyle |
| `ZenAuthFlow` | Floating petals, calm earth tones | Wellness, meditation, journaling |
| `RetroAuthFlow` | CRT scanlines, 8-bit glitch effects | Retro-themed, gaming apps |

All templates **automatically include** login, registration, forgot password, and email verification pages styled to match.

---

## 👤 AuthManagerPage — Post-Login Profile Management

A premium, ready-to-use profile management page that works with any template. Drop it in after authentication to give users account management out-of-the-box.

**Features:**
- Animated avatar with pulsing glow ring
- Inline display name editing
- Provider badges (Email, Google, Phone, Guest)
- Change password dialog (email/password users)
- Email verification prompt (unverified users)
- Sign out with confirmation
- Extensible with custom action tiles

### Basic Usage

```dart
NovaAuthFlow(
  config: const AuthTemplateConfig(showGoogleSignIn: true),
  authenticatedBuilder: (context, user) {
    // Drop in the manager page as your post-login screen
    return const AuthManagerPage();
  },
)
```

### With Custom Actions

```dart
AuthManagerPage(
  onSignedOut: () => Navigator.pushReplacementNamed(context, '/login'),
  headerGradientColors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  additionalActions: [
    AuthManagerAction(
      icon: Icons.settings,
      label: 'App Settings',
      subtitle: 'Theme, language, notifications',
      onTap: () => Navigator.pushNamed(context, '/settings'),
    ),
    AuthManagerAction(
      icon: Icons.delete_forever,
      label: 'Delete Account',
      subtitle: 'Permanently remove your data',
      iconColor: Colors.red,
      onTap: () => _confirmDeleteAccount(),
    ),
  ],
)
```

> [!TIP]
> The `AuthManagerPage` uses the same `AuthBloc` as the login templates. When used inside an `*AuthFlow` widget's `authenticatedBuilder`, the BLoC is already available — no extra setup needed.

---

## ⚙️ AuthTemplateConfig — The Control Panel

Every template reads from a single `AuthTemplateConfig` object. This is how you control what appears on screen.

```dart
const config = AuthTemplateConfig(
  // ── Feature Toggles ──────────────────────────────────
  showGoogleSignIn: true,       // Show/hide Google button
  showPhoneSignIn: true,        // Show/hide Phone button
  showAnonymousSignIn: true,    // Show/hide Guest button
  showRegister: true,           // Show/hide "Create Account" link
  showForgotPassword: true,     // Show/hide "Forgot Password" link
  showRememberMe: true,         // Show/hide "Remember Me" checkbox

  // ── Text Customization ───────────────────────────────
  loginTitle: 'Welcome Back',               // Login page title
  loginSubtitle: 'Sign in to continue',     // Login page subtitle
  registerTitle: 'Create Account',          // Register page title
  registerSubtitle: 'Join us today',        // Register page subtitle

  // ── Branding ─────────────────────────────────────────
  logo: Image.asset('assets/logo.png'),     // Widget at the top of login
);
```

### What happens when you disable features?

| Config | Effect |
|---|---|
| `showGoogleSignIn: false` | Google button hidden. The "OR" divider auto-hides if all social options are off. |
| `showPhoneSignIn: false` | Phone button hidden. No SMS dialog triggered. |
| `showAnonymousSignIn: false` | Guest button hidden. |
| All three `false` | Entire social section + "OR" divider hidden. Only email/password form remains. |
| `showRegister: false` | "Create Account" / "Sign Up" link hidden. Users cannot register. |
| `showForgotPassword: false` | "Forgot Password" link hidden. |
| `showRememberMe: false` | Checkbox hidden. Session always persists (Firebase default behavior). |

---

## ✅ Do's and Don'ts

### ✅ DO

- **DO** complete platform setup (SHA keys, meta tags) **before** testing auth providers.
- **DO** use `const AuthTemplateConfig(...)` to enable tree-shaking and avoid unnecessary rebuilds.
- **DO** pass `serverClientId` (Web Client ID) when creating `FirebaseAuthRepository` if you use Google Sign-In on Android.
- **DO** pass `firestore` + `createUserCollection: true` if you want automatic Firestore user profile creation.
- **DO** wrap `PhoneAuthDialog` in `BlocProvider.value(value: context.read<AuthBloc>(), ...)` when showing it from a custom UI — the dialog needs access to the same BLoC.
- **DO** listen for `EmailVerificationRequiredState` — the module **enforces** email verification for email/password accounts before emitting `AuthenticatedState`.
- **DO** handle `AuthErrorState` in a `BlocListener` to show user-friendly error messages.
- **DO** call `_bloc.close()` in your `dispose()` method when you manage the BLoC yourself.
- **DO** add both `SHA-1` **and** `SHA-256` fingerprints — Google Sign-In needs SHA-1, App Check needs SHA-256.

### ❌ DON'T

- **DON'T** use the Android OAuth Client ID as `serverClientId`. Always use the **Web application** Client ID from Google Cloud Console. Getting this wrong produces `DEVELOPER_ERROR`.
- **DON'T** access `firebase_auth.User` directly in your app. Always use the `AuthUser` entity returned by the BLoC/repository. This keeps your code decoupled from Firebase.
- **DON'T** create multiple `FirebaseAuthRepository` instances. The repository internally initializes `GoogleSignIn` and `PhoneAuthService` — creating duplicates can cause race conditions.
- **DON'T** dispatch `AuthBloc` events from inside `BlocBuilder` callbacks. Use `BlocListener` for side effects.
- **DON'T** call `context.read<AuthBloc>()` inside another BLoC. If two BLoCs need auth data, inject the shared `AuthRepository` into both.
- **DON'T** forget to call `InitializeAuthEvent` when you create the `AuthBloc` yourself. Without it, the bloc won't restore the user's session.
- **DON'T** put UI logic in the `AuthBloc.listener`. The BLoC only emits state; your UI layer decides what to show.
- **DON'T** hardcode Firestore collection names in multiple places. Use the `usersCollectionName` parameter on `FirebaseAuthRepository`.
- **DON'T** skip email verification handling. If a user registers with email/password, the module emits `EmailVerificationRequiredState`, **not** `AuthenticatedState`. Your UI must handle this state.

---

## 🔧 Troubleshooting & Common Mistakes

### `DEVELOPER_ERROR` on Android Google Sign-In

**Cause:** Wrong `serverClientId` or missing SHA fingerprint.

**Fix:**
1. Go to Google Cloud Console → APIs & Services → Credentials.
2. Copy the **Web application** Client ID (not Android).
3. Pass it as `serverClientId` in `FirebaseAuthRepository`.
4. Ensure `SHA-1` is added to Firebase Console for your Android app.

---

### Google Sign-In silently fails on Web

**Cause:** Missing `<meta>` tag or unauthorized domain.

**Fix:**
1. Add `<meta name="google-signin-client_id" content="YOUR_CLIENT_ID">` to `web/index.html`.
2. Go to Firebase Console → Auth → Settings → Authorized domains → add `localhost`.

---

### Social buttons still visible after setting `show...SignIn: false`

**Cause:** You are editing the wrong config object. If you use Pattern 2 (your own repository + template), make sure the `config` parameter you pass to the `*AuthFlow` widget is the one with the disabled flags — not a default config created elsewhere.

**Fix:** Search your codebase for all `AuthTemplateConfig(` instantiations and confirm the correct one is being used.

---

### Phone auth throws error on Web

**Cause:** reCAPTCHA verification domain not whitelisted, or Phone provider not enabled.

**Fix:**
1. Firebase Console → Authentication → Sign-in method → enable Phone.
2. Firebase Console → Authentication → Settings → Authorized domains → add `localhost`.

---

### `EmailVerificationRequiredState` keeps firing even after verification

**Cause:** Firebase caches the user token. The `isEmailVerified` flag updates only after `user.reload()`.

**Fix:** The module handles this internally via `RefreshCurrentUserEvent`. On the verification screen, tap the "I Verified, Refresh" button (or dispatch `RefreshCurrentUserEvent(isSilent: true)` from your custom UI).

---

## 📚 Further Reading

| Document | Content |
|---|---|
| [📖 DOCUMENTATION.md](DOCUMENTATION.md) | Full API reference: BLoC events/states, AuthUser entity, AuthFailure types, FirebaseAuthRepository params, Firestore sync rules |
| [🛣️ ROADMAP.md](ROADMAP.md) | Planned features: Apple Sign-In, Supabase support, Biometric auth, Passkeys, Localization |
| [`example_app/`](example_app/) | Working example app with all 8 templates, manual integration, and DI examples |

---

## 📦 Dependencies

This module brings the following packages (managed automatically via `pubspec.yaml`):

| Package | Purpose |
|---|---|
| `firebase_auth` | Core Firebase Authentication SDK |
| `cloud_firestore` | Optional Firestore user profile sync |
| `google_sign_in` | Google Sign-In (native + web popup fallback) |
| `flutter_bloc` | BLoC state management |
| `dartz` | Functional `Either<L, R>` type for error handling |
| `equatable` | Value equality for entities and states |
| `flutter_secure_storage` | Encrypted storage for "Remember Me" persistence |
| `logger` | Structured logging (suppressed in production) |

---

*Built with ❤️ for the Flutter community.*
