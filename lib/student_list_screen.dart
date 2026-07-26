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

  // Türkçe karakter duyarlı alfabetik sıralama fonksiyonu
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

      // Eğer karakter alfabe tanımımızda yoksa varsayılan kod birimini kullan
      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  // Öğrencileri alfabetik sıraya göre çeken fonksiyon
  Future<List<Map<String, dynamic>>> _getOgrenciler() async {
    var studentsQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    List<Map<String, dynamic>> ogrenciListesi = [];
    for (var doc in studentsQuery.docs) {
      ogrenciListesi.add({'id': doc.id, ...doc.data()});
    }

    // Türkçe kurala göre önce Ad, adlar aynıysa Soyad sıralaması
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
          // YATAY KAYDIRILABİLİR HIZLI ERİŞİM AKSİYON PANELİ (2 Satır)
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
                          /*_buildHizliIslemButonu(
                            icon: Icons.cloud_upload,
                            label: "Öğrenci Yükle",
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OgrenciYuklemeScreen(),
                                ),
                              );
                            },
                          ),*/
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
                            icon: Icons.date_range,
                            label: "Hızlı Ödev Durumu Ekle",
                            color: Colors.indigo,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TarihBazliOdevYoneticisiScreen(
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
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildHizliIslemButonu(
                            icon: Icons.assignment_ind,
                            label: "Nöbetçi Öğrenci",
                            color: Colors.green.shade700,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NobetciScreen(
                                    studentId: "",
                                    classId: widget.classId,
                                  ),
                                ),
                              );
                            },
                          ),
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
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // TEMEL ÖĞRENCİ LİSTESİ VE YÖNETİMİ
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
                          "Öğrenci No: ${student['schoolNumber'] ?? 'Belirtilmemiş'}",
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
