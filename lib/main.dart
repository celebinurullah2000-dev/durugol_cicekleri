import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure ile oluşan dosya
import 'firestore_service.dart'; // FirestoreService sınıfınızın olduğu dosya
import 'home_screen.dart'; // Sınıf Listesi ekranınız
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore hatası için
import 'student_home_screen.dart'; // StudentHomeScreen hatası için

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase başlatılamadı: $e");
  }
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('userRole');
  final studentId = prefs.getString('studentId');

  runApp(MyApp(initialRole: role, studentId: studentId));
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  final String? studentId;
  const MyApp({super.key, this.initialRole, this.studentId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Durugöl Çiçekleri',
      // main.dart içinde MaterialApp'in home kısmı:
      home: initialRole == 'teacher'
          ? const HomeScreen()
          : (initialRole == 'student'
                ? StudentHomeScreen(studentId: studentId ?? '')
                : const LoginScreen()),
      theme: ThemeData(
        useMaterial3: true, // Modern tasarımı aktif eder
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo, // Buraya kendi ana rengini seçebilirsin
          primary: Colors.indigo.shade700,
          surface: Colors.white,
        ),
        fontFamily: 'Poppins', // (Pubspec'e eklememiz gerekir)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
}

// Öğretmen için öğrenci ekleme ekranı (Basitleştirilmiş)
class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllerlar
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ... diğer isteğe bağlı alanlar için de controller eklenmeli

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Öğrenci Ekle")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              "Zorunlu Alanlar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "Öğrenci Adı"),
              validator: (val) => val!.isEmpty ? "Lütfen ad girin" : null,
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Öğrenci Soyadı"),
              validator: (val) => val!.isEmpty ? "Lütfen soyad girin" : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Öğrenci Şifresi"),
              validator: (val) =>
                  val!.isEmpty ? "Lütfen şifre belirleyin" : null,
            ),
            const Divider(height: 40),
            ExpansionTile(
              title: const Text("Detaylı Bilgiler (İsteğe Bağlı)"),
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Okul Numarası"),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "TC Kimlik No"),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Anne Mesleği"),
                ),
                // İhtiyaca göre diğer alanları buraya ekleyebilirsiniz...
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Firestore'a kaydetme işlemini başlat
                  _firestoreService.addStudent({
                    'firstName': _firstNameController.text,
                    'lastName': _lastNameController.text,
                    'password': _passwordController.text,
                    'createdAt': DateTime.now(),
                  });
                  Navigator.pop(context); // Kayıt sonrası geri dön
                }
              },
              child: const Text("Öğrenciyi Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
