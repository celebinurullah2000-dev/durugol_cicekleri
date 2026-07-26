import 'dart:math';
import 'package:flutter/material.dart';

class ZitAnlamliKelimeSayfasi extends StatefulWidget {
  final String studentId;
  final String classId;

  const ZitAnlamliKelimeSayfasi({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<ZitAnlamliKelimeSayfasi> createState() =>
      _ZitAnlamliKelimeSayfasiState();
}

class _ZitAnlamliKelimeSayfasiState extends State<ZitAnlamliKelimeSayfasi> {
  // İlkokul seviyesine uygun zıt anlamlı kelime listesi
  final List<Map<String, String>> _hamKelimeListesi = [
    {
      "kelime": "Büyük",
      "dogru": "Küçük",
      "yanlis1": "İri",
      "yanlis2": "Ufak",
      "yanlis3": "Uzun",
    },
    {
      "kelime": "Yaşlı",
      "dogru": "Genç",
      "yanlis1": "İhtiyar",
      "yanlis2": "Bebek",
      "yanlis3": "Çocuk",
    },
    {
      "kelime": "Siyah",
      "dogru": "Beyaz",
      "yanlis1": "Kara",
      "yanlis2": "Gri",
      "yanlis3": "Mavi",
    },
    {
      "kelime": "Uzun",
      "dogru": "Kısa",
      "yanlis1": "Yüksek",
      "yanlis2": "Geniş",
      "yanlis3": "Büyük",
    },
    {
      "kelime": "Hızlı",
      "dogru": "Yavaş",
      "yanlis1": "Süratli",
      "yanlis2": "Çabuk",
      "yanlis3": "Aceleci",
    },
    {
      "kelime": "Zengin",
      "dogru": "Fakir",
      "yanlis1": "Varlıklı",
      "yanlis2": "Paralı",
      "yanlis3": "Cimri",
    },
    {
      "kelime": "Açık",
      "dogru": "Kapalı",
      "yanlis1": "Geniş",
      "yanlis2": "Ferah",
      "yanlis3": "Temiz",
    },
    {
      "kelime": "Acı",
      "dogru": "Tatlı",
      "yanlis1": "Ekşi",
      "yanlis2": "Tuzlu",
      "yanlis3": "Biberli",
    },
    {
      "kelime": "Güzel",
      "dogru": "Çirkin",
      "yanlis1": "Hoş",
      "yanlis2": "İyi",
      "yanlis3": "Şirin",
    },
    {
      "kelime": "Uzak",
      "dogru": "Yakın",
      "yanlis1": "Irak",
      "yanlis2": "İçeri",
      "yanlis3": "Dışarı",
    },
    {
      "kelime": "Ağır",
      "dogru": "Hafif",
      "yanlis1": "Yavaş",
      "yanlis2": "Zor",
      "yanlis3": "Koyu",
    },
    {
      "kelime": "İyi",
      "dogru": "Kötü",
      "yanlis1": "Güzel",
      "yanlis2": "Fena",
      "yanlis3": "Doğru",
    },
    {
      "kelime": "Yeni",
      "dogru": "Eski",
      "yanlis1": "Taze",
      "yanlis2": "Modern",
      "yanlis3": "Antika",
    },
    {
      "kelime": "İlk",
      "dogru": "Son",
      "yanlis1": "Önce",
      "yanlis2": "Sonra",
      "yanlis3": "Orta",
    },
    {
      "kelime": "Var",
      "dogru": "Yok",
      "yanlis1": "Gel",
      "yanlis2": "Git",
      "yanlis3": "Al",
    },
    {
      "kelime": "Gel",
      "dogru": "Git",
      "yanlis1": "Koş",
      "yanlis2": "Dur",
      "yanlis3": "Bak",
    },
    {
      "kelime": "İn",
      "dogru": "Çık",
      "yanlis1": "Yat",
      "yanlis2": "Kalk",
      "yanlis3": "Atla",
    },
    {
      "kelime": "Al",
      "dogru": "Ver",
      "yanlis1": "tut",
      "yanlis2": "Bırak",
      "yanlis3": "Getir",
    },
    {
      "kelime": "Ön",
      "dogru": "Arka",
      "yanlis1": "Yan",
      "yanlis2": "Üst",
      "yanlis3": "Alt",
    },
    {
      "kelime": "Alt",
      "dogru": "Üst",
      "yanlis1": "Aşağı",
      "yanlis2": "İçeri",
      "yanlis3": "Dışarı",
    },
    {
      "kelime": "Aşağı",
      "dogru": "Yukarı",
      "yanlis1": "Alt",
      "yanlis2": "Üst",
      "yanlis3": "Derin",
    },
    {
      "kelime": "İçeri",
      "dogru": "Dışarı",
      "yanlis1": "Uzakta",
      "yanlis2": "Yakında",
      "yanlis3": "Yanda",
    },
    {
      "kelime": "Gece",
      "dogru": "Gündüz",
      "yanlis1": "Akşam",
      "yanlis2": "Sabah",
      "yanlis3": "Öğle",
    },
    {
      "kelime": "Sabah",
      "dogru": "Akşam",
      "yanlis1": "Gece",
      "yanlis2": "Gündüz",
      "yanlis3": "Öğle",
    },
    {
      "kelime": "Erken",
      "dogru": "Geç",
      "yanlis1": "Hızlı",
      "yanlis2": "Yavaş",
      "yanlis3": "Vakitli",
    },
    {
      "kelime": "Zor",
      "dogru": "Kolay",
      "yanlis1": "Basit",
      "yanlis2": "Güç",
      "yanlis3": "Ağır",
    },
    {
      "kelime": "Temiz",
      "dogru": "Kirli",
      "yanlis1": "Pak",
      "yanlis2": "Lekesiz",
      "yanlis3": "Düzenli",
    },
    {
      "kelime": "Dolu",
      "dogru": "Boş",
      "yanlis1": "Tıklim",
      "yanlis2": "Açık",
      "yanlis3": "Kapalı",
    },
    {
      "kelime": "Cimri",
      "dogru": "Cömert",
      "yanlis1": "Eli sıkı",
      "yanlis2": "Zengin",
      "yanlis3": "Fakir",
    },
    {
      "kelime": "Mutlu",
      "dogru": "Üzgün",
      "yanlis1": "Sevinçli",
      "yanlis2": "Neşeli",
      "yanlis3": "Kederli",
    },
    {
      "kelime": "Zayıf",
      "dogru": "Şişman",
      "yanlis1": "Çelimsiz",
      "yanlis2": "İnce",
      "yanlis3": "Güçlü",
    },
    {
      "kelime": "Geniş",
      "dogru": "Dar",
      "yanlis1": "Büyük",
      "yanlis2": "Ufak",
      "yanlis3": "Feram",
    },
    {
      "kelime": "Kalın",
      "dogru": "İnce",
      "yanlis1": "Dar",
      "yanlis2": "Geniş",
      "yanlis3": "Uzun",
    },
    {
      "kelime": "Sert",
      "dogru": "Yumuşak",
      "yanlis1": "Katı",
      "yanlis2": "Kaba",
      "yanlis3": "Sağlam",
    },
    {
      "kelime": "Doğru",
      "dogru": "Yanlış",
      "yanlis1": "Gerçek",
      "yanlis2": "Yalan",
      "yanlis3": "Hatalı",
    },
    {
      "kelime": "Dost",
      "dogru": "Düşman",
      "yanlis1": "Arkadaş",
      "yanlis2": "Yabancı",
      "yanlis3": "Komşu",
    },
    {
      "kelime": "Cesur",
      "dogru": "Korkak",
      "yanlis1": "Yiğit",
      "yanlis2": "Atılgan",
      "yanlis3": "Çekingen",
    },
    {
      "kelime": "Faydalı",
      "dogru": "Zararlı",
      "yanlis1": "Yararlı",
      "yanlis2": "İyi",
      "yanlis3": "Kötü",
    },
    {
      "kelime": "Barış",
      "dogru": "Savaş",
      "yanlis1": "Kavga",
      "yanlis2": "Sulh",
      "yanlis3": "Harp",
    },
    {
      "kelime": "Bayat",
      "dogru": "Taze",
      "yanlis1": "Güzel",
      "yanlis2": "Kuru",
      "yanlis3": "Yumuşak",
    },
    {
      "kelime": "Boş",
      "dogru": "Dolu",
      "yanlis1": "Açık",
      "yanlis2": "Kapalı",
      "yanlis3": "Temiz",
    },
    {
      "kelime": "Cılız",
      "dogru": "Gürbüz",
      "yanlis1": "Zayıf",
      "yanlis2": "İnce",
      "yanlis3": "Kısa",
    },
    {
      "kelime": "Çalışkan",
      "dogru": "Tembel",
      "yanlis1": "Akıllı",
      "yanlis2": "Başarılı",
      "yanlis3": "Yaramaz",
    },
    {
      "kelime": "Derin",
      "dogru": "Sığ",
      "yanlis1": "Yüksek",
      "yanlis2": "Alçak",
      "yanlis3": "Geniş",
    },
    {
      "kelime": "Diri",
      "dogru": "Ölü",
      "yanlis1": "Canlı",
      "yanlis2": "Yaşayan",
      "yanlis3": "Yorgun",
    },
    {
      "kelime": "Doğal",
      "dogru": "Yapay",
      "yanlis1": "Hakiki",
      "yanlis2": "Sahte",
      "yanlis3": "Katışıksız",
    },
    {
      "kelime": "Durgun",
      "dogru": "Hareketli",
      "yanlis1": "Sakin",
      "yanlis2": "Yavaş",
      "yanlis3": "Hızlı",
    },
    {
      "kelime": "Eksik",
      "dogru": "Tam",
      "yanlis1": "Az",
      "yanlis2": "Çok",
      "yanlis3": "Yarım",
    },
    {
      "kelime": "Fakir",
      "dogru": "Zengin",
      "yanlis1": "Yoksul",
      "yanlis2": "Paralı",
      "yanlis3": "Cimri",
    },
    {
      "kelime": "Giriş",
      "dogru": "Çıkış",
      "yanlis1": "Kapı",
      "yanlis2": "Koridor",
      "yanlis3": "Pencere",
    },
    {
      "kelime": "Gölge",
      "dogru": "Işık",
      "yanlis1": "Karanlık",
      "yanlis2": "Güneş",
      "yanlis3": "Bulut",
    },
    {
      "kelime": "Hür",
      "dogru": "Tutsak",
      "yanlis1": "Özgür",
      "yanlis2": "Esir",
      "yanlis3": "Yalnız",
    },
    {
      "kelime": "Irak",
      "dogru": "Yakın",
      "yanlis1": "Uzak",
      "yanlis2": "İçeri",
      "yanlis3": "Dışarı",
    },
    {
      "kelime": "İhtiyar",
      "dogru": "Genç",
      "yanlis1": "Yaşlı",
      "yanlis2": "Çocuk",
      "yanlis3": "Bebek",
    },

    {
      "kelime": "Kâr",
      "dogru": "Zarar",
      "yanlis1": "Kazanç",
      "yanlis2": "Para",
      "yanlis3": "Ücret",
    },
    {
      "kelime": "Kuru",
      "dogru": "Yaş",
      "yanlis1": "Islak",
      "yanlis2": "Nemli",
      "yanlis3": "Sulu",
    },
    {
      "kelime": "Mat",
      "dogru": "Parlak",
      "yanlis1": "Soluk",
      "yanlis2": "Renksiz",
      "yanlis3": "Işıltılı",
    },
    {
      "kelime": "Ödül",
      "dogru": "Ceza",
      "yanlis1": "Mükafat",
      "yanlis2": "Hediye",
      "yanlis3": "Suç",
    },

    {
      "kelime": "Sabah",
      "dogru": "Akşam",
      "yanlis1": "Gece",
      "yanlis2": "Öğle",
      "yanlis3": "Gündüz",
    },
    {
      "kelime": "Sakin",
      "dogru": "Hırçın",
      "yanlis1": "Sessiz",
      "yanlis2": "Uslu",
      "yanlis3": "Durgun",
    },
    {
      "kelime": "Sevinç",
      "dogru": "Üzüntü",
      "yanlis1": "Neşe",
      "yanlis2": "Mutluluk",
      "yanlis3": "Keder",
    },
    {
      "kelime": "Sığ",
      "dogru": "Derin",
      "yanlis1": "Yüksek",
      "yanlis2": "Alçak",
      "yanlis3": "Geniş",
    },
    {
      "kelime": "Suçlu",
      "dogru": "Masum",
      "yanlis1": "Kabahatli",
      "yanlis2": "Temiz",
      "yanlis3": "Doğru",
    },

    {
      "kelime": "Tavan",
      "dogru": "Taban",
      "yanlis1": "Duvar",
      "yanlis2": "Zemin",
      "yanlis3": "Çatı",
    },
    {
      "kelime": "Tek",
      "dogru": "Çift",
      "yanlis1": "Bir",
      "yanlis2": "İki",
      "yanlis3": "Yalnız",
    },
    {
      "kelime": "Ucuz",
      "dogru": "Pahalı",
      "yanlis1": "Bedava",
      "yanlis2": "Hesaplı",
      "yanlis3": "Değerli",
    },
    {
      "kelime": "Üstün",
      "dogru": "Zayıf",
      "yanlis1": "Başarılı",
      "yanlis2": "İyi",
      "yanlis3": "Kötü",
    },
    {
      "kelime": "Vahşi",
      "dogru": "Evcil",
      "yanlis1": "Korkunç",
      "yanlis2": "Yırtıcı",
      "yanlis3": "Tatlı",
    },
    {
      "kelime": "Yalan",
      "dogru": "Gerçek",
      "yanlis1": "Doğru",
      "yanlis2": "Yanlış",
      "yanlis3": "Hayal",
    },
    {
      "kelime": "Yasak",
      "dogru": "Serbest",
      "yanlis1": "İzinli",
      "yanlis2": "Kapalı",
      "yanlis3": "Müsaade",
    },
    {
      "kelime": "Yerli",
      "dogru": "Yabancı",
      "yanlis1": "Milli",
      "yanlis2": "Halk",
      "yanlis3": "Komşu",
    },
    {
      "kelime": "Yüksek",
      "dogru": "Alçak",
      "yanlis1": "Uzak",
      "yanlis2": "Derin",
      "yanlis3": "Kısa",
    },
    {
      "kelime": "Cevap",
      "dogru": "Soru",
      "yanlis1": "Yanıt",
      "yanlis2": "Problem",
      "yanlis3": "Test",
    },
    {
      "kelime": "Dost",
      "dogru": "Düşman",
      "yanlis1": "Arkadaş",
      "yanlis2": "Yabancı",
      "yanlis3": "Akraba",
    },
    {
      "kelime": "Eksik",
      "dogru": "Fazla",
      "yanlis1": "Tam",
      "yanlis2": "Az",
      "yanlis3": "Çok",
    },
    {
      "kelime": "Fena",
      "dogru": "İyi",
      "yanlis1": "Kötü",
      "yanlis2": "Güzel",
      "yanlis3": "Hoş",
    },
    {
      "kelime": "Gündüz",
      "dogru": "Gece",
      "yanlis1": "Sabah",
      "yanlis2": "Akşam",
      "yanlis3": "Öğle",
    },
    {
      "kelime": "Hatırlamak",
      "dogru": "Unutmak",
      "yanlis1": "Bilmek",
      "yanlis2": "Öğrenmek",
      "yanlis3": "Duymak",
    },
    {
      "kelime": "İhtiyar",
      "dogru": "Genç",
      "yanlis1": "Yaşlı",
      "yanlis2": "Çocuk",
      "yanlis3": "Bebek",
    },

    {
      "kelime": "Kahraman",
      "dogru": "Korkak",
      "yanlis1": "Cesur",
      "yanlis2": "Yiğit",
      "yanlis3": "Güçlü",
    },

    {
      "kelime": "Medeni",
      "dogru": "İlkel",
      "yanlis1": "Modern",
      "yanlis2": "Eski",
      "yanlis3": "Yeni",
    },
    {
      "kelime": "Neşeli",
      "dogru": "Kederli",
      "yanlis1": "Mutlu",
      "yanlis2": "Sevinçli",
      "yanlis3": "Üzgün",
    },

    {
      "kelime": "Parlak",
      "dogru": "Mat",
      "yanlis1": "Işıklı",
      "yanlis2": "Renkli",
      "yanlis3": "Temiz",
    },
    {
      "kelime": "Reddetmek",
      "dogru": "Kabul etmek",
      "yanlis1": "İstemek",
      "yanlis2": "Almak",
      "yanlis3": "Vermek",
    },

    {
      "kelime": "Tembel",
      "dogru": "Çalışkan",
      "yanlis1": "Yavaş",
      "yanlis2": "Uykucu",
      "yanlis3": "Akıllı",
    },
    {
      "kelime": "Uslu",
      "dogru": "Yaramaz",
      "yanlis1": "Sakin",
      "yanlis2": "Dürüst",
      "yanlis3": "Akıllı",
    },
    {
      "kelime": "Üretim",
      "dogru": "Tüketim",
      "yanlis1": "Fabrika",
      "yanlis2": "Mal",
      "yanlis3": "Satış",
    },
    {
      "kelime": "Yavaş",
      "dogru": "Hızlı",
      "yanlis1": "Ağır",
      "yanlis2": "Çabuk",
      "yanlis3": "Süratli",
    },
    {
      "kelime": "Zarar",
      "dogru": "Kâr",
      "yanlis1": "Ziyan",
      "yanlis2": "Kötülük",
      "yanlis3": "Borç",
    },
    {
      "kelime": "Zengin",
      "dogru": "Yoksul",
      "yanlis1": "Varlıklı",
      "yanlis2": "Paralı",
      "yanlis3": "Fakir",
    },
    {
      "kelime": "Sevinmek",
      "dogru": "Üzülmek",
      "yanlis1": "Gülmek",
      "yanlis2": "Ağlamak",
      "yanlis3": "Kızmak",
    },
  ];

  late List<Map<String, String>> _kelimeListesi;
  late int _toplamSoru;

  int _currentIndex = 0;
  int _puan = 0;
  bool _soruCevaplandi = false;
  String? _secilenCevap;
  List<String> _karisikSecenekler = [];

  @override
  void initState() {
    super.initState();
    _oyunuSifirla();
  }

  void _oyunuSifirla() {
    _kelimeListesi = List.from(_hamKelimeListesi);
    _kelimeListesi.shuffle(Random());
    _toplamSoru = 10;
    _currentIndex = 0;
    _puan = 0;
    _soruCevaplandi = false;
    _secilenCevap = null;
    _secenekleriHazirla();
  }

  void _secenekleriHazirla() {
    final mevcutSoru = _kelimeListesi[_currentIndex];
    _karisikSecenekler = [
      mevcutSoru["dogru"]!,
      mevcutSoru["yanlis1"]!,
      mevcutSoru["yanlis2"]!,
      mevcutSoru["yanlis3"]!,
    ];
    _karisikSecenekler.shuffle(Random());
  }

  void _cevabiKontrolEt(String secim) {
    if (_soruCevaplandi) return;

    setState(() {
      _soruCevaplandi = true;
      _secilenCevap = secim;

      if (secim == _kelimeListesi[_currentIndex]["dogru"]) {
        _puan += 10;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _toplamSoru - 1) {
          _currentIndex++;
          _soruCevaplandi = false;
          _secilenCevap = null;
          _secenekleriHazirla();
        } else {
          _oyunBittiDialogGoster();
        }
      });
    });
  }

  void _oyunBittiDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Tebrikler! 🎉"),
        content: Text(
          "Oyunu tamamladın!\nToplam Puanın: $_puan / ${_toplamSoru * 10}",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _oyunuSifirla();
              });
            },
            child: const Text("Tekrar Oyna"),
          ),
        ],
      ),
    );
  }

  Color _butonRengi(String secenek) {
    if (!_soruCevaplandi) return Colors.white;

    final dogruCevap = _kelimeListesi[_currentIndex]["dogru"];

    if (secenek == dogruCevap) {
      return Colors.green.shade300; // Doğru cevap her zaman yeşil
    }
    if (secenek == _secilenCevap) {
      return Colors.red.shade300; // Yanlış seçildiyse kırmızı
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final mevcutSoru = _kelimeListesi[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zıt Anlamlılar Oyunu"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Skor ve Soru Sayacı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    "Soru: ${_currentIndex + 1}/$_toplamSoru",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.deepPurple.shade100,
                ),
                Chip(
                  label: Text(
                    "Puan: $_puan",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Kelime Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const Text(
                      "Aşağıdaki kelimenin ZIT anlamlısı hangisidir?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      mevcutSoru["kelime"]!,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Seçenekler
            Expanded(
              child: ListView.builder(
                itemCount: _karisikSecenekler.length,
                itemBuilder: (context, index) {
                  final secenek = _karisikSecenekler[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _butonRengi(secenek),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.deepPurple.shade200,
                            width: 1.5,
                          ),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _cevabiKontrolEt(secenek),
                      child: Text(
                        secenek,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
