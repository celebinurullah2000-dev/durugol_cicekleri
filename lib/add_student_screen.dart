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
  String? _selectedGender; // Seçilen cinsiyet ('K' veya 'E')

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

            // CİNSİYET SEÇİMİ (Nöbetçi algoritması için şart)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Cinsiyet"),
              initialValue: _selectedGender,
              items: const [
                DropdownMenuItem(value: 'K', child: Text("Kız")),
                DropdownMenuItem(value: 'E', child: Text("Erkek")),
              ],
              onChanged: (val) => setState(() => _selectedGender = val),
              validator: (val) => val == null ? "Lütfen cinsiyet seçin" : null,
            ),

            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: "Okul Numarası"),
              validator: (val) =>
                  val!.isEmpty ? "Lütfen okul numarası girin" : null,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Öğrenci Şifresi"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _selectedClassId != null &&
                    _selectedGender != null) {
                  // 1. Sadece ihtiyacımız olan navigator'ı kaydediyoruz
                  final navigator = Navigator.of(context);

                  // 2. Firestore işlemini yap (gender alanı eklendi)
                  await FirebaseFirestore.instance.collection('students').add({
                    'firstName': _firstNameController.text,
                    'lastName': _lastNameController.text,
                    'classId': _selectedClassId,
                    'gender': _selectedGender, // 'K' veya 'E'
                    'schoolNumber': _numberController.text,
                    'password': _passwordController.text,
                    'createdAt': DateTime.now(),
                    'hasBeenOnDuty':
                        false, // Yeni eklenen öğrenci için başlangıç değeri
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
