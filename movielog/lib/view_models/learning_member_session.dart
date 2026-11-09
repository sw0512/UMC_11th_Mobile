import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  int? _memberId;
  int? get memberId => _memberId;
  void setMemberId(int id) {
    if (id < 1) throw ArgumentError('올바른 학습용 회원 ID가 필요합니다.');
    _memberId = id;
    notifyListeners();
  }

  void clear() {
    _memberId = null;
    notifyListeners();
  }
}
