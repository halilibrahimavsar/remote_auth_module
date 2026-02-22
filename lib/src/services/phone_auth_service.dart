import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:remote_auth_module/src/core/exceptions/auth_exceptions.dart';
import 'package:remote_auth_module/src/domain/entities/auth_user.dart';
import 'package:remote_auth_module/src/data/models/auth_user_mapper.dart';

/// Service to handle Firebase Phone Authentication.
class PhoneAuthService {
  final fb.FirebaseAuth _auth;

  PhoneAuthService({required fb.FirebaseAuth auth}) : _auth = auth;

  /// Starts the phone verification process.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(AuthException exception) onVerificationFailed,
    required void Function(AuthUser user) onVerificationCompleted,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          log('[PhoneAuthService] Auto-verification completed');
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final user = userCredential.user;
            if (user != null) {
              onVerificationCompleted(user.toDomain());
            }
          } catch (e) {
            log('[PhoneAuthService] Auto-sign-in failed: $e');
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          log('[PhoneAuthService] Verification failed: ${e.code}');
          onVerificationFailed(mapFirebaseAuthCode(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          log('[PhoneAuthService] Code sent: $verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          log('[PhoneAuthService] Auto-retrieval timeout: $verificationId');
        },
      );
    } catch (e) {
      log('[PhoneAuthService] Unexpected error: $e');
      onVerificationFailed(GenericAuthException(cause: e));
    }
  }

  /// Signs in with an SMS code.
  Future<AuthUser> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const GenericAuthException(cause: 'missing-phone-auth-user');
      }
      return user.toDomain();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthCode(e.code);
    } catch (e) {
      throw GenericAuthException(cause: e);
    }
  }
}
