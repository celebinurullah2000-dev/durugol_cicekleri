import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId; // Seçilen sınıfın ID'si

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Öğrenci Kaydı")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SINIF SEÇİMİ (Firebase'den çekilen sınıflar)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                var classList = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Sınıf Seçin"),
                  initialValue: _selectedClassId,
                  items: classList.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['className']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClassId = val),
                  validator: (val) => val == null ? "Sınıf seçmelisiniz" : null,
                );
              },
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
              controller: _numberController,
              decoration: const InputDecoration(labelText: "Okul Numarası"),
              validator: (val) =>
                  val!.isEmpty ? "Lütfen okul numarası girin" : null,
            ),
            TextField(
              controller: _passwordController, // İşte buraya bağlıyoruz
              decoration: const InputDecoration(labelText: "Öğrenci Şifresi"),
              obscureText: true,
            ),

            // ... diğer alanlar
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _selectedClassId != null) {
                  // 1. Sadece ihtiyacımız olan navigator'ı kaydediyoruz
                  final navigator = Navigator.of(context);

                  // 2. Firestore işlemini yap
                  await FirebaseFirestore.instance.collection('students').add({
                    'firstName': _firstNameController.text,
                    'lastName': _lastNameController.text,
                    'classId': _selectedClassId,
                    'schoolNumber': _numberController.text,
                    'password': _passwordController.text,
                    'createdAt': DateTime.now(),
                  });

                  // 3. Kaydedilen navigator referansını kullan
                  navigator.pop();
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
