# Implementation Plan - Student Marketplace BLoC Structure

This plan outlines the creation of a scalable, feature-based directory structure for a Flutter application using the BLoC pattern.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///C:/Users/chokw/AndroidStudioProjects/market/pubspec.yaml)
Add the following dependencies:
- `flutter_bloc`: For state management.
- `equatable`: To simplify equality comparisons in BLoC states/events.
- `bloc`: Core BLoC library.
- `get_it`: For dependency injection.

---

### Project Structure (under `lib/`)

I will create a feature-first folder structure:

#### Core Layer (`lib/core/`)
- `constants/`: App strings, dimensions, etc.
- `theme/`: App themes and colors.
- `utils/`: Common helper functions.
- `error/`: Failure and Exception classes.

#### Data Layer (`lib/data/`)
- `models/`: Global data models (e.g., `User`, `Product`).
- `repositories/`: Abstract and concrete repository implementations.
- `providers/`: Data sources (API clients, local database).

#### Features Layer (`lib/features/`)
Each feature will contain its own logic and UI:
- `auth/`
  - `bloc/`: `AuthBloc`, `AuthEvent`, `AuthState`.
  - `presentation/`: `LoginScreen`, `SignupScreen`, specific widgets.
- `home/`
  - `bloc/`: `HomeBloc`.
  - `presentation/`: `HomeScreen`.
- `product/`
  - `bloc/`: `ProductBloc` (for details and adding products).
  - `presentation/`: `ProductDetailsScreen`, `AddProductScreen`.
- `cart/`
  - `bloc/`: `CartBloc`.
  - `presentation/`: `CartScreen`.
- `profile/`
  - `bloc/`: `ProfileBloc`.
  - `presentation/`: `ProfileScreen`.

---

### Verification Plan

#### Automated Tests
- I will run `flutter pub get` to verify dependencies.
- I will create a basic `app.dart` and update `main.dart` to ensure the structure compiles.

#### Manual Verification
- Verify the directory hierarchy in the file explorer.
