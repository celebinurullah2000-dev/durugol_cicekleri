import 'package:flutter/material.dart'; // Scaffold, AppBar, Text vb. temel widgetlar için
import 'package:shared_preferences/shared_preferences.dart'; // Çıkış yaparken oturumu silmek için
import 'login_screen.dart'; // Çıkış yapınca tekrar giriş ekranına dönmek için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'OkudugumKitaplarScreen.dart';
import 'odevlerim_screen.dart';
import 'cesitli_isler_screen.dart';
import 'oyunlar_menu_screen.dart';
import 'Dogum_Gunleri_Screen.dart';

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

  void dogumGunuKontrolEtVeBildir(BuildContext context, String classId) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: classId)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String dogumTarihi = data['dogumTarihi'] ?? '';
        int kalanGun = dogumGununeKalanGunHesapla(dogumTarihi);

        // Doğum gününe 3 gün veya daha az kaldıysa (0 gün dahil)
        if (kalanGun >= 0 && kalanGun <= 3) {
          String adSoyad =
              data['adSoyad'] ??
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

          // Bildirimin ard arda patlamaması için veya her açılışta göstermek istiyorsanız:
          if (!context.mounted) return;

          _dogumGunuDialogGoster(context, adSoyad, kalanGun);
          break; // Birden fazla varsa önce yaklaşanı gösterip dönebiliriz
        }
      }
    } catch (e) {
      // Hata yönetimi sessiz geçilebilir
    }
  }

  int dogumGununeKalanGunHesapla(String dogumTarihiStr) {
    try {
      List<String> parcalar = dogumTarihiStr.split('.');
      if (parcalar.length != 3) return 999;
      int gun = int.parse(parcalar[0]);
      int ay = int.parse(parcalar[1]);

      DateTime simdi = DateTime.now();
      DateTime buYilDogumGunu = DateTime(simdi.year, ay, gun);

      if (buYilDogumGunu.isBefore(
        DateTime(simdi.year, simdi.month, simdi.day),
      )) {
        buYilDogumGunu = DateTime(simdi.year + 1, ay, gun);
      }

      return buYilDogumGunu
          .difference(DateTime(simdi.year, simdi.month, simdi.day))
          .inDays;
    } catch (e) {
      return 999;
    }
  }

  void _dogumGunuDialogGoster(
    BuildContext context,
    String ogrenciAdi,
    int kalanGun,
  ) {
    String mesaj = kalanGun == 0
        ? "Bugün $ogrenciAdi adlı arkadaşımızın doğum günü! 🎂 Birlikte nice mutlu yıllara dileyelim! 🎉"
        : "$ogrenciAdi adlı arkadaşımızın doğum gününe $kalanGun gün kaldı! 🎈 Şimdiden hazırlıklara başlayalım! 🎁";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.celebration, color: Colors.pink, size: 30),
            SizedBox(width: 10),
            Text("Doğum Günü Var!"),
          ],
        ),
        content: Text(mesaj, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Harika!"),
          ),
        ],
      ),
    );
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

      if (cId.isNotEmpty && mounted) {
        dogumGunuKontrolEtVeBildir(context, cId);
      }
    });
  }

  // Öğrencinin Kendi Şifresini Değiştirme Fonksiyonu
  void _ogrenciSifreDegistir(BuildContext context) {
    final TextEditingController yeniSifreController = TextEditingController();
    final TextEditingController yeniSifreTekrarController =
        TextEditingController();

    bool yeniSifreGizli = true;
    bool yeniSifreTekrarGizli = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Şifremi Değiştir"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Yeni Şifre Kutusu
                TextField(
                  controller: yeniSifreController,
                  obscureText: yeniSifreGizli,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        yeniSifreGizli
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          yeniSifreGizli = !yeniSifreGizli;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 2. Yeni Şifre (Tekrar) Kutusu
                TextField(
                  controller: yeniSifreTekrarController,
                  obscureText: yeniSifreTekrarGizli,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre (Tekrar)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        yeniSifreTekrarGizli
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          yeniSifreTekrarGizli = !yeniSifreTekrarGizli;
                        });
                      },
                    ),
                  ),
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
                String sifre1 = yeniSifreController.text.trim();
                String sifre2 = yeniSifreTekrarController.text.trim();

                if (sifre1.isEmpty || sifre2.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lütfen tüm alanları doldurun."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (sifre1 != sifre2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Girdiğiniz şifreler birbiriyle uyuşmuyor!",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                FirebaseFirestore.instance
                    .collection('students')
                    .doc(widget.studentId)
                    .update({'password': sifre1});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Şifreniz başarıyla güncellendi."),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Güncelle"),
            ),
          ],
        ),
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
      {'title': 'Çeşitli İşler', 'image': 'assets/images/cesitli_isler.png'},
      {'title': 'Oyunlar', 'image': 'assets/images/oyunlar.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Merhaba, $studentName"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cake, color: Colors.pink),
            tooltip: "Sınıf Doğum Günleri",
            onPressed: () {
              if (classId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DogumGunleriScreen(classId: classId),
                ),
              );
            },
          ),
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
                  } else if (menuItems[index]['title'] == 'Çeşitli İşler') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CesitliIslerScreen(
                          studentId: widget.studentId,
                          classId: classId,
                        ),
                      ),
                    );
                  } else if (menuItems[index]['title'] == 'Oyunlar') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OyunlarMenuScreen(
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
