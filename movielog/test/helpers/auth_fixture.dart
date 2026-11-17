import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/data/models/rating_dto.dart';

class MemoryTokenStorage implements TokenStorage {
  String? token;
  Object? readFailure;
  Object? writeFailure;
  Object? deleteFailure;
  Completer<void>? writeGate;
  Completer<void>? deleteGate;
  int reads = 0, writes = 0, deletes = 0;
  @override
  Future<String?> readAccessToken() async {
    reads++;
    if (readFailure != null) throw readFailure!;
    return token;
  }

  @override
  Future<void> saveAccessToken(String value) async {
    writes++;
    await writeGate?.future;
    if (writeFailure != null) throw writeFailure!;
    token = value;
  }

  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    await deleteGate?.future;
    if (deleteFailure != null) throw deleteFailure!;
    token = null;
  }
}

MemberInfo fixtureMember({String nickname = '무비러버'}) => MemberInfo(
  email: 'demo@example.com',
  nickname: nickname,
  createdAt: DateTime.utc(2026, 10, 10),
);

class AuthFixtureService extends AuthApiService {
  AuthFixtureService() : super(Dio());
  Object? failure;
  Completer<LoginResult>? gate;
  int calls = 0;
  LoginRequest? request;
  @override
  Future<LoginResult> login(LoginRequest value) async {
    calls++;
    request = value;
    if (failure != null) throw failure!;
    return gate?.future ??
        const LoginResult(nickname: '무비러버', accessToken: 'test-session-value');
  }
}

class MemberFixtureService extends MemberApiService {
  MemberFixtureService() : super(Dio());
  Object? failure;
  Completer<MemberInfo>? gate;
  int gets = 0, patches = 0;
  String? lastNickname;
  @override
  Future<MemberInfo> fetchMe() async {
    gets++;
    if (failure != null) throw failure!;
    return gate?.future ?? fixtureMember();
  }

  @override
  Future<MemberInfo> updateNickname(String value) async {
    patches++;
    lastNickname = value;
    if (failure != null) throw failure!;
    return gate?.future ?? fixtureMember(nickname: value);
  }
}

AuthViewModel signedInAuth() =>
    AuthViewModel(
        AuthFixtureService(),
        MemberFixtureService(),
        MemoryTokenStorage(),
      )
      ..status = AuthStatus.signedIn
      ..member = fixtureMember()
      ..memberStatus = MemberLoadStatus.success;
SessionRatings seededRatings(Iterable<RatingDto> items) {
  final auth = signedInAuth();
  final store = SessionRatings(auth);
  for (final r in items) {
    store.upsert(r, auth.sessionVersion);
  }
  return store;
}
