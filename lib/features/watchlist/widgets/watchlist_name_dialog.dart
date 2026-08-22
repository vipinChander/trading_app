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
  });

  final String title;
  final String confirmLabel;
  final String initialValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => WatchlistNameDialog(
        title: title,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
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
    final error = Validators.watchlistName(_controller.text, existingNames: const []);
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
