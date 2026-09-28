import 'dart:async';

import 'package:flutter/material.dart';

/// App bar with an autofocused search field. [onQueryChanged] fires after
/// the user pauses typing, so we don't hit the API on every keystroke.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.hintText,
    required this.onQueryChanged,
  });

  final String hintText;
  final ValueChanged<String> onQueryChanged;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    setState(() {}); // Toggle the clear button.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.onQueryChanged(value.trim()),
    );
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {});
    widget.onQueryChanged('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      title: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(hintText: widget.hintText),
        onChanged: _onChanged,
        onSubmitted: (v) {
          _debounce?.cancel();
          widget.onQueryChanged(v.trim());
        },
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.close_rounded),
            onPressed: _clear,
          ),
      ],
    );
  }
}
