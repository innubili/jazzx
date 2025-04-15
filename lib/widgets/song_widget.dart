import 'package:flutter/material.dart';
import '../models/song.dart';

class SongWidget extends StatefulWidget {
  final Song song;
  final ValueChanged<Song> onUpdated;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const SongWidget({
    super.key,
    required this.song,
    required this.onUpdated,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  State<SongWidget> createState() => _SongWidgetState();
}

class _SongWidgetState extends State<SongWidget> {
  late Song _editedSong;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _editedSong = widget.song;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _editableText(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value,
        enabled: _editMode,
        decoration: InputDecoration(labelText: label, filled: true),
        onChanged: onChanged,
      ),
    );
  }

  Widget _editableBpm() {
    final bpmList = List.generate(41, (i) => (i * 5) + 60); // 60–260 BPM
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'BPM', filled: true),
        value: _editedSong.bpm > 0 ? _editedSong.bpm : 100,
        items:
            bpmList
                .map(
                  (bpm) =>
                      DropdownMenuItem(value: bpm, child: Text(bpm.toString())),
                )
                .toList(),
        onChanged:
            _editMode
                ? (val) => setState(
                  () => _editedSong = _editedSong.copyWith(bpm: val ?? 100),
                )
                : null,
      ),
    );
  }

  Widget _editableKey() {
    const keys = [
      'C',
      'Db',
      'D',
      'Eb',
      'E',
      'F',
      'Gb',
      'G',
      'Ab',
      'A',
      'Bb',
      'B',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Key', filled: true),
        value: _editedSong.key,
        items:
            keys
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
        onChanged:
            _editMode
                ? (val) => setState(
                  () => _editedSong = _editedSong.copyWith(key: val ?? 'C'),
                )
                : null,
      ),
    );
  }

  Widget _summaryRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${_editedSong.songwriters} (${_editedSong.year}) • '
        '${_editedSong.key} • ${_editedSong.type} • ${_editedSong.form} • ${_editedSong.bpm} BPM',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child:
              _editMode
                  ? TextFormField(
                    initialValue: _editedSong.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged:
                        (val) => setState(
                          () => _editedSong = _editedSong.copyWith(title: val),
                        ),
                  )
                  : Text(
                    _editedSong.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
        if (!_editMode) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => setState(() => _editMode = true),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Duplicate',
            onPressed: widget.onCopy,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: widget.onDelete,
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: () {
              widget.onUpdated(_editedSong); // Save only when confirmed
              setState(() => _editMode = false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed:
                () => setState(() {
                  _editMode = false;
                  _editedSong = widget.song;
                }),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          if (!_editMode) _summaryRow(),
          if (_editMode) ...[
            _editableText(
              "Composer",
              _editedSong.songwriters,
              (val) => setState(
                () => _editedSong = _editedSong.copyWith(songwriters: val),
              ),
            ),
            _editableKey(),
            _editableText(
              "Style",
              _editedSong.type,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(type: val)),
            ),
            _editableText(
              "Form",
              _editedSong.form,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(form: val)),
            ),
            _editableBpm(),
            _editableText(
              "Year",
              _editedSong.year,
              (val) =>
                  setState(() => _editedSong = _editedSong.copyWith(year: val)),
            ),
            _editableText(
              "Notes",
              _editedSong.notes,
              (val) => setState(
                () => _editedSong = _editedSong.copyWith(notes: val),
              ),
            ),
            _editableText(
              "Recommended Versions",
              _editedSong.recommendedVersions,
              (val) => setState(
                () =>
                    _editedSong = _editedSong.copyWith(
                      recommendedVersions: val,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
