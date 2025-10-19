// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUp(UserModel user) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      // Update display name
      await userCredential.user!.updateDisplayName(user.name);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Sign up failed");
    }
  }
}
