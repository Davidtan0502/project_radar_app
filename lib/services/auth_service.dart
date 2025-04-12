import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current user's UID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if a user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the current user's role
  Future<String?> getUserRole() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if current user is an admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // Create a new admin user (run once manually)
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create user document in Firestore with admin role
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // 3. Send email verification
      await userCredential.user?.sendEmailVerification();
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  // Regular user registration
  Future<void> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Add to pending registrations (for admin approval)
      await _firestore.collection('pending_registrations').add({
        'uid': userCredential.user?.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Send email verification
      await userCredential.user?.sendEmailVerification();
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // User login
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is approved
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.data()?['status'] != 'active') {
        await _auth.signOut();
        throw Exception('Account not yet approved by admin');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // User logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}