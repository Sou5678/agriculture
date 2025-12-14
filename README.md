# Plant Disease Early Detection App

A Flutter mobile application for early detection of plant diseases using AI-powered image analysis.

## Features

- **Camera Integration**: Capture plant images directly from the app
- **Image Gallery**: Select existing images from device gallery
- **AI Analysis**: Mock AI-powered disease detection with confidence scores
- **Disease Information**: Detailed information about detected diseases
- **Treatment Recommendations**: Personalized treatment and prevention tips
- **Detection History**: Save and review past detections
- **Search & Filter**: Search through detection history
- **Responsive Design**: Optimized for both iOS and Android

## Screenshots

The app includes:
- Home screen with feature overview
- Camera screen with focus guides
- Result screen with detailed analysis
- History screen with search functionality

## Technology Stack

- **Flutter**: Cross-platform mobile development
- **Material Design**: Modern UI components
- **Camera Plugin**: Camera functionality
- **Image Picker**: Gallery image selection
- **SharedPreferences**: Local data persistence
- **Provider**: State management
- **GoRouter**: Navigation between screens

## Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Generate model files:
```bash
flutter pub run build_runner build
```

3. Run on device/simulator:
```bash
flutter run
```

## Project Structure

```
lib/
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   ├── camera_screen.dart    # Image capture
│   ├── result_screen.dart    # Analysis results
│   └── history_screen.dart   # Detection history
├── models/
│   └── detection_result.dart # Data models
├── providers/
│   └── detection_provider.dart # State management
└── main.dart                 # App entry point
```

## Key Features Implementation

### Camera Integration
- Real-time camera preview
- Focus area guidance
- Image capture with quality optimization
- Gallery image selection

### AI Analysis Simulation
- Mock disease detection algorithm
- Confidence scoring system
- Symptom identification
- Treatment recommendations

### Data Persistence
- Local storage of detection history
- Image path preservation
- Search and filter capabilities

### User Experience
- Material Design interface
- Smooth navigation transitions
- Loading states and feedback
- Error handling and permissions

## Permissions Required

- Camera access for image capture
- Photo library access for image selection
- Storage access for saving images

## Future Enhancements

- Real AI model integration
- Cloud storage and sync
- User accounts and profiles
- Plant care reminders
- Community features
- Offline mode support

## Development Notes

This is a frontend-only implementation with mock AI analysis. To integrate with a real AI service:

1. Replace the mock analysis in `DetectionProvider.analyzeImage()`
2. Add API integration for image upload
3. Implement real-time disease detection
4. Add user authentication if needed

## License

MIT License - feel free to use this code for your own projects.






import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);