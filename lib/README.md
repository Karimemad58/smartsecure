# SmartSecure Flutter App

A smart locker booking app with 8 screens matching the provided design.

## Screens Included

1. **Splash Screen** – Logo with animation → auto-navigates to onboarding
2. **Onboarding (3 slides)** – Store safely / Open with phone / Fast payments
3. **Welcome / Login** – Email, password, social login
4. **Sign Up** – Registration with national ID photo upload
5. **Home** – Book locker banner + nearby locations list
6. **Search** – Search bar + map view + filtered results
7. **Locker Detail** – Location info + locker size selection + booking

## How to Run

1. Make sure Flutter is installed: https://flutter.dev/docs/get-started/install

2. Open the `smart_secure` folder in VS Code:
   ```
   cd smart_secure
   ```

3. Get dependencies:
   ```
   flutter pub get
   ```

4. Run on an emulator or connected device:
   ```
   flutter run
   ```

   Or run on Chrome (web):
   ```
   flutter run -d chrome
   ```

## Project Structure

```
lib/
├── main.dart
└── screens/
    ├── splash_screen.dart
    ├── onboarding_screen.dart
    ├── welcome_screen.dart
    ├── signup_screen.dart
    ├── home_screen.dart
    ├── search_screen.dart
    └── locker_detail_screen.dart
```

## Color Palette

- Primary Blue: `#3B6FE8`
- Background: `#F5F7FF`
- Text Dark: `#1A1A2E`
- Text Light: `#8090B0`
