import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OdevlerimScreen extends StatelessWidget {
  final String studentId;
  const OdevlerimScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ödevlerim")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .collection('odevler')
            .orderBy('teslimTarihi')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz bir ödeviniz bulunmuyor."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var odev = snapshot.data!.docs[index];
              bool isTamamlandi = odev['tamamlandi'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(odev['baslik'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Teslim: ${odev['teslimTarihi']}"),
                  trailing: Checkbox(
                    value: isTamamlandi,
                    onChanged: (val) {
                      FirebaseFirestore.instance
                          .collection('students')
                          .doc(studentId)
                          .collection('odevler')
                          .doc(odev.id)
                          .update({'tamamlandi': val});
                    },
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