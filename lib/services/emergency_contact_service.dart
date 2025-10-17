import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, String>>> loadContacts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', user.id)
          .order('created_at');

      if (response.isEmpty) return [];

      return response.map<Map<String, String>>((contact) {
        return {
          'id': contact['id'].toString(),
          'name': contact['name'] ?? '',
          'phone': contact['phone'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error loading contacts: $e');
      return [];
    }
  }

  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // First, delete all existing contacts for this user
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('user_id', user.id);

      // Then insert the updated list
      if (contacts.isNotEmpty) {
        final contactsToInsert = contacts.map((contact) {
          return {
            'user_id': user.id,
            'name': contact['name'],
            'phone': contact['phone'],
            'created_at': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase
            .from('emergency_contacts')
            .insert(contactsToInsert);
      }
    } catch (e) {
      print('Error saving contacts: $e');
      rethrow;
    }
  }
}