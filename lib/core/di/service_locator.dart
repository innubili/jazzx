import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../services/firebase_service.dart';
import '../../services/youtube_service.dart';
import '../../services/spotify_service.dart';
import '../../services/google_search_service.dart';
import '../../services/sharing_intent_service.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/jazz_standards_provider.dart';
import '../../providers/irealpro_provider.dart';
import '../../secrets.dart';
import '../cache/cache_manager.dart';

import '../repositories/user_repository.dart';
import '../repositories/cached_user_repository.dart';
import '../repositories/jazz_standards_repository.dart';
import '../repositories/cached_jazz_standards_repository.dart';
import '../monitoring/performance_monitor.dart';
import '../logging/logging_service.dart';
import '../../features/session/domain/usecases/save_session_usecase.dart';
import '../../features/session/domain/usecases/load_sessions_usecase.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // External dependencies
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);

  // Cache Manager (initialize early)
  sl.registerLazySingleton<CacheManager>(() => CacheManager());
  await sl.get<CacheManager>().initialize();

  // Services (Singletons - one instance throughout app lifecycle)
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
  sl.registerLazySingleton<YouTubeSearchService>(() => YouTubeSearchService());
  sl.registerLazySingleton<SpotifySearchService>(() => SpotifySearchService());
  sl.registerLazySingleton<GoogleSearchService>(
    () => GoogleSearchService(
      apiKey: APP_GOOGLE_API_KEY,
      cx: GOOGLE_CUSTOM_SEARCH_CX,
    ),
  );
  sl.registerLazySingleton<SharingIntentService>(() => SharingIntentService());
  sl.registerLazySingleton<PerformanceMonitor>(() => PerformanceMonitor());
  sl.registerLazySingleton<LoggingService>(() => LoggingService());

  // Repositories (Singletons for caching)
  sl.registerLazySingleton<UserRepository>(
    () =>
        CachedUserRepository(sl.get<FirebaseService>(), sl.get<CacheManager>()),
  );
  sl.registerLazySingleton<JazzStandardsRepository>(
    () => CachedJazzStandardsRepository(
      sl.get<FirebaseService>(),
      sl.get<CacheManager>(),
      sl.get<PerformanceMonitor>(),
    ),
  );

  // Use Cases (Factories - new instance each time)
  sl.registerFactory<SaveSessionUseCase>(
    () => SaveSessionUseCase(sl.get<UserRepository>()),
  );
  sl.registerFactory<LoadSessionsUseCase>(
    () => LoadSessionsUseCase(sl.get<UserRepository>()),
  );

  // Providers (Factories - new instance each time)
  sl.registerFactory<UserProfileProvider>(() => UserProfileProvider());
  sl.registerFactory<JazzStandardsProvider>(() => JazzStandardsProvider());
  sl.registerFactory<IRealProProvider>(() => IRealProProvider());
}

// Helper methods for easy access
class ServiceLocator {
  static T get<T extends Object>() => sl.get<T>();

  // Convenience getters for commonly used services
  static FirebaseService get firebaseService => get<FirebaseService>();
  static UserProfileProvider get userProfileProvider =>
      get<UserProfileProvider>();
  static JazzStandardsProvider get jazzStandardsProvider =>
      get<JazzStandardsProvider>();
  static YouTubeSearchService get youtubeService => get<YouTubeSearchService>();
  static SpotifySearchService get spotifyService => get<SpotifySearchService>();
  static GoogleSearchService get googleSearchService =>
      get<GoogleSearchService>();

  // Repository getters
  static UserRepository get userRepository => get<UserRepository>();
  static JazzStandardsRepository get jazzStandardsRepository =>
      get<JazzStandardsRepository>();

  // Use case getters
  static SaveSessionUseCase get saveSessionUseCase => get<SaveSessionUseCase>();
  static LoadSessionsUseCase get loadSessionsUseCase =>
      get<LoadSessionsUseCase>();

  // Performance monitoring
  static PerformanceMonitor get performanceMonitor => get<PerformanceMonitor>();

  // Cache management
  static CacheManager get cacheManager => get<CacheManager>();

  // Logging service
  static LoggingService get loggingService => get<LoggingService>();
}
