# M4 Family

Flutter mobile app for M4 Family real estate — a native port of the M4 Family web
platform. Four portals in one app: **Guest**, **Customer**, **Channel Partner (CP)**,
and **Investor**.

- **Package (Android):** `com.m4family.m4_mobile`
- **Bundle ID (iOS):** `com.m4family.m4Mobile`
- **State management:** Riverpod · **Routing:** go_router · **Networking:** dio

## Getting started

```bash
flutter pub get
cp .env.example .env        # then fill in API_URL / WEB_URL
flutter run
```

`.env` is required at runtime (loaded via `flutter_dotenv`) and holds `API_URL`
and `WEB_URL`.

## Release builds

Android release signing reads `android/key.properties` (never committed). Without
it, builds fall back to the debug key so local/CI builds keep working.

```bash
# one-time: create the upload keystore (run inside android/app)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload

# then: cp android/key.properties.example android/key.properties  and fill it in
flutter build appbundle --release    # Play Store
flutter build ipa --release          # App Store
```

## Project layout

```
lib/
  core/            theme, network (ApiClient), providers, utils
  data/            models
  presentation/
    screens/       124 screens across the 4 portals
    widgets/       shared widgets (shells, drawers, amenity icons, ...)
    providers/     Riverpod providers (auth, projects, ...)
android/ ios/      native shells
packages/          vendored lucide_icons override
```

## Notes

- R8/ProGuard is enabled for release (`android/app/proguard-rules.pro`).
- Native launch screen shows the M4 logo on black to match the Flutter splash.
