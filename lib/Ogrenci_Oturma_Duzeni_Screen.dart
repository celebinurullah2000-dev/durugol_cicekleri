import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciOturmaDuzeniScreen extends StatelessWidget {
  final String classId;

  const OgrenciOturmaDuzeniScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Oturma Düzeni Listesi"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('oturma_duzeni')
            .orderBy('siraNo') // Sıra numarasına göre sıralı gelsin
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz bir oturma düzeni oluşturulmamış.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              int siraNo = data['siraNo'] ?? (index + 1);
              String ogrenci1 = data['ogrenci1Ad'] ?? 'Boş';
              String ogrenci2 = data['ogrenci2Ad'] ?? 'Boş';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      "$siraNo",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ),
                  title: Text(ogrenci1, style: const TextStyle(fontSize: 15)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      ogrenci2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
