import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/api_failure.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movie);
  final RatingApiService _service;
  final int? memberId;
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;
  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    final id = memberId;
    if (id == null) throw const ApiFailure('먼저 학습용 회원가입을 완료해 주세요.');
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _service.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } catch (e) {
      if (_disposed) return;
      final error = ApiFailure.from(e);
      submitStatus = SubmitStatus.error;
      submitMessage = error.message;
      notifyListeners();
      throw error;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
