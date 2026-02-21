import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_auth_module/src/services/firestore_user_service.dart';

void main() {
  late FirestoreUserService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreUserService(firestore: fakeFirestore);
  });

  group('FirestoreUserService', () {
    test('updateUserDocument throws ArgumentError if data is empty', () async {
      expect(() => service.updateUserDocument('uid', {}), throwsArgumentError);
    });

    test(
      'updateUserDocument throws ArgumentError if updating restricted fields',
      () async {
        expect(
          () => service.updateUserDocument('uid', {'email': 'hacker@test.com'}),
          throwsArgumentError,
        );

        expect(
          () => service.updateUserDocument('uid', {'uid': 'new_uid'}),
          throwsArgumentError,
        );

        expect(
          () => service.updateUserDocument('uid', {'createdAt': 'now'}),
          throwsArgumentError,
        );
      },
    );

    test('updateUserDocument allows valid updates', () async {
      // Create initial doc
      await fakeFirestore.collection('users').doc('uid').set({
        'uid': 'uid',
        'email': 'user@test.com',
      });

      await service.updateUserDocument('uid', {'bio': 'Hello World'});

      final doc = await fakeFirestore.collection('users').doc('uid').get();
      final data = doc.data();
      expect(data, isNotNull);
      final userData = data!;

      expect(userData['bio'], 'Hello World');
      expect(userData.containsKey('updatedAt'), isTrue);
      expect(userData['email'], 'user@test.com'); // Ensure not modified
    });
  });
}
