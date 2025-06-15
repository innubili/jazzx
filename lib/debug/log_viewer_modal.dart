import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/logging/logging_service.dart';
import '../core/logging/structured_logger.dart';

/// Modal dialog for viewing and filtering logs
class LogViewerModal extends StatefulWidget {
  const LogViewerModal({super.key});

  @override
  State<LogViewerModal> createState() => _LogViewerModalState();
}

class _LogViewerModalState extends State<LogViewerModal> {
  LoggingService? _loggingService;

  List<LogEntry> _logs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  LogLevel? _selectedLevel;
  LogCategory? _selectedCategory;
  bool _includeMemoryLogs = true;
  bool _includePersistedLogs = true;

  @override
  void initState() {
    super.initState();
    _initializeLoggingService();
  }

  void _initializeLoggingService() {
    try {
      _loggingService = LoggingService();
      _loadLogs();
    } catch (e) {
      // Logging service not available, show empty state
      setState(() {
        _logs = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLogs() async {
    if (_loggingService == null) return;

    setState(() => _isLoading = true);

    try {
      final logs = await _loggingService!.getRecentLogs(
        limit: 500,
        minLevel: _selectedLevel,
        category: _selectedCategory,
        includeMemoryLogs: _includeMemoryLogs,
        includePersistedLogs: _includePersistedLogs,
      );

      // Apply search filter
      final filteredLogs =
          _searchQuery.isEmpty
              ? logs
              : logs
                  .where(
                    (log) =>
                        log.message.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        log.component?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ==
                            true ||
                        log.metadata.toString().toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

      setState(() {
        _logs = filteredLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load logs: $e')));
      }
    }
  }

  Future<void> _exportLogs() async {
    if (_loggingService == null) return;

    try {
      final exportData = await _loggingService!.exportLogs(
        since: DateTime.now().subtract(const Duration(hours: 24)),
        minLevel: _selectedLevel,
        category: _selectedCategory,
      );

      await Clipboard.setData(ClipboardData(text: exportData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs exported to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export logs: $e')));
      }
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Logs'),
            content: const Text(
              'Are you sure you want to clear all logs? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirmed == true && _loggingService != null) {
      try {
        await _loggingService!.clearAllLogs();
        await _loadLogs();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All logs cleared')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to clear logs: $e')));
        }
      }
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(LogCategory category) {
    switch (category) {
      case LogCategory.cache:
        return Icons.storage;
      case LogCategory.network:
        return Icons.wifi;
      case LogCategory.auth:
        return Icons.security;
      case LogCategory.performance:
        return Icons.speed;
      case LogCategory.ui:
        return Icons.widgets;
      case LogCategory.database:
        return Icons.storage;
      case LogCategory.error:
        return Icons.error;
      case LogCategory.analytics:
        return Icons.analytics;
      case LogCategory.system:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Log Viewer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _exportLogs,
                      icon: const Icon(Icons.download),
                      tooltip: 'Export Logs',
                    ),
                    IconButton(
                      onPressed: _clearLogs,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Clear All Logs',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(),

            // Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Search
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _loadLogs();
                    },
                  ),
                ),

                // Level filter
                DropdownButton<LogLevel?>(
                  value: _selectedLevel,
                  hint: const Text('Level'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Levels'),
                    ),
                    ...LogLevel.values.map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.name.toUpperCase()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedLevel = value);
                    _loadLogs();
                  },
                ),

                // Category filter
                DropdownButton<LogCategory?>(
                  value: _selectedCategory,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...LogCategory.values.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(category), size: 16),
                            const SizedBox(width: 4),
                            Text(category.name.toUpperCase()),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _loadLogs();
                  },
                ),

                // Source toggles
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _includeMemoryLogs,
                      onChanged: (value) {
                        setState(() => _includeMemoryLogs = value ?? true);
                        _loadLogs();
                      },
                    ),
                    const Text('Memory'),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: _includePersistedLogs,
                      onChanged: (value) {
                        setState(() => _includePersistedLogs = value ?? true);
                        _loadLogs();
                      },
                    ),
                    const Text('Persisted'),
                  ],
                ),

                // Refresh button
                ElevatedButton.icon(
                  onPressed: _loadLogs,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Stats
            Text(
              'Showing ${_logs.length} logs',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 8),

            // Log list
            Expanded(
              child:
                  _loggingService == null
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, size: 48, color: Colors.orange),
                            SizedBox(height: 16),
                            Text('Logging service not available'),
                            SizedBox(height: 8),
                            Text(
                              'Please restart the app to enable structured logging',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _logs.isEmpty
                      ? const Center(child: Text('No logs found'))
                      : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ExpansionTile(
                              leading: Icon(
                                _getCategoryIcon(log.category),
                                color: _getLevelColor(log.level),
                                size: 20,
                              ),
                              title: Text(
                                log.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getLevelColor(log.level),
                                ),
                              ),
                              subtitle: Text(
                                '${log.timestamp.toIso8601String().substring(11, 23)} | ${log.level.name.toUpperCase()} | ${log.category.name.toUpperCase()}${log.component != null ? ' | ${log.component}' : ''}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (log.metadata.isNotEmpty) ...[
                                        const Text(
                                          'Metadata:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            log.metadata.entries
                                                .map(
                                                  (e) => '${e.key}: ${e.value}',
                                                )
                                                .join('\n'),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (log.error != null) ...[
                                        const Text(
                                          'Error:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            log.error!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      if (log.stackTrace != null) ...[
                                        const Text(
                                          'Stack Trace:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            log.stackTrace!,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
