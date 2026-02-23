import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:remote_auth_module/src/data/repositories/firebase_auth_repository.dart';

class MockFirebaseAuth extends Mock implements fb.FirebaseAuth {}

class MockFirebaseUser extends Mock implements fb.User {}

class MockUserInfo extends Mock implements fb.UserInfo {}

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
  });

  group('FirebaseAuthRepository.reloadCurrentUser', () {
    test('returns null when there is no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final repository = FirebaseAuthRepository(auth: mockAuth);
      final result = await repository.reloadCurrentUser();

      expect(result, isNull);
    });

    test('reloads and returns updated user snapshot', () async {
      final initialUser = MockFirebaseUser();
      final refreshedUser = MockFirebaseUser();
      final info = MockUserInfo();

      when(() => info.providerId).thenReturn('password');

      when(() => initialUser.reload()).thenAnswer((_) async {});
      when(() => initialUser.uid).thenReturn('uid-123');
      when(() => initialUser.email).thenReturn('user@test.com');
      when(() => initialUser.displayName).thenReturn('User');
      when(() => initialUser.photoURL).thenReturn(null);
      when(() => initialUser.emailVerified).thenReturn(false);
      when(() => initialUser.isAnonymous).thenReturn(false);
      when(() => initialUser.providerData).thenReturn([info]);

      when(() => refreshedUser.uid).thenReturn('uid-123');
      when(() => refreshedUser.email).thenReturn('user@test.com');
      when(() => refreshedUser.displayName).thenReturn('User');
      when(() => refreshedUser.photoURL).thenReturn(null);
      when(() => refreshedUser.emailVerified).thenReturn(true);
      when(() => refreshedUser.isAnonymous).thenReturn(false);
      when(() => refreshedUser.providerData).thenReturn([info]);

      var currentUserReadCount = 0;
      when(() => mockAuth.currentUser).thenAnswer((_) {
        currentUserReadCount += 1;
        return currentUserReadCount == 1 ? initialUser : refreshedUser;
      });

      final repository = FirebaseAuthRepository(auth: mockAuth);
      final result = await repository.reloadCurrentUser();

      verify(() => initialUser.reload()).called(1);
      expect(result, isNotNull);
      expect(result!.id, 'uid-123');
      expect(result.isEmailVerified, isTrue);
    });
  });
}
