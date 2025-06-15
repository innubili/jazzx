import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jazzx_app/core/cache/cache_manager.dart';
import 'package:jazzx_app/core/cache/cached_repository.dart';
import 'package:jazzx_app/core/cache/cache_initialization_service.dart';
import 'package:jazzx_app/core/errors/failures.dart';

void main() {
  group('Cache Integration Tests', () {
    late CacheManager cacheManager;
    late CachedRepository cachedRepo;
    late CacheInitializationService cacheService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      cacheManager = CacheManager();
      await cacheManager.initialize();

      cachedRepo = CachedRepository(cacheManager, 'TestRepository');
      cacheService = CacheInitializationService(cacheManager);
    });

    test('CachedRepository executes operations with caching', () async {
      const testKey = 'integration_test_key';
      const testData = 'integration_test_data';
      int operationCallCount = 0;

      // Define a mock operation that increments a counter
      Future<Result<String>> mockOperation() async {
        operationCallCount++;
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Simulate network delay
        return Success(testData);
      }

      // First call should execute the operation
      final result1 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result1.isSuccess, isTrue);
      expect(result1.data, equals(testData));
      expect(operationCallCount, equals(1));

      // Second call should use cache (operation not called again)
      final result2 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result2.isSuccess, isTrue);
      expect(result2.data, equals(testData));
      expect(operationCallCount, equals(1)); // Still 1, not called again
    });

    test('CachedRepository handles list operations', () async {
      const testKey = 'integration_list_test_key';
      final testData = ['item1', 'item2', 'item3'];
      int operationCallCount = 0;

      Future<Result<List<String>>> mockListOperation() async {
        operationCallCount++;
        await Future.delayed(const Duration(milliseconds: 10));
        return Success(testData);
      }

      // First call should execute the operation
      final result1 = await cachedRepo.executeList<String>(
        cacheKey: testKey,
        operation: mockListOperation,
      );

      expect(result1.isSuccess, isTrue);
      expect(result1.data, equals(testData));
      expect(operationCallCount, equals(1));

      // Second call should use cache
      final result2 = await cachedRepo.executeList<String>(
        cacheKey: testKey,
        operation: mockListOperation,
      );

      expect(result2.isSuccess, isTrue);
      expect(result2.data, equals(testData));
      expect(operationCallCount, equals(1)); // Still 1, not called again
    });

    test('CachedRepository handles force refresh', () async {
      const testKey = 'force_refresh_test_key';
      const testData = 'force_refresh_test_data';
      int operationCallCount = 0;

      Future<Result<String>> mockOperation() async {
        operationCallCount++;
        return Success('$testData-$operationCallCount');
      }

      // First call
      final result1 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result1.isSuccess, isTrue);
      expect(result1.data, equals('$testData-1'));
      expect(operationCallCount, equals(1));

      // Second call with force refresh should call operation again
      final result2 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
        forceRefresh: true,
      );

      expect(result2.isSuccess, isTrue);
      expect(result2.data, equals('$testData-2'));
      expect(
        operationCallCount,
        equals(2),
      ); // Called again due to force refresh
    });

    test('CachedRepository handles errors correctly', () async {
      const testKey = 'error_test_key';
      int operationCallCount = 0;

      Future<Result<String>> mockErrorOperation() async {
        operationCallCount++;
        return Error(const NetworkFailure('Test network error'));
      }

      // Error should not be cached
      final result1 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockErrorOperation,
      );

      expect(result1.isError, isTrue);
      expect(result1.failure, isA<NetworkFailure>());
      expect(operationCallCount, equals(1));

      // Second call should execute operation again (errors not cached)
      final result2 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockErrorOperation,
      );

      expect(result2.isError, isTrue);
      expect(
        operationCallCount,
        equals(2),
      ); // Called again because error wasn't cached
    });

    test('Cache invalidation works correctly', () async {
      const testKey = 'invalidation_test_key';
      const testData = 'invalidation_test_data';
      int operationCallCount = 0;

      Future<Result<String>> mockOperation() async {
        operationCallCount++;
        return Success('$testData-$operationCallCount');
      }

      // First call
      final result1 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result1.data, equals('$testData-1'));
      expect(operationCallCount, equals(1));

      // Invalidate cache
      await cachedRepo.invalidateCache(keys: [testKey]);

      // Next call should execute operation again
      final result2 = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result2.data, equals('$testData-2'));
      expect(operationCallCount, equals(2)); // Called again after invalidation
    });

    test('Cache preloading works', () async {
      const testKey = 'preload_test_key';
      const testData = 'preload_test_data';
      int operationCallCount = 0;

      Future<Result<String>> mockOperation() async {
        operationCallCount++;
        return Success(testData);
      }

      // Preload cache
      await cachedRepo.preloadCache<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(operationCallCount, equals(1));

      // Now regular call should use preloaded cache
      final result = await cachedRepo.execute<String>(
        cacheKey: testKey,
        operation: mockOperation,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, equals(testData));
      expect(operationCallCount, equals(1)); // Still 1, used preloaded cache
    });

    test('Cache initialization service works', () async {
      // Test that cache service can be created and initialized
      expect(cacheService, isNotNull);

      // Test cache statistics
      final stats = cacheService.getCacheStatistics();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('requests'), isTrue);
      expect(stats.containsKey('hits'), isTrue);
      expect(stats.containsKey('misses'), isTrue);
      expect(stats.containsKey('hitRate'), isTrue);
    });

    test('Cache performance monitoring', () async {
      // Add some cache operations to generate statistics
      await cacheManager.set('perf_test_1', 'data1');
      await cacheManager.set('perf_test_2', 'data2');

      await cacheManager.get<String>('perf_test_1');
      await cacheManager.get<String>('perf_test_2');
      await cacheManager.get<String>('non_existent_key');

      // Monitor performance
      cacheService.monitorCachePerformance();

      final stats = cacheService.getCacheStatistics();
      expect(int.parse(stats['requests'].toString()), greaterThan(0));
    });
  });
}
