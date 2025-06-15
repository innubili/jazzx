import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jazzx_app/core/cache/cache_manager.dart';
import 'package:jazzx_app/core/cache/cache_keys.dart';

void main() {
  group('Cache System Tests', () {
    late CacheManager cacheManager;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      cacheManager = CacheManager();
      await cacheManager.initialize();
    });

    test('Cache Manager initializes successfully', () async {
      expect(cacheManager, isNotNull);
      expect(cacheManager.stats, isNotNull);
    });

    test('Can store and retrieve simple data from cache', () async {
      const testKey = 'test_key';
      const testData = 'test_data';

      // Store data
      await cacheManager.set(testKey, testData);

      // Retrieve data
      final retrievedData = await cacheManager.get<String>(testKey);

      expect(retrievedData, equals(testData));
    });

    test('Can store and retrieve complex data from cache', () async {
      const testKey = 'test_complex_key';
      final testData = {
        'name': 'Test User',
        'age': 25,
        'preferences': {'darkMode': true, 'notifications': false},
      };

      // Store data
      await cacheManager.set(testKey, testData);

      // Retrieve data
      final retrievedData = await cacheManager.get<Map<String, dynamic>>(
        testKey,
      );

      expect(retrievedData, isNotNull);
      expect(retrievedData!['name'], equals('Test User'));
      expect(retrievedData['age'], equals(25));
      expect(retrievedData['preferences']['darkMode'], equals(true));
    });

    test('Cache keys are generated correctly', () {
      const userId = 'test_user_123';

      expect(
        CacheKeys.userProfile(userId),
        equals('user_profile_test_user_123'),
      );
      expect(
        CacheKeys.userSessions(userId),
        equals('user_sessions_test_user_123'),
      );
      expect(
        CacheKeys.userStatistics(userId),
        equals('user_statistics_test_user_123'),
      );
      expect(CacheKeys.jazzStandards, equals('jazz_standards_all'));
    });

    test('Cache TTL configurations are reasonable', () {
      // Test that TTL values are within reasonable ranges
      expect(CacheTTL.userProfile.inHours, equals(2));
      expect(CacheTTL.jazzStandards.inDays, equals(7));
      expect(CacheTTL.searchResults.inMinutes, equals(15));
      expect(CacheTTL.userSessions.inMinutes, equals(30));
    });

    test('Cache statistics track operations correctly', () async {
      const testKey = 'stats_test_key';
      const testData = 'stats_test_data';

      // Reset stats for this test
      cacheManager.stats.reset();

      // Initial stats should be zero after reset
      expect(cacheManager.stats.requests, equals(0));
      expect(cacheManager.stats.totalHits, equals(0));
      expect(cacheManager.stats.misses, equals(0));

      // Store data
      await cacheManager.set(testKey, testData);

      // First get should be a hit (data is in memory cache after set)
      await cacheManager.get<String>(testKey);
      expect(cacheManager.stats.requests, equals(1));
      expect(cacheManager.stats.totalHits, equals(1));

      // Second get should also be a hit
      await cacheManager.get<String>(testKey);
      expect(cacheManager.stats.requests, equals(2));
      expect(cacheManager.stats.totalHits, equals(2));
    });

    test('Can clear cache', () async {
      const testKey = 'clear_test_key';
      const testData = 'clear_test_data';

      // Store data
      await cacheManager.set(testKey, testData);

      // Verify data exists
      final retrievedData = await cacheManager.get<String>(testKey);
      expect(retrievedData, equals(testData));

      // Clear cache
      await cacheManager.clear();

      // Verify data is gone
      final clearedData = await cacheManager.get<String>(testKey);
      expect(clearedData, isNull);
    });

    test('Can remove specific cache entries', () async {
      const testKey1 = 'remove_test_key_1';
      const testKey2 = 'remove_test_key_2';
      const testData1 = 'remove_test_data_1';
      const testData2 = 'remove_test_data_2';

      // Store data
      await cacheManager.set(testKey1, testData1);
      await cacheManager.set(testKey2, testData2);

      // Verify both exist
      expect(await cacheManager.get<String>(testKey1), equals(testData1));
      expect(await cacheManager.get<String>(testKey2), equals(testData2));

      // Remove one
      await cacheManager.remove(testKey1);

      // Verify only one is gone
      expect(await cacheManager.get<String>(testKey1), isNull);
      expect(await cacheManager.get<String>(testKey2), equals(testData2));
    });

    test('Cache strategies work correctly', () async {
      const testKey = 'strategy_test_key';
      const testData = 'strategy_test_data';

      // Test memory-only strategy
      await cacheManager.set(
        testKey,
        testData,
        strategy: CacheStrategy.memoryOnly,
      );

      final memoryData = await cacheManager.get<String>(testKey);
      expect(memoryData, equals(testData));

      // Test persistent-only strategy
      await cacheManager.set(
        '${testKey}_persistent',
        testData,
        strategy: CacheStrategy.persistentOnly,
      );

      final persistentData = await cacheManager.get<String>(
        '${testKey}_persistent',
      );
      expect(persistentData, equals(testData));
    });
  });
}
