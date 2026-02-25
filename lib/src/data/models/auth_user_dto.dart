import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';

/// DTO that maps the Firebase [User] to the domain [AuthUser].
class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.displayName,
    this.photoURL,
    this.isAnonymous = false,
    this.providerIds = const [],
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final bool isAnonymous;
  final List<String> providerIds;

  factory AuthUserDto.fromFirebaseUser(User user) {
    return AuthUserDto(
      id: user.uid,
      email: user.email ?? user.providerData.firstOrNull?.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      providerIds: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      isEmailVerified: isEmailVerified,
      isAnonymous: isAnonymous,
      providerIds: providerIds,
    );
  }
}

/// Extension for existing code compatibility if still needed inside repository
extension FirebaseUserMapper on User {
  AuthUser toDomain() => AuthUserDto.fromFirebaseUser(this).toEntity();
}
