# JO Service - On-Demand Service Marketplace

<div align="center">

![JO Service Logo](assets/default_user.png)

**A comprehensive Flutter-based service marketplace connecting users with skilled service providers**

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.2+-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

## 🚀 Overview

JO Service is a modern, feature-rich mobile application that serves as a comprehensive marketplace for on-demand services. Built with Flutter, it provides a seamless experience for users to discover, book, and manage services while enabling service providers to showcase their skills and manage their business operations.

### ✨ Key Features

- **🔐 Multi-Role Authentication System**
  - User accounts with service booking capabilities
  - Service provider profiles with business management tools
  - Admin panel for platform oversight and management

- **📍 Location-Based Services**
  - Real-time GPS location tracking
  - Interactive maps with service provider locations
  - Address-based service discovery

- **💬 Real-Time Communication**
  - In-app chat system with WebSocket support
  - Push notifications for instant updates
  - Message history and conversation management

- **📱 Advanced Booking System**
  - Multi-step booking process
  - Real-time availability checking
  - Booking status tracking and management

- **⭐ Comprehensive Rating System**
  - Multi-criteria rating for service quality
  - Provider reputation management
  - User feedback and review system

- **🌍 Internationalization**
  - Arabic and English language support
  - RTL layout support for Arabic
  - Localized content and user experience

## 🏗️ Architecture

### System Design
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Layer    │    │  Provider Layer │    │   Admin Layer   │
│                 │    │                 │    │                 │
│ • Home Screen   │    │ • Dashboard     │    │ • User Mgmt     │
│ • Bookings      │    │ • Bookings      │    │ • Provider Mgmt  │
│ • Profile       │    │ • Messages      │    │ • Analytics     │
│ • Chat          │    │ • Services      │    │ • Reports       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Service Layer  │
                    │                 │
                    │ • API Service   │
                    │ • Auth Service  │
                    │ • Chat Service  │
                    │ • Location Svc  │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Data Layer     │
                    │                 │
                    │ • Models        │
                    │ • Local Storage │
                    │ • Backend API   │
                    └─────────────────┘
```

### Technology Stack

- **Frontend Framework**: Flutter 3.19+
- **Programming Language**: Dart 3.2+
- **State Management**: Provider Pattern
- **Backend Integration**: RESTful API + WebSocket
- **Local Storage**: SharedPreferences + SecureStorage
- **Maps & Location**: Google Maps + Geolocator
- **Real-time Communication**: WebSocket Channel
- **Notifications**: Local Notifications + WorkManager
- **Internationalization**: Flutter Localizations

## 📱 Screenshots

<details>
<summary>📱 User Experience Screens</summary>

- **Home Screen**: Service discovery with search and categories
- **Provider List**: Browse available service providers
- **Provider Detail**: View provider information and services
- **Booking Flow**: Multi-step service booking process
- **Chat Interface**: Real-time messaging with providers
- **User Profile**: Account management and preferences

</details>

<details>
<summary>🏢 Provider Experience Screens</summary>

- **Provider Dashboard**: Business overview and statistics
- **Booking Management**: Handle incoming service requests
- **Service Management**: Update offerings and availability
- **Message Center**: Communicate with clients
- **Profile Editor**: Manage business information

</details>

<details>
<summary>⚙️ Admin Experience Screens</summary>

- **Admin Dashboard**: Platform overview and analytics
- **User Management**: Monitor and manage user accounts
- **Provider Management**: Oversee service provider operations
- **Booking Analytics**: Track service metrics and trends

</details>

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.19.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio** / **VS Code** with Flutter extensions
- **iOS Development**: Xcode 14.0+ (for iOS builds)
- **Android Development**: Android Studio with Android SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/joservice_frontend.git
   cd joservice_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**

   **Android:**
   - Ensure Android SDK is properly configured
   - Add Google Maps API key in `android/app/src/main/AndroidManifest.xml`

   **iOS:**
   - Install CocoaPods: `sudo gem install cocoapods`
   - Run: `cd ios && pod install`
   - Add Google Maps API key in `ios/Runner/AppDelegate.swift`

4. **Configure environment**
   - Copy `.env.example` to `.env` (if available)
   - Update API endpoints in `lib/constants/api_config.dart`

5. **Run the application**
   ```bash
   flutter run
   ```

### Build Instructions

**Debug Build:**
```bash
flutter build apk --debug          # Android
flutter build ios --debug          # iOS
flutter build web --debug          # Web
```

**Release Build:**
```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS
flutter build web --release        # Web
```

## 🔧 Configuration

### Backend Configuration

The app is configured to use the production backend by default. See [BACKEND_CONFIG.md](BACKEND_CONFIG.md) for detailed configuration options.

**Current Production Backend:**
- **API Base URL**: `https://joservicebackend-production.up.railway.app/api`
- **WebSocket URL**: `wss://joservicebackend-production.up.railway.app`

### Environment Variables

Create a `.env` file in the root directory:
```env
# Backend Configuration
PRODUCTION_BASE_URL=https://your-backend.com
API_BASE_URL=https://your-backend.com/api
WS_BASE_URL=wss://your-backend.com

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# App Configuration
APP_NAME=JO Service
APP_VERSION=1.0.0
```

### API Configuration

Update `lib/constants/api_config.dart` to modify backend endpoints:

```dart
class ApiConfig {
  static const String productionBaseUrl = 'https://your-backend.com';
  static const String apiBaseUrl = '$productionBaseUrl/api';
  static const String wsBaseUrl = 'wss://your-backend.com';
}
```

## 📁 Project Structure

```
lib/
├── constants/           # App constants and configuration
│   ├── api_config.dart  # Backend API configuration
│   └── theme.dart       # App theme and styling
├── l10n/               # Internationalization files
│   ├── app_ar.arb      # Arabic translations
│   ├── app_en.arb      # English translations
│   └── app_localizations.dart
├── models/             # Data models
│   ├── user_model.dart
│   ├── provider_model.dart
│   ├── booking_model.dart
│   ├── chat_message.model.dart
│   ├── chat_conversation.dart
│   └── rating_model.dart
├── screens/            # UI screens
│   ├── user/          # User-specific screens
│   ├── provider/      # Provider-specific screens
│   ├── admin/         # Admin-specific screens
│   └── shared/        # Shared/common screens
├── services/          # Business logic and API services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── utils/             # Utility functions and helpers
├── widgets/           # Reusable UI components
└── main.dart          # App entry point
```

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 📦 Dependencies

### Core Dependencies
- **flutter_localizations**: Internationalization support
- **http**: HTTP client for API communication
- **provider**: State management solution
- **google_maps_flutter**: Google Maps integration
- **geolocator**: Location services
- **web_socket_channel**: Real-time communication
- **flutter_secure_storage**: Secure data storage
- **image_picker**: Image selection and capture
- **lottie**: Animation support
- **workmanager**: Background task management

### Development Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: Code quality and linting

## 🚀 Deployment

### Android Deployment

1. **Generate keystore**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure signing**
   - Create `android/key.properties`
   - Update `android/app/build.gradle`

3. **Build APK**
   ```bash
   flutter build apk --release
   ```

### iOS Deployment

1. **Configure signing**
   - Set up Apple Developer account
   - Configure certificates and provisioning profiles

2. **Build iOS app**
   ```bash
   flutter build ios --release
   ```

3. **Archive and upload**
   - Use Xcode to archive the app
   - Upload to App Store Connect

### Web Deployment

1. **Build web version**
   ```bash
   flutter build web --release
   ```

2. **Deploy to hosting service**
   - Upload `build/web/` contents to your web server
   - Configure server for SPA routing

## 🔒 Security Features

- **Secure Storage**: Sensitive data stored using flutter_secure_storage
- **API Authentication**: JWT-based authentication system
- **Input Validation**: Comprehensive input sanitization
- **Permission Management**: Granular permission handling
- **Data Encryption**: Secure transmission of sensitive information

## 🌍 Internationalization

The app supports multiple languages with RTL layout support:

- **English**: Default language with LTR layout
- **Arabic**: Full RTL support with localized content

### Adding New Languages

1. Create new ARB file in `lib/l10n/`
2. Add translations for all keys
3. Update `l10n.yaml` configuration
4. Regenerate localization files

## 📊 Performance Optimization

- **Lazy Loading**: Images and content loaded on demand
- **Caching**: Local storage for frequently accessed data
- **Background Processing**: Efficient background task management
- **Memory Management**: Optimized image handling and disposal
- **Network Optimization**: Efficient API calls and data transfer

## 🐛 Troubleshooting

### Common Issues

**Build Errors:**
```bash
flutter clean
flutter pub get
flutter run
```

**iOS Pod Issues:**
```bash
cd ios
pod deintegrate
pod install
```

**Android Gradle Issues:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Permission Issues:**
- Ensure all required permissions are declared in manifest files
- Check platform-specific permission handling

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines

- Follow Flutter coding standards
- Write comprehensive tests for new features
- Update documentation for API changes
- Ensure proper error handling
- Test on multiple platforms

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Contributors**: All developers who contributed to this project
- **Open Source Community**: For the excellent packages and tools

## 📞 Support

- **Documentation**: [Project Wiki](https://github.com/yourusername/joservice_frontend/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/joservice_frontend/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/joservice_frontend/discussions)
- **Email**: support@joservice.com

---

<div align="center">

**Built with ❤️ using Flutter**

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Powered%20by-Dart-blue.svg)](https://dart.dev/)

</div>