import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'helpers/auth_fixture.dart';
import 'helpers/preference_test_store.dart';

void main() {
  testWidgets('initial splash resolves to login when no stored token', (
    tester,
  ) async {
    resetPreferenceStore();
    final storage = MemoryTokenStorage();
    final auth = AuthViewModel(
      AuthFixtureService(),
      MemberFixtureService(),
      storage,
    );
    await tester.pumpWidget(MyApp(authViewModel: auth, tokenStorage: storage));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(auth.status, AuthStatus.signedOut);
  });
}
