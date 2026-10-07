import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/genre_preference.dart';

import 'helpers/preference_test_store.dart';

void main() {
  setUp(resetPreferenceStore);

  test('defaults to all genres without a saved value', () async {
    expect(await GenrePreference().read(), '전체');
  });

  test(
    'another preference instance reads the saved genre and clear removes it',
    () async {
      await GenrePreference().save('SF');
      final preferences = GenrePreference();
      expect(await preferences.read(), 'SF');
      await preferences.clear();
      expect(await GenrePreference().read(), '전체');
    },
  );
}
