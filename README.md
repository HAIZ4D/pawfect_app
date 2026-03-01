<div align="center">

# 🐾 Pawfect

### AI-Powered Pet Healthcare Application

*Because your pet deserves the best care — powered by artificial intelligence.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## 📖 About Pawfect

**Pawfect** is a smart mobile application built with Flutter that helps pet owners monitor, manage, and protect their pets' health using the power of AI. From detecting illnesses through photos and symptoms to managing complete medical records — Pawfect is your all-in-one pet healthcare companion.

> Built for dog and cat owners who want fast, reliable, and intelligent healthcare guidance right from their phone.

---

## ✨ Features

### 🤖 AI Illness Detection
- Analyze pet symptoms using **Google Gemini 2.0 Flash AI**
- Upload or capture photos of visible symptoms
- Select from **50+ symptoms** across 8 categories
- Get instant diagnosis with urgency levels: `EMERGENCY` / `HIGH` / `MODERATE` / `LOW`
- Receive human-friendly explanations, first-aid instructions, and a professional vet report

### ☠️ Poisoning Detection & Assessment
- Identify toxic substances harmful to pets
- AI-powered poisoning risk assessment
- Report and track poisoning incidents
- Substance detail database with danger levels

### 📋 PawBook — Pet Profile Manager
- Create and manage profiles for multiple pets
- Store breed, age, weight history, and photos
- Full **medical history** tracking
- **Vaccination** records management
- Generate shareable **PDF medical reports**

### 📲 QR Medical Share
- Generate a QR code for your pet's medical profile
- Instantly share records with veterinarians
- Scan QR codes to view pet health profiles

### 🏥 Vet Finder
- Find nearby veterinary clinics using Google Maps
- Location-based search with real-time results

### 🔐 Secure Authentication
- Email & password login and registration
- Google Sign-In support
- Password reset via email

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **AI Engine** | Google Gemini 2.0 Flash |
| **Backend** | Firebase (Auth, Firestore, Storage, Analytics) |
| **State Management** | Provider |
| **Maps** | Google Maps API |
| **Camera** | Flutter Camera + Image Picker |
| **PDF** | `pdf` package |
| **QR Code** | `qr_flutter` |
| **Auth** | Firebase Auth + Google Sign-In |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # Theme, colors, text styles
│   ├── utils/           # Validators, formatters, image processor
│   └── widgets/         # Shared UI components
├── features/
│   ├── auth/            # Login, Register, Forgot Password
│   ├── dashboard/       # Home dashboard & pet care tips
│   ├── detector/        # AI illness detection & symptom checker
│   ├── pawbook/         # Pet profiles & medical records
│   └── poisoning_detection/ # Poisoning risk assessment
├── models/              # Data models (Pet, Diagnosis, etc.)
├── services/            # Gemini AI, PDF, Risk Assessment
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.7.0
- [Dart SDK](https://dart.dev/get-dart) >= 3.7.0
- Android Studio / VS Code
- A Firebase project
- A Google Gemini API key

### 1. Clone the repository

```bash
git clone https://github.com/your-username/pawfect-app.git
cd pawfect-app
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Open `.env` and fill in your API key:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

Get your Gemini API key at [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)

### 3. Set up Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Run FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. Download `google-services.json` and place it in `android/app/`

### 4. Set up Google Maps (Android)

Open `android/local.properties` and add:

```properties
MAPS_API_KEY=your_google_maps_api_key_here
```

### 5. Install dependencies and run

```bash
flutter pub get
flutter run
```

---

## 🔒 Security

This project follows secure secrets management practices:

- All API keys are stored in **`.env`** and **`local.properties`** — both gitignored
- Firebase config files (`firebase_options.dart`, `google-services.json`) are gitignored
- No credentials are ever hardcoded in source code
- See `.env.example` for required environment variables

---

## 📸 Screenshots

> *Coming soon*

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

Made with ❤️ for pets everywhere 🐶🐱

**Pawfect** — *Smart Care for Happy Paws*

</div>
