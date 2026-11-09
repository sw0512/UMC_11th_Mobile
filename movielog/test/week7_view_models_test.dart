import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/submit_status.dart';

import 'helpers/week6_fixture_services.dart';
import 'helpers/tmdb_fixture_service.dart';

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
  test('v6 local constraints and memory-only session', () {
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
    final session = LearningMemberSession();
    expect(session.memberId, isNull);
    session.setMemberId(77);
    expect(session.memberId, 77);
    session.clear();
    expect(session.memberId, isNull);
    session.dispose();
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
  test('detail writes actual TMDB ID and created member, prevents duplicate create', () async {
    final service = RatingsFixtureService()..writeGate = Completer<void>();
    final vm = MovieDetailViewModel(service, 77, movie(550));
    final pending = vm.createRating(score: 5, comment: '후기');
    await vm.createRating(score: 5);
    expect(service.creates, 1);
    expect(service.createRequests.single.movieId, 550);
    expect(service.writeMembers, [77]);
    service.writeGate!.complete();
    await pending;
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
    final missing = MovieDetailViewModel(service, null, movie(550));
    await expectLater(
      missing.createRating(score: 4),
      throwsA(isA<ApiFailure>()),
    );
    expect(service.creates, 1);
    missing.dispose();
  });
  test('saved update followed by GET failure completes successfully and retries only GET', () async {
    final service = RatingsFixtureService();
    final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
    await vm.load();
    service.failReadAfterWrite = true;
    await vm.updateRating(ratingId: 1, score: 5, comment: '수정');
    expect(service.updates, 1);
    expect(vm.refreshWarning, contains('저장은 완료'));
    expect(vm.status, MyRatingsLoadStatus.error);
    expect(vm.isWriting, false);
    service.failure = null;
    await vm.load();
    expect(service.updates, 1);
    expect(vm.refreshWarning, isNull);
    expect(vm.ratings.single.rating.score, 5);
    vm.dispose();
  });
  test('write failure is not confused with refresh failure and 403/404 reconcile GET', () async {
    final service = RatingsFixtureService();
    final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
    await vm.load();
    for (final code in [400, 403, 404, 409]) {
      final before = service.members.length;
      service.writeFailure = ApiFailure(
        '서버 안내 $code',
        code: 'COMMON$code',
        status: code,
      );
      await expectLater(
        vm.updateRating(ratingId: 1, score: 4),
        throwsA(
          isA<ApiFailure>().having((e) => e.message, 'message', '서버 안내 $code'),
        ),
      );
      expect(
        service.members.length,
        before + ([403, 404].contains(code) ? 1 : 0),
      );
      expect(vm.refreshWarning, isNull);
      expect(vm.isWriting, false);
    }
    vm.dispose();
  });
  test('bulk delete snapshots selection, removes only successes and retains failures for retry', () async {
    final service = RatingsFixtureService()
      ..items = [sampleRating(1, 550), sampleRating(2, 680)]
      ..deleteFailures.add(2);
    final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
    await vm.load();
    vm.toggleEditing();
    vm.toggleSelected(1);
    vm.toggleSelected(2);
    final result = await vm.deleteSelected();
    expect(result, contains('1개 삭제, 1개'));
    expect(vm.ratings.map((r) => r.rating.ratingId), [2]);
    expect(vm.selectedRatingIds, {2});
    expect(vm.editing, true);
    service.deleteFailures.clear();
    await vm.deleteSelected();
    expect(vm.ratings, isEmpty);
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(vm.editing, false);
    expect(vm.selectedRatingIds, isEmpty);
    vm.dispose();
  });
  test(
    'cancel editing clears selection; unknown rating cannot be written',
    () async {
      final service = RatingsFixtureService();
      final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
      await vm.load();
      vm.toggleEditing();
      vm.toggleSelected(1);
      vm.toggleEditing();
      expect(vm.selectedRatingIds, isEmpty);
      expect(service.deletes, isEmpty);
      await expectLater(vm.deleteRating(999), throwsA(isA<ApiFailure>()));
      expect(service.deletes, isEmpty);
      vm.dispose();
    },
  );
  test('single delete maintains busy state through refresh and last row becomes empty', () async {
    final service = RatingsFixtureService()..writeGate = Completer<void>();
    final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
    await vm.load();
    final pending = vm.deleteRating(1);
    expect(vm.isWriting, true);
    await expectLater(vm.deleteRating(1), throwsA(isA<ApiFailure>()));
    expect(service.deletes, [1]);
    service.writeGate!.complete();
    await pending;
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(vm.isWriting, false);
    vm.dispose();
  });
}
