import 'package:flutter/material.dart';
import 'hafiza_oyunu_screen.dart'; // Hafıza oyunu ekranı importu
import 'es_anlamli_oyunu_screen.dart';
import 'Zit_Anlamli_Kelime_Sayfasi.dart';
import 'Toplama_Oyunu_Screen.dart';
import 'Cikarma_Oyunu_Screen.dart';

class OyunlarMenuScreen extends StatelessWidget {
  final String studentId;
  final String classId;

  const OyunlarMenuScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eğitici Oyunlar 🎮"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Yan yana 2 oyun kartı
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Hafıza Oyunu Kartı
            _buildOyunKarti(
              context,
              baslik: "Hafıza Oyunu",
              ikon: Icons.psychology,
              renk: Colors.purple.shade50,
              ikonRenk: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HafizaOyunuScreen(),
                  ),
                );
              },
            ),
            _buildOyunKarti(
              context,
              baslik: "Eş Anlamlılar",
              ikon: Icons.menu_book,
              renk: Colors.blue.shade50,
              ikonRenk: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EsAnlamliOyunuScreen(
                      studentId: studentId,
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            _buildOyunKarti(
              context,
              baslik: "Zıt Anlamlılar",
              ikon: Icons.swap_horiz, // İsteğe göre ikon değiştirebilirsin
              renk: Colors.green.shade50,
              ikonRenk: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ZitAnlamliKelimeSayfasi(
                      studentId: studentId,
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            _buildOyunKarti(
              context,
              baslik: "Toplama Oyunu",
              ikon: Icons.add_circle, // İsteğe göre ikon değiştirebilirsin
              renk: Colors.red.shade50,
              ikonRenk: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToplamaOyunuScreen(
                      studentId: studentId,
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            _buildOyunKarti(
              context,
              baslik: "Çıkarma Oyunu",
              ikon: Icons.remove_circle, // İsteğe göre ikon değiştirebilirsin
              renk: Colors.deepOrange.shade50,
              ikonRenk: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CikarmaOyunuScreen(
                      studentId: studentId,
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            // Buraya ileride başka oyunlar ekleyebilirsiniz
          ],
        ),
      ),
    );
  }

  Widget _buildOyunKarti(
    BuildContext context, {
    required String baslik,
    required IconData ikon,
    required Color renk,
    required Color ikonRenk,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: renk,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ikonRenk.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 48, color: ikonRenk),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ikonRenk,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
