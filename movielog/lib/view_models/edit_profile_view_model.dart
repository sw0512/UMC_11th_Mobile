import 'package:flutter/foundation.dart';

import '../data/services/member_api_service.dart';
import '../data/models/api_failure.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this.service, this.auth);
  final MemberApiService service;
  final AuthViewModel auth;
  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;
  String? validateNickname(String input) =>
      input.trim().length < 2 || input.trim().length > 12
      ? '닉네임은 2~12자로 입력해 주세요.'
      : null;
  Future<bool> save(String input) async {
    if (_disposed ||
        status == EditProfileStatus.saving ||
        auth.status != AuthStatus.signedIn ||
        auth.member == null) {
      return false;
    }
    final version = auth.sessionVersion;
    final nickname = input.trim();
    message = null;
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      notifyListeners();
      return false;
    }
    if (nickname == auth.member!.nickname) {
      status = EditProfileStatus.success;
      notifyListeners();
      return true;
    }
    status = EditProfileStatus.saving;
    notifyListeners();
    try {
      final updated = await service.updateNickname(nickname);
      if (_disposed ||
          !auth.isCurrent(version) ||
          auth.status != AuthStatus.signedIn) {
        return false;
      }
      auth.updateMember(updated, expectedVersion: version);
      status = EditProfileStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      await auth.handleFailure(e, version);
      if (_disposed || !auth.isCurrent(version)) return false;
      final error = ApiFailure.from(e);
      status = EditProfileStatus.failure;
      if (error.code == 'MEMBER409_1' || error.code == 'COMMON400') {
        nicknameError = error.message;
      } else {
        message = error.message;
        if (error.code == 'MEMBER404_1') await auth.loadMember(force: true);
      }
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
