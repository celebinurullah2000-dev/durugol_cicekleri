import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClassScreen extends StatelessWidget {
  final TextEditingController _classNameController = TextEditingController();

  AddClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sınıf Ekle")),
      body: Column(
        children: [
          TextField(
            controller: _classNameController,
            decoration: const InputDecoration(
              labelText: "Sınıf Adı ve Şubesi (Örn: 3/A)",
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. İşlem başlamadan önce referansı kaydet
              final navigator = Navigator.of(context);

              // 2. Firestore'a sınıfı kaydet
              await FirebaseFirestore.instance.collection('classes').add({
                'className': _classNameController.text,
                'teacherId': 'current_teacher_id',
              });

              // 3. Kaydedilen referansı güvenle kullan
              navigator.pop();
            },
            child: const Text("Sınıfı Kaydet"),
          ),
        ],
      ),
    );
  }
}
