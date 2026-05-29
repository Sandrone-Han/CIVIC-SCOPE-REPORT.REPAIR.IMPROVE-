# Civic Scope Integration Tests


## Overview

screenshots in folder `integration_test`
- **Project:** Civic Scope
- **Test type:** Flutter integration testing
- **Source files:** 4 integration test files
- **Execution target:** Android emulator or another supported Flutter device

## Scope

The integration tests cover four main areas:

1. **Authentication flow**
   - Login
   - Forgot password navigation
   - Reset email submission
   - Sign-up navigation with prefilled values
   - Reset password success

2. **Debug flow**
   - Enable debug mode
   - Open role selector
   - Launch admin debug sign-in path

3. **Role shell navigation**
   - Guest
   - Citizen
   - Worker
   - Company
   - Council
   - Admin

4. **Settings and report flow**
   - Theme change
   - Theme persistence after rebuild
   - Logout
   - Report submitted confirmation screen


## How to Run

In order to successfully run the integration tests you need to have the android emulator installed. To confirm the emulator or device is available:

```bash
flutter emulators
flutter devices
```

Once you've verified it's running and detected, run each test file separately from the project root. Note that you should **not** execute `flutter run` before running each integration test.

To run the tests enter:

```bash
flutter test integration_tests/authentication_navigation_flow_test.dart
```
```bash
flutter test integration_tests/debug_role_selector_flow_test.dart
```
```bash
flutter test integration_tests/role_shell_navigation_flow_test.dart
```
```bash
flutter test integration_tests/settings_and_report_flow_test.dart
```

## Result Summary

| Group | Coverage |
|---|---|
| AUTH | Authentication flow |
| DBG | Debug mode and role selector |
| SHELL | Six role shells and navigation |
| SET/REP | Settings and report submitted |
| TOTAL | All planned integration tests |

## Detailed Coverage

### 1. Authentication

| ID | Test | Expected result |
|---|---|---|
| AUTH-01 | Login success | Sign-in is triggered with the entered credentials and the app continues to the expected authenticated flow. |
| AUTH-02 | Forgot password navigation | `ForgotPasswordScreen` opens with the email prefilled and returns to `LoginPage`. |
| AUTH-03 | Reset email success | Reset handler is called once and confirmation text is displayed. |
| AUTH-04 | Sign-up navigation with prefills | `SignUpScreen` opens with both values prefilled and can return to `LoginPage`. |
| AUTH-05 | Reset password success | Reset code is verified, password reset succeeds, success message appears, and the app returns home. |

### 2. Debug Role Selector

| ID | Test | Expected result |
|---|---|---|
| DBG-01 | Enable debug mode | Debug mode is enabled, sign-out is triggered, and `RoleSelectorScreen` becomes available. |
| DBG-02 | Admin debug sign-in | Admin debug credentials are used and the app routes to auth loading. |

### 3. Role Shell Navigation

Each role shell includes three checks:

- Branch switching
- Deep link opening the final tab
- Repeated tap on the current tab remains stable

| Role |Expected result |
|------|------|
| Guest | Map, Search, and Settings tabs remain visible and navigation behaves correctly. |
| Citizen | All citizen tabs remain visible and deep linking opens the correct branch. |
| Worker | Worker shell opens expected pages and remains stable on repeated current-tab taps. |
| Company | Company shell switches branches correctly and deep links to the expected tab. |
| Council | Council shell behaves correctly across branch switches and deep links. |
| Admin |Admin shell opens correctly, including the Admin panel branch. |

### 4. Settings and Report Flow

| ID | Test | Expected result |
|---|---|---|
| SET-01 | Guest settings and welcome route | Theme is changed to Dark, preference is saved, sign-out is triggered, and Welcome route opens. |
| SET-02 | Theme persistence | Dark theme remains selected after app rebuild using the same preferences. |
| SET-03 | Authenticated logout | Profile, Bookmarked, and Log Out are shown and sign-out is triggered once. |
| REP-01 | Report submitted confirmation | Category and status are shown, `last_screen` is saved, and Home map route opens. |

For information regarding our unit tests go [here](./UNIT_TESTS_README.md)