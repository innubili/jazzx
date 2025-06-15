import 'package:flutter/material.dart';
import '../core/cache/cache_initialization_service.dart';
import '../core/di/service_locator.dart';
import '../core/repositories/jazz_standards_repository.dart';

import '../core/errors/failures.dart';

/// Debug screen to test and monitor cache performance
class CacheDebugScreen extends StatefulWidget {
  const CacheDebugScreen({super.key});

  @override
  State<CacheDebugScreen> createState() => _CacheDebugScreenState();
}

class _CacheDebugScreenState extends State<CacheDebugScreen> {
  Map<String, dynamic> _cacheStats = {};
  String _lastOperation = 'None';
  bool _isLoading = false;
  int _operationCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCacheStats();
  }

  void _updateCacheStats() {
    final cacheService = CacheInitializationServiceFactory.create();
    setState(() {
      _cacheStats = cacheService.getCacheStatistics();
    });
  }

  Future<void> _testJazzStandardsCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Loading Jazz Standards...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final repo = ServiceLocator.get<JazzStandardsRepository>();
      final result = await repo.getJazzStandards();

      stopwatch.stop();

      setState(() {
        _operationCount++;
        _lastOperation =
            result.isSuccess
                ? 'Jazz Standards loaded (${result.data?.length ?? 0} items) in ${stopwatch.elapsedMilliseconds}ms'
                : 'Failed to load Jazz Standards: ${result.failure?.message}';
        _isLoading = false;
      });

      _updateCacheStats();
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _lastOperation = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSearchCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Searching Jazz Standards...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final repo = ServiceLocator.get<JazzStandardsRepository>();
      final result = await repo.searchJazzStandards('autumn');

      stopwatch.stop();

      setState(() {
        _operationCount++;
        _lastOperation =
            result.isSuccess
                ? 'Search results (${result.data?.length ?? 0} items) in ${stopwatch.elapsedMilliseconds}ms'
                : 'Failed to search: ${result.failure?.message}';
        _isLoading = false;
      });

      _updateCacheStats();
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _lastOperation = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Clearing cache...';
    });

    try {
      final cacheService = CacheInitializationServiceFactory.create();
      await cacheService.clearAllCaches();

      setState(() {
        _lastOperation = 'Cache cleared successfully';
        _isLoading = false;
        _operationCount = 0;
      });

      _updateCacheStats();
    } catch (e) {
      setState(() {
        _lastOperation = 'Error clearing cache: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cache Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Requests: ${_cacheStats['requests'] ?? 0}'),
                    Text('Hits: ${_cacheStats['hits'] ?? 0}'),
                    Text('Misses: ${_cacheStats['misses'] ?? 0}'),
                    Text('Hit Rate: ${_cacheStats['hitRate'] ?? '0.0'}%'),
                    Text('Memory Hits: ${_cacheStats['memoryHits'] ?? 0}'),
                    Text(
                      'Memory Hit Rate: ${_cacheStats['memoryHitRate'] ?? '0.0'}%',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Last Operation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Operation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Operations performed: $_operationCount'),
                    const SizedBox(height: 4),
                    Text(
                      _lastOperation,
                      style: TextStyle(
                        color:
                            _lastOperation.contains('Error')
                                ? Colors.red
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons
            const Text(
              'Cache Performance Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testJazzStandardsCache,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Test Jazz Standards Cache'),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testSearchCache,
                child: const Text('Test Search Cache'),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All Cache'),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test Cache Performance:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Click "Test Jazz Standards Cache" multiple times'),
                    Text('2. First call will be slow (cache miss)'),
                    Text('3. Subsequent calls will be fast (cache hits)'),
                    Text('4. Watch the hit rate increase!'),
                    Text('5. Clear cache to reset and test again'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateCacheStats,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
