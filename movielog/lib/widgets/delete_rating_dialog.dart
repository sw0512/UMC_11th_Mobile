import 'package:flutter/material.dart';

import '../data/models/api_failure.dart';
import 'movielog_button.dart';

class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onConfirm});
  final Future<void> Function() onConfirm;
  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _busy ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '삭제',
          isLoading: _busy,
          onPressed: _busy ? null : _confirm,
        ),
      ],
    ),
  );
}
