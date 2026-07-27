import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_screen.dart';
import 'TopluOdevScreen.dart';
import 'TarihBazliOdevYoneticisiScreen.dart';
import 'SinifIsTakipScreen.dart';
import 'nobetci_screen.dart';
import 'kitap_okuma_takip_screen.dart';
import 'student_detail_screen.dart';
// ignore: unused_import
import 'ogrenci_yukleme_screen.dart';
import 'oturma_duzeni_screen.dart';
import 'Devamsizlik_Screen.dart';
import 'Sinif_Gorevleri_Screen.dart'; // --- EKLENEN SINIF GÖREVLERİ İMPORTU ---

Future<Map<String, dynamic>> ogrenciDevamsizlikRaporunuGetir(
  String classId,
  String studentId,
) async {
  var snapshot = await FirebaseFirestore.instance
      .collection('classes')
      .doc(classId)
      .collection('devamsizliklar')
      .get();

  int toplamDevamsizlik = 0;
  List<String> gelmedigiTarihler = [];

  for (var doc in snapshot.docs) {
    var data = doc.data();
    var ogrencilerMap = data['ogrenciler'] as Map<String, dynamic>?;

    if (ogrencilerMap != null && ogrencilerMap[studentId] == true) {
      toplamDevamsizlik++;
      gelmedigiTarihler.add(data['tarih'] ?? doc.id);
    }
  }

  gelmedigiTarihler.sort();

  return {'toplam': toplamDevamsizlik, 'tarihler': gelmedigiTarihler};
}

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
  void _sil(BuildContext context, String studentId) {
    FirebaseFirestore.instance.collection('students').doc(studentId).delete();
    setState(() {});
  }

  // --- NÖBETÇİ & GÖREVLİ SEÇENEKLERİ MENÜSÜ ---
  void _showNobetciVeGorevliSecenekleri(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nöbetçi & Görevli İşlemleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.assignment_ind,
                  color: Colors.green.shade700,
                ),
                title: const Text("Nöbetçi Öğrenci"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NobetciScreen(
                        studentId: "",
                        classId: widget.classId,
                        isTeacher: true,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.how_to_vote, color: Colors.indigo),
                title: const Text("Sınıf Görevlileri (Seçim & Takip)"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SinifGorevleriScreen(
                        classId:
                            widget.classId, // sinifId yerine classId olmalı
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOdevIslemleriSecenekleri(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ödev İşlemleri",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.indigo),
                title: const Text("Hızlı Ödev Durumu Ekle"),
                onTap: () {
                  Navigator.pop(context);
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
              ListTile(
                leading: const Icon(Icons.checklist_rtl, color: Colors.blue),
                title: const Text("Toplu Ödev"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopluOdevScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.assignment_add,
                  color: Colors.orange.shade800,
                ),
                title: const Text("Ödev Ver"),
                onTap: () {
                  Navigator.pop(context);
                  _odevVerDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

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

  int _turkceKarsilastir(String a, String b) {
    const String turkceAlfabe = 'aabcçdefgğhıijklmnoöprsştuüvyz';

    String aKucuk = a
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');

    String bKucuk = b
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');

    int minLength = aKucuk.length < bKucuk.length
        ? aKucuk.length
        : bKucuk.length;

    for (int i = 0; i < minLength; i++) {
      int indexA = turkceAlfabe.indexOf(aKucuk[i]);
      int indexB = turkceAlfabe.indexOf(bKucuk[i]);

      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  Future<List<Map<String, dynamic>>> _getOgrenciler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];
    for (var doc in studentsQuery.docs) {
      ogrenciListesi.add({'id': doc.id, ...doc.data()});
    }

    ogrenciListesi.sort((a, b) {
      String adA = a['firstName'] ?? '';
      String adB = b['firstName'] ?? '';
      int adKarsilastir = _turkceKarsilastir(adA, adB);

      if (adKarsilastir != 0) {
        return adKarsilastir;
      }

      String soyadA = a['lastName'] ?? '';
      String soyadB = b['lastName'] ?? '';
      return _turkceKarsilastir(soyadA, soyadB);
    });

    return ogrenciListesi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} Sınıf Paneli"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: Colors.indigo.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          // --- İSTEDİĞİNİZ YERE "NÖBETÇİ & GÖREVLİ" BUTONU EKLENDİ ---
                          _buildHizliIslemButonu(
                            icon: Icons.group_work,
                            label: "Nöbetçi & Görevli",
                            color: Colors.green.shade700,
                            onTap: () {
                              _showNobetciVeGorevliSecenekleri(context);
                            },
                          ),
                          _buildHizliIslemButonu(
                            icon: Icons.fact_check,
                            label: "İş Takibi",
                            color: Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SinifIsTakipScreen(
                                    classId: widget.classId,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildHizliIslemButonu(
                            icon: Icons.assignment,
                            label: "Ödev İşlemleri",
                            color: Colors.indigo,
                            onTap: () {
                              _showOdevIslemleriSecenekleri(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Eski "Nöbetçi Öğrenci" düğmesi kaldırıldı ve yukarı taşındı.
                          _buildHizliIslemButonu(
                            icon: Icons.menu_book,
                            label: "Kitap ve Ödev",
                            color: Colors.brown,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => KitapOkumaTakipScreen(
                                    classId: widget.classId,
                                    className: widget.className,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildHizliIslemButonu(
                            icon: Icons.grid_view,
                            label: "Oturma Düzeni",
                            color: Colors.indigo.shade700,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OturmaDuzeniScreen(
                                    classId: widget.classId,
                                    isTeacher: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildHizliIslemButonu(
                            icon: Icons.fact_check,
                            label: "Devamsızlık",
                            color: Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DevamsizlikScreen(
                                    classId: widget.classId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getOgrenciler(),
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
                        leading: CircleAvatar(
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
                          "No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}",
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
