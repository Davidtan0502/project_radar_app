import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContactService {
  static const _key = 'sos_contacts';

  Future<List<Map<String, String>>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) => Map<String, String>.from(jsonDecode(s))).toList();
  }

  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = contacts.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList(_key, list);
  }
}
