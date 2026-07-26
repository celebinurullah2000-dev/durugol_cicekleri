import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_kitap_odev_screen.dart';

class KitapOkumaTakipScreen extends StatefulWidget {
  final String classId;
  final String className;

  const KitapOkumaTakipScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<KitapOkumaTakipScreen> createState() => _KitapOkumaTakipScreenState();
}

class _KitapOkumaTakipScreenState extends State<KitapOkumaTakipScreen> {
  bool _siralamayiAc = false;

  Future<List<Map<String, dynamic>>> _getOgrencilerVeVeriler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];

    for (var doc in studentsQuery.docs) {
      var studentData = doc.data();

      var kitaplarQuery = await doc.reference
          .collection('okunan_kitaplar')
          .get();

      int toplamSayfa = 0;
      for (var k in kitaplarQuery.docs) {
        var kData = k.data();
        if (kData.containsKey('sayfaSayisi')) {
          toplamSayfa += (kData['sayfaSayisi'] as num).toInt();
        }
      }

      var odevQuery = await doc.reference.collection('odevler').get();
      int toplamOdev = 0;
      int yapilanOdev = 0;
      bool kilitliVar = false;

      for (var odevDoc in odevQuery.docs) {
        var odevData = odevDoc.data();
        List kitaplar = odevData['kitaplar'] ?? [];
        for (var k in kitaplar) {
          toplamOdev++;
          if (k['durum'] == 'yapildi') {
            yapilanOdev++;
          } else if (k['durum'] == 'ogretmen_reddi') {
            kilitliVar = true;
          }
        }
      }

      ogrenciListesi.add({
        'id': doc.id,
        ...studentData,
        'toplamSayfa': toplamSayfa,
        'toplamOdev': toplamOdev,
        'yapilanOdev': yapilanOdev,
        'kilitliVar': kilitliVar,
      });
    }

    if (_siralamayiAc) {
      ogrenciListesi.sort(
        (a, b) => (b['toplamSayfa'] as int).compareTo(a['toplamSayfa'] as int),
      );
    }

    return ogrenciListesi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Kitap ve Ödev Takibi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_siralamayiAc ? Icons.star : Icons.sort_by_alpha),
            tooltip: _siralamayiAc ? "Puan Sırası Açık" : "Alfabetik Sıra",
            onPressed: () {
              setState(() {
                _siralamayiAc = !_siralamayiAc;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOgrencilerVeVeriler(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Bu sınıfta henüz kayıtlı öğrenci yok."),
            );
          }

          final students = snapshot.data!;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final firstName = student['firstName'] ?? '';
              final lastName = student['lastName'] ?? '';
              final toplamSayfa = student['toplamSayfa'] ?? 0;

              int toplamOdev = student['toplamOdev'] ?? 0;
              int yapilanOdev = student['yapilanOdev'] ?? 0;
              bool kilitliVar = student['kilitliVar'] ?? false;

              String odevDurumMetni = "Ödev yok";
              Color odevDurumRengi = Colors.grey;

              if (toplamOdev > 0) {
                if (kilitliVar) {
                  odevDurumMetni =
                      "Kilitli Ödev Var ($yapilanOdev/$toplamOdev)";
                  odevDurumRengi = Colors.red;
                } else if (yapilanOdev == toplamOdev) {
                  odevDurumMetni = "Tümü Tamamlandı ($yapilanOdev/$toplamOdev)";
                  odevDurumRengi = Colors.green;
                } else {
                  odevDurumMetni = "Devam Ediyor ($yapilanOdev/$toplamOdev)";
                  odevDurumRengi = Colors.orange;
                }
              }

              final initials =
                  (firstName.isNotEmpty ? firstName[0] : '') +
                  (lastName.isNotEmpty ? lastName[0] : '');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(
                          studentData: student,
                          studentId: student['id'],
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  leading: _siralamayiAc
                      ? CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                  title: Text(
                    "$firstName $lastName",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sınıf No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}  •  Toplam: $toplamSayfa Sayfa",
                      ),
                      const SizedBox(height: 2),
                      Text(
                        odevDurumMetni,
                        style: TextStyle(
                          color: odevDurumRengi,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.indigo,
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
