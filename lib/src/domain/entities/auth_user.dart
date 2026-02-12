import 'package:flutter/foundation.dart';

/// Immutable representation of an authenticated user.
///
/// This is the domain entity exposed by the package.
/// It wraps the essential user information without leaking Firebase types.
@immutable
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.isEmailVerified,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoURL == other.photoURL &&
          isEmailVerified == other.isEmailVerified;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoURL, isEmailVerified);

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName, verified: $isEmailVerified)';
}
