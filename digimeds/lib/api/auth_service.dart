// import 'package:firebase_auth/firebase_auth.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // 🔹 Sign In
//   Future<String?> signIn(String email, String password) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return null; // success
//     } on FirebaseAuthException catch (e) {
//       return _handleAuthError(e);
//     } catch (e) {
//       return "An unexpected error occurred. Please try again.";
//     }
//   }

//   // 🔹 Sign Up
//   Future<String?> signUp(String email, String password) async {
//     try {
//       await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return null; // success
//     } on FirebaseAuthException catch (e) {
//       return _handleAuthError(e);
//     } catch (e) {
//       return "An unexpected error occurred. Please try again.";
//     }
//   }

//   // 🔹 Sign Out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // 🔹 Stream for auth state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // 🔹 Error Handler
//   String _handleAuthError(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'user-not-found':
//         return "No account found for this email. Please sign up first.";
//       case 'wrong-password':
//         return "Incorrect password. Please try again.";
//       case 'email-already-in-use':
//         return "This email is already registered. Try logging in instead.";
//       case 'invalid-email':
//         return "Please enter a valid email address.";
//       case 'weak-password':
//         return "Password should be at least 6 characters long.";
//       case 'network-request-failed':
//         return "Please check your internet connection and try again.";
//       default:
//         return "Something went wrong. Please try again.";
//     }
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Sign In (Renamed to match LoginScreen)
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // 🔹 Sign Up (Renamed to match SignupScreen & Added Name)
  Future<String?> signUpWithEmail({
    required String name, // Added name parameter
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update the Display Name immediately
      await userCredential.user?.updateDisplayName(name);

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // 🔹 Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 🔹 Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔹 Error Handler (Your existing robust logic)
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No account found for this email. Please sign up first.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'email-already-in-use':
        return "This email is already registered. Try logging in instead.";
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'weak-password':
        return "Password should be at least 6 characters long.";
      case 'network-request-failed':
        return "Please check your internet connection and try again.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}
