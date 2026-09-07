# PagoVoz Project Structure

## Root

```text
PagoVoz/
├── app/                          # Android app module
├── gradle/                       # Gradle wrapper and version catalog
├── build.gradle.kts              # Root Gradle config
├── settings.gradle.kts           # Project settings
├── gradle.properties             # Shared Gradle properties
├── local.properties              # Local SDK, Supabase and signing config
├── gradlew / gradlew.bat         # Gradle wrapper scripts
├── download-landing.html         # Standalone download landing page draft
├── index.html                    # Static landing page for web deployment
├── PROJECT_ANALYSIS.md           # Existing project analysis notes
├── PROJECT_HANDOFF_2026-03-08.md # Existing handoff notes
├── SUPABASE_CONFIG_CHECK.md      # Supabase validation notes
├── SUPABASE_SETUP_GUIDE.md       # Supabase setup guide
└── supabase_setup.sql            # Supabase SQL setup script
```

## App Module

```text
app/
├── build.gradle.kts              # App build config, versions, signing, BuildConfig
├── proguard-rules.pro            # Release shrinking/obfuscation rules
├── release/                      # Manual release artifacts kept in repo workspace
├── build/                        # Generated outputs
└── src/
    ├── main/
    ├── test/
    └── androidTest/
```

## Main Source Set

```text
app/src/main/
├── AndroidManifest.xml
├── ic_launcher-playstore.png
├── java/com/example/pagovoz/
│   ├── MainActivity.kt
│   ├── AppNavigation.kt
│   ├── AppNavigationViewModel.kt
│   ├── ViewModelFactories.kt
│   ├── ActivationScreen.kt
│   ├── ActivationViewModel.kt
│   ├── HomeScreen.kt
│   ├── HomeComponents.kt
│   ├── HomeViewModel.kt
│   ├── HistoryScreen.kt
│   ├── ReportGeneratorScreen.kt
│   ├── ReportsViewModel.kt
│   ├── PremiumScreens.kt
│   ├── UpdateViewModel.kt
│   ├── PagoNotificationListener.kt
│   ├── PaymentNotificationParser.kt
│   ├── SessionManager.kt
│   ├── SupabaseManager.kt
│   ├── Repositories.kt
│   ├── DailyResetPolicy.kt
│   └── ui/theme/
│       ├── Color.kt
│       ├── Theme.kt
│       └── Type.kt
└── res/
    ├── drawable/
    ├── mipmap-*/
    ├── values/
    └── xml/
```

## Main Code Responsibilities

- `MainActivity.kt`: app entry point and activation flow bootstrap.
- `PagoNotificationListener.kt`: listens for posted notifications and triggers voice/payment handling.
- `PaymentNotificationParser.kt`: extracts payment sender and amount from Yape/Plin notifications.
- `SessionManager.kt`: local persistence for activation, premium state, totals and history.
- `SupabaseManager.kt`: remote integration for license validation, premium status and app update checks.
- `Repositories.kt`: small repository abstractions over session/license/update access.
- `HomeScreen.kt`, `HistoryScreen.kt`, `ReportGeneratorScreen.kt`, `PremiumScreens.kt`, `ActivationScreen.kt`: Compose UI screens.
- `HomeViewModel.kt`, `ActivationViewModel.kt`, `ReportsViewModel.kt`, `UpdateViewModel.kt`, `AppNavigationViewModel.kt`: presentation state and screen logic.

## Resources

```text
app/src/main/res/
├── values/
│   ├── strings.xml               # User-facing text
│   ├── colors.xml
│   └── themes.xml
├── xml/
│   ├── backup_rules.xml
│   ├── data_extraction_rules.xml
│   └── file_paths.xml
├── drawable/
│   └── mi_logo.png
└── mipmap-*/                     # Launcher icons
```

## Tests

```text
app/src/test/java/com/example/pagovoz/
├── ActivationViewModelTest.kt
├── HomeViewModelTest.kt
├── PaymentNotificationParserTest.kt
├── DailyResetPolicyTest.kt
├── MainDispatcherRule.kt
└── ExampleUnitTest.kt
```

- `test/`: unit tests for parser and view models.
- `androidTest/`: instrumentation test scaffold for device/emulator tests.

## Build And Release Outputs

```text
app/build/outputs/apk/release/
├── Pago-voz.apk
├── output-metadata.json
└── SHA256.txt
```

- `Pago-voz.apk`: signed release APK output.
- `output-metadata.json`: Gradle metadata for the generated APK.
- `SHA256.txt`: checksum file for distribution verification.

## Operational Files

- `local.properties`: local-only values for SDK path, Supabase URL/key and release signing credentials.
- `index.html`: static landing page intended for Vercel or similar hosting.
- `download-landing.html`: alternate landing page version kept in the repo root.

## Notes

- The project currently uses a single Android app module.
- The app depends on Supabase for licensing, premium status and remote update metadata.
- Release distribution is based on signed APK files and GitHub Releases rather than Play Store delivery.
