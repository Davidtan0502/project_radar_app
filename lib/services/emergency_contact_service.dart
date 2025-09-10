import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyContactService {
  final _firestore = FirebaseFirestore.instance;

  /// Reference: users/{uid}/emergency_contacts
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

  /// Load contacts ordered by position
  Future<List<Map<String, String>>> loadContacts() async {
    final snap = await _contactsRef.orderBy('position').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id, // keep ID for delete/edit
        'name': data['name'] as String? ?? '',
        'phone': data['phone'] as String? ?? '',
      };
    }).toList();
  }

  /// Save contacts with correct positions
  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final batch = _firestore.batch();
    final existing = await _contactsRef.get();

    // Delete old docs
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    // Save new with updated positions
    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      final docRef = _contactsRef.doc(contact['id']); // keep same ID if present
      batch.set(docRef, {
        'name': contact['name'],
        'phone': contact['phone'],
        'position': i, // ✅ enforce order
      });
    }

    await batch.commit();
  }

  /// Delete a single contact by ID
  Future<void> deleteContact(String contactId) async {
    await _contactsRef.doc(contactId).delete();
  }
}
