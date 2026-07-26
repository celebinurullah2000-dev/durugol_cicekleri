import 'package:flutter/material.dart';
import 'dart:async';

class HafizaOyunuScreen extends StatefulWidget {
  const HafizaOyunuScreen({super.key});

  @override
  State<HafizaOyunuScreen> createState() => _HafizaOyunuScreenState();
}

class _HafizaOyunuScreenState extends State<HafizaOyunuScreen> {
  // Oyun kartlarında kullanılacak ikon veya görseller (Örn: Hayvanlar / Nesneler)
  final List<IconData> _kartSimgeleri = [
    Icons.pets,
    Icons.star,
    Icons.favorite,
    Icons.wb_sunny,
    Icons.ac_unit,
    Icons.bolt,
  ];

  late List<Map<String, dynamic>> _kartlar;
  int? _oncekiSecimIndex;
  bool _beklemede = false;
  int _skor = 0;
  int _hamleSayisi = 0;

  @override
  void initState() {
    super.initState();
    _oyunuBaslat();
  }

  void _oyunuBaslat() {
    // 6 simgeden çift oluşturarak 12 kartlık bir liste yapalım
    List<Map<String, dynamic>> geciciList = [];
    for (int i = 0; i < _kartSimgeleri.length; i++) {
      geciciList.add({
        'id': i,
        'icon': _kartSimgeleri[i],
        'acik': false,
        'eslesti': false,
      });
      geciciList.add({
        'id': i,
        'icon': _kartSimgeleri[i],
        'acik': false,
        'eslesti': false,
      });
    }
    geciciList.shuffle(); // Kartları karıştır
    setState(() {
      _kartlar = geciciList;
      _oncekiSecimIndex = null;
      _skor = 0;
      _hamleSayisi = 0;
      _beklemede = false;
    });
  }

  void _kartTiklandi(int index) {
    if (_beklemede) return;
    if (_kartlar[index]['acik'] || _kartlar[index]['eslesti']) return;

    setState(() {
      _kartlar[index]['acik'] = true;
    });

    if (_oncekiSecimIndex == null) {
      _oncekiSecimIndex = index;
    } else {
      _hamleSayisi++;
      int oncekiIndex = _oncekiSecimIndex!;

      // İki kart aynı mı kontrol et
      if (_kartlar[oncekiIndex]['id'] == _kartlar[index]['id']) {
        // Eşleşti
        _kartlar[oncekiIndex]['eslesti'] = true;
        _kartlar[index]['eslesti'] = true;
        _oncekiSecimIndex = null;
        _skor++;

        // Oyun bitti mi kontrolü
        if (_skor == _kartSimgeleri.length) {
          _oyunBitirmeDiyalogGoster();
        }
      } else {
        // Eşleşmedi, kısa bir süre gösterip tekrar kapat
        _beklemede = true;
        Timer(const Duration(milliseconds: 800), () {
          setState(() {
            _kartlar[oncekiIndex]['acik'] = false;
            _kartlar[index]['acik'] = false;
            _oncekiSecimIndex = null;
            _beklemede = false;
          });
        });
      }
    }
  }

  void _oyunBitirmeDiyalogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Tebrikler! 🎉"),
        content: Text(
          "Tebrikler, tüm eşleşmeleri buldun!\nToplam Hamle: $_hamleSayisi",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _oyunuBaslat();
            },
            child: const Text("Tekrar Oyna"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hafıza Kartı Oyunu"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _oyunuBaslat,
            tooltip: "Yeniden Başlat",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Hamle: $_hamleSayisi",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Bulunan: $_skor / ${_kartSimgeleri.length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 sütunlu görünüm
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _kartlar.length,
              itemBuilder: (context, index) {
                bool kartAcik =
                    _kartlar[index]['acik'] || _kartlar[index]['eslesti'];
                return GestureDetector(
                  onTap: () => _kartTiklandi(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: kartAcik ? Colors.white : Colors.indigo,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.indigo.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: kartAcik
                          ? Icon(
                              _kartlar[index]['icon'],
                              size: 40,
                              color: Colors.indigo.shade700,
                            )
                          : const Icon(
                              Icons.question_mark,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
