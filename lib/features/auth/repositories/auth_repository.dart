import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../models/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login time
      if (userCredential.user != null) {
        await _updateLastLoginTime(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document in Firestore
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: email.trim(),
          displayName: displayName,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google.
  ///
  /// Note: requires the Android SHA-1 fingerprint of your debug/release
  /// keystore to be registered in the Firebase console (Project Settings →
  /// your Android app → Add fingerprint), otherwise [signInWithCredential]
  /// returns an `invalid-credential` error.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final user = UserModel(
        id: uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  /// Create or update user document (for Google Sign-In)
  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing user
        await docRef.update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Create new user
        await _createUserDocument(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          phoneNumber: user.phoneNumber,
          profileImageUrl: user.photoURL,
        );
      }
    } catch (e) {
      throw Exception('Failed to create/update user document: ${e.toString()}');
    }
  }

  /// Update last login time. Best-effort — never blocks the auth flow.
  Future<void> _updateLastLoginTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Silent — not critical for UX.
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      final updates = <String, dynamic>{};

      if (displayName != null) {
        await user.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete Firestore user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
