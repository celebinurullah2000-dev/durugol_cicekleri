import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final String classId;
  final String className;

  const StudentListScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  // Sıralama modunun açık olup olmadığını tutan değişken
  bool _siralamayiAc = false;

  // Öğrenci Silme Fonksiyonu
  void _sil(BuildContext context, String studentId) {
    FirebaseFirestore.instance.collection('students').doc(studentId).delete();
    setState(() {});
  }

  // Öğrenci Düzenleme Fonksiyonu
  void _duzenle(
    BuildContext context,
    String studentId,
    Map<String, dynamic> studentData,
  ) {
    final TextEditingController adController = TextEditingController(
      text: studentData['firstName'],
    );
    final TextEditingController soyadController = TextEditingController(
      text: studentData['lastName'],
    );
    final TextEditingController sifreController = TextEditingController(
      text: studentData['password'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Öğrenci Bilgilerini Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adController,
                decoration: const InputDecoration(labelText: "Ad"),
              ),
              TextField(
                controller: soyadController,
                decoration: const InputDecoration(labelText: "Soyad"),
              ),
              TextField(
                controller: sifreController,
                decoration: const InputDecoration(labelText: "Yeni Şifre"),
                obscureText: false,
              ),
            ],
          ),
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
                  .doc(studentId)
                  .update({
                    'firstName': adController.text,
                    'lastName': soyadController.text,
                    'password': sifreController.text,
                  });
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bilgiler başarıyla güncellendi."),
                ),
              );
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  // --- ÖDEV VERME DİYALOĞU (Öğretmenin ödev göndermesi için) ---
  void _odevVerDialog(BuildContext context) {
    final TextEditingController tarihStrController = TextEditingController(
      text: "21 Temmuz 2026, Salı",
    );
    final TextEditingController kitapAdiController = TextEditingController();
    final TextEditingController sayfaController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sınıfa Ödev Ver"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tarihStrController,
                decoration: const InputDecoration(
                  labelText: "Tarih Formatı (Örn: 21-Temmuz-2026, Salı)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: kitapAdiController,
                decoration: const InputDecoration(labelText: "Kitap Adı"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sayfaController,
                decoration: const InputDecoration(
                  labelText: "Sayfa Aralığı (Örn: 10-15)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: aciklamaController,
                decoration: const InputDecoration(
                  labelText: "Bu Kitap İçin Açıklama / Yönerge",
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String secilenTarih = tarihStrController.text.trim();
              String kitapAdi = kitapAdiController.text.trim();
              String sayfaAraligi = sayfaController.text.trim();
              String aciklama = aciklamaController.text.trim();

              var studentsSnapshot = await FirebaseFirestore.instance
                  .collection('students')
                  .where('classId', isEqualTo: widget.classId)
                  .get();

              for (var studentDoc in studentsSnapshot.docs) {
                var odevlerRef = studentDoc.reference.collection('odevler');

                var existingOdev = await odevlerRef
                    .where('tarihStr', isEqualTo: secilenTarih)
                    .get();

                if (existingOdev.docs.isNotEmpty) {
                  var docId = existingOdev.docs.first.id;
                  var mevcutVeri = existingOdev.docs.first.data();
                  List mevcutKitaplar = List.from(mevcutVeri['kitaplar'] ?? []);

                  // Yeni kitabı ve kendi özel açıklamasını listeye ekle
                  mevcutKitaplar.add({
                    'kitapAdi': kitapAdi,
                    'sayfaAraligi': sayfaAraligi,
                    'aciklama': aciklama,
                  });

                  await odevlerRef.doc(docId).update({
                    'kitaplar': mevcutKitaplar,
                  });
                } else {
                  await odevlerRef.add({
                    'tarihStr': secilenTarih,
                    'kitaplar': [
                      {
                        'kitapAdi': kitapAdi,
                        'sayfaAraligi': sayfaAraligi,
                        'aciklama': aciklama,
                      },
                    ],
                    'durum': 'bekliyor',
                  });
                }
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ödev kitaba özel açıklamasıyla eklendi."),
                ),
              );
            },
            child: const Text("Ödevi Gönder"),
          ),
        ],
      ),
    );
  }

  // Öğrencileri ve alt koleksiyondaki okunan kitapları çekip toplam sayfa hesaplayan fonksiyon
  Future<List<Map<String, dynamic>>> _getOgrencilerVeSayfalar() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];

    for (var doc in studentsQuery.docs) {
      var studentData = doc.data();

      // Her öğrencinin okunan_kitaplar alt koleksiyonunu çekiyoruz
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

      ogrenciListesi.add({
        'id': doc.id,
        ...studentData,
        'toplamSayfa': toplamSayfa,
      });
    }

    // Eğer sıralama butonu aktifse, toplam sayfa sayısına göre büyükten küçüğe sırala
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
        title: Text("${widget.className} Öğrencileri"),
        actions: [
          // 1. Ödev Verme Butonu (Yeni Eklenen)
          IconButton(
            icon: const Icon(Icons.assignment_add),
            tooltip: "Sınıfa Ödev Ver",
            onPressed: () => _odevVerDialog(context),
          ),
          // Liderlik / Sıralama Butonu Eklendi
          IconButton(
            icon: Icon(_siralamayiAc ? Icons.star : Icons.sort_by_alpha),
            tooltip: "Sıralama Modunu Değiştir",
            onPressed: () {
              setState(() {
                _siralamayiAc = !_siralamayiAc;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOgrencilerVeSayfalar(),
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
                    ).then(
                      (_) => setState(() {}),
                    ); // Detaydan dönünce listeyi tazele
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
                  subtitle: Text(
                    "Sınıf No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}  •  Toplam: $toplamSayfa Sayfa",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _duzenle(context, student['id'], student),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _sil(context, student['id']),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.indigo),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
          setState(() {}); // Yeni öğrenci eklenip gelinirse listeyi güncelle
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
