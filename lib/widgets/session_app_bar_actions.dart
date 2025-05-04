import 'package:flutter/material.dart';

class SessionAppBarActions extends StatelessWidget {
  final bool editMode;
  final bool hasEdits;
  final bool editRecordedSession;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  const SessionAppBarActions({
    super.key,
    required this.editMode,
    required this.hasEdits,
    required this.editRecordedSession,
    this.onSave,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if ((editMode && hasEdits) || editRecordedSession)
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: onSave,
          ),
        if (!editMode)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Session',
            onPressed: onEdit,
          ),
        if (!editMode)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Session',
            onPressed: onDelete,
          ),
      ],
    );
  }
}
