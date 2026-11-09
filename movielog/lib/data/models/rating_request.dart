int validateServerScore(double value) {
  if (!value.isFinite ||
      value < 1 ||
      value > 5 ||
      value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

String? normalizedComment(String? value) {
  final text = value?.trim();
  if (text != null && text.length > 500) {
    throw ArgumentError('코멘트는 500자 이하로 입력해 주세요.');
  }
  return text == null || text.isEmpty ? null : text;
}

class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });
  final int movieId;
  final int score;
  final String? comment;
  Map<String, dynamic> toJson() {
    if (movieId < 1) throw ArgumentError('올바른 영화 ID가 필요합니다.');
    validateServerScore(score.toDouble());
    final text = normalizedComment(comment);
    return {
      'movieId': movieId,
      'score': score,
      'comment': ?text,
    };
  }
}
