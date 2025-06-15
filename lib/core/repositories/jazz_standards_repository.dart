import 'package:collection/collection.dart';
import '../../models/song.dart';
import '../../services/firebase_service.dart';
import '../errors/failures.dart';
import '../monitoring/performance_monitor.dart';

abstract class JazzStandardsRepository {
  Future<Result<List<Song>>> getJazzStandards();
  Future<Result<List<Song>>> searchJazzStandards(String query);
  Future<Result<Song?>> getJazzStandardByTitle(String title);
}

class FirebaseJazzStandardsRepository implements JazzStandardsRepository {
  final FirebaseService _firebaseService;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  List<Song>? _cachedStandards;
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiration = Duration(hours: 1);

  FirebaseJazzStandardsRepository(this._firebaseService);

  @override
  Future<Result<List<Song>>> getJazzStandards() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Check cache first
      if (_cachedStandards != null &&
          _lastCacheTime != null &&
          DateTime.now().difference(_lastCacheTime!) < _cacheExpiration) {
        stopwatch.stop();
        _performanceMonitor.recordCacheHit('jazz_standards');
        _performanceMonitor.recordRepositoryCall(
          'getJazzStandards',
          stopwatch.elapsed,
        );
        return Success(_cachedStandards!);
      }

      _performanceMonitor.recordCacheMiss('jazz_standards');
      final standards = await _firebaseService.loadJazzStandards();

      // Update cache
      _cachedStandards = standards;
      _lastCacheTime = DateTime.now();

      stopwatch.stop();
      _performanceMonitor.recordRepositoryCall(
        'getJazzStandards',
        stopwatch.elapsed,
      );
      return Success(standards);
    } catch (e) {
      stopwatch.stop();
      _performanceMonitor.recordRepositoryCall(
        'getJazzStandards',
        stopwatch.elapsed,
        hasError: true,
      );
      return Error(
        DatabaseFailure('Failed to load jazz standards: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Song>>> searchJazzStandards(String query) async {
    try {
      final standardsResult = await getJazzStandards();
      if (standardsResult.isError) {
        return Error(standardsResult.failure!);
      }

      final standards = standardsResult.data!;
      final filteredStandards =
          standards.where((song) {
            final titleMatch = song.title.toLowerCase().contains(
              query.toLowerCase(),
            );
            final composerMatch = song.songwriters.toLowerCase().contains(
              query.toLowerCase(),
            );
            return titleMatch || composerMatch;
          }).toList();

      return Success(filteredStandards);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to search jazz standards: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Song?>> getJazzStandardByTitle(String title) async {
    try {
      final standardsResult = await getJazzStandards();
      if (standardsResult.isError) {
        return Error(standardsResult.failure!);
      }

      final standards = standardsResult.data!;
      final song =
          standards
              .where((s) => s.title.toLowerCase() == title.toLowerCase())
              .firstOrNull;

      return Success(song);
    } catch (e) {
      return Error(
        DatabaseFailure('Failed to get jazz standard: ${e.toString()}'),
      );
    }
  }

  void clearCache() {
    _cachedStandards = null;
    _lastCacheTime = null;
  }
}
