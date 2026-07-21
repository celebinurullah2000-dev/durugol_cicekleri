// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool _siralamayiAc = false;

  Future<List<Map<String, dynamic>>> _getOgrenciler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .get();
    List<Map<String, dynamic>> ogrenciListesi = [];

    for (var doc in studentsQuery.docs) {
      var kitaplar = await doc.reference.collection('okunan_kitaplar').get();
      int toplamSayfa = 0;
      for (var k in kitaplar.docs) {
        toplamSayfa += (k['sayfaSayisi'] as num).toInt();
      }

      ogrenciListesi.add({
        'id': doc.id,
        'isim': doc['isim'],
        'sifre': doc['sifre'],
        'toplamSayfa': toplamSayfa,
      });
    }

    if (_siralamayiAc) {
      ogrenciListesi.sort(
        (a, b) => b['toplamSayfa'].compareTo(a['toplamSayfa']),
      );
    }

    return ogrenciListesi;
  }

  void _ogrenciEkle(BuildContext context) {
    final TextEditingController isimController = TextEditingController();
    final TextEditingController sifreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Öğrenci Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: isimController,
              decoration: const InputDecoration(labelText: "İsim Soyisim"),
            ),
            TextField(
              controller: sifreController,
              decoration: const InputDecoration(labelText: "Şifre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('students').add({
                'isim': isimController.text,
                'sifre': sifreController.text,
                'eklenmeTarihi': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _ogrenciSil(String docId) {
    FirebaseFirestore.instance.collection('students').doc(docId).delete();
    setState(() {});
  }

  void _ogrenciDuzenle(
    BuildContext context,
    String docId,
    String mevcutIsim,
    String mevcutSifre,
  ) {
    final TextEditingController isimController = TextEditingController(
      text: mevcutIsim,
    );
    final TextEditingController sifreController = TextEditingController(
      text: mevcutSifre,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bilgileri Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: isimController,
              decoration: const InputDecoration(labelText: "İsim"),
            ),
            TextField(
              controller: sifreController,
              decoration: const InputDecoration(labelText: "Şifre"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('students')
                  .doc(docId)
                  .update({
                    'isim': isimController.text,
                    'sifre': sifreController.text,
                  });
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğretmen Paneli - 2-D"),
        actions: [
          // --- SIRALAMA BUTONU BURADA ---
          IconButton(
            icon: Icon(
              _siralamayiAc ? Icons.star : Icons.sort_by_alpha,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _siralamayiAc = !_siralamayiAc;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOgrenciler(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var ogrenciler = snapshot.data!;

          if (ogrenciler.isEmpty) {
            return const Center(child: Text("Henüz kayıtlı öğrenci yok."));
          }

          return ListView.builder(
            itemCount: ogrenciler.length,
            itemBuilder: (context, index) {
              var ogrenci = ogrenciler[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _siralamayiAc
                          ? CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.indigo,
                              size: 30,
                            ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ogrenci['isim'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Şifre: ${ogrenci['sifre']}"),
                            const SizedBox(height: 4),
                            Text(
                              "Toplam: ${ogrenci['toplamSayfa']} Sayfa",
                              style: TextStyle(
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _ogrenciDuzenle(
                          context,
                          ogrenci['id'],
                          ogrenci['isim'],
                          ogrenci['sifre'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _ogrenciSil(ogrenci['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _ogrenciEkle(context),
      ),
    );
  }
}
