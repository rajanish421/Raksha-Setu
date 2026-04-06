<div align="center">

# 🛡️ Raksha Setu

### *Secure HQ-Controlled Communication for India's Defence Personnel*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](#)

> **Raksha Setu** (रक्षा सेतु — "Defence Bridge") is a Flutter-based mobile application providing encrypted, HQ-authorised communication for Indian military personnel (soldiers & veterans) and their families.

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [App Flow Diagram](#-app-flow-diagram)
- [Project Structure](#-project-structure)
- [User Roles](#-user-roles)
- [Screens & Navigation](#-screens--navigation)
- [Security Model](#-security-model)
- [Getting Started](#-getting-started)
- [Environment Setup](#-environment-setup)
- [Firebase Setup](#-firebase-setup)
- [Dependencies](#-dependencies)
- [Contributing](#-contributing)

---

## 🔍 Overview

Raksha Setu is a **closed-network communication platform** designed exclusively for Indian defence personnel and their approved family members. All users require **HQ approval** before they can communicate — ensuring no unauthorised access.

| 👮 Soldier / Veteran | 👨‍👩‍👧 Family Member |
|---|---|
| Manages family groups | Connects via soldier's Service Number |
| Initiates voice/video calls | Receives end-to-end encrypted messages |
| Receives real-time alerts | Views call history |
| Approves/rejects family members | Profile & document access |

---

## ✨ Key Features

### 🔐 Authentication & Onboarding
- **Role-based registration** – Soldier, Veteran, or Family member
- **Firebase OTP verification** via phone number
- **HQ Approval flow** – accounts start as `pending` until approved by admin
- **Selfie + document upload** for identity verification (via Cloudinary)
- **Biometric / local auth** support

### 💬 Encrypted Chat
- **End-to-end encryption** using AES-256-CBC (per-group symmetric key stored in Firestore)
- **Text messages** with real-time Firestore sync
- **Image & file sharing** (photos, PDFs, documents)
- **Voice messages** with audio waveform visualisation
- **In-chat voice & video call** initiation

### 📞 Voice & Video Calls
- **Group voice calls** powered by ZegoUIKit
- **Video calls** with Zego prebuilt UI
- **Incoming call notifications** (local + FCM push)
- **Call history** screen

### 🚨 Alert System
- Real-time alerts broadcast to soldier's groups
- **Unread badge count** with live Firestore stream
- Filter alerts by group, type, or status
- Alert detail view with full context

### 👥 Family Management (Soldier)
- Link family members via Service Number
- **Approve or reject** family join requests
- Create & manage **family groups**
- View live online/offline status of members

### 👤 Profile
- View full profile (rank, unit, role, phone)
- Open uploaded documents (PDF viewer / image viewer)
- Secure logout with active session cleanup

### 🔔 Notifications
- FCM push notifications for calls & alerts
- Local notifications for incoming call screen overlay
- Screenshot protection toggle

---

## 🏗️ Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter (Dart)                      │
│              Provider – State Management                │
├────────────────────┬────────────────────────────────────┤
│   Firebase Suite   │          Third-party SDKs          │
│  ─────────────── │  ────────────────────────────────  │
│  • Firebase Auth  │  • ZegoUIKit  (Voice/Video Calls) │
│  • Cloud Firestore│  • Cloudinary (File Upload)        │
│  • Firebase FCM   │  • encrypt    (AES-256 Chat)       │
│                    │  • audio_waveforms (Voice UI)      │
└────────────────────┴────────────────────────────────────┘
```

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3.x (Material Design) |
| **Language** | Dart 3.x |
| **State Management** | Provider |
| **Backend / Database** | Firebase Firestore |
| **Authentication** | Firebase Auth (Email + OTP Phone) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **File Storage** | Cloudinary |
| **Voice & Video Calls** | ZegoCloud UIKit |
| **Chat Encryption** | AES-256-CBC (`encrypt` package) |
| **Local Auth** | `local_auth` (biometrics/PIN) |
| **PDF Viewer** | `syncfusion_flutter_pdfviewer` / `flutter_pdfview` |
| **Audio** | `record`, `just_audio`, `flutter_sound`, `audio_waveforms` |

---

## 🗺️ App Flow Diagram

```
                    ┌──────────────┐
                    │  Splash Screen│
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │Welcome Screen│
                    └──┬───────┬───┘
                       │       │
               ┌───────▼─┐  ┌──▼──────┐
               │  Login  │  │Register │
               └───┬─────┘  └──┬──────┘
                   │            │
           ┌───────▼─┐     ┌────▼────────────┐
           │OTP Verify│     │Pending Approval │
           └───┬──────┘     └─────────────────┘
               │
        ┌──────▼──────────────────────────────┐
        │            Home Screen               │
        │  (Role-based tab navigation)         │
        └──┬──────────┬───────────┬────────────┘
           │          │           │
   ┌───────▼──┐ ┌─────▼────┐ ┌───▼──────┐
   │ Soldier  │ │  Groups  │ │  Profile │
   │Dashboard │ │  & Chat  │ │  Screen  │
   └──┬───────┘ └─────┬────┘ └──────────┘
      │               │
 ┌────▼───┐     ┌─────▼─────────────────┐
 │ Alerts │     │  Chat Screen           │
 │ Screen │     │  ├── Text Messages     │
 └────────┘     │  ├── Voice Messages    │
                │  ├── Media Sharing     │
                │  └── Voice/Video Call  │
                └───────────────────────┘
```

---

## 📁 Project Structure

```
raksha_setu/
├── lib/
│   ├── main.dart                    # App entry point, Firebase init
│   ├── firebase_options.dart        # Generated Firebase config
│   ├── log_service.dart             # Logging utility
│   │
│   ├── constants/
│   │   ├── app_colors.dart          # Defence-themed colour palette
│   │   ├── app_theme.dart           # Material ThemeData
│   │   └── zego_config.dart         # ZegoCloud credentials
│   │
│   ├── models/
│   │   ├── user_model.dart          # UserModel (soldier/family/veteran)
│   │   ├── message_model.dart       # Chat message model
│   │   ├── alert_model.dart         # Alert model
│   │   ├── call_model.dart          # Call session model
│   │   ├── call_log_model.dart      # Call history log
│   │   └── family_group_model.dart  # Group model
│   │
│   ├── providers/
│   │   └── user_provider.dart       # Global user state (ChangeNotifier)
│   │
│   ├── on_boarding/
│   │   ├── splash_screen.dart       # Initial loading screen
│   │   └── welcome_screen.dart      # Login / Register choice
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/             # Login, Register, OTP, PendingApproval
│   │   │   └── services/            # AuthService, OtpService, FirebaseOtpService
│   │   │
│   │   ├── home/
│   │   │   └── screens/home_screen.dart   # Bottom-tab shell
│   │   │
│   │   ├── soldier_homescreen/
│   │   │   ├── screens/             # SoldierHome, Alerts, AlertDetails, GroupDetails, FamilyMemberDetails
│   │   │   ├── services/            # AlertService, FamilyGroupService, FamilyManagementService, UserService
│   │   │   └── widgets/             # FamilyMemberCard, FamilyGroupTile, CreateGroupDialog
│   │   │
│   │   ├── family_home/
│   │   │   └── family_home_screen.dart    # Family dashboard (WIP)
│   │   │
│   │   ├── chat/
│   │   │   ├── screens/             # ChatScreen, GroupsListScreen, ViewerScreen
│   │   │   ├── services/            # MessageService, EncryptionService, ChatMediaService, VoiceService
│   │   │   └── widgets/             # VoicePlayerWidget
│   │   │
│   │   ├── call/
│   │   │   ├── screens/             # CallScreen, VoiceCallScreen, VideoCallScreen, CallingScreen, CallHistory
│   │   │   ├── services/            # CallService, CallNotificationService, LocalNotificationService, IncomingCallListener
│   │   │   └── widgets/             # IncomingCallSheet
│   │   │
│   │   ├── profile/
│   │   │   └── screens/             # ProfileScreen, ImageViewerScreen, PDFViewerScreen
│   │   │
│   │   ├── status/
│   │   │   └── active_user_service.dart   # Online/offline presence tracking
│   │   │
│   │   └── upload/
│   │       ├── cloudinary_upload_service.dart
│   │       ├── firebase_upload_service.dart
│   │       └── upload_service.dart        # Abstract upload interface
│   │
│   ├── custom_widgets/
│   │   └── primary_button.dart      # Reusable primary / outlined button
│   │
│   └── utils/
│       ├── app_router.dart          # Named route generator
│       └── route_names.dart         # Route name constants
│
├── assets/
│   └── ringtones/ringtone1.mp3      # Incoming call ringtone
├── android/                         # Android platform config
├── ios/                             # iOS platform config
├── pubspec.yaml                     # Dependencies & assets
└── .env                             # API keys (not committed)
```

---

## 👥 User Roles

| Role | Description | Registration |
|---|---|---|
| `soldier` | Active military personnel | Service Number + Rank + Unit |
| `veteran` | Retired military personnel | Service Number |
| `family` | Family member of a soldier | Reference Service Number + Relationship |
| `admin` | Unit/HQ administrator | Assigned by super admin |
| `superAdmin` | Platform super administrator | Internal |

**Status lifecycle:**
```
  Register → pending ──► approved (by HQ) ──► active
                     └──► rejected
                     └──► suspended
```

---

## 📱 Screens & Navigation

| Screen | Route | Description |
|---|---|---|
| Splash | `/splash` | Auto-redirects based on auth state |
| Welcome | `/welcome` | Login / Register entry point |
| Login | `/login` | Service ID or phone + password + OTP |
| Register | `/register` | Role-based registration form with uploads |
| OTP Verification | `/otp-verification` | Firebase phone OTP screen |
| Pending Approval | `/pending-approval` | Waiting for HQ approval |
| Home | `/home` | Bottom navigation shell |
| Soldier Dashboard | (tab) | Family members, groups, alert badge |
| Alerts | `/alerts` | Filterable real-time alert list |
| Group Chat | (push) | Encrypted group messaging |
| Voice Call | (push) | ZegoUIKit voice call |
| Video Call | (push) | ZegoUIKit video call |
| Profile | (tab) | User profile, documents, logout |

---

## 🔒 Security Model

```
┌──────────────────────────────────────────────────┐
│               Security Layers                    │
│                                                  │
│  1. HQ Approval Gate                             │
│     └─ All accounts start as "pending"           │
│        Must be approved before any access        │
│                                                  │
│  2. OTP / Phone Verification                     │
│     └─ Firebase phone auth on every new device   │
│                                                  │
│  3. AES-256-CBC Chat Encryption                  │
│     └─ Per-group symmetric key in Firestore      │
│        IV prepended to every encrypted payload   │
│                                                  │
│  4. Closed Groups                                │
│     └─ Only HQ-authorised members join groups    │
│                                                  │
│  5. Screenshot Protection                        │
│     └─ no_screenshot package (toggle in code)    │
│                                                  │
│  6. Local Auth (Biometrics/PIN)                  │
│     └─ local_auth for additional screen lock     │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.x`
- [Dart SDK](https://dart.dev/get-dart) `^3.9.2`
- Android Studio / Xcode (for device/emulator)
- A Firebase project (see [Firebase Setup](#-firebase-setup))
- A [ZegoCloud](https://www.zegocloud.com/) account (for calls)
- A [Cloudinary](https://cloudinary.com/) account (for file uploads)

### Clone & Install

```bash
# Clone the repository
git clone https://github.com/rajanish421/Raksha-Setu.git
cd Raksha-Setu

# Install Flutter dependencies
flutter pub get
```

### Run the App

```bash
# Debug mode
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ios --release
```

---

## ⚙️ Environment Setup

Create a `.env` file in the **project root** (alongside `pubspec.yaml`):

```env
# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# ZegoCloud
ZEGO_APP_ID=your_zego_app_id
ZEGO_APP_SIGN=your_zego_app_sign
```

> ⚠️ **Never commit `.env` to version control.** It is listed in `.gitignore`.

---

## 🔥 Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an **Android** app (package: `com.example.raksha_setu`) and download `google-services.json` → place in `android/app/`
3. Add an **iOS** app and download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Enable the following Firebase services:
   - **Authentication** → Email/Password + Phone
   - **Cloud Firestore** → create database in production mode
   - **Cloud Messaging** (FCM)
5. Run FlutterFire CLI to regenerate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | All registered user profiles |
| `groups` | Chat groups (with `encKey` for encryption) |
| `messages/{groupId}/msgs` | Encrypted messages per group |
| `alerts` | Broadcast alerts for soldiers |
| `active_calls` | Live call session tracking |

---

## 📦 Dependencies

### Core
| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.2.1 | Firebase initialisation |
| `firebase_auth` | ^6.1.2 | Authentication |
| `cloud_firestore` | ^6.1.0 | Real-time database |
| `firebase_messaging` | ^16.0.4 | Push notifications |
| `provider` | ^6.1.5 | State management |

### Communication
| Package | Version | Purpose |
|---|---|---|
| `zego_uikit_prebuilt_call` | ^4.21.1 | Voice & video calls |
| `zego_uikit_signaling_plugin` | ^2.8.19 | Call signalling |
| `record` | ^6.1.2 | Voice message recording |
| `just_audio` | ^0.10.5 | Audio playback |
| `audio_waveforms` | ^2.0.0 | Voice message waveform UI |

### Security & Files
| Package | Version | Purpose |
|---|---|---|
| `encrypt` | ^5.0.3 | AES-256-CBC encryption |
| `local_auth` | ^3.0.0 | Biometric authentication |
| `no_screenshot` | ^0.3.1 | Screenshot protection |
| `image_picker` | ^1.2.1 | Camera / gallery access |
| `file_picker` | ^10.3.7 | Document picker |
| `dio` | ^5.9.0 | HTTP file downloads |

### UI & Utilities
| Package | Version | Purpose |
|---|---|---|
| `lottie` | ^3.3.2 | Lottie animations |
| `photo_view` | ^0.15.0 | Image zoom viewer |
| `syncfusion_flutter_pdfviewer` | ^31.2.15 | PDF viewing |
| `flutter_local_notifications` | ^19.5.0 | Local notifications |
| `awesome_notifications` | ^0.10.1 | Rich notifications |
| `flutter_dotenv` | ^6.0.0 | `.env` file loading |
| `uuid` | ^4.5.2 | UUID generation |

---

## 🎨 Design

The app uses a **defence-themed dark colour palette**:

| Name | Hex | Usage |
|---|---|---|
| Primary | `#0B3D2E` | App bars, buttons |
| Primary Light | `#145C41` | Highlighted surfaces |
| Accent / Gold | `#F9B233` | Badges, icons, CTAs |
| Background | `#050B0A` | Screen background |
| Surface | `#101818` | Cards, inputs |
| Text Primary | `#FFFFFF` | Main text |
| Text Secondary | `#B0B9B8` | Subtitles, hints |
| Danger | `#EF476F` | Errors, alerts |
| Success | `#06D6A0` | Confirmations |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

> ⚠️ This is a **private defence communication project**. Do not share credentials, API keys, or user data publicly.

---

## 📄 License

This project is **proprietary and private**. Unauthorised distribution or use is prohibited.

---

<div align="center">

**Raksha Setu** — *Bridging the gap between duty and family, securely.*

🇮🇳 *Jai Hind* 🇮🇳

</div>
