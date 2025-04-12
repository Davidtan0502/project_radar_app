import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Auth Tests', () {
    late FirebaseAuth auth;
    
    setUp(() {
      auth = FirebaseAuth.instance;
    });

    test('Successful registration', () async {
      try {
        final result = await auth.createUserWithEmailAndPassword(
          email: 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
          password: 'password123'
        );
        expect(result.user, isNotNull);
      } catch (e) {
        fail('Registration failed: $e');
      }
    });
  });
}