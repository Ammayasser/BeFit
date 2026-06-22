<div align="center">

<img src="assets/images/app-logo/befit-logo.jpg" alt="BeFit Logo" width="120" style="border-radius: 24px;" />

# 🏋️ BeFit — AI-Powered Fitness & Health Companion

**Your all-in-one Flutter fitness app: workouts, nutrition tracking, AI coaching, and wearable health data — beautifully unified.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS-lightgrey)](https://flutter.dev)

</div>

---

## 📱 Overview

**BeFit** is a premium, AI-powered fitness and health companion built with Flutter. It combines workout tracking, smart nutrition logging, barcode food scanning, AI chat coaching, personalized smart plans, and real-time wearable integration — all wrapped in a sleek, modern dark-mode UI.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏋️ **Workout Tracker** | Log exercises with sets, reps, weights, rest timers, and animated muscle maps |
| 🥗 **Nutrition Logger** | Log meals, scan barcodes, search food database, and track macros |
| 🤖 **AI Fitness Coach** | Chat with an AI coach powered by Google Gemini for real-time advice |
| 📋 **Smart Plans** | AI-generated personalized weekly workout & nutrition plans |
| 📊 **Progress Analytics** | Charts, streaks, achievements, and weekly summaries |
| 🔔 **Smart Notifications** | Workout reminders, hydration alerts, daily progress nudges |
| 🏆 **Achievements** | Gamified milestone system to keep you motivated |
| 📷 **Pose Detection** | Real-time ML Kit pose detection for form feedback during workouts |
| 🌙 **Dark / Light Mode** | Beautifully designed themes with smooth transitions |

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x |
| **State Management** | Riverpod + Provider |
| **Navigation** | go_router |
| **Local Database** | SQLite (sqflite) + Hive |
| **Charts** | fl_chart |
| **Animations** | flutter_animate, Lottie, flutter_staggered_animations |
| **UI** | Google Fonts, cached_network_image, shimmer, skeletonizer |
| **Notifications** | flutter_local_notifications + timezone |
| **Video/Audio** | video_player, audioplayers |
| **Camera** | camera, mobile_scanner, image_picker |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.x` (Dart `^3.11.5`)
- Android Studio or VS Code with Flutter plugin
- Android device / emulator running API 26+ (Android 8.0+)

### 1. Clone the Repository

```bash
git clone https://github.com/Ammayasser/BeFit.git
cd BeFit
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

> 💡 **Tip**: Use an Android emulator or a physical device running Android 8.0+ (API 26+) for the best experience. 

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants
│   ├── database/        # SQLite & Hive setup
│   ├── router/          # go_router navigation
│   ├── services/        # AI, HTTP, notification services
│   ├── theme/           # Light & dark themes
│   └── widgets/         # Shared UI components
└── features/
    ├── auth/            # Onboarding & user setup
    ├── workout/         # Workout logging & tracking
    ├── nutrition/       # Meal logging, barcode scanner
    ├── ai_coach/        # AI chat interface
    ├── smart_plan/      # AI-generated plans
    ├── progress/        # Charts & analytics
    ├── health/          # Wearable health data
    └── settings/        # User preferences
```

---

## 🔐 Security & Privacy

- The AI backend is powered by a **custom, proprietary AI model** developed specifically for BeFit — no third-party AI credentials are required from contributors.
- Health data is processed **on-device only** and never sent to external servers.
- The app requests only the minimum necessary permissions.
- All sensitive configuration is gitignored and never committed to version control.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feat/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
&nbsp;|&nbsp; &copy; 2026 BeFit
</div>
