import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
  });

  group('RememberMeService', () {
    test(
      'load() returns true by default when no value has been saved',
      () async {
        when(
          () => mockStorage.read(key: 'auth_remember_me'),
        ).thenAnswer((_) async => null);

        final service = RememberMeService(storageService: mockStorage);
        expect(await service.load(), isTrue);
      },
    );

    test('save(true) then load() returns true', () async {
      when(
        () => mockStorage.write(key: 'auth_remember_me', value: 'true'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.read(key: 'auth_remember_me'),
      ).thenAnswer((_) async => 'true');

      final service = RememberMeService(storageService: mockStorage);
      await service.save(value: true);
      expect(await service.load(), isTrue);

      verify(
        () => mockStorage.write(key: 'auth_remember_me', value: 'true'),
      ).called(1);
    });

    test('save(false) then load() returns false', () async {
      when(
        () => mockStorage.write(key: 'auth_remember_me', value: 'false'),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.read(key: 'auth_remember_me'),
      ).thenAnswer((_) async => 'false');

      final service = RememberMeService(storageService: mockStorage);
      await service.save(value: false);
      expect(await service.load(), isFalse);

      verify(
        () => mockStorage.write(key: 'auth_remember_me', value: 'false'),
      ).called(1);
    });

    test('clear() delegates to storage provider', () async {
      when(
        () => mockStorage.delete(key: 'auth_remember_me'),
      ).thenAnswer((_) async {});

      final service = RememberMeService(storageService: mockStorage);
      await service.clear();

      verify(() => mockStorage.delete(key: 'auth_remember_me')).called(1);
    });
  });
}
