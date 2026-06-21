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
| 🥗 **Nutrition Logger** | Log meals, scan barcodes, search USDA food database, and track macros |
| 🤖 **AI Fitness Coach** | Chat with an AI coach powered by Google Gemini for real-time advice |
| 📋 **Smart Plans** | AI-generated personalized weekly workout & nutrition plans |
| 📊 **Progress Analytics** | Charts, streaks, achievements, and weekly summaries |
| ❤️ **Health Integration** | Sync steps, heart rate, sleep data via Android Health Connect |
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
| **AI / ML** | Google Gemini API, ML Kit Pose Detection |
| **Nutrition Data** | USDA FoodData API, OpenFoodFacts, Spoonacular |
| **Health Data** | Android Health Connect (health package) |
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
- A valid `config.json` file with your API keys (see below)

### 1. Clone the Repository

```bash
git clone https://github.com/Ammayasser/BeFit.git
cd BeFit
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API Keys

This project uses environment-based API keys — **no keys are ever stored in source code**.

Create a `config.json` file in the project root (this file is gitignored):

```json
{
  "BEFIT_GEMINI_API_KEY": "your_gemini_api_key_here",
  "BEFIT_GEMINI_SECONDARY_API_KEY": "your_secondary_gemini_key_here",
  "BEFIT_GEMINI_TERTIARY_API_KEY": "your_tertiary_gemini_key_here",
  "BEFIT_USDA_API_KEY": "your_usda_api_key_here",
  "BEFIT_OPENROUTER_KEY": "your_openrouter_key_here",
  "BEFIT_SPOONACULAR_API_KEY": "your_spoonacular_key_here"
}
```

Get your free API keys:
- **Gemini**: [Google AI Studio](https://aistudio.google.com/apikey)
- **USDA**: [FoodData Central](https://fdc.nal.usda.gov/api-guide.html)
- **Spoonacular**: [Spoonacular Developer](https://spoonacular.com/food-api)
- **OpenRouter**: [OpenRouter](https://openrouter.ai/)

### 4. Run the App

```bash
# Run with API keys injected from config.json
flutter run \
  --dart-define=BEFIT_GEMINI_API_KEY=your_key \
  --dart-define=BEFIT_GEMINI_SECONDARY_API_KEY=your_key \
  --dart-define=BEFIT_GEMINI_TERTIARY_API_KEY=your_key \
  --dart-define=BEFIT_USDA_API_KEY=your_key \
  --dart-define=BEFIT_OPENROUTER_KEY=your_key \
  --dart-define=BEFIT_SPOONACULAR_API_KEY=your_key
```

> 💡 **Tip**: On VS Code, add these as `--dart-define` entries in your `launch.json` for convenience.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants & API key references
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

- **No API keys are committed** to version control — all secrets live in the local `config.json` (gitignored) and are injected at build time via `--dart-define`.
- Health data is processed **on-device only** and never sent to external servers.
- The app requests only the minimum necessary permissions.

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
Made with ❤️ and Flutter &nbsp;|&nbsp; &copy; 2026 BeFit
</div>
