import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert the auth state changes stream to a broadcast stream
  final Stream<User?> _userStream =
      FirebaseAuth.instance.authStateChanges().asBroadcastStream();

  // Getter for the user stream
  Stream<User?> get user => _userStream;

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!result.user!.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }

      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<void> registerWithEmailPassword(
      String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
