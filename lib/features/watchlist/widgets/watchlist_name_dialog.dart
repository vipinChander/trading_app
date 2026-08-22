import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';

/// Shared dialog for both "create watchlist" and "rename watchlist" --
/// same validation, same shape, different title/initial value.
class WatchlistNameDialog extends StatefulWidget {
  const WatchlistNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
    this.existingNames = const [],
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  /// Names already in use. The dialog rejects a duplicate unless it matches
  /// [initialValue] exactly (the "rename to the same name" no-op case).
  final List<String> existingNames;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String initialValue = '',
    List<String> existingNames = const [],
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => WatchlistNameDialog(
        title: title,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
        existingNames: existingNames,
      ),
    );
  }

  @override
  State<WatchlistNameDialog> createState() => _WatchlistNameDialogState();
}

class _WatchlistNameDialogState extends State<WatchlistNameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  void _submit() {
    final error = Validators.watchlistName(
      _controller.text,
      existingNames: widget.existingNames,
      currentName: widget.initialValue.isNotEmpty ? widget.initialValue : null,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(labelText: 'Watchlist name', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
