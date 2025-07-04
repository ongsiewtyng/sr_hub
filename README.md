# Study Resource Hub

A comprehensive mobile application built with Flutter for managing library resources, seat reservations, and digital content access.

## Features

### 1. Library Seat Reservation
- Interactive library map with real-time seat availability
- Seat and study room booking system
- Reservation management
- Indoor navigation to reserved seats

### 2. Bookstore Integration
- Digital and physical book catalog
- eReader functionality
- Wishlist management
- Search and filtering capabilities

### 3. Resource Management
- Library catalog search
- Digital resource access
- Advanced filtering and categorization

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── features/
│   ├── library_reservation/
│   ├── bookstore/
│   └── resource_management/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/study-resource-hub.git
```

2. Navigate to the project directory:
```bash
cd study-resource-hub
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Dependencies

Key packages used in this project:
- `flutter_bloc` for state management
- `get_it` for dependency injection
- `dio` for network requests
- `shared_preferences` for local storage
- `flutter_map` for interactive maps
- `pdf_render` for PDF handling
- `epub_view` for eReader functionality

## Architecture

The project follows Clean Architecture principles with the following layers:
- Presentation Layer (UI)
- Domain Layer (Business Logic)
- Data Layer (Data Sources)

## State Management

The app uses BLoC pattern for state management, with the following key BLoCs:
- LibraryMapBloc
- ReservationBloc
- BookstoreBloc
- ResourceSearchBloc

## API Integration

The app integrates with the following APIs:
- Google Books API for book data
- Open Library API for additional book metadata
- Custom backend API for library seat management

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
