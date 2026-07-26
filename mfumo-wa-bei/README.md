# Mfumo wa Bei

Flutter frontend for a pricing system, intended to connect to a Django backend.

## Run the app

```bash
flutter pub get
flutter run -d chrome -t lib/main_dev.dart --web-port 50100
```

Open the web app at:

```text
http://localhost:50100/
```

Register page:

```text
http://localhost:50100/#/register
```

## Useful commands

Install dependencies:

```bash
flutter pub get
```

Run web app on the fixed development port:

```bash
flutter run -d chrome -t lib/main_dev.dart --web-port 50100
```

Run Android app:

```bash
flutter run -d android -t lib/main_dev.dart
```

Run tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Build production Android APK:

```bash
flutter build apk --release -t lib/main_prod.dart
```

Build production web app:

```bash
flutter build web --release -t lib/main_prod.dart
```

## Project stack

- Flutter for the mobile frontend
- Django for the backend API

## Suggested next work

- Add screens for products, prices, and reports
- Connect to Django REST API endpoints
- Add state management and authentication
