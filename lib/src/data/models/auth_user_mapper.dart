import 'package:firebase_auth/firebase_auth.dart' show User;
import '../../domain/entities/auth_user.dart';

/// Extension to map Firebase [User] to domain [AuthUser].
extension FirebaseUserMapper on User {
  AuthUser toDomain() {
    return AuthUser(
      id: uid,
      email: email ?? providerData.firstOrNull?.email ?? '',
      displayName: displayName,
      photoURL: photoURL,
      isEmailVerified: emailVerified,
      providerIds: providerData.map((p) => p.providerId).toList(),
    );
  }
}
