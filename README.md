# Market — Campus Student Marketplace

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC-blue)](#architecture--state-management)
[![Android CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20(Android)-green)](.github/workflows/android_ci_cd.yml)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Market** is a full-featured, cross-platform mobile marketplace application built for university students to buy, sell, and trade items locally on campus. Built with **Flutter**, **BLoC Pattern**, **Clean Architecture**, and **Supabase**, this app demonstrates production-ready mobile engineering standards including real-time chat, offline caching, native image optimization, in-app monetization, and deep-link integration.

---

## Features

- **Campus & Category Filtering:** Browse products tailored specifically to your university and filter by categories (Electronics, Books, Kitchen, Sports, Room, etc.).
- **Secure Authentication & Onboarding:** Complete authentication flow powered by Supabase Auth (Email & Password, Email Verification, Deep-Link Password Resets, and Profile Setup).
- **Product Management & Seller Inventory:** List products with multi-photo support, edit listing prices, track product statuses (`Active` vs `Payment Pending`), and manage personal inventory.
- **Real-time Buyer-Seller Messaging:** Instant 1-on-1 chat using Supabase Realtime subscriptions, complete with unread message badges, message history, and auto-scrolling chat UI.
- **Offline-First & Caching:** Instant product loading via local persistent storage (`Hive`) paired with automatic network detection (`connectivity_plus`) to handle offline states seamlessly.
- **Image Optimization & Bandwidth Efficiency:** Hardware-level image cropping and resolution reduction (`maxWidth`/`maxHeight`/`imageQuality`) before upload to keep payload sizes lightweight (~150KB vs 10MB raw camera photos), rendered via memory-efficient `CachedNetworkImage`.
- **Monetization & In-App Purchases:** RevenueCat (`purchases_flutter`) integration for listing fee purchases, free trial tracking, and paywall management.
- **Deep Linking:** Custom URI scheme routing (`app_links`) handling authentication callbacks and payment confirmation redirects (`marketapp://paymentrecieved-callback`).

---

## Architecture & State Management

The project is structured according to **Clean Architecture** principles, enforcing strict separation of concerns into distinct layers:

```text
lib/
├── core/                   # Utilities, Theme, Offline Caching, Snacking, Global Constants
├── data/                   # Data sources (Supabase API), Models (JSON serialization), Repositories Impl
├── domain/                 # Core Business Entities & Abstract Repository Interfaces
├── features/               # Feature-based BLoC & Presentation Modules
│   ├── auth/               # Authentication State Management
│   ├── user/               # User Profile Management
│   ├── product/            # Main Catalog & Seller Inventory (ProductBloc, MyProductsBloc)
│   ├── chat/               # 1-on-1 Messaging (ChatBloc)
│   ├── conversation/       # Conversations Inbox (ConversationsBloc)
│   ├── search/             # Catalog Search Engine (SearchBloc)
│   ├── images/             # Media Upload Pipeline (ImagesBloc)
│   ├── network/            # Real-time Network Connectivity Monitor (NetworkBloc)
│   └── presentation/       # UI Views, Pages & Shared Widgets
└── main.dart               # App Entry Point & Service Locator Initialization
```

### Key Engineering Practices Highlighted:
- **BLoC Pattern (`flutter_bloc`):** Unidirectional data flow ensuring predictable state management and UI testability.
- **Single-Responsibility BLoCs:** Feature-decoupled BLoCs (e.g., separating `ProductBloc` for the main feed from `MyProductsBloc` for seller listings) to prevent state clobbering and unexpected screen rebuilds.
- **Dependency Injection (`GetIt`):** Inverted dependencies allowing easy swapping of data sources or mocking for unit/integration testing.

---

## Tech Stack & Libraries

| Category | Technology / Package |
|---|---|
| **Framework & Language** | [Flutter](https://flutter.dev) (Dart 3) |
| **State Management** | [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) & [`equatable`](https://pub.dev/packages/equatable) |
| **Backend & Realtime** | [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) |
| **Dependency Injection** | [`get_it`](https://pub.dev/packages/get_it) |
| **Local Storage / Caching** | [`hive_flutter`](https://pub.dev/packages/hive_flutter) |
| **Network Status** | [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) |
| **Monetization** | [`purchases_flutter`](https://pub.dev/packages/purchases_flutter) (RevenueCat) |
| **Media Handling** | [`image_picker`](https://pub.dev/packages/image_picker), [`image_cropper`](https://pub.dev/packages/image_cropper), [`cached_network_image`](https://pub.dev/packages/cached_network_image) |
| **Deep Links** | [`app_links`](https://pub.dev/packages/app_links) |
| **Environment Config** | [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) |

---

## Getting Started

### Prerequisites

Ensure you have the following installed on your development machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0`)
- Android Studio / Xcode / VS Code with Flutter extension
- A [Supabase](https://supabase.com) project with Database, Storage buckets (`user-images`), and Auth configured.
- (Optional) A [RevenueCat](https://www.revenuecat.com) project for testing payment entitlements.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/market.git
   cd market
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   REVENUECAT_API_KEY=your-revenuecat-api-key
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## ⚙️ Android CI/CD Pipeline (GitHub Actions & Google Play)

An automated **Android-only CI/CD pipeline** is configured via GitHub Actions (`.github/workflows/android_ci_cd.yml`):

### Pipeline Stages:
1. **Analyze & Test:** Automatically runs `flutter analyze` and `flutter test` on every push and pull request.
2. **Build Android Release:** Configures JDK 17, injects environment variables, decodes release signing keystores, and compiles both release `.apk` and `.aab` (App Bundle) artifacts.
3. **Google Play Console Upload:** Automated deployment of the `.aab` file to Google Play Console's Internal Testing track upon merging into `main`.

### Configurable GitHub Repository Secrets:
| Secret Name | Description |
|---|---|
| `SUPABASE_URL` | Supabase backend URL |
| `SUPABASE_ANON_KEY` | Supabase public anon key |
| `REVENUECAT_API_KEY` | RevenueCat API key |
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded release `.jks` keystore file |
| `ANDROID_KEY_ALIAS` | Release keystore key alias |
| `ANDROID_KEY_PASSWORD` | Release keystore key password |
| `ANDROID_STORE_PASSWORD` | Release keystore store password |
| `PLAY_CONSOLE_SERVICE_ACCOUNT_JSON` | Google Play Developer API Service Account JSON |

---

## Key Architectural Lessons & Highlights

- **Decoupled BLoC Architecture:** Resolved complex state collisions between the main marketplace feed and individual seller dashboards by separating inventory management into a dedicated `MyProductsBloc`.
- **Bandwidth & Memory Performance:** Implemented native hardware-level image scaling (`maxWidth`/`maxHeight`) prior to network transmission, reducing user data consumption by ~95% and guaranteeing fast image loads across grid feeds.
- **Resilient Real-time Sync:** Combined local `Hive` offline caching with Supabase Realtime subscriptions to present an immediate UI render while fetching incoming network updates asynchronously.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
