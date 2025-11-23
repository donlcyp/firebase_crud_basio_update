import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          return userCredential.user;
        } catch (e) {
          print('Credential error: $e');
          // Even if there's an error, check if user is logged in
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            return currentUser;
          }
          return null;
        }
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // EMAIL/PASSWORD REGISTRATION
  Future<User?> registerWithEmail(String email, String password) async {
    try{
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  } 

  // EMAIL/PASSWORD lOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try{
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }
  
  // SIGN OUT
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

  // FORGOT PASSWORD
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password Reset Error: $e');
      rethrow;
    }
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}