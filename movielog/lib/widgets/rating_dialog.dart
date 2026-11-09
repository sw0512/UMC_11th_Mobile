import 'package:flutter/material.dart';

import '../data/models/api_failure.dart';
import '../data/models/rating_request.dart';
import 'movie_rating_input.dart';
import 'movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.movieId,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });
  final int? movieId;
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _comment = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _submitting = false;
  String? _error;
  Future<void> _submit() async {
    if (_submitting || _score < 1 || _score > 5) return;
    final text = _comment.text.trim();
    if (text.length > 500) {
      setState(() => _error = '코멘트는 500자 이하로 입력해 주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_score, text.isEmpty ? null : text);
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = ApiFailure.from(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: Text(widget.initialScore == 0 ? '평점 남기기' : '평점 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_score == 0 ? '별점을 선택해주세요.' : '$_score점을 선택했어요.'),
            const SizedBox(height: 16),
            MovieRatingInput(
              movieId: widget.movieId,
              rating: _score.toDouble(),
              enabled: !_submitting,
              onChanged: (value) =>
                  setState(() => _score = validateServerScore(value)),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('rating-comment'),
              controller: _comment,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: '코멘트 (선택)',
                hintText: '코멘트를 남겨보세요.',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '확인',
          isLoading: _submitting,
          onPressed: _score > 0 && !_submitting ? _submit : null,
        ),
      ],
    ),
  );
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }
}
