import 'package:flutter_test/flutter_test.dart';
import 'package:remote_auth_module/src/services/remember_me_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RememberMeService', () {
    setUp(() {
      // Reset shared preferences state between tests
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'load() returns true by default when no value has been saved',
      () async {
        final service = RememberMeService();
        expect(await service.load(), isTrue);
      },
    );

    test('save(true) then load() returns true', () async {
      final service = RememberMeService();
      await service.save(value: true);
      expect(await service.load(), isTrue);
    });

    test('save(false) then load() returns false', () async {
      final service = RememberMeService();
      await service.save(value: false);
      expect(await service.load(), isFalse);
    });

    test('clear() resets to default true', () async {
      final service = RememberMeService();
      await service.save(value: false);
      await service.clear();
      expect(await service.load(), isTrue);
    });
  });
}
