# SmartLister for MAD/WPF1
SmartLister is a comprehensive shopping list application developed with Flutter, designed to streamline the process of managing and sharing shopping lists. This application allows users to create, manage, and share their shopping lists directly from their mobile devices.

## Getting Started
To get started with SmartLister, you need to set up your development environment and ensure that all necessary tools and dependencies are correctly installed.

## Prerequisites
Flutter SDK: Install the latest version of Flutter. You can download it from Flutter's official website.
Android Studio or Visual Studio Code: You will need an IDE to write your code. Android Studio or VS Code with the Flutter plugin installed is recommended.
Android Emulator or Physical Device: The application is best tested on an Android emulator (API level 34 or higher) or a physical device with at least Android OS version 14.

## Installation
Clone the Repository:

git clone https://github.com/ahmeteminemre/smartlister.git
cd smartlister
Install Dependencies:

flutter pub get

Run the Application: flutter run

Make sure your emulator or physical device is running and connected before executing the command above.

## Important Notes
Internet Connection: SmartLister requires a stable internet connection as it interacts with Firebase for authentication, database storage, and other cloud services.
Firebase Setup: Ensure you have set up Firebase and added your configuration files (google-services.json for Android) to the project.

## Features
Create, edit, and delete shopping lists.
Share lists across devices using Firebase Dynamic Links.
Manage user authentication with Firebase Auth.
Store and retrieve data from Firebase Firestore.

### Documentation
For a comprehensive guide and API reference, visit the Flutter online documentation.

