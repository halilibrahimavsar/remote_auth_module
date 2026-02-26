# Remote Auth Module — Roadmap

This document outlines the current capabilities, planned improvements, and long-term vision for the Remote Auth Module.

---

## 📌 Current State (v1.0.0)

### Architecture
- ✅ Strict Clean Architecture (Domain → Data → Presentation)
- ✅ BLoC state management with sealed events/states
- ✅ Functional error handling (`Either<AuthFailure, T>` via `dartz`)
- ✅ Abstract `AuthRepository` interface (swap Firebase for any backend)

### Authentication Providers
- ✅ Email/Password (with mandatory email verification gate)
- ✅ Google Sign-In (native on mobile, popup on web, silent restore)
- ✅ Phone Authentication (SMS OTP with reCAPTCHA on web)
- ✅ Anonymous/Guest Sign-In
- ✅ Password reset via email
- ✅ Password change (with re-authentication)
- ✅ Display name update

### UI Templates
- ✅ `RemoteAuthFlow` — Standard Material 3 glassmorphism
- ✅ `AuroraAuthFlow` — Dark mesh gradient with orbiting particles
- ✅ `WaveAuthFlow` — Liquid water-wave animated header
- ✅ `NeonAuthFlow` — Cyberpunk neon glow
- ✅ `NovaAuthFlow` — Space starfield with gold accents
- ✅ `PrismaAuthFlow` — Morphing blobs and frosted glass
- ✅ `ZenAuthFlow` — Falling petals, calm earth tones
- ✅ `RetroAuthFlow` — CRT scanlines and 8-bit glitch effects

### Data Layer
- ✅ `FirebaseAuthRepository` with configurable Firestore sync
- ✅ `FirestoreUserService` (auto-creates, updates, and manages user docs)
- ✅ `RememberMeService` (encrypted persistence via `flutter_secure_storage`)
- ✅ Structured logging via `logger` package (auto-suppressed in production)

### Configuration
- ✅ `AuthTemplateConfig` — 10+ toggleable parameters (Google, Phone, Anonymous, Register, Forgot Password, Remember Me, titles, logos)
- ✅ Multi-Firebase-app support (inject custom `FirebaseAuth` / `FirebaseFirestore` instances)

### Testing
- ✅ Unit tests for BLoC, Repository, Entities, and Failures
- ✅ Mock support via `mocktail`
- ✅ `bloc_test` for state transition assertions

---

## 🔜 Short-Term (Next Release)

| Feature | Description | Status |
|---|---|---|
| Apple Sign-In | Native Apple auth for iOS/macOS with web fallback | 🔲 Planned |
| Localization (l10n) | `.arb`-based translations for all template strings | 🔲 Planned |
| Template screenshots | Embedded preview images in documentation | 🔲 Planned |
| Backend optionality | DI-level pruning of unused auth services to reduce initialization overhead | 🔲 Planned |
| More template customization | Custom color overrides per template (primary, accent, background) | 🔲 Planned |

---

## 🔄 Medium-Term

| Feature | Description | Status |
|---|---|---|
| Biometric Authentication | FaceID/TouchID via `local_auth`, tied into BLoC session gating | 🔲 Exploring |
| Supabase Backend | `SupabaseAuthRepository` as a drop-in alternative to Firebase | 🔲 Exploring |
| GitHub/Twitter OAuth | Expand OAuth provider coverage | 🔲 Exploring |
| Passkeys (FIDO2) | Modern passwordless authentication flow | 🔲 Research |
| TOTP 2FA | Authenticator app-based two-factor authentication | 🔲 Research |
| Profile management page | Built-in page for avatar upload, name edit, email change | 🔲 Exploring |

---

## 🔭 Long-Term Vision

| Feature | Description |
|---|---|
| Enterprise admin panel | `remote_auth_admin` micro-module for user/role management dashboard |
| Remote Config integration | Toggle templates and features via Firebase Remote Config flags |
| CLI tooling | Automated SHA fingerprint injection, domain whitelisting, and config generation |
| Offline-first auth | Cached credentials + sync-on-reconnect for field/rural apps |

---

## 🤝 Contributing

If you want to contribute or suggest a feature:

1. Open an issue describing the feature or bug.
2. Reference this roadmap to check if it's already planned.
3. Follow the module's Clean Architecture layers — domain changes go in `domain/`, Firebase implementations in `data/`, UI in `presentation/`.
4. All PRs must pass `flutter analyze` with zero warnings and `flutter test` with no failures.

---

*This roadmap is a living document. Priorities may shift based on project needs and community feedback.*
