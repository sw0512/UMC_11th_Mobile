import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/submit_status.dart';

import 'helpers/week6_fixture_services.dart';

const request = CreateMemberRequest(
  email: 'demo@example.com',
  password: 'MockPass123!',
  nickname: '무비',
);
Future<void> ready(SignUpViewModel vm) async {
  vm.onNicknameChanged(request.nickname);
  vm.onEmailChanged(request.email);
  await vm.checkNickname(request.nickname);
  await vm.checkEmail(request.email);
}

void main() {
  test('signup local constraints', () {
    expect(SignUpViewModel.validateNickname('x' * 13), isNotNull);
    for (final password in [
      'short',
      'password123',
      'PASSWORD123!',
      'Password123',
      'Password!',
    ]) {
      expect(SignUpViewModel.validatePassword(password), isNotNull);
    }
    expect(SignUpViewModel.validatePassword('MockPass123!'), isNull);
  });
  test('signup blocks duplicate submits and field changes while pending, publishes created ID', () async {
    final service = CheckFixtureService()
      ..signupPending = Completer<CommonResponse<SignUpResult>>();
    final vm = SignUpViewModel(service);
    await ready(vm);
    final pending = vm.submit(request);
    await vm.submit(request);
    expect(service.signups, 1);
    expect(vm.isSubmitting, true);
    expect(vm.canCheckNickname, false);
    vm.onNicknameChanged('다른값');
    service.signupPending!.complete(
      const CommonResponse(
        isSuccess: true,
        code: 'COMMON201',
        message: 'ok',
        result: SignUpResult(
          memberId: 77,
          email: 'demo@example.com',
          nickname: '무비',
        ),
      ),
    );
    await pending;
    expect(vm.createdMemberId, 77);
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
  });
  test('only password-specific 400 attaches to field; other 400 and final 409 use snackbar', () async {
    final service = CheckFixtureService();
    final vm = SignUpViewModel(service);
    await ready(vm);
    service.signupFailure = const ApiFailure(
      '비밀번호 형식 오류',
      status: 400,
      code: 'COMMON400',
    );
    await vm.submit(request);
    expect(vm.passwordErrorText, '비밀번호 형식 오류');
    expect(vm.snackbarMessage, isNull);
    vm.onPasswordChanged();
    expect(vm.passwordErrorText, isNull);
    service.signupFailure = const ApiFailure(
      '이메일 형식 오류',
      status: 400,
      code: 'COMMON400',
    );
    await vm.submit(request);
    expect(vm.passwordErrorText, isNull);
    expect(vm.snackbarMessage, '이메일 형식 오류');
    service.signupFailure = const ApiFailure(
      '이미 사용 중인 이메일입니다.',
      status: 409,
      code: 'COMMON409',
    );
    await vm.submit(request);
    expect(vm.snackbarMessage, '이미 사용 중인 이메일입니다.');
    expect(vm.createdMemberId, isNull);
    vm.onEmailChanged('other@example.com');
    expect(vm.snackbarMessage, isNull);
    expect(vm.emailCheckStatus, CheckStatus.idle);
    vm.dispose();
  });
  test('signup ignores result after disposal', () async {
    final service = CheckFixtureService()
      ..signupPending = Completer<CommonResponse<SignUpResult>>();
    final vm = SignUpViewModel(service);
    await ready(vm);
    final pending = vm.submit(request);
    vm.dispose();
    service.signupPending!.complete(
      const CommonResponse(
        isSuccess: true,
        code: 'COMMON201',
        message: 'ok',
        result: SignUpResult(
          memberId: 77,
          email: 'demo@example.com',
          nickname: '무비',
        ),
      ),
    );
    await pending;
    expect(vm.createdMemberId, isNull);
  });
}
