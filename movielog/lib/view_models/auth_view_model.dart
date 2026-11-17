import 'package:flutter/foundation.dart';

import '../core/storage/token_storage.dart';
import '../core/network/api_error.dart';
import '../data/models/api_failure.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);
  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;
  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool storageCleanupFailed = false;
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;
  bool _disposed = false;
  Future<void>? _tokenWrite;
  bool isCurrent(int version) => !_disposed && version == _sessionVersion;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_disposed ||
        storageCleanupInProgress ||
        storageCleanupFailed ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    message = null;
    _notify();
    bool checkingServer = false;
    try {
      final token = await _storage.readAccessToken();
      if (!isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        checkingServer = true;
        final me = await _memberApi.fetchMe();
        if (!isCurrent(version)) return;
        member = me;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } catch (e) {
      if (!isCurrent(version)) return;
      final error = ApiFailure.from(e);
      if (isExpiredCode(error.code)) {
        await expireSession(expectedVersion: version);
        return;
      }
      status = AuthStatus.retryRequired;
      message = checkingServer
          ? '로그인 상태를 확인하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.'
          : '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        storageCleanupFailed ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_sessionVersion;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    _notify();
    bool saving = false;
    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!isCurrent(version)) return;
      saving = true;
      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } catch (e) {
      if (!isCurrent(version)) return;
      status = AuthStatus.signedOut;
      final failure = ApiFailure.from(e);
      message = saving
          ? '로그인 정보를 안전하게 저장하지 못했어요.'
          : failure.code == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : failure.message;
      if (saving) {
        try {
          await _storage.deleteAccessToken();
        } catch (_) {
          storageCleanupFailed = true;
        }
        if (!isCurrent(version)) return;
      }
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();
    try {
      final me = await _memberApi.fetchMe();
      if (!isCurrent(version)) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } catch (e) {
      if (!isCurrent(version)) return;
      final error = ApiFailure.from(e);
      if (isExpiredCode(error.code)) {
        await expireSession(expectedVersion: version);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  void updateMember(MemberInfo updated, {required int expectedVersion}) {
    if (!isCurrent(expectedVersion) || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  Future<void> handleFailure(Object e, int version) async {
    if (isExpiredCode(ApiFailure.from(e).code)) {
      await expireSession(expectedVersion: version);
    }
  }

  Future<void> expireSession({required int expectedVersion}) async {
    if (!isCurrent(expectedVersion) ||
        status == AuthStatus.signedOut ||
        storageCleanupInProgress) {
      return;
    }
    await _clear(expired: true);
  }

  Future<void> logout() => _clear(expired: false);
  Future<void> retryStorageCleanup() => _clear(expired: false);
  Future<void> _clear({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion;
    storageCleanupInProgress = true;
    storageCleanupFailed = false;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      try {
        await _tokenWrite;
      } catch (_) {}
      await _storage.deleteAccessToken();
    } catch (_) {
      if (isCurrent(version)) {
        storageCleanupFailed = true;
        message = '인증 정보 삭제에 실패했어요. 저장소 정리를 다시 시도해 주세요.';
      }
    } finally {
      if (isCurrent(version)) {
        storageCleanupInProgress = false;
        _notify();
      }
    }
  }

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
