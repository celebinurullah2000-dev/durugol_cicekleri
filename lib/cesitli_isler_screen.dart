import 'package:flutter/material.dart';
import 'nobetci_screen.dart';
import 'Ogrenci_Oturma_Duzeni_Screen.dart';

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
