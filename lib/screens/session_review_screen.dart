import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../widgets/session_review_widget.dart';
// import '../utils/utils.dart';
// import '../utils/session_utils.dart';
import '../providers/user_profile_provider.dart';
// import '../services/firebase_service.dart';

class SessionReviewScreen extends StatefulWidget {
  final String sessionId;
  final Session? session;
  final bool manualEntry;
  final DateTime? initialDateTime;

  const SessionReviewScreen({
    super.key,
    required this.sessionId,
    this.session,
    this.manualEntry = false,
    this.initialDateTime,
  });

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  bool _editMode = false;
  late Session _editableSession;
  late Session _originalSession;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _editableSession = widget.session!;
      _originalSession = widget.session!;
    } else if (widget.manualEntry && widget.initialDateTime != null) {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).profile;
      String? defaultInstrument;
      final instruments = profile?.preferences.instruments ?? [];
      if (instruments.length == 1) {
        defaultInstrument = instruments.first;
      }
      _editableSession = Session.getDefault(
        instrument: defaultInstrument ?? 'guitar',
      );
      _originalSession = _editableSession;
      _editMode = true;
    } else {
      throw Exception(
        'SessionReviewScreen requires either session or manualEntry+initialDateTime',
      );
    }
  }

  bool get _hasEdits {
    return _editableSession != _originalSession;
  }

  void _startEdit() {
    setState(() => _editMode = true);
  }

  void _saveEdit(Session updated) async {
    setState(() {
      _editMode = false;
    });
    // Validate ended before saving
    int fixedEnded = updated.ended;
    if (fixedEnded == 0) {
      // Use initialDateTime if available, else now
      if (widget.initialDateTime != null) {
        fixedEnded = widget.initialDateTime!.millisecondsSinceEpoch ~/ 1000;
      } else {
        fixedEnded = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      updated = updated.copyWith(ended: fixedEnded);
      // Optional: show a warning to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session date/time was missing. Using current date/time.',
          ),
        ),
      );
    }
    print('[SessionReviewScreen] Saving session: ${updated.toJson()}');
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final sessionId = updated.ended.toString();
    await profileProvider.saveSessionWithId(sessionId, updated);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Session saved.')));
    _originalSession = updated;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  void _onSessionChanged(Session session) {
    setState(() {
      // Recalculate duration as sum of all category times + warmup
      final total =
          ((session.warmupTime ?? 0) +
                  session.categories.values.fold(
                    0,
                    (sum, cat) => sum + (cat.time),
                  ))
              .toInt();
      _editableSession = session.copyWith(duration: total);
    });
  }

  String _formatSessionDate(int ended) {
    int ts = ended;
    // Use fallback only if both session.ended and sessionId are valid and nonzero
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
  }

  String _formatSessionTime(int ended) {
    int ts = ended;
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _showDatePickerOnly() async {
    int ts = _editableSession.ended;
    if (ts == 0 && int.tryParse(widget.sessionId) != null) {
      ts = int.parse(widget.sessionId);
    }
    DateTime initial = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    // Clamp initialDate to firstDate if needed
    final firstDate = DateTime(2000);
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      initial.hour,
      initial.minute,
    );
    setState(() {
      _editableSession = _editableSession.copyWith(
        ended: (newDateTime.millisecondsSinceEpoch ~/ 1000),
      );
    });
  }

  void _showTimePickerOnly() async {
    // Use the correct reference for the current time, fallback to sessionId if ended is 0 or 1
    int ts = _editableSession.ended;
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final current = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;
    // Only update the time, keep the date unchanged
    final newDateTime = DateTime(
      current.year,
      current.month,
      current.day,
      pickedTime.hour,
      pickedTime.minute,
      current.second,
      current.millisecond,
      current.microsecond,
    );
    setState(() {
      _editableSession = _editableSession.copyWith(
        ended: (newDateTime.millisecondsSinceEpoch ~/ 1000),
      );
    });
  }

  Future<bool> _onWillPop() async {
    if (_editMode && _hasEdits) {
      final discard = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text(
                'You have unsaved changes. Do you really want to discard them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Discard'),
                ),
              ],
            ),
      );
      return discard == true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop) Navigator.of(context).maybePop();
            },
          ),
          title: Text(_editMode ? 'Session (edit)' : 'Session'),
          actions: [
            if (_editMode && _hasEdits)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: () {
                  _saveEdit(_editableSession);
                },
              ),
            if (!_editMode)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Session',
                onPressed: _startEdit,
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Session of ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  InkWell(
                    onTap: _editMode ? _showDatePickerOnly : null,
                    child: Text(
                      _formatSessionDate(_editableSession.ended),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _editMode ? _showTimePickerOnly : null,
                    child: Text(
                      _formatSessionTime(_editableSession.ended),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(_editableSession.duration),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            // Instrument selection chips (with left padding, no text below)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Builder(
                builder: (context) {
                  final profile =
                      Provider.of<UserProfileProvider>(context).profile;
                  final instruments = profile?.preferences.instruments ?? [];
                  if (instruments.isEmpty) {
                    return const Text('No instruments set in preferences');
                  }
                  return Wrap(
                    spacing: 8,
                    children:
                        instruments.map((instr) {
                          final isSelected =
                              _editableSession.instrument == instr;
                          return ChoiceChip(
                            label: Text(instr),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected && !isSelected) {
                                setState(() {
                                  _editableSession = _editableSession.copyWith(
                                    instrument: instr,
                                  );
                                });
                              }
                            },
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            Expanded(
              child: SessionReviewWidget(
                sessionId: widget.sessionId,
                session: _editableSession,
                editMode: _editMode,
                onSave: _saveEdit,
                onSessionChanged: _onSessionChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
