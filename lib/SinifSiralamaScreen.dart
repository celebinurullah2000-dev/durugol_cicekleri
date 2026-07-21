import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SinifSiralamaScreen extends StatelessWidget {
  const SinifSiralamaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sınıf Başarı Sıralaması")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gelecekte bir FutureBuilder ile her öğrencinin sayfa sayısını
          // toplayıp bir listeye atıp sıralamamız gerekecek.
          // Basit ve etkili bir başlangıç için:
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var student = snapshot.data!.docs[index];
              return _OgrenciSiraKarti(student: student);
            },
          );
        },
      ),
    );
  }
}

class _OgrenciSiraKarti extends StatelessWidget {
  final DocumentSnapshot student;
  const _OgrenciSiraKarti({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: student.reference.collection('okunan_kitaplar').snapshots(),
      builder: (context, snapshot) {
        int toplamSayfa = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            toplamSayfa += (doc['sayfaSayisi'] as num).toInt();
          }
        }

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text("${snapshot.data?.docs.length ?? 0}"),
            ),
            title: Text(student['adSoyad'] ?? "Öğrenci"),
            trailing: Text(
              "$toplamSayfa Sayfa",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        );
      },
    );
  }
}
