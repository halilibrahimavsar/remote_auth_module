# example_app

Example integration for `remote_auth_module`.

## Run Android / iOS

```bash
flutter pub get
flutter run
```

## Run Web

This example supports web, but Firebase web options must be configured.

### Option 1 (recommended)
Generate `firebase_options.dart` including web values:

```bash
flutterfire configure --project <your-project-id> --platforms=android,ios,web
```

Then run:

```bash
flutter run -d chrome
```

### Option 2 (no file edit, via dart-define)
If your `firebase_options.dart` still has placeholder web values, you can run with:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_WEB_PROJECT_ID=... \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=...
```

`example_app/lib/main.dart` now includes a web bootstrap fallback that reads these values.
