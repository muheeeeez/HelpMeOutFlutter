# HelpMeOut - Flutter Video Sharing Platform

HelpMeOut is a mobile application built with Flutter that allows users to share videos to get help from specialists in their field. This application enables users to upload videos, manage their videos, and share them with others to receive help and guidance.

## Features

### User Authentication

- User registration with email verification
- Secure login system
- Password reset functionality
- Firebase Authentication integration

### Video Management

- Upload videos from your device
- Give custom titles to your videos
- View detailed information about each video
- Copy and share video links
- Delete videos when no longer needed

### Video Playback

- Built-in video player for smooth playback
- Progress bar for video navigation
- Play/pause controls

### Additional Features

- Automatic video transcription via AssemblyAI integration
- Short URL generation for easy sharing
- Clean, modern UI with responsive design
- User profile management

## Technologies Used

- Flutter SDK
- Firebase Authentication
- Cloud Firestore (database)
- Firebase Storage (video storage)
- AssemblyAI SDK (transcription)
- Video Player package
- Image Picker for file selection
- HTTP package for API requests
- Path Provider and Permission Handler for file system operations

## Project Setup

### Prerequisites

- Flutter SDK (latest version)
- Firebase account
- AssemblyAI API key
- Android Studio/VS Code with Flutter/Dart plugins

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/helpmeout_flutter.git
cd helpmeout_flutter
```

2. Install dependencies:

```bash
flutter pub get
```

3. Set up Firebase:

   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the `google-services.json` file to the Android app directory
   - Download and add the `GoogleService-Info.plist` file to the iOS app directory
   - Enable Authentication, Firestore, and Storage in Firebase console

4. Configure Firebase App Check in Firebase Console:

   - Enable App Check in Firebase Console
   - Configure with Play Integrity for Android and Device Check for iOS

5. Set up AssemblyAI API:

   - Get an API key from AssemblyAI
   - Add it to the designated area in the code

6. Run the app:

```bash
flutter run
```

## Project Structure

- `/lib`: Main source code directory
  - `/Authentication`: User authentication files
  - `/Widgets`: Reusable UI components
  - `/legal`: Legal documentation pages
  - `/utils`: Utility functions and helpers
  - `main.dart`: Application entry point
  - `welcome.dart`: Main dashboard screen
  - `upload_video_screen.dart`: Video upload functionality
  - `video-details-page.dart`: Video playback and details

## Best Practices Implemented

- State management with StatefulWidgets
- Form validation
- Error handling
- Clean UI with consistent styling
- Secure authentication
- Responsive design
- Proper file organization
- Code commenting
- Firebase security rules

## Optimization Techniques

- Lazy loading of resources
- Progressive image loading
- Caching of downloaded videos
- Efficient Firestore queries
- Memory management for video playback
- Responsive UI for different screen sizes
- Error boundaries and graceful degradation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- AssemblyAI for transcription services
