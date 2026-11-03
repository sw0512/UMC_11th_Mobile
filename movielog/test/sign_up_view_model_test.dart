import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'helpers/week6_fixture_services.dart';

void main() {
  test('available is invalidated; duplicate cache restores error without another request', () async {
    final service = CheckFixtureService();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('영화광');
    await vm.checkNickname('영화광');
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    vm.onNicknameChanged('다른닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    service.available = false;
    await vm.checkNickname('다른닉네임');
    expect(vm.canCheckNickname, false);
    await vm.checkNickname('다른닉네임');
    expect(service.nicknameCalls, 2);
    vm.onNicknameChanged('변경');
    expect(vm.nicknameErrorText, isNull);
    expect(vm.canCheckNickname, true);
    vm.onNicknameChanged(' 다른닉네임 ');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.nicknameErrorText, contains('이미 사용 중'));
    expect(service.nicknameCalls, 2);
    vm.dispose();
  });
  test('nickname and email requests do not invalidate each other', () async {
    final service = CheckFixtureService()
      ..nicknamePending = Completer<bool>()
      ..emailPending = Completer<bool>();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('영화광');
    vm.onEmailChanged('movie@example.com');
    final n = vm.checkNickname('영화광');
    final e = vm.checkEmail('movie@example.com');
    expect(vm.canCheckNickname, false);
    expect(vm.canCheckEmail, false);
    service.nicknamePending!.complete(true);
    service.emailPending!.complete(false);
    await Future.wait([n, e]);
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    expect(vm.emailCheckStatus, CheckStatus.duplicated);
    vm.onEmailChanged('other@example.com');
    vm.onEmailChanged('movie@example.com');
    expect(vm.canCheckEmail, false);
    expect(service.emailCalls, 1);
    vm.dispose();
  });
  test('late responses after edits and disposal are ignored', () async {
    final service = CheckFixtureService()..nicknamePending = Completer<bool>();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('예전값');
    final request = vm.checkNickname('예전값');
    vm.onNicknameChanged('새로운값');
    service.nicknamePending!.complete(false);
    await request;
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.nicknameErrorText, isNull);
    service.nicknamePending = Completer<bool>();
    final next = vm.checkNickname('새로운값');
    vm.dispose();
    service.nicknamePending!.complete(true);
    await next;
  });
  test('network error differs from duplicate and permits retry; invalid formats cannot request', () async {
    final service = CheckFixtureService()..fail = true;
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('a');
    expect(vm.canCheckNickname, false);
    vm.onEmailChanged('invalid');
    await vm.checkEmail('invalid');
    expect(service.emailCalls, 0);
    vm.onEmailChanged('valid@example.com');
    await vm.checkEmail('valid@example.com');
    expect(vm.emailCheckStatus, CheckStatus.error);
    expect(vm.emailErrorText, contains('실패'));
    expect(vm.canCheckEmail, true);
    service.fail = false;
    await vm.checkEmail('valid@example.com');
    expect(vm.emailCheckStatus, CheckStatus.available);
    vm.dispose();
  });
}
