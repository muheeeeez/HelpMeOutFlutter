import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP
  Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Check if email exists first to avoid the PigeonUserDetails error
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          return 'This email is already registered. Please login instead.';
        }
      } catch (e) {
        print('Error checking email: $e');
        // Continue with sign-up even if this check fails
      }

      // Create user in Firebase Auth with try-catch for each step
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          return 'This email is already registered. Please login instead.';
        }
        if (e.toString().contains('weak-password')) {
          return 'The password provided is too weak.';
        }
        if (e.toString().contains('invalid-email')) {
          return 'The email address is not valid.';
        }
        throw e; // Re-throw if it's not a known error
      }

      // Verify user was created
      User? user = userCredential.user;
      if (user == null) {
        // If for some reason userCredential.user is null, try to get current user
        user = _auth.currentUser;
        if (user == null) {
          return 'Sign-up failed. Could not create user.';
        }
      }

      // Now we have a user, let's save to Firestore
      try {
        // Create user record in Firestore with timestamp
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'videos': []
        });
      } catch (e) {
        print('Error saving to Firestore: $e');
        // Continue anyway since user is created in Auth
      }

      // Send verification email - handle separately
      try {
        await user.sendEmailVerification();
      } catch (e) {
        print('Error sending verification email: $e');
        // Continue anyway - the account is created
      }

      return 'Sign-up successful! Please check your email for verification.';
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please login instead.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return e.message ?? 'An error occurred during sign-up.';
      }
    } catch (e) {
      print('Unhandled error during sign-up: $e');

      // Special handling for the PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        // Check if user was actually created despite the error
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          // User exists, try to save to Firestore
          try {
            await _firestore.collection('users').doc(currentUser.uid).set({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'videos': []
            });

            // Try to send verification email
            try {
              await currentUser.sendEmailVerification();
            } catch (e) {
              print('Error sending verification in fallback: $e');
            }

            return 'Sign-up successful! Please check your email for verification.';
          } catch (firestoreError) {
            print('Error writing to Firestore in fallback: $firestoreError');
            return 'Account created but profile data could not be saved. Please contact support.';
          }
        }
      }

      return 'An error occurred during sign-up: ${e.toString()}';
    }
  }

  // LOGIN
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Try to sign in
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e.toString().contains('user-not-found')) {
          return 'No account found with this email. Please register first.';
        }
        if (e.toString().contains('wrong-password')) {
          return 'Incorrect password. Please try again.';
        }
        if (e.toString().contains('user-disabled')) {
          return 'This account has been disabled. Please contact support.';
        }
        throw e; // Re-throw if it's not a known error
      }

      // Check email verification
      User? user = userCredential?.user;
      if (user == null) {
        // Try to get current user if userCredential.user is null
        user = _auth.currentUser;
        if (user == null) {
          return 'Login failed. Please try again.';
        }
      }

      // Try to refresh user info
      try {
        await user.reload();
        // Get fresh user object after reload
        user = _auth.currentUser;
      } catch (e) {
        print('Error reloading user: $e');
        // Continue with potentially stale user data
      }

      // Check verification status
      if (user != null) {
        if (user.emailVerified) {
          return 'Login successful';
        } else {
          // Email not verified, send a new verification email
          try {
            await user.sendEmailVerification();
          } catch (e) {
            print('Error sending verification email: $e');
          }

          // Sign user out
          try {
            await _auth.signOut();
          } catch (e) {
            print('Error signing out unverified user: $e');
          }

          return 'Please verify your email before logging in. A new verification email has been sent.';
        }
      }

      return 'Login failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        default:
          return e.message ?? 'An error occurred during login.';
      }
    } catch (e) {
      print('Unhandled error during login: $e');

      // Special handling for PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        // Check if login actually succeeded despite the error
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          // Login succeeded, check verification
          if (currentUser.emailVerified) {
            return 'Login successful';
          } else {
            // Try to send verification email
            try {
              await currentUser.sendEmailVerification();
            } catch (verificationError) {
              print(
                  'Error sending verification in fallback: $verificationError');
            }

            // Sign out
            try {
              await _auth.signOut();
            } catch (signOutError) {
              print('Error signing out in fallback: $signOutError');
            }

            return 'Please verify your email before logging in. A new verification email has been sent.';
          }
        }
      }

      return 'An error occurred during login: ${e.toString()}';
    }
  }

  // FORGOT PASSWORD
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset link sent.';
    } catch (e) {
      return e.toString();
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // CHECK EMAIL VERIFICATION
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
