# Testing

This project includes unit tests, widget tests, and a small integration test suite for the most stable and high-value flows.

## Verified Test Coverage

The current test set covers the following areas:

### UI and navigation
- report submission confirmation screen behavior
- settings screen behavior for guest and authenticated roles
- route navigation using `go_router`

### State management
- Riverpod providers for:
  - authentication actions
  - current user state
  - derived role, display name, email, and company ID
  - theme mode persistence
  - debug and shared preference integration

### Validation and domain logic
- email validation
- password and confirm-password validation
- verification code validation
- model serialization and deserialization
- copy/update behavior for selected domain models

### Test infrastructure
- fake authentication repository
- fake user repository
- shared test app builders
- mock shared preferences setup

## Project Structure

```text
test/
├── core/
│   ├── theme/
│   │   └── app_theme_test.dart
│   └── utils/
│       └── validators_test.dart
├── features/
│   ├── reports/
│   │   └── report_submitted_screen_test.dart
│   └── settings/
│       └── settings_screen_test.dart
├── helpers/
│   ├── fake_auth_repository.dart
│   ├── fake_user_repository.dart
│   ├── test_app.dart
│   └── test_preferences.dart
├── shared/
│   ├── models/
│   │   └── models_serialization_test.dart
│   └── providers/
│       ├── auth_provider_test.dart
│       ├── debug_mode_provider_test.dart
│       ├── theme_provider_test.dart
│       └── user_provider_test.dart
└── main_user_role_provider_test.dart
```

## Tech Stack

The available test files show usage of the following technologies:

- Flutter
- Dart
- Flutter Test
- Riverpod
- GoRouter
- SharedPreferences
- Firebase Auth
- Mockito


## How to run

Install dependencies first:

```bash
flutter pub get
```

Run unit and widget tests:

```bash
flutter test
```
## Expected result

A successful run finishes without failures in the terminal.

Example:

```text
+111: All tests passed!
```

If you see failed counts such as `-1` or `-3`, at least one test is still failing and needs investigation.

For information regarding our integration tests go [here](./INTEGRATION_TESTS_README.md)
