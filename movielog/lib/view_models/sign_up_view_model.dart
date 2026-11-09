import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/sign_up_service.dart';
import '../data/models/create_member_request.dart';
import '../data/models/api_failure.dart';
import 'submit_status.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class _CheckField {
  String current = '';
  String? duplicated;
  CheckStatus status = CheckStatus.idle;
  int version = 0;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;
  final _nickname = _CheckField();
  final _email = _CheckField();
  bool _disposed = false;
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;
  bool get isSubmitting => submitStatus == SubmitStatus.submitting;
  void onPasswordChanged() {
    if (_disposed || isSubmitting) return;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
  }

  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,}$')
        .hasMatch(v)) {
      return '비밀번호는 대문자·소문자·숫자·특수문자를 포함한 8자 이상이어야 합니다.';
    }
    return null;
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        isSubmitting ||
        !checksAvailable ||
        request.nickname.trim() != _nickname.current ||
        request.email.trim() != _email.current) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (id == null || id < 1 || !response.isSuccess) {
        throw const ApiFailure('가입 결과를 확인하지 못했습니다. 서버 상태를 확인해 주세요.');
      }
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } catch (e) {
      if (_disposed) return;
      final error = ApiFailure.from(e);
      submitStatus = SubmitStatus.error;
      if (error.status == 400 && error.message.contains('비밀번호')) {
        passwordErrorText = error.message;
      } else {
        snackbarMessage = error.message;
      }
    }
    if (!_disposed) notifyListeners();
  }

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _error(_nickname, '닉네임');
  String? get emailErrorText => _error(_email, '이메일');
  bool get canCheckNickname =>
      validateNickname(_nickname.current) == null && _canCheck(_nickname);
  bool get canCheckEmail =>
      validateEmail(_email.current) == null && _canCheck(_email);
  bool get checksAvailable =>
      _nickname.status == CheckStatus.available &&
      _email.status == CheckStatus.available;
  bool _canCheck(_CheckField field) =>
      !_disposed &&
      !isSubmitting &&
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;
  static String? validateNickname(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '닉네임을 입력해주세요.';
    if (v.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    if (v.length > 12) return '닉네임은 12자 이하여야 합니다.';
    return null;
  }

  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '이메일을 입력해주세요.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _error(_CheckField field, String label) => switch (field.status) {
    CheckStatus.duplicated => '이미 사용 중인 $label입니다.',
    CheckStatus.error => '$label 중복 확인에 실패했습니다. 다시 시도해 주세요.',
    _ => null,
  };
  void _changed(_CheckField field, String value) {
    if (_disposed || isSubmitting) return;
    passwordErrorText = null;
    snackbarMessage = null;
    field.current = value.trim();
    field.version++;
    field.status = field.current == field.duplicated
        ? CheckStatus.duplicated
        : CheckStatus.idle;
    notifyListeners();
  }

  void onNicknameChanged(String value) => _changed(_nickname, value);
  void onEmailChanged(String value) => _changed(_email, value);
  Future<void> checkNickname(String value) =>
      _check(_nickname, value, canCheckNickname, _service.checkNickname);
  Future<void> checkEmail(String value) =>
      _check(_email, value, canCheckEmail, _service.checkEmail);
  Future<void> _check(
    _CheckField field,
    String value,
    bool allowed,
    Future<bool> Function(String) request,
  ) async {
    final requested = value.trim();
    if (!allowed || requested != field.current) return;
    final version = ++field.version;
    field.status = CheckStatus.checking;
    notifyListeners();
    try {
      final available = await request(requested);
      if (_disposed || version != field.version || field.current != requested) {
        return;
      }
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      if (!available) field.duplicated = requested;
    } on DioException {
      if (_disposed || version != field.version || field.current != requested) {
        return;
      }
      field.status = CheckStatus.error;
    } catch (_) {
      if (_disposed || version != field.version) return;
      field.status = CheckStatus.error;
    }
    if (!_disposed && version == field.version) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
