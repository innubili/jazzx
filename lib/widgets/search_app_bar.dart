import 'package:flutter/material.dart';
import 'dart:async';

/// An app bar that shows a title for a few seconds, then fades into a search bar.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Duration titleDuration;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchCleared;
  final List<Widget>? actions;

  const SearchAppBar({
    Key? key,
    required this.title,
    this.titleDuration = const Duration(seconds: 2),
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchCleared,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  bool _showTitle = true;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    Future.delayed(widget.titleDuration, () {
      if (mounted) setState(() => _showTitle = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showTitle
            ? Text(widget.title, key: const ValueKey('title'))
            : SizedBox(
                key: const ValueKey('search'),
                height: 40,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    border: InputBorder.none,
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              if (widget.onSearchCleared != null) widget.onSearchCleared!();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (query) {
                    setState(() {});
                    if (widget.onSearchChanged != null) widget.onSearchChanged!(query);
                  },
                ),
              ),
      ),
      actions: widget.actions,
    );
  }
}
