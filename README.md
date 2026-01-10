# 📅 sureplan

A modern, streamlined event planning and coordination application built with **Flutter** and **Supabase**. Sureplan makes it easy to create events, invite friends, and manage your social calendar all in one place.

---

## ✨ Features

- **🚀 Event Management**: Create, edit, and manage personal or public events with ease. Add descriptions, locations, and custom background images.
- **✉️ Seamless Invitations**: Invite friends to your events and keep track of RSVPs (Going, Maybe, Not Going) in real-time.
- **🔍 Event Discovery**: Search for public events and join the local community happenings.
- **🔔 Real-time Notifications**: Stay updated with instant push notifications for new invites and event updates using Firebase Cloud Messaging (FCM).
- **💡 Feature Requests**: A dedicated "Ideas" section where users can suggest new features and upvote their favorites, helping shape the future of the app.
- **🔐 Secure Authentication**: Multi-provider login support including **Apple Sign-In** and **Google Sign-In**, powered by Supabase Auth.
- **🎨 Premium UI/UX**: A clean, modern interface featuring custom illustrations and smooth animations for a premium user experience.

---

## 🛠️ Technical Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart)
- **Backend/Database**: [Supabase](https://supabase.com/) (PostgreSQL + Realtime)
- **Authentication**: Supabase Auth (Apple & Google Sign-In)
- **Push Notifications**: Firebase Cloud Messaging (FCM) & `flutter_local_notifications`
- **State Management**: Built-in Flutter state management (StatefulWidgets / Listeners)
- **Local Storage**: `flutter_secure_storage` / `shared_preferences` (where applicable)

---

## 📁 Project Structure

```text
lib/
├── auth/               # Authentication logic and pages
├── bottom_navigation/  # Main feature screens (Home, Invites, Search, Ideas)
├── events/             # Event creation, editing, and details
├── models/             # Data models (Event, Invite, UserProfile)
├── services/           # Business logic and database interactions
├── settings/           # User profile and app settings
├── welcome/            # Onboarding and landing pages
└── main.dart           # App entry point and initialization
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode
- A Supabase project
- A Firebase project (for notifications)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/sureplan.git
   cd sureplan
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Environment Setup**:
   Create a `.env` file in the root directory and add your Supabase and Firebase credentials:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

We love contributions! If you have a suggestion or found a bug, feel free to open an issue or submit a pull request. You can also use the in-app **Ideas** feature to suggest and upvote new functionalities.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
