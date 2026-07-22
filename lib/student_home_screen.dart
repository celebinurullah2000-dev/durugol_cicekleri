import 'package:flutter/material.dart'; // Scaffold, AppBar, Text vb. temel widgetlar için
import 'package:shared_preferences/shared_preferences.dart'; // Çıkış yaparken oturumu silmek için
import 'login_screen.dart'; // Çıkış yapınca tekrar giriş ekranına dönmek için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'OkudugumKitaplarScreen.dart';
import 'odevlerim_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final String studentId;
  const StudentHomeScreen({super.key, required this.studentId});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String studentName = "Öğrenci"; // Başlangıç değeri
  String classId = ""; // Sınıf ID'sini tutmak için değişken

  @override
  void initState() {
    super.initState();
    _loadStudentData(); // Hem ismi hem de sınıf ID'sini yüklüyoruz
  }

  // Öğrenci bilgilerini SharedPreferences ve Firestore'dan yükleme
  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();

    // Önce hafızadan alalım
    String isim = prefs.getString('studentName') ?? "Öğrenci";
    String cId = prefs.getString('classId') ?? "";

    // Eğer hafızada classId yoksa doğrudan Firestore'dan çekelim (Garanti yöntem)
    if (cId.isEmpty) {
      var studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        var data = studentDoc.data() as Map<String, dynamic>;
        cId = data['classId'] ?? "";
        isim = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();

        // Hafızaya kaydedelim ki bir sonraki seferde hızlı gelsin
        await prefs.setString('classId', cId);
        await prefs.setString('studentName', isim);
      }
    }

    setState(() {
      studentName = isim.isNotEmpty ? isim : "Öğrenci";
      classId = cId; // Sınıf ID değişkenimizi dolduruyoruz
    });
  }

  // Öğrencinin Kendi Şifresini Değiştirme Fonksiyonu
  void _ogrenciSifreDegistir(BuildContext context) {
    final TextEditingController yeniSifreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Şifremi Değiştir"),
        content: TextField(
          controller: yeniSifreController,
          decoration: const InputDecoration(
            labelText: "Yeni Şifre",
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (yeniSifreController.text.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('students')
                    .doc(widget.studentId)
                    .update({'password': yeniSifreController.text});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifreniz başarıyla güncellendi."),
                  ),
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Buton verileri (resim isimleri ve başlıklar)
    final List<Map<String, String>> menuItems = [
      {'title': 'Okuduğum Kitaplar', 'image': 'assets/images/kitaplarim.png'},
      {'title': 'Ödevlerim', 'image': 'assets/images/odevlerim.png'},
      {'title': 'Projelerim', 'image': 'assets/images/projelerim.png'},
      {'title': 'Davranışlarım', 'image': 'assets/images/davranislarim.png'},
      {'title': 'Denemelerim', 'image': 'assets/images/testlerim.png'},
      {'title': 'Kurslarım', 'image': 'assets/images/kurslarim.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Merhaba, $studentName"),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.vpn_key,
              color: Colors.indigo,
            ), // Şifre değiştirme ikonu
            tooltip: "Şifremi Değiştir",
            onPressed: () => _ogrenciSifreDegistir(context),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Oturumu tamamen siler

              if (!context.mounted) return;

              // LoginScreen'e geri döndürür
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Yan yana 2 buton
            crossAxisSpacing: 14, // Yatay boşluk
            mainAxisSpacing: 14, // Dikey boşluk
            childAspectRatio:
                1.35, // Genişliği yüksekliğine göre daha fazla yaparak boşlukları yok ettik
          ),
          itemBuilder: (context, index) {
            return Card(
              elevation: 2,
              shadowColor: Colors.indigo.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (menuItems[index]['title'] == 'Okuduğum Kitaplar') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OkudugumKitaplarScreen(studentId: widget.studentId),
                      ),
                    );
                  } else if (menuItems[index]['title'] == 'Ödevlerim') {
                    if (classId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sınıf bilgisi yükleniyor, lütfen tekrar deneyin.",
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OdevlerimScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else {
                    // Diğer sayfalar için henüz bir şey yapmadık,
                    // buraya "Yakında eklenecek" gibi bir uyarı veya ScaffoldMessenger ekleyebilirsiniz.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${menuItems[index]['title']} bölümü yapım aşamasında!",
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // İçeriği tam merkeze alır
                    children: [
                      Expanded(
                        // Resmin kartın genişliğine göre büyümesini sağlar
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 15.0,
                          ), // Üstten biraz boşluk
                          child: Image.asset(
                            menuItems[index]['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 15.0,
                        ), // Yazının alttan boşluğu
                        child: Text(
                          menuItems[index]['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Yazıyı da biraz büyüttük
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
