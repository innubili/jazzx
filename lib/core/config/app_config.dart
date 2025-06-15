import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'JazzX';
  static const String version = '1.0.0';
  
  // Environment-specific configurations
  static bool get isDebug => kDebugMode;
  static bool get isProduction => kReleaseMode;
  
  // Firebase configuration
  static const String firebaseProjectId = 'your-project-id';
  
  // API endpoints
  static const String youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  
  // Cache configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // Session configuration
  static const int defaultSessionDuration = 30; // minutes
  static const int maxSessionDuration = 180; // minutes
  static const int sessionPageSize = 20;
  
  // Audio configuration
  static const int defaultMetronomeBpm = 120;
  static const int minMetronomeBpm = 40;
  static const int maxMetronomeBpm = 200;
  
  // UI configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  
  // Logging configuration
  static bool get enableLogging => isDebug;
  static bool get enableCrashlytics => isProduction;
  
  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = false;
  
  // Validation rules
  static const int minPasswordLength = 8;
  static const int maxSongNameLength = 100;
  static const int maxNoteLength = 500;
  
  // Network configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
}
