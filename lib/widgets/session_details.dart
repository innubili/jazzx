import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../providers/user_profile_provider.dart';

class SessionDetails extends StatelessWidget {
  final Session session;
  final bool editMode;
  final ValueChanged<Session>? onSessionChanged;
  final VoidCallback? onShowDatePicker;
  final VoidCallback? onShowTimePicker;

  const SessionDetails({
    super.key,
    required this.session,
    required this.editMode,
    this.onSessionChanged,
    this.onShowDatePicker,
    this.onShowTimePicker,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;
    final instruments = profile?.preferences.instruments ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                session.instrument,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              InkWell(
                onTap: editMode ? onShowDatePicker : null,
                child: Text(
                  _formatSessionDate(session.ended),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: editMode ? onShowTimePicker : null,
                child: Text(
                  _formatSessionTime(session.ended),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(session.duration),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          instruments.isEmpty
              ? const Text('No instruments set in preferences')
              : Wrap(
                spacing: 8,
                children:
                    instruments.map((instr) {
                      final isSelected = session.instrument == instr;
                      return ChoiceChip(
                        label: Text(instr),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected &&
                              !isSelected &&
                              onSessionChanged != null) {
                            onSessionChanged!(
                              session.copyWith(instrument: instr),
                            );
                          }
                        },
                      );
                    }).toList(),
              ),
          // Add more session details here as needed
        ],
      ),
    );
  }

  String _formatSessionDate(int ended) {
    int ts = ended;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
  }

  String _formatSessionTime(int ended) {
    int ts = ended;
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
}
