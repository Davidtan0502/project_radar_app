import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyContactService {
  final _firestore = FirebaseFirestore.instance;

  /// THIS is all new: points at users/{uid}/emergency_contacts
  CollectionReference<Map<String, dynamic>> get _contactsRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(
        code: 'NO_USER',
        message: 'No user signed in',
      );
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('emergency_contacts');
  }

  /// Load contacts for just the current user
  Future<List<Map<String, String>>> loadContacts() async {
    final snap = await _contactsRef.orderBy('createdAt').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] as String? ?? '',
        'phone': data['phone'] as String? ?? '',
      };
    }).toList();
  }

  /// Overwrite that user’s contacts: batch‐delete old, write new
  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final batch = _firestore.batch();
    final existing = await _contactsRef.get();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final contact in contacts) {
      final docRef = _contactsRef.doc();
      batch.set(docRef, {
        'name': contact['name'],
        'phone': contact['phone'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
