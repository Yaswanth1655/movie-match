# Movie Match - Platform Commons Flutter Assignment

A movie discovery app where multiple users can save movies they want to watch, with the app showing matches (movies saved by 2+ users) to help groups decide what to watch together.

## Features

### Core Functionality
- **Users Management**: Browse and add users from Reqres API
- **Movie Discovery**: Browse trending movies from TMDB API
- **Save Movies**: Users can save movies to their personal list
- **Matches**: See movies that multiple users have saved
- **Offline-First**: Full offline support with automatic background sync

### Technical Implementation

#### Architecture
- **Clean Architecture**: Organized into presentation, domain, and data layers
- **State Management**: Bloc/Cubit pattern for reactive state management
- **Dependency Injection**: get_it for managing dependencies
- **Local Database**: Drift (SQLite) for offline-first data persistence
- **Network**: Dio with automatic retry logic for API calls
- **Background Sync**: WorkManager for syncing offline changes when online

#### Key Features

##### 1. Offline-First Architecture
- All data is stored locally in SQLite database
- App works fully offline after initial data fetch
- Changes made offline are queued and synced when connection returns
- No data loss, no duplicates

##### 2. Retry Mechanism
- **API Calls**: Automatic retry with exponential backoff (3 attempts)
- **Database Queries**: Retry wrapper for transient database failures
- **Network Connectivity**: Continuous monitoring with automatic sync triggers

##### 3. Real-time Updates
- Streams from local database for instant UI updates
- Save count badges animate when numbers change
- Matches page updates automatically when users save/unsave movies

##### 4. Enhanced UI/UX
- **Urbanist Font**: Google Font used throughout the app
- **Shimmer Loaders**: Skeleton screens instead of spinners
- **Hero Animations**: Smooth transitions between pages
- **Fade-in Effects**: Images and list items fade in gracefully
- **Badge Animations**: Save count chips animate on changes
- **Top Match Highlighting**: Best match highlighted with gold background

##### 5. Error Handling
- Comprehensive try-catch blocks prevent crashes
- Graceful degradation when API fails
- Fallback to OMDB API if TMDB is unavailable
- User-friendly error messages

## Project Structure

```
lib/
├── app/
│   ├── di/
│   │   └── injection.dart              # Dependency injection setup
│   ├── router/
│   │   ├── app_router.dart            # Navigation routes
│   │   └── route_args.dart            # Route arguments
│   └── app.dart                        # Main app widget
├── core/
│   ├── config/
│   │   ├── env/
│   │   │   └── app_env.dart           # Environment variables
│   │   └── theme/
│   │       ├── theme.dart             # App theme with Urbanist font
│   │       └── app_palette.dart       # Color palette
│   ├── database/
│   │   ├── app_database.dart          # Database tables and queries
│   │   ├── app_database.g.dart        # Generated code
│   │   └── database_retry_wrapper.dart # DB retry logic
│   └── sync/
│       ├── sync_worker.dart           # WorkManager task
│       └── sync_initializer.dart      # Sync setup
├── features/
│   ├── users/
│   │   ├── data/
│   │   │   ├── users_repository.dart
│   │   │   └── reqres_user_remote_source.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── users_cubit.dart
│   │       │   ├── add_user_cubit.dart
│   │       │   └── saved_movies_cubit.dart
│   │       └── pages/
│   │           ├── users_page.dart
│   │           ├── add_user_page.dart
│   │           └── user_saved_movies_page.dart
│   ├── movies/
│   │   ├── data/
│   │   │   ├── movies_repository.dart
│   │   │   └── movie_remote_source.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── movies_cubit.dart
│   │       │   └── movie_detail_cubit.dart
│   │       └── pages/
│   │           ├── movies_page.dart
│   │           └── movie_detail_page.dart
│   └── matches/
│       └── presentation/
│           ├── cubit/
│           │   └── matches_cubit.dart
│           └── pages/
│               └── matches_page.dart
├── common/
│   └── bloc/
│       ├── connectivity_cubit/
│       │   └── connectivity_cubit.dart # Network monitoring
│       ├── sync_cubit/
│       │   └── sync_cubit.dart        # Sync state management
│       └── active_user_cubit/
│           └── active_user_cubit.dart  # Current user state
└── main.dart
```

## Database Schema

### Users Table
```dart
- localId: INTEGER (Primary Key, Auto-increment)
- serverId: INTEGER (nullable) // ID from Reqres API
- firstName: TEXT
- lastName: TEXT
- avatar: TEXT
- movieTaste: TEXT // User's movie preferences
- pendingSync: BOOLEAN // true if needs sync to server
- createdAt: DATETIME
- updatedAt: DATETIME
```

### Movies Table
```dart
- movieId: INTEGER (Primary Key) // TMDB movie ID
- title: TEXT
- overview: TEXT
- posterPath: TEXT
- releaseDate: TEXT
- source: TEXT // 'tmdb' or 'omdb'
- rawPayload: TEXT // JSON payload
- createdAt: DATETIME
- updatedAt: DATETIME
```

### SavedMovies Table (Junction Table)
```dart
- id: INTEGER (Primary Key, Auto-increment)
- userLocalId: INTEGER (Foreign Key → Users)
- movieId: INTEGER (Foreign Key → Movies)
- createdAt: DATETIME
- UNIQUE(userLocalId, movieId) // Prevent duplicates
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.3.4)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- API Keys (see below)

### API Keys Setup

1. **TMDB API Key**
   - Sign up at [themoviedb.org](https://www.themoviedb.org/)
   - Go to Settings → API → Request a developer key
   - Copy your API key

2. **Reqres API** (Optional)
   - Reqres is a free API that doesn't require registration
   - API key header is sent but not validated

3. **Update .env file**
   ```bash
   OMDB_API_KEY=7f6c47ae
   TMDB_API_KEY=your_tmdb_api_key_here
   REQRES_API_KEY=optional_reqres_key
   ```

### Installation

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd basic_app-main
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Generate Drift database code
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Update API keys in `.env` file

5. Run the app
   ```bash
   flutter run
   ```

## Key Dependencies

```yaml
dependencies:
  # State Management
  flutter_bloc: ^latest
  bloc: ^latest
  hydrated_bloc: ^9.1.0
  
  # Dependency Injection
  get_it: ^latest
  
  # Networking
  dio: ^latest
  connectivity_plus: ^latest
  
  # Local Database
  drift: 2.19.1+1
  sqlite3_flutter_libs: ^latest
  path_provider: ^latest
  
  # Background Tasks
  workmanager: ^latest
  
  # UI/UX
  cached_network_image: ^latest
  shimmer: ^latest
  google_fonts: ^latest # For Urbanist font
  
  # Utilities
  logger: ^latest
  flutter_dotenv: ^latest
  equatable: ^latest
  dartz: ^latest
```

## How It Works

### Offline Flow

1. **Add User Offline**
   - User fills form and submits
   - User saved to local DB with `pendingSync = true`
   - User appears immediately in users list
   - When online, WorkManager syncs to Reqres API

2. **Save Movies Offline**
   - User browses cached movies
   - Saves/unsaves movies
   - Changes stored in SavedMovies table
   - Matches page updates in real-time

3. **Background Sync**
   - WorkManager runs every 15 minutes
   - Checks for users with `pendingSync = true`
   - POSTs to Reqres API
   - Updates local record with server ID
   - Sets `pendingSync = false`

### Network Resilience

- **Dio Interceptor**: Retries failed requests 3 times with exponential backoff
- **Database Retry**: Wraps DB operations with retry logic
- **Stream Retry**: Database streams auto-reconnect on errors
- **Connectivity Monitor**: Triggers sync when network returns
- **Fallback API**: Uses OMDB if TMDB fails

## Design Decisions

### Why Drift?
- Type-safe queries
- Stream support for reactive UI
- Migration system
- Better than raw sqflite

### Why Bloc/Cubit?
- Predictable state management
- Easy to test
- Separates business logic from UI
- Works well with streams

### Why Offline-First?
- Better user experience
- Works in poor connectivity
- Faster perceived performance
- Required by assignment

### Why WorkManager?
- Guaranteed background execution
- Respects battery optimization
- Survives app restarts
- Perfect for sync tasks

## Testing the Offline Flow

1. **Turn on Airplane Mode**
2. **Add a new user**
   - Name: "Test User"
   - Movie Taste: "loves action"
   - User saved with "pending sync" status
3. **Browse movies** (shows cached movies)
4. **Save 3-4 movies** for the new user
5. **Check Saved Movies page** - all movies visible
6. **Check Matches page** - if other users saved same movies, matches appear
7. **Turn off Airplane Mode**
8. **Wait 10-20 seconds** - sync triggers automatically
9. **Verify user has server ID** (check database or logs)

## Performance Optimizations

- Paginated API requests (20 items per page)
- Infinite scroll with lazy loading
- Cached network images
- Database indexes on foreign keys
- Stream-based UI updates (no polling)
- Shimmer placeholders prevent layout shift

## Known Limitations

- WorkManager minimum interval is 15 minutes
- OMDB API doesn't provide overview/description
- Reqres API is a mock API (doesn't persist data permanently)
- Hero animations require unique tags

## Future Enhancements

- User authentication
- Push notifications for matches
- Movie recommendations based on taste
- Social features (comments, ratings)
- Export matches to calendar
- Dark mode toggle
- Search functionality
- Filter and sort options

## Troubleshooting

### Build Runner Issues
```bash
flutter clean
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Database Issues
```bash
# Uninstall app to clear database
flutter clean
flutter run
```

### WorkManager Not Running
- Check battery optimization settings
- WorkManager won't run in debug mode as frequently
- Use release build for accurate testing

### API Errors
- Verify API keys in .env
- Check internet connection
- Check API rate limits

## License

This project is part of the Platform Commons Flutter Developer assignment.

## Contact

For questions or issues, please reach out to the Platform Commons engineering team.
