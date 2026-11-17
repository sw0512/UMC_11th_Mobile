import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/api_failure.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';
import 'submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._service,
    this.auth,
    this.sessionRatings,
    this.movie,
  );
  final RatingApiService _service;
  final AuthViewModel auth;
  final SessionRatings sessionRatings;
  final TmdbMovieDto movie;
  bool get canRate => auth.status == AuthStatus.signedIn;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;
  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) {
      throw const ApiFailure('요청을 처리 중입니다.');
    }
    if (!canRate) throw const ApiFailure('먼저 로그인해 주세요.');
    final version = auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      final rating = await _service.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (!auth.isCurrent(version)) throw const ApiFailure('세션이 변경됐습니다.');
      sessionRatings.upsert(rating, version);
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } catch (e) {
      await auth.handleFailure(e, version);
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
