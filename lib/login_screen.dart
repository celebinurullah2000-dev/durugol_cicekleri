import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore hatası için
import 'student_home_screen.dart'; // StudentHomeScreen hatası için

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isRoleSelected = false; // Başlangıçta butonlar görünecek
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Arka Plan: Pastel geçişli bir renk paleti
      body: Container(
        width: double.infinity, // Ekranın tamamını yatayda kapla
        height: double.infinity, // Ekranın tamamını dikeyde kapla
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ], // Hafif mavi tonları
          ),
        ),
        child: SingleChildScrollView(
          // Klavye açıldığında taşmayı önler
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // 2. Başlık Alanı
              Container(
                margin: const EdgeInsets.only(
                  bottom: 40,
                ), // Altına biraz boşluk bırakalım
                child: Image.asset(
                  'assets/images/durugol_cicekleri_giris_ekrani.png',
                  height:
                      200, // Resminizin boyutuna göre bu değeri artırıp azaltabilirsiniz
                  fit: BoxFit.contain,
                ),
              ),
              //const SizedBox(height: 5),
              _buildSinifGorseli(),
              const SizedBox(height: 40),
              if (!_isRoleSelected) ...[
                // --- ROL SEÇİM BUTONLARI ---

                // Öğretmen Butonu (Arka plan resmi ekleyebilirsin)
                Row(
                  children: [
                    const SizedBox(width: 20),
                    // Öğretmen Butonu (Ekranın yarısı)
                    Expanded(
                      child: _buildRoleButton(
                        "",
                        "assets/images/ogretmen.png",
                        () => setState(() => _isRoleSelected = true),
                      ),
                    ),
                    const SizedBox(width: 20), // İki buton arası boşluk
                    // Öğrenci Butonu (Ekranın yarısı)
                    Expanded(
                      child: _buildRoleButton(
                        "",
                        "assets/images/ogrenci.png",
                        () => setState(() => _isRoleSelected = true),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ] else ...[
                // --- ŞİFRE GİRİŞ EKRANI (Butonlar seçilince görünür) ---
                const Text(
                  "Şifrenizi Girin",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 30),
                // 1. ŞİFRE KUTUSU (Sabit genişlikte)
                Container(
                  width: 300, // Sabit genişlik
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Şifrenizi yazın",
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. GİRİŞ YAP BUTONU (Arka plan resimli)
                InkWell(
                  onTap: () => _login(context),
                  child: Container(
                    width: 250,
                    height: 100,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/giris_butonu.png'),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. GERİ DÖN BUTONU (Arka plan resimli)
                InkWell(
                  onTap: () => setState(() => _isRoleSelected = false),
                  child: Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/geri_butonu.png'),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    String title,
    String imagePath,
    VoidCallback onPressed,
  ) {
    return AspectRatio(
      aspectRatio: 1 / 1, // Bu satır butonun her zaman KARE olmasını sağlar
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20), // Tıklama efekti için
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinifGorseli() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('genel_ayarlar')
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Bağlantı bekleniyor mu?
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // 2. Bir hata oluştu mu?
        if (snapshot.hasError) {
          return const Text("Bir hata oluştu");
        }

        // 3. Veri var mı ve doküman gerçekten mevcut mu?
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Text("Veri bulunamadı");
        }

        // 4. Güvenli bir şekilde veriyi Map'e çeviriyoruz
        final data = snapshot.data!.data() as Map<String, dynamic>;

        // 5. 'sinif_gorsel_url' alanı var mı kontrol ediyoruz
        final imageUrl = data['sinif_gorsel_url'] as String?;

        if (imageUrl == null || imageUrl.isEmpty) {
          return const Text("Görsel adresi boş");
        }

        return Image.network(
          imageUrl,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Text("HATA: ${error.toString()}");
          },
        );
      },
    );
  }

  // 1. Fonksiyonun kullanılmadığı uyarısını çözmek için bunu bir butonun on onPressed'ına bağlayacağız
  Future<void> _login(BuildContext context) async {
    final password = _passwordController.text;
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    if (password == "123456") {
      await prefs.setString('userRole', 'teacher');
      if (!mounted) return;
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    // 2. ÖĞRENCİ GİRİŞİ (Firestore'da şifre ara)
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students') // Öğrencilerin kayıtlı olduğu koleksiyon
        .where('password', isEqualTo: password)
        .get();

    if (studentSnapshot.docs.isNotEmpty) {
      var studentDoc =
          studentSnapshot.docs.first; // Dokümanın tamamını alıyoruz
      var studentData = studentDoc.data();

      await prefs.setString('userRole', 'student');
      await prefs.setString(
        'studentId',
        studentDoc.id,
      ); // ID'yi SharedPreferences'a kaydediyoruz
      await prefs.setString(
        'studentName',
        "${studentData['firstName']} ${studentData['lastName']}",
      );

      if (!mounted) return;

      // Navigator.pushReplacement kısmını güncelledik:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StudentHomeScreen(studentId: studentDoc.id), // ID'yi gönderiyoruz
        ),
      );
    } else {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text("Hatalı Şifre!")));
    }
  }
}
