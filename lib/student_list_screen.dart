import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';
import 'TopluOdevScreen.dart';
import 'TarihBazliOdevYoneticisiScreen.dart';
import 'SinifIsTakipScreen.dart';

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

  // --- ÖDEV VERME DİYALOĞU ---
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
                  labelText: "Tarih Formatı (Örn: 21 Temmuz 2026, Salı)",
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

                  mevcutKitaplar.add({
                    'kitapAdi': kitapAdi,
                    'sayfaAraligi': sayfaAraligi,
                    'aciklama': aciklama,
                    'durum': 'bekliyor',
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
                        'durum': 'bekliyor',
                      },
                    ],
                  });
                }
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
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

  // Öğrencileri, okunan sayfaları ve ödev durum özetlerini çeken fonksiyon
  Future<List<Map<String, dynamic>>> _getOgrencilerVeVeriler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];

    for (var doc in studentsQuery.docs) {
      var studentData = doc.data();

      // Okunan kitaplar toplam sayfa hesabı
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

      // Ödev durumları hesabı
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

    // Sıralama modu aktifse toplam sayfa sayısına göre büyükten küçüğe sırala
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // YATAY KAYDIRILABİLİR HIZLI ERİŞİM AKSİYON PANELİ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Colors.indigo.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildHizliIslemButonu(
                    icon: Icons.fact_check,
                    label: "İş Takibi",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SinifIsTakipScreen(classId: widget.classId),
                        ),
                      );
                    },
                  ),
                  _buildHizliIslemButonu(
                    icon: Icons.date_range,
                    label: "Hızlı Ödev Durumu Ekle",
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TarihBazliOdevYoneticisiScreen(
                            classId: widget.classId,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildHizliIslemButonu(
                    icon: Icons.checklist_rtl,
                    label: "Toplu Ödev",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopluOdevScreen(),
                        ),
                      );
                    },
                  ),
                  _buildHizliIslemButonu(
                    icon: Icons.assignment_add,
                    label: "Ödev Ver",
                    color: Colors.orange.shade800,
                    onTap: () => _odevVerDialog(context),
                  ),
                  _buildHizliIslemButonu(
                    icon: _siralamayiAc ? Icons.star : Icons.sort_by_alpha,
                    label: _siralamayiAc ? "Puan Sırası" : "Alfabetik",
                    color: Colors.purple,
                    onTap: () {
                      setState(() {
                        _siralamayiAc = !_siralamayiAc;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // ÖĞRENCİ LİSTESİ
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                        odevDurumMetni =
                            "Tümü Tamamlandı ($yapilanOdev/$toplamOdev)";
                        odevDurumRengi = Colors.green;
                      } else {
                        odevDurumMetni =
                            "Devam Ediyor ($yapilanOdev/$toplamOdev)";
                        odevDurumRengi = Colors.orange;
                      }
                    }

                    final initials =
                        (firstName.isNotEmpty ? firstName[0] : '') +
                        (lastName.isNotEmpty ? lastName[0] : '');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                        isThreeLine: true,
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
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
          setState(() {});
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // Üst kısımdaki hızlı işlem butonları için yardımcı widget
  Widget _buildHizliIslemButonu({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 95,
          height: 75,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
