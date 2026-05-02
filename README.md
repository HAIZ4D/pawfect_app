<div align="center">

# 🐾 Pawfect

### AI-Powered Pet Healthcare

*Snap, scan, and stay one step ahead.*

[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini_2.5_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)

</div>

---

## ✨ Live demo

> 🌐 **<https://pawfect-ed0a1.web.app>**

That's the web build of the app, running right now. Open it in a browser and you can sign up, add a pet, run a scan via gallery upload, log weights, and explore the full UI. The native camera doesn't work on the web build (Flutter web limitation), but every other feature does.

For the full mobile experience, install it locally per the setup steps below.

---

## What it does

Pawfect is a pet healthcare app for dog and cat owners. Three core jobs:

1. **AI illness detection.** Snap a photo or pick symptoms. Google Gemini 2.5 Flash reads skin, eyes, wounds and posture, returns a likely condition with urgency level (`EMERGENCY` / `HIGH` / `MODERATE` / `LOW`), first-aid steps, and a vet-ready report.
2. **PawBook digital record.** A magazine-style profile per pet. Photos, breed, weight history, vaccinations, scan results, all kept together. Shareable QR for any vet to read.
3. **Poison alert.** Toxic substance triage. Search what your pet ate, get the urgency, the first-aid, and the nearest open vet.

Plus a daily Gemini-curated care insight, a weight trend sparkline, a health pulse chart of recent scan urgencies, and reminders for vaccinations and medications.

---

## 🛠️ Tech stack

| Layer | Tool |
|---|---|
| Framework | Flutter (Dart 3.7+) |
| AI | Google Gemini 2.5 Flash via `google_generative_ai` |
| Backend | Firebase (Auth, Firestore, Storage, Analytics) |
| State | Provider |
| Auth | Firebase Auth + Google Sign-In |
| Maps | Google Maps SDK (vet finder) |
| PDF / QR | `pdf` + `qr_flutter` |
| Image | `camera` + `image_picker` + `image` |

---

## 🚀 Run it locally

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.7 or newer
- A Google account (for the Gemini key + your own Firebase project)
- Android Studio or VS Code with the Flutter plugin
- An Android device or emulator (the iOS build path needs an Apple Developer account; not covered here)

### 1. Clone

```bash
git clone https://github.com/HAIZ4D/pawfect_app.git
cd pawfect_app
flutter pub get
```

### 2. Get a Gemini API key

1. Go to <https://aistudio.google.com/app/apikey>.
2. Click **Create API key** and copy the value.
3. In the project root, copy the template and fill it in:

   ```bash
   cp .env.example .env
   ```

   Open `.env` and replace `YOUR_GEMINI_API_KEY_HERE` with your key. The `.env` file is gitignored — never commit it.

### 3. Set up your own Firebase project

The shared `firebase_options.dart` and `google-services.json` are NOT in the repo (they're gitignored for security). You'll create your own:

1. Go to <https://console.firebase.google.com> and click **Add project**. Name it anything (e.g., `pawfect-yourname`).
2. Once created, go to **Build → Authentication → Get started**. Enable **Email/Password** and (optionally) **Google** sign-in providers.
3. Go to **Build → Firestore Database → Create database**. Start in **production mode**, pick a region.
4. Install the FlutterFire CLI and connect your project:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   When prompted, select your new Firebase project. The CLI generates `lib/firebase_options.dart` and drops `android/app/google-services.json` for you.

### 4. Deploy Firestore rules

The repo includes `firestore.rules` (the security policy). Deploy it so the app can actually read/write data:

**Easy path (Console):** Open Firebase Console → **Firestore Database → Rules** tab. Copy the contents of `firestore.rules` from this repo, paste it in, click **Publish**.

**CLI path:**
```bash
npm install -g firebase-tools
firebase login
firebase use --add  # pick your project
firebase deploy --only firestore:rules
```

### 5. (Android only) Google Sign-In SHA-1 setup

If you want **Google sign-in** to work on Android, you need to register your debug-keystore SHA-1 with Firebase:

```bash
cd android
./gradlew signingReport     # macOS / Linux
gradlew.bat signingReport   # Windows
```

Find the `debug` variant's `SHA1:` line in the output. Copy it.

In Firebase Console → Project Settings (gear icon) → your Android app → **Add fingerprint** → paste the SHA-1 → save. Then re-download `google-services.json` to overwrite the one in `android/app/`.

Email/password sign-in works without this step. Skip it if you don't need Google sign-in locally.

### 6. (Android only) Maps API key for the vet finder

1. Enable **Maps SDK for Android** in [Google Cloud Console](https://console.cloud.google.com/google/maps-apis).
2. Generate an API key (or reuse the Gemini one if not restricted).
3. Open `android/local.properties` (auto-generated; gitignored) and add:

   ```properties
   MAPS_API_KEY=your_maps_api_key_here
   ```

The vet finder will return a blank map without this. Everything else still works.

### 7. Run

```bash
flutter run
```

Pick your Android device when prompted. First build takes a few minutes; subsequent hot-restarts are seconds.

---

## 📁 Project layout

```
lib/
├── core/
│   ├── constants/       # Colours, theme, app constants
│   ├── utils/           # Validators, image processing
│   └── widgets/         # LiquidAppBar, LiquidBackground, GlassCard
├── features/
│   ├── auth/            # Login, register, password reset, AuthGate
│   ├── onboarding/      # First-run intro
│   ├── dashboard/       # Home with carousel + weight chart + recent scans
│   ├── detector/        # Camera scan, symptom questionnaire, results
│   ├── pawbook/         # Pet profiles, medical history, QR share
│   ├── poisoning_detection/   # Vet finder, incident reports
│   └── profile/         # User profile + settings
├── models/              # Pet, Diagnosis, Vaccination, WeightRecord, etc.
├── repositories/        # Firestore data access (auth, pets, diagnoses, health)
├── services/            # Gemini, AI agent, PDF generation, tip service
├── firebase_options.dart   # (gitignored - generated by flutterfire configure)
└── main.dart            # App entry + AuthGate
```

---

## 🔒 Secrets and what's gitignored

This repo never commits:

| File | What's in it | Why gitignored |
|---|---|---|
| `.env` | `GEMINI_API_KEY=...` | Real API key |
| `lib/firebase_options.dart` | Firebase project SDK config | Auto-generated, project-specific |
| `android/app/google-services.json` | Android Firebase config | Project-specific |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config | Project-specific |
| `android/local.properties` | Maps API key, Flutter SDK path | Real key, machine-specific path |
| `.claude/`, `CLAUDE.md` | Local Claude Code settings | Personal dev tooling |

`.env.example` ships in the repo as a template with placeholder values. Copy it to `.env` to start.

If you fork or clone this, you're setting up your own Firebase project and your own Gemini key. None of mine ever get to your machine.

---

## ⚠️ Things to know

- **Web build limitations:** the live demo at `pawfect-ed0a1.web.app` works for everything except native camera capture (gallery upload still works) and the vet finder map (needs the Maps JS API set up). For a real demo, install on Android.
- **Firestore rules:** must be deployed before the app can read/write data. The error message in the app will guide you (`Permission denied. Update firestore.rules…`).
- **Medical disclaimer:** Pawfect is informational triage. It is **not** a replacement for a licensed veterinarian. Every diagnosis screen surfaces this.

---

## 📄 License

MIT.

---

<div align="center">

**Pawfect.** When they can't tell you, we listen.

</div>
