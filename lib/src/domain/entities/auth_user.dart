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

  /// The authentication provider IDs for this user (e.g., 'password', 'google.com').
  final List<String> providerIds;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.isEmailVerified,
    this.providerIds = const [],
  });

  /// Whether the user signed in via an OAuth provider (e.g., Google, Apple)
  /// rather than email/password only.
  bool get isOAuthUser => providerIds.any((p) => p != 'password');

  /// Compatibility alias for host apps that use a remote/user identifier name.
  String get remoteId => id;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
    List<String>? providerIds,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      providerIds: providerIds ?? this.providerIds,
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
          isEmailVerified == other.isEmailVerified &&
          listEquals(providerIds, other.providerIds);

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    photoURL,
    isEmailVerified,
    Object.hashAll(providerIds),
  );

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName, '
      'verified: $isEmailVerified, providers: $providerIds)';
}
