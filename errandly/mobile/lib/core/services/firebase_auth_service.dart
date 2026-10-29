import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final String idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? uid;

  GoogleAuthResult({
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.uid,
  });
}

class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  int? _resendToken;

  User? get currentUser => _auth.currentUser;

  /// Formats Nigerian or international numbers into standard E.164 (+234...) format.
  static String normalizePhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-()]'), '').trim();

    if (clean.startsWith('+')) {
      return clean;
    }

    if (clean.startsWith('234')) {
      return '+$clean';
    }

    if (clean.startsWith('0') && clean.length == 11) {
      return '+234${clean.substring(1)}';
    }

    if (clean.length == 10 && !clean.startsWith('0')) {
      return '+234$clean';
    }

    return clean.startsWith('+') ? clean : '+$clean';
  }

  /// Authenticate using Google Sign-In and retrieve Firebase & Google ID Tokens.
  Future<GoogleAuthResult?> signInWithGoogle() async {
    try {
      debugPrint('[FirebaseAuth] Initiating Google Sign-In...');
      // 1. Trigger the native Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[FirebaseAuth] Google Sign-In canceled by user.');
        return null;
      }

      // 2. Obtain auth details (idToken + accessToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('[FirebaseAuth] Google auth details received for: ${googleUser.email}');

      // 3. Create a Google credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      final String? idToken = await firebaseUser?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to obtain Firebase ID token after Google sign-in.');
      }

      return GoogleAuthResult(
        idToken: idToken,
        accessToken: googleAuth.accessToken,
        email: firebaseUser?.email ?? googleUser.email,
        displayName: firebaseUser?.displayName ?? googleUser.displayName,
        photoUrl: firebaseUser?.photoURL ?? googleUser.photoUrl,
        uid: firebaseUser?.uid,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuth] FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Google Sign-In failed.');
    } catch (e) {
      debugPrint('[FirebaseAuth] Generic error during Google sign-in: $e');
      // Fallback: Attempt signInWithProvider for web or custom tabs if native GoogleSignIn fails
      try {
        debugPrint('[FirebaseAuth] Attempting signInWithProvider fallback...');
        final provider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithProvider(provider);
        final User? firebaseUser = userCredential.user;
        final String? idToken = await firebaseUser?.getIdToken();

        if (idToken != null) {
          return GoogleAuthResult(
            idToken: idToken,
            email: firebaseUser?.email,
            displayName: firebaseUser?.displayName,
            photoUrl: firebaseUser?.photoURL,
            uid: firebaseUser?.uid,
          );
        }
      } catch (fallbackError) {
        debugPrint('[FirebaseAuth] signInWithProvider fallback also failed: $fallbackError');
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Sends an SMS verification code via Firebase Phone Authentication.
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    Function(String idToken)? onAutoVerified,
    VoidCallback? onCodeAutoRetrievalTimeout,
  }) async {
    final formatted = normalizePhoneNumber(phoneNumber);
    debugPrint('[FirebaseAuth] Sending verification SMS to $formatted');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formatted,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[FirebaseAuth] Phone verification completed automatically.');
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            final token = await userCredential.user?.getIdToken();
            if (token != null && onAutoVerified != null) {
              onAutoVerified(token);
            }
          } catch (e) {
            debugPrint('[FirebaseAuth] Auto signInWithCredential error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[FirebaseAuth] Verification failed: ${e.code} - ${e.message}');
          String message = e.message ?? 'Phone verification failed.';
          if (e.code == 'invalid-phone-number') {
            message = 'The phone number format is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests sent from this device. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Please contact support or try later.';
          } else if (e.code == 'network-request-failed') {
            message = 'Network error. Please check your internet connection.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[FirebaseAuth] Code sent to $formatted (id: $verificationId)');
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[FirebaseAuth] Code auto-retrieval timed out for id: $verificationId');
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout();
          }
        },
      );
    } catch (e) {
      debugPrint('[FirebaseAuth] Exception calling verifyPhoneNumber: $e');
      onError(e.toString());
    }
  }

  /// Verifies the 6-digit SMS OTP code entered by the user, signs in, and returns the Firebase ID token.
  Future<String?> verifySmsCodeAndGetIdToken({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Failed to sign in with SMS verification code.');
    }

    final idToken = await user.getIdToken();
    return idToken;
  }

  /// Get current Firebase ID token.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _auth.currentUser?.getIdToken(forceRefresh);
  }

  /// Signs out of Firebase Auth and Google Sign-In.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
