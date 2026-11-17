import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

class SessionRatings extends ChangeNotifier {
  SessionRatings(this.auth) : _version = auth.sessionVersion {
    auth.addListener(_changed);
  }
  final AuthViewModel auth;
  int _version;
  final Map<int, RatingDto> _items = {};
  List<RatingDto> get items => List.unmodifiable(_items.values);
  void _changed() {
    if (_version != auth.sessionVersion) {
      _version = auth.sessionVersion;
      _items.clear();
      notifyListeners();
    }
  }

  void upsert(RatingDto value, int version) {
    if (auth.isCurrent(version) && auth.status == AuthStatus.signedIn) {
      _items[value.ratingId] = value;
      notifyListeners();
    }
  }

  void remove(int id, int version) {
    if (auth.isCurrent(version)) {
      _items.remove(id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    auth.removeListener(_changed);
    super.dispose();
  }
}
