# EV Charging Station Finder 

A modern, user-friendly mobile application that helps electric vehicle owners find and manage charging stations. Built with Flutter and Firebase, this app provides real-time information about charging station availability and allows users to manage their favorite stations.

![App Preview](assets/images/app_preview.png)

##  Key Features

### For Users
- **Find Charging Stations** 
  - View stations on an interactive map
  - See real-time availability status
  - Filter by charging speed and connector type
  - Get directions to stations

- **Station Management** 
  - Save favorite charging stations
  - Quick access to frequently used stations
  - View detailed station information
  - Rate and review stations

- **Smart Features** 
  - QR code scanning for quick station access
  - Real-time availability updates
  - Price comparison between stations
  - Charging history tracking

- **User Profile** 
  - Personalized user dashboard
  - Vehicle information management
  - Charging preferences
  - Usage statistics

### Technical Features
- Material 3 Design
- Dark/Light theme support
- Offline data persistence
- Real-time updates
- Location-based services
- Secure authentication

##  Getting Started

### For Users
1. Download the app from:
   - [Google Play Store](link-to-play-store)
   - [Apple App Store](link-to-app-store)

2. Create an account using:
   - Email and password
   - Google account
   - Apple ID (iOS only)

3. Allow location permissions for the best experience

### For Developers

#### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- [Firebase Account](https://firebase.google.com/)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

#### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/tarikmsr/ev_charging_app.git
   cd ev_charging_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Add Android & iOS apps in Firebase console
   - Download and add configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
   - Enable Authentication and Firestore in Firebase console

4. **Configure Environment**
   - Copy `.env.example` to `.env`
   - Add your API keys and configuration

5. **Run the App**
   ```bash
   flutter run
   ```

##  Project Structure
```
lib/
├── core/                   # Core functionality
│   ├── models/            # Data models
│   ├── services/          # Service classes
│   ├── routes/            # App routes
│   └── widgets/           # Shared widgets
├── features/              # Feature modules
│   ├── authentication/    # Auth feature
│   ├── charging_stations/ # Stations feature
│   ├── dashboard/         # Dashboard feature
│   └── profile/          # Profile feature
└── main.dart             # App entry point
```

##  Security Features
- Secure user authentication
- Protected API endpoints
- Firestore security rules
- Data encryption
- Safe credential storage

##  Supported Platforms
- Android 5.0 (API 21) or higher
- iOS 12 or higher

##  Built With
- [Flutter](https://flutter.dev/) - UI framework
- [Firebase](https://firebase.google.com/) - Backend services
- [Google Maps](https://developers.google.com/maps) - Maps integration
- [Provider](https://pub.dev/packages/provider) - State management
- [Geolocator](https://pub.dev/packages/geolocator) - Location services

##  Database Structure

### Users Collection
```json
{
  "users": {
    "<userId>": {
      "email": "string",
      "firstName": "string",
      "lastName": "string",
      "favoriteStations": ["stationId1", "stationId2"],
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

### Stations Collection
```json
{
  "stations": {
    "<stationId>": {
      "name": "string",
      "latitude": "number",
      "longitude": "number",
      "address": "string",
      "available": "boolean",
      "power": "number",
      "pricePerKwh": "number",
      "connectorTypes": ["Type2", "CCS"],
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

##  Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

##  License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

##  Support
- Email: support@evchargingapp.com
- Website: www.evchargingapp.com
- Twitter: [@evchargingapp](https://twitter.com/evchargingapp)

##  Acknowledgments
- [Flutter Team](https://flutter.dev/team)
- [Firebase](https://firebase.google.com)
- [OpenStreetMap Contributors](https://www.openstreetmap.org/about)
- All our amazing contributors!