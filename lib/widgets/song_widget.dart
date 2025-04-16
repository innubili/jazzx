import 'package:flutter/material.dart';
import '../models/song.dart';

class SongWidget extends StatefulWidget {
  final Song song;
  final ValueChanged<Song> onUpdated;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final String? highlightQuery;

  const SongWidget({
    super.key,
    required this.song,
    required this.onUpdated,
    required this.onCopy,
    required this.onDelete,
    this.highlightQuery,
  });

  @override
  State<SongWidget> createState() => _SongWidgetState();
}

class _SongWidgetState extends State<SongWidget> {
  late Song _editedSong;
  bool _editMode = false;
  bool _useCustomKey = false;
  final TextEditingController _customKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedSong = widget.song;
    if (!Song.musicalKeys.contains(_editedSong.key)) {
      _useCustomKey = true;
      _customKeyController.text = _editedSong.key;
    }
  }

  @override
  void dispose() {
    _customKeyController.dispose();
    widget.onUpdated(_editedSong);
    super.dispose();
  }

  TextSpan _highlightedText(String text) {
    final query = widget.highlightQuery?.toLowerCase() ?? '';
    if (query.isEmpty || _editMode) return TextSpan(text: text);

    final spans = <TextSpan>[];
    int start = 0;
    final lower = text.toLowerCase();

    while (true) {
      final index = lower.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(backgroundColor: Colors.yellow),
        ),
      );
      start = index + query.length;
    }

    return TextSpan(children: spans);
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
    final bpmList = List.generate(41, (i) => (i * 5) + 60);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Key', filled: true),
            value: _useCustomKey ? 'Other' : _editedSong.key,
            items: [
              ...Song.musicalKeys.map(
                (k) => DropdownMenuItem(value: k, child: Text(k)),
              ),
              const DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged:
                _editMode
                    ? (val) => setState(() {
                      if (val == 'Other') {
                        _useCustomKey = true;
                        _editedSong = _editedSong.copyWith(
                          key: _customKeyController.text,
                        );
                      } else {
                        _useCustomKey = false;
                        _editedSong = _editedSong.copyWith(key: val ?? 'C');
                      }
                    })
                    : null,
          ),
          if (_editMode && _useCustomKey)
            TextFormField(
              controller: _customKeyController,
              decoration: const InputDecoration(
                labelText: 'Custom Key',
                filled: true,
              ),
              onChanged:
                  (val) => setState(
                    () => _editedSong = _editedSong.copyWith(key: val),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    final summary = _editedSong.summary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: _highlightedText(summary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
                  : RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [_highlightedText(_editedSong.title)],
                    ),
                    overflow: TextOverflow.ellipsis,
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
            onPressed: () => setState(() => _editMode = false),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed:
                () => setState(() {
                  _editMode = false;
                  _editedSong = widget.song;
                  _customKeyController.text = widget.song.key;
                  _useCustomKey = !Song.musicalKeys.contains(widget.song.key);
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
