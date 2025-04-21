import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final bool searchLocal;
  final bool searchIRealPro;
  final ValueChanged<bool> onToggleLocal;
  final ValueChanged<bool> onToggleIRealPro;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onClear,
    required this.searchLocal,
    required this.searchIRealPro,
    required this.onToggleLocal,
    required this.onToggleIRealPro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                labelText: 'Search...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Checkbox(
                value: searchLocal,
                onChanged: (val) => onToggleLocal(val ?? false),
              ),
              const Text('Local'),
            ],
          ),
          Column(
            children: [
              Checkbox(
                value: searchIRealPro,
                onChanged: (val) => onToggleIRealPro(val ?? false),
              ),
              const Text('iRealPro'),
            ],
          ),
        ],
      ),
    );
  }
}
