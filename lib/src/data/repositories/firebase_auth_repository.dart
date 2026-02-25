import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/core/logging/app_logger.dart';
import 'package:remote_auth_module/src/data/models/auth_user_dto.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/domain/failures/auth_failure.dart';
import 'package:remote_auth_module/src/domain/repositories/auth_repository.dart';
import 'package:remote_auth_module/src/services/auth_providers.dart';
import 'package:remote_auth_module/src/services/firestore_user_service.dart';
import 'package:remote_auth_module/src/services/phone_auth_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  factory FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String? serverClientId,
    String? clientId,
    bool createUserCollection = false,
    String usersCollectionName = 'users',
  }) {
    final effectiveAuth = auth ?? fb.FirebaseAuth.instance;
    return FirebaseAuthRepository._(
      auth: effectiveAuth,
      createUserCollection: createUserCollection,
      emailProvider: EmailAuthProvider(auth: effectiveAuth),
      googleService: GoogleAuthService(
        auth: effectiveAuth,
        serverClientId: serverClientId,
        clientId: clientId,
      ),
      phoneService: PhoneAuthService(auth: effectiveAuth),
      firestoreService:
          createUserCollection && firestore != null
              ? FirestoreUserService(
                firestore: firestore,
                usersCollection: usersCollectionName,
              )
              : null,
    );
  }

  FirebaseAuthRepository._({
    required fb.FirebaseAuth auth,
    required bool createUserCollection,
    required EmailAuthProvider emailProvider,
    required GoogleAuthService googleService,
    required PhoneAuthService phoneService,
    FirestoreUserService? firestoreService,
  }) : _auth = auth,
       _createUserCollection = createUserCollection,
       _emailProvider = emailProvider,
       _googleService = googleService,
       _phoneService = phoneService,
       _firestoreService = firestoreService;

  final fb.FirebaseAuth _auth;
  final EmailAuthProvider _emailProvider;
  final GoogleAuthService _googleService;
  final PhoneAuthService _phoneService;
  final FirestoreUserService? _firestoreService;
  final bool _createUserCollection;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map((user) => user?.toDomain());
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> getCurrentUser() async {
    try {
      return Right(_auth.currentUser?.toDomain());
    } catch (e, st) {
      AppLogger.e('getCurrentUser unexpected error', error: e, stackTrace: st);
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> reloadCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return const Right(null);
      }

      await currentUser.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        await _syncUserDocument(refreshedUser);
        return Right(refreshedUser.toDomain());
      }
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.e('reloadCurrentUser FirebaseAuthException', error: e);
      return Left(mapFirebaseAuthCode(e.code));
    } catch (e, st) {
      AppLogger.e(
        'reloadCurrentUser unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> initializeSession() async {
    try {
      if (!kIsWeb) {
        await _googleService.signInSilently();
      }
    } catch (e) {
      AppLogger.w('Silent sign-in failed: $e', error: e);
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _syncUserDocument(user);
        return Right(user.toDomain());
      }
      return const Right(null);
    } catch (e, st) {
      AppLogger.e(
        'initializeSession unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final authUser = await _emailProvider.signIn(
        email: email,
        password: password,
      );

      if (_auth.currentUser != null) {
        await _syncUserDocument(_auth.currentUser!);
      }
      return Right(authUser);
    } on AuthFailure catch (f) {
      AppLogger.e('signInWithEmailAndPassword failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'signInWithEmailAndPassword unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final authUser = await _emailProvider.register(
        email: email,
        password: password,
      );

      if (_auth.currentUser != null) {
        await _syncUserDocument(_auth.currentUser!);
      }
      return Right(authUser);
    } on AuthFailure catch (f) {
      AppLogger.e('signUpWithEmailAndPassword failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'signUpWithEmailAndPassword unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle() async {
    try {
      final authUser = await _googleService.signIn();

      if (_auth.currentUser != null) {
        await _syncUserDocument(_auth.currentUser!);
      }
      return Right(authUser);
    } on AuthFailure catch (f) {
      AppLogger.d('signInWithGoogle failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'signInWithGoogle unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        return const Left(UnexpectedAuthFailure('anonymous-sign-in-failed'));
      }
      await _syncUserDocument(user);
      return Right(user.toDomain());
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.e('signInAnonymously failed', error: e);
      return Left(mapFirebaseAuthCode(e.code));
    } catch (e, st) {
      AppLogger.e(
        'signInAnonymously unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthFailure exception) onVerificationFailed,
    required void Function(AuthUser user) onVerificationCompleted,
  }) async {
    return _phoneService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: (user) async {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          await _syncUserDocument(fbUser);
        }
        onVerificationCompleted(user);
      },
    );
  }

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final authUser = await _phoneService.signInWithSmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      if (_auth.currentUser != null) {
        await _syncUserDocument(_auth.currentUser!);
      }
      return Right(authUser);
    } on AuthFailure catch (f) {
      AppLogger.e('signInWithSmsCode failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'signInWithSmsCode unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _googleService.signOut();
    } catch (e) {
      AppLogger.w('Google signOut failed non-critically', error: e);
    }

    try {
      await _emailProvider.signOut();
      return const Right(unit);
    } on AuthFailure catch (f) {
      AppLogger.e('signOut failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e('signOut unexpected error', error: e, stackTrace: st);
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendEmailVerification() async {
    try {
      await _emailProvider.sendEmailVerification();
      return const Right(unit);
    } on AuthFailure catch (f) {
      AppLogger.e('sendEmailVerification failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'sendEmailVerification unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _emailProvider.sendPasswordReset(email: email);
      return const Right(unit);
    } on AuthFailure catch (f) {
      AppLogger.e('sendPasswordResetEmail failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'sendPasswordResetEmail unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateDisplayName({
    required String name,
  }) async {
    try {
      await _emailProvider.updateDisplayName(name);
      if (_auth.currentUser != null) {
        await _syncUserDocument(_auth.currentUser!);
      }
      return const Right(unit);
    } on AuthFailure catch (f) {
      AppLogger.e('updateDisplayName failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e(
        'updateDisplayName unexpected error',
        error: e,
        stackTrace: st,
      );
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _emailProvider.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(unit);
    } on AuthFailure catch (f) {
      AppLogger.e('updatePassword failed: ${f.message}');
      return Left(f);
    } catch (e, st) {
      AppLogger.e('updatePassword unexpected error', error: e, stackTrace: st);
      return Left(UnexpectedAuthFailure(e.toString()));
    }
  }

  Future<void> _syncUserDocument(fb.User user) async {
    if (_createUserCollection && _firestoreService != null) {
      await _firestoreService.createOrUpdateUserDocument(user);
    }
  }
}
