import 'package:firebase_auth/firebase_auth.dart'; // Bu importun olduğundan emin olun
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hata 1: User? tipi yerine Future<UserCredential?> kullanımı daha güvenlidir.
  // Hata 2: Hata yönetimi (try-catch) eksikliği.
  Future<User?> signIn(String email, String password) async {
    try {
      // Boş alan kontrolü
      if (email.isEmpty || password.isEmpty) {
        throw Exception("E-posta veya şifre boş bırakılamaz.");
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Hata 3: Firebase'e özgü hata mesajlarını yakalama
      developer.log("Firebase Hatası: ${e.message}");
      return null;
    } catch (e) {
      // Hata 4: Genel hata yakalama
      developer.log("Genel Hata: $e");
      return null;
    }
  }

  // Hata 5: Çıkış yapma fonksiyonunun eksikliği
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
