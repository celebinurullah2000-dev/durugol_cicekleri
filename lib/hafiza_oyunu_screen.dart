import 'package:flutter/material.dart';
import 'dart:async';

class HafizaOyunuScreen extends StatefulWidget {
  const HafizaOyunuScreen({super.key});

  @override
  State<HafizaOyunuScreen> createState() => _HafizaOyunuScreenState();
}

class _HafizaOyunuScreenState extends State<HafizaOyunuScreen> {
  final List<IconData> _tumSimgeler = [
    Icons.pets,
    Icons.star,
    Icons.favorite,
    Icons.wb_sunny,
    Icons.ac_unit,
    Icons.bolt,
    Icons.face,
    Icons.local_florist,
    Icons.music_note,
    Icons.airplanemode_active,
  ];

  int _currentLevel = 1;
  late int _aktifKartSayisi;
  late List<Map<String, dynamic>> _kartlar;
  int? _oncekiSecimIndex;
  bool _beklemede = false;

  // Yeni Skor, Hamle ve Can Değişkenleri
  int _toplamPuan = 0;
  int _bulunanCift = 0;
  int _hamleSayisi = 0;
  int _kalanCan = 3;
  int _kalanHamleLimiti = 0;

  @override
  void initState() {
    super.initState();
    _seviyeyiBaslat();
  }

  void _seviyeyiBaslat() {
    _aktifKartSayisi = 4 + (_currentLevel - 1) * 2;
    if (_aktifKartSayisi > 20) _aktifKartSayisi = 20;

    int ciftSayisi = _aktifKartSayisi ~/ 2;

    // Kart sayısına göre dinamik hamle limiti (Örn: Çift başına 3-4 hata hakkı)
    _kalanHamleLimiti = ciftSayisi * 3;

    List<Map<String, dynamic>> geciciList = [];
    for (int i = 0; i < ciftSayisi; i++) {
      geciciList.add({
        'id': i,
        'icon': _tumSimgeler[i],
        'acik': false,
        'eslesti': false,
      });
      geciciList.add({
        'id': i,
        'icon': _tumSimgeler[i],
        'acik': false,
        'eslesti': false,
      });
    }
    geciciList.shuffle();

    setState(() {
      _kartlar = geciciList;
      _oncekiSecimIndex = null;
      _bulunanCift = 0;
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
      _kalanHamleLimiti--; // Her yanlış veya doğru hamlede limit azalır
      int oncekiIndex = _oncekiSecimIndex!;

      if (_kartlar[oncekiIndex]['id'] == _kartlar[index]['id']) {
        // Eşleşti! Az hamle yapana daha çok puan
        _kartlar[oncekiIndex]['eslesti'] = true;
        _kartlar[index]['eslesti'] = true;
        _oncekiSecimIndex = null;
        _bulunanCift++;

        // Dinamik Puan Hesaplama (Seviye ve hıza göre)
        int kazanilanPuan = (20 - _hamleSayisi).clamp(5, 20) * _currentLevel;
        _toplamPuan += kazanilanPuan;

        // Bölüm bitti mi?
        if (_bulunanCift == _aktifKartSayisi ~/ 2) {
          _seviyeBittiDiyalogGoster();
        }
      } else {
        // Eşleşmedi
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

      // Hamle Limiti bitti mi kontrolü
      if (_kalanHamleLimiti <= 0 && _bulunanCift < _aktifKartSayisi ~/ 2) {
        _canKaybet();
      }
    }
  }

  void _canKaybet() {
    setState(() {
      _kalanCan--;
      // Açık kalmış eşleşmemiş tüm kartları kapat
      for (var kart in _kartlar) {
        if (!kart['eslesti']) {
          kart['acik'] = false;
        }
      }
      _oncekiSecimIndex = null;

      // Canı kaldıysa yeni hamle hakkı ver ve kartları yeniden karıştır
      if (_kalanCan > 0) {
        _kalanHamleLimiti = (_aktifKartSayisi ~/ 2) * 3;
        _kartlar.shuffle();
      }
    });

    if (_kalanCan <= 0) {
      _oyunBittiDiyalogGoster();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Hamle hakkın bitti! Bir can kaybettin ve kartlar karıştırıldı! ⚠️",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _seviyeBittiDiyalogGoster() {
    bool sonLevelMi = _aktifKartSayisi >= 20;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          sonLevelMi ? "Tebrikler Şampiyon! 🏆" : "Bölüm Tamamlandı! 🎉",
        ),
        content: Text(
          sonLevelMi
              ? "Tüm seviyeleri bitirdin!\nToplam Puanın: $_toplamPuan"
              : "$_currentLevel. Seviyeyi geçtin!\nPuanın: $_toplamPuan\nSonraki seviyeye geçelim mi?",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (sonLevelMi) {
                  _currentLevel = 1;
                  _toplamPuan = 0;
                  _kalanCan = 3;
                } else {
                  _currentLevel++;
                }
                _seviyeyiBaslat();
              });
            },
            child: Text(sonLevelMi ? "Yeniden Başla" : "Sonraki Seviye"),
          ),
        ],
      ),
    );
  }

  void _oyunBittiDiyalogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Oyun Bitti! 😢"),
        content: Text("Canların bitti.\nToplam Puanın: $_toplamPuan"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentLevel = 1;
                _toplamPuan = 0;
                _kalanCan = 3;
                _seviyeyiBaslat();
              });
            },
            child: const Text("Tekrar Oyna"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int sutunSayisi = _aktifKartSayisi <= 6 ? 2 : 4;

    return Scaffold(
      appBar: AppBar(
        title: Text("Hafıza Oyunu - Seviye $_currentLevel"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _currentLevel = 1;
                _toplamPuan = 0;
                _kalanCan = 3;
                _seviyeyiBaslat();
              });
            },
            tooltip: "Yeniden Başlat",
          ),
        ],
      ),
      body: Column(
        children: [
          // Bilgi Paneli (Can, Puan, Hamle Limiti)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Can Göstergesi (Kalpler)
                Row(
                  children: List.generate(
                    3,
                    (index) => Icon(
                      index < _kalanCan
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
                Text(
                  "Puan: $_toplamPuan",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  "Hak: $_kalanHamleLimiti",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kalanHamleLimiti <= 3
                        ? Colors.red
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: sutunSayisi,
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
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: kartAcik
                          ? Icon(
                              _kartlar[index]['icon'],
                              size: 36,
                              color: Colors.indigo.shade700,
                            )
                          : const Icon(
                              Icons.question_mark,
                              size: 28,
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
