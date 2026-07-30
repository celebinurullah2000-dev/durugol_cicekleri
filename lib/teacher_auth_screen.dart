// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- Google Sign-In paketi
import 'home_screen.dart';

class TeacherAuthScreen extends StatefulWidget {
  const TeacherAuthScreen({super.key});

  @override
  State<TeacherAuthScreen> createState() => _TeacherAuthScreenState();
}

class _TeacherAuthScreenState extends State<TeacherAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _sifreGizli = true;

  // --- GOOGLE İLE GİRİŞ FONKSİYONU ---
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Tip kısmındaki gereksiz '?' işareti kaldırıldı
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 2. Yetkilendirme istemcisinden token bilgilerini alıyoruz
      final authorizationClient = googleUser.authorizationClient;
      final authorization = await authorizationClient.authorizationForScopes([
        'email',
        'profile',
      ]);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: null,
      );

      // 3. Firebase'e giriş yap
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 4. Firestore'da bu öğretmen daha önce kayıt olmuş mu kontrol et
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();

        if (!teacherDoc.exists) {
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(user.uid)
              .set({
                'teacherId': user.uid,
                'email': user.email,
                'className': 'Sınıfım',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google ile giriş başarısız: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    // ... (Eski e-posta/şifre kayıt ve giriş kodlarınız aynen kalacak)
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final className = _classNameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        (!_isLoginMode && className.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        String teacherId = userCredential.user!.uid;

        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .set({
              'teacherId': teacherId,
              'email': email,
              'className': className,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? "Öğretmen Girişi" : "Öğretmen Kaydı"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(
                _isLoginMode
                    ? "Öğretmen Hesabınızla Giriş Yapın"
                    : "Yeni Sınıf ve Hesap Oluşturun",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              if (!_isLoginMode) ...[
                TextField(
                  controller: _classNameController,
                  decoration: InputDecoration(
                    labelText: "Sınıf Adı (Örn: 4/A Sınıfı)",
                    prefixIcon: const Icon(Icons.class_),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-posta Adresi",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _sifreGizli,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sifreGizli ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        // E-posta ile Giriş/Kayıt Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _submit,
                            child: Text(
                              _isLoginMode
                                  ? "Giriş Yap"
                                  : "Kayıt Ol ve Sınıfı Oluştur",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- GOOGLE İLE GİRİŞ BUTONU ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            onPressed: _signInWithGoogle,
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 30,
                              color: Colors.red,
                            ),
                            label: const Text(
                              "Google ile Devam Et",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode
                      ? "Hesabınız yok mu? Hemen Kayıt Olun"
                      : "Zaten hesabınız var mı? Giriş Yapın",
                  style: const TextStyle(color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
