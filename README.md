# Fleet Monitoring App

A Flutter application for monitoring and tracking vehicles in real-time on a map.

## Features

- **Real-time Map View**: Display cars on a Google Maps interface with live updates every 5 seconds
- **Car Details**: View detailed information about each car including speed and status
- **Search Functionality**: Search for cars by name or ID
- **Filtering**: Filter cars by status (Moving/Parked)
- **Real-time Tracking**: Track individual cars with automatic camera focus
- **Offline Support**: Caches car data for offline use

## Setup Instructions

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Android Studio or VS Code with Flutter extensions
- Android/iOS emulator or physical device

### Getting Started

1. Clone the repository:
   ```
   git clone <repository-url>
   cd course
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Set up Google Maps API Key:
   - For Android: Add your API key to `android/app/src/main/AndroidManifest.xml`
   - For iOS: Add your API key to `ios/Runner/AppDelegate.swift`

4. Run the app:
   ```
   flutter run
   ```

## Architecture

This app follows a clean architecture approach with:

- **Models**: Data classes representing car information
- **Services**: API communication and data handling
- **Providers**: State management using Provider pattern
- **Screens**: UI components for different app screens
- **Widgets**: Reusable UI components

## Mock API

The app uses a simulated API for demonstration purposes. In a production environment, replace the mock service with actual API endpoints.

### API Endpoints Used

1. Primary API endpoint (currently simulated):
   ```
   https://682d05d64fae18894754a65a.mockapi.io/cars/
   ```

2. Expected JSON format:
   ```json
   [
     {
       "id": 1,
       "name": "Car A",
       "latitude": -1.94995,
       "longitude": 30.05885,
       "speed": 45,
       "status": "Moving"
     },
     {
       "id": 2,
       "name": "Car B",
       "latitude": -1.94955,
       "longitude": 30.05825,
       "speed": 0,
       "status": "Parked"
     }
   ]
   ```

3. Implementation details:
   - The app attempts to fetch data from the API every 5 seconds
   - If the API is unavailable, it falls back to simulated data
   - Car positions are animated smoothly between updates
   - Data is cached locally using SharedPreferences

## License

This project is licensed under the MIT License - see the LICENSE file for details.
