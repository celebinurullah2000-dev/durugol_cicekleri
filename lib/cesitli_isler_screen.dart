import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'nobetci_screen.dart';
import 'Ogrenci_Oturma_Duzeni_Screen.dart';
import 'Ogrenci_Gorevli_Goruntuleme_Screen.dart';

class OgrenciDevamsizlikScreen extends StatelessWidget {
  final String classId;
  final String studentId; // Giriş yapan öğrencinin ID'si

  const OgrenciDevamsizlikScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devamsızlık Bilgilerim"),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('devamsizliklar')
            .orderBy(
              'tarih',
              descending: true,
            ) // Bugünden geçmişe doğru sıralama
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz devamsızlık kaydı bulunmuyor.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var devamsizlikDocs = snapshot.data!.docs;
          List<String> gelmedigiTarihler = [];

          // Kayıtları tarayıp bu öğrencinin devamsız olduğu tarihleri ayıklayalım
          for (var doc in devamsizlikDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String tarihStr = data['tarih'] ?? '';
            var ogrencilerMap =
                data['ogrenciler'] as Map<String, dynamic>? ?? {};

            if (ogrencilerMap[studentId] == true) {
              // Tarihi GG.AA.YYYY formatına çevirelim
              String formatliTarih = tarihStr;
              try {
                List<String> parts = tarihStr.split('-');
                if (parts.length == 3) {
                  formatliTarih = "${parts[2]}.${parts[1]}.${parts[0]}";
                }
              } catch (_) {}

              gelmedigiTarihler.add(formatliTarih);
            }
          }

          return Column(
            children: [
              // Özet Kartı
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: gelmedigiTarihler.isEmpty
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gelmedigiTarihler.isEmpty
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Toplam Devamsızlık",
                      style: TextStyle(
                        fontSize: 16,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${gelmedigiTarihler.length} Gün",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gelmedigiTarihler.isEmpty
                          ? "Harika! Hiç devamsızlığınız yok."
                          : "Aşağıdaki tarihlerde okula gelmediğiniz kaydedilmiştir.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Gelmediğiniz Tarihler",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Liste
              Expanded(
                child: gelmedigiTarihler.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: gelmedigiTarihler.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(
                                  Icons.event_busy,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                gelmedigiTarihler[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Text(
                                "Gelmedi",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CesitliIslerScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const CesitliIslerScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<CesitliIslerScreen> createState() => _CesitliIslerScreenState();
}

class _CesitliIslerScreenState extends State<CesitliIslerScreen> {
  // İstediğiniz sıralamayla buton başlıkları
  final List<String> _menuItems = [
    "Nöbetçi",
    "Görevli",
    "Oturma Düzeni",
    "Doğum Günleri",
    "Devamsızlık",
    "Ders Programı",
    "Etkinlikler",
    "Yarışmalar",
    "Sözlük",
    "Atasözleri",
    "Deyimler",
    "Ritmik saymalar",
    "Çarpım Tablosu",
  ];

  int _selectedIndex = 0; // Aktif seçili olan butonun indeksini tutar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Çeşitli İşler")),
      body: Column(
        children: [
          // 2 Satırlık, kaydırılabilir veya sabit üst menü alanı
          Container(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: 110, // 2 satırın sığması için yüksekliği biraz artırdık
              child: GridView.builder(
                scrollDirection:
                    Axis.horizontal, // Yatay kaydırılabilir 2 satır için
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Tam 2 satır olacak
                  mainAxisSpacing: 8, // Butonlar arası dikey boşluk
                  crossAxisSpacing: 8, // Butonlar arası yatay boşluk
                  childAspectRatio: 0.35, // Butonların uzunluk/genişlik oranı
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedIndex == index;
                  return ChoiceChip(
                    label: Text(_menuItems[index]),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedIndex = index;

                        if (_menuItems[_selectedIndex] == "Nöbetçi") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NobetciScreen(
                                studentId: widget.studentId,
                                classId: widget.classId,
                                isTeacher:
                                    false, // Öğrenci yetkisi (salt okunur)
                              ),
                            ),
                          );
                        }

                        if (_menuItems[_selectedIndex] == "Oturma Düzeni") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciOturmaDuzeniScreen(
                                classId: widget.classId,
                              ),
                            ),
                          );
                        }

                        if (_menuItems[_selectedIndex] == "Devamsızlık") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OgrenciDevamsizlikScreen(
                                classId: widget.classId,
                                studentId: widget.studentId,
                              ),
                            ),
                          );
                        }
                        if (_menuItems[_selectedIndex] == "Görevli") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OgrenciGorevliGoruntulemeScreen(
                                    classId: widget.classId,
                                    studentId: widget.studentId,
                                  ),
                            ),
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),

          // Seçilen sekmeye göre değişecek içerik alanı
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "${_menuItems[_selectedIndex]} içeriği burada yer alacak.",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
