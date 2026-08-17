# 📱 Nagpur Setu (नागपूर सेतू) — Flutter Mobile App
### Official Native Android & iOS Civic Reporting & Municipal Accountability App

> Built with **Flutter 3.32**, **Dart 3.8**, and Google Material 3 Design matching the Stitch design system.

---

## 🌟 Mobile-First Features

1. **🗺️ Interactive Map Screen (`lib/screens/map_screen.dart`)**
   * High-performance vector/raster map powered by `flutter_map` and `latlong2`.
   * Real-time status pins (🔴 Open, 🟠 In Progress, 🟢 Resolved).
   * Tap any pin to pop up an interactive Material 3 **Bottom Sheet** with instant issue preview, report counter, and quick navigation.
   * Ward flyTo dropdown and GPS "Locate Me" targeting.

2. **📸 3-Step Mobile Report Wizard (`lib/screens/report_screen.dart`)**
   * **Step 1:** Photo Proof capture + **AI Vision Classifier** (`lib/services/vision_classifier.dart`) suggesting category with confidence match.
   * **Step 2:** Ward and landmark picker with **50-meter Haversine Duplicate Proximity Alert**.
   * **Step 3:** Citizen Phone OTP verification with SHA-256 privacy hashing (prevents spam bots without requiring Aadhaar).
   * Animated **Celebration Confetti** on successful report publication!

3. **🔍 Public Issue Detail Screen (`lib/screens/issue_detail_screen.dart`)**
   * Exact Stitch design replica.
   * Full-width Hero image with overlay gradient.
   * Social proof counter: `32 🍊 citizens corroborated this same issue`.
   * Verified location card & status history timeline (`Reported` ➔ `Assigned` ➔ `In Progress` ➔ `Resolved`).
   * Before & After side-by-side comparative repair audit cards.
   * Bottom bar with `Share` and `+1 Me Too` (`Icons.exposure_plus_1`).

4. **🏆 Ward Accountability Leaderboard (`lib/screens/leaderboard_screen.dart`)**
   * Gold 🥇, Silver 🥈, and Bronze 🥉 podium ranking cards.
   * Resolution percentage progress bars across all 10 Nagpur municipal wards.

5. **🛡️ NMC Admin Command Desk (`lib/screens/admin_screen.dart`)**
   * Real-time KPI summary cards.
   * Priority Urgency Queue ranked by citizen corroboration count descending.
   * **Mandatory Resolution Proof:** Requires field official to upload a verified **After-Photo** before marking ticket closed.

---

## 📱 How to Run on Android / iOS

```bash
# 1. Navigate to the flutter project directory
cd /home/endertrailer/nagpur_setu_flutter

# 2. Get dependencies
flutter pub get

# 3. Run on connected Android device or Emulator
flutter run -d android

# 4. Build Debug APK
flutter build apk --debug

# The generated APK is located at:
# build/app/outputs/flutter-apk/app-debug.apk
```
# nagpur_setu
