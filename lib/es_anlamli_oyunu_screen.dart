import 'package:flutter/material.dart';

class EsAnlamliOyunuScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const EsAnlamliOyunuScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<EsAnlamliOyunuScreen> createState() => _EsAnlamliOyunuScreenState();
}

class _EsAnlamliOyunuScreenState extends State<EsAnlamliOyunuScreen> {
  // İlkokul seviyesine uygun eş anlamlı kelime havuzu
  final List<Map<String, String>> _kelimeListesi = [
    {
      "kelime": "Mektep",
      "dogru": "Okul",
      "yanlis1": "Öğrenci",
      "yanlis2": "Sınıf",
      "yanlis3": "Kitap",
    },
    {
      "kelime": "Öğrenci",
      "dogru": "Talebe",
      "yanlis1": "Öğretmen",
      "yanlis2": "Okul",
      "yanlis3": "Sıra",
    },
    {
      "kelime": "Öğretmen",
      "dogru": "Muallim",
      "yanlis1": "Öğrenci",
      "yanlis2": "Müdür",
      "yanlis3": "Tatil",
    },
    {
      "kelime": "Misafir",
      "dogru": "Konuk",
      "yanlis1": "Ev sahibi",
      "yanlis2": "Komşu",
      "yanlis3": "Akraba",
    },
    {
      "kelime": "Hediye",
      "dogru": "Armağan",
      "yanlis1": "Paket",
      "yanlis2": "Kutu",
      "yanlis3": "Kurdele",
    },
    {
      "kelime": "Önemli",
      "dogru": "Mühim",
      "yanlis1": "Kolay",
      "yanlis2": "Basit",
      "yanlis3": "Zor",
    },
    {
      "kelime": "Sonbahar",
      "dogru": "Güz",
      "yanlis1": "İlkbahar",
      "yanlis2": "Yaz",
      "yanlis3": "Kış",
    },
    {
      "kelime": "Yıl",
      "dogru": "Sene",
      "yanlis1": "Ay",
      "yanlis2": "Gün",
      "yanlis3": "Hafta",
    },
    {
      "kelime": "Yaşlı",
      "dogru": "İhtiyar",
      "yanlis1": "Genç",
      "yanlis2": "Çocuk",
      "yanlis3": "Bebek",
    },
    {
      "kelime": "Kırmızı",
      "dogru": "Al",
      "yanlis1": "Mavi",
      "yanlis2": "Sarı",
      "yanlis3": "Yeşil",
    },
    {
      "kelime": "Siyah",
      "dogru": "Kara",
      "yanlis1": "Beyaz",
      "yanlis2": "Gri",
      "yanlis3": "Pembe",
    },
    {
      "kelime": "Beyaz",
      "dogru": "Ak",
      "yanlis1": "Kara",
      "yanlis2": "Mor",
      "yanlis3": "Turuncu",
    },
    {
      "kelime": "Doktor",
      "dogru": "Hekim",
      "yanlis1": "Hemşire",
      "yanlis2": "Hasta",
      "yanlis3": "İlaç",
    },
    {
      "kelime": "Fakir",
      "dogru": "Yoksul",
      "yanlis1": "Zengin",
      "yanlis2": "Parasız",
      "yanlis3": "Cimri",
    },
    {
      "kelime": "Zengin",
      "dogru": "Varlıklı",
      "yanlis1": "Yoksul",
      "yanlis2": "Fakir",
      "yanlis3": "Mutlu",
    },
    {
      "kelime": "Nehir",
      "dogru": "Irmak",
      "yanlis1": "Deniz",
      "yanlis2": "Göl",
      "yanlis3": "Okyanus",
    },
    {
      "kelime": "Vakit",
      "dogru": "Zaman",
      "yanlis1": "Saat",
      "yanlis2": "Dakika",
      "yanlis3": "Gün",
    },
    {
      "kelime": "Fayda",
      "dogru": "Yarar",
      "yanlis1": "Zarar",
      "yanlis2": "Kötülük",
      "yanlis3": "Hata",
    },
    {
      "kelime": "Cevap",
      "dogru": "Yanıt",
      "yanlis1": "Soru",
      "yanlis2": "Problem",
      "yanlis3": "Test",
    },
    {
      "kelime": "Soru",
      "dogru": "Sual",
      "yanlis1": "Yanıt",
      "yanlis2": "Cevap",
      "yanlis3": "Çözüm",
    },
    {
      "kelime": "Özgür",
      "dogru": "Hür",
      "yanlis1": "Tutsak",
      "yanlis2": "Esir",
      "yanlis3": "Yalnız",
    },
    {
      "kelime": "Uzak",
      "dogru": "Irak",
      "yanlis1": "Yakın",
      "yanlis2": "İçeri",
      "yanlis3": "Dışarı",
    },
    {
      "kelime": "Hızlı",
      "dogru": "Süratli",
      "yanlis1": "Yavaş",
      "yanlis2": "Ağır",
      "yanlis3": "Durağan",
    },
    {
      "kelime": "Kuvvetli",
      "dogru": "Güçlü",
      "yanlis1": "Zayıf",
      "yanlis2": "Çelimsiz",
      "yanlis3": "Küçük",
    },
    {
      "kelime": "Küçük",
      "dogru": "Ufak",
      "yanlis1": "Büyük",
      "yanlis2": "İri",
      "yanlis3": "Dev",
    },
    {
      "kelime": "Büyük",
      "dogru": "İri",
      "yanlis1": "Ufak",
      "yanlis2": "Minik",
      "yanlis3": "Küçük",
    },
    {
      "kelime": "Millet",
      "dogru": "Ulus",
      "yanlis1": "Devlet",
      "yanlis2": "Vatandaş",
      "yanlis3": "Şehir",
    },
    {
      "kelime": "Önder",
      "dogru": "Lider",
      "yanlis1": "Takım",
      "yanlis2": "Üye",
      "yanlis3": "Arkadaş",
    },
    {
      "kelime": "Kelime",
      "dogru": "Sözcük",
      "yanlis1": "Cümle",
      "yanlis2": "Harf",
      "yanlis3": "Hece",
    },
    {
      "kelime": "Cümle",
      "dogru": "Tümce",
      "yanlis1": "Sözcük",
      "yanlis2": "Kelime",
      "yanlis3": "Paragraf",
    },
    {
      "kelime": "Yaşam",
      "dogru": "Hayat",
      "yanlis1": "Ölüm",
      "yanlis2": "Nefes",
      "yanlis3": "Uyku",
    },
    {
      "kelime": "Hatıra",
      "dogru": "Anı",
      "yanlis1": "Hayal",
      "yanlis2": "Rüya",
      "yanlis3": "Gelecek",
    },
    {
      "kelime": "Hikaye",
      "dogru": "Öykü",
      "yanlis1": "Masal",
      "yanlis2": "Roman",
      "yanlis3": "Şiir",
    },
    {
      "kelime": "Barış",
      "dogru": "Sulh",
      "yanlis1": "Savaş",
      "yanlis2": "Kavga",
      "yanlis3": "Gürültü",
    },
    {
      "kelime": "Savaş",
      "dogru": "Harp",
      "yanlis1": "Sulh",
      "yanlis2": "Barış",
      "yanlis3": "Dostluk",
    },
    {
      "kelime": "Lisan",
      "dogru": "Dil",
      "yanlis1": "Konuşma",
      "yanlis2": "Ses",
      "yanlis3": "Yazı",
    },
    {
      "kelime": "Tabiat",
      "dogru": "Doğa",
      "yanlis1": "Şehir",
      "yanlis2": "Bina",
      "yanlis3": "Fabrika",
    },

    {
      "kelime": "Güzel",
      "dogru": "Hoş",
      "yanlis1": "Çirkin",
      "yanlis2": "Kötü",
      "yanlis3": "Fena",
    },
    {
      "kelime": "Fena",
      "dogru": "Kötü",
      "yanlis1": "İyi",
      "yanlis2": "Güzel",
      "yanlis3": "Hoş",
    },
    {
      "kelime": "Imkan",
      "dogru": "Olanak",
      "yanlis1": "Engel",
      "yanlis2": "Zorluk",
      "yanlis3": "Problem",
    },
    {
      "kelime": "Neden",
      "dogru": "Sebep",
      "yanlis1": "Sonuç",
      "yanlis2": "Netice",
      "yanlis3": "Amaç",
    },
    {
      "kelime": "Sonuç",
      "dogru": "Netice",
      "yanlis1": "Sebep",
      "yanlis2": "Neden",
      "yanlis3": "Başlangıç",
    },
    {
      "kelime": "Görev",
      "dogru": "Vazife",
      "yanlis1": "Oyun",
      "yanlis2": "Eğlence",
      "yanlis3": "Dinlenme",
    },
    {
      "kelime": "Yetenek",
      "dogru": "Kabiliyet",
      "yanlis1": "Çaba",
      "yanlis2": "Çalışma",
      "yanlis3": "Tembellik",
    },
    {
      "kelime": "Ödül",
      "dogru": "Mükafat",
      "yanlis1": "Ceza",
      "yanlis2": "Suç",
      "yanlis3": "Hata",
    },
    {
      "kelime": "Özel",
      "dogru": "Hususî",
      "yanlis1": "Genel",
      "yanlis2": "Umumi",
      "yanlis3": "Ortak",
    },
    {
      "kelime": "Genel",
      "dogru": "Umumi",
      "yanlis1": "Özel",
      "yanlis2": "Hususî",
      "yanlis3": "Kişisel",
    },
    {
      "kelime": "Şehir",
      "dogru": "Kent",
      "yanlis1": "Köy",
      "yanlis2": "Kasaba",
      "yanlis3": "Mahalle",
    },
    {
      "kelime": "Asır",
      "dogru": "Yüzyıl",
      "yanlis1": "Yıl",
      "yanlis2": "Ay",
      "yanlis3": "Gün",
    },
    {
      "kelime": "Doğa",
      "dogru": "Tabiat",
      "yanlis1": "Cadde",
      "yanlis2": "Sokak",
      "yanlis3": "Ev",
    },
    {
      "kelime": "Grup",
      "dogru": "Küme",
      "yanlis1": "Tek",
      "yanlis2": "Birey",
      "yanlis3": "Yalnız",
    },

    {
      "kelime": "Kürsü",
      "dogru": "Platform",
      "yanlis1": "Sıra",
      "yanlis2": "Masa",
      "yanlis3": "Yazı tahtası",
    },
    {
      "kelime": "Eser",
      "dogru": "Yapıt",
      "yanlis1": "Yazar",
      "yanlis2": "Çizer",
      "yanlis3": "Okuyucu",
    },
    {
      "kelime": "Aylak",
      "dogru": "Boş",
      "yanlis1": "Çalışkan",
      "yanlis2": "Meşgul",
      "yanlis3": "Yorgun",
    },
    {
      "kelime": "Neşe",
      "dogru": "Sevinç",
      "yanlis1": "Üzüntü",
      "yanlis2": "Keder",
      "yanlis3": "Ağlama",
    },
    {
      "kelime": "Keder",
      "dogru": "Üzüntü",
      "yanlis1": "Sevinç",
      "yanlis2": "Neşe",
      "yanlis3": "Mutluluk",
    },
    {
      "kelime": "Rüya",
      "dogru": "Düş",
      "yanlis1": "Gerçek",
      "yanlis2": "Hayat",
      "yanlis3": "Uyanıklık",
    },
    {
      "kelime": "Sıhhat",
      "dogru": "Sağlık",
      "yanlis1": "Hastalık",
      "yanlis2": "Ateş",
      "yanlis3": "Nezle",
    },
    {
      "kelime": "Güç",
      "dogru": "Zor",
      "yanlis1": "Kolay",
      "yanlis2": "Basit",
      "yanlis3": "Rahat",
    },
    {
      "kelime": "Basit",
      "dogru": "Kolay",
      "yanlis1": "Zor",
      "yanlis2": "Güç",
      "yanlis3": "Karmaşık",
    },
    {
      "kelime": "İlave",
      "dogru": "Ek",
      "yanlis1": "Çıkarma",
      "yanlis2": "Eksiltme",
      "yanlis3": "Azaltma",
    },
    {
      "kelime": "Fırsat",
      "dogru": "Vesile",
      "yanlis1": "Engel",
      "yanlis2": "Zaman",
      "yanlis3": "Yer",
    },
    {
      "kelime": "Yasa",
      "dogru": "Kanun",
      "yanlis1": "Kural",
      "yanlis2": "Düzen",
      "yanlis3": "Ceza",
    },

    {
      "kelime": "Hata",
      "dogru": "Kusur",
      "yanlis1": "Doğru",
      "yanlis2": "Yarar",
      "yanlis3": "Başarı",
    },

    {
      "kelime": "Fikir",
      "dogru": "Düşünce",
      "yanlis1": "Akıl",
      "yanlis2": "Hayal",
      "yanlis3": "Bilgi",
    },
    {
      "kelime": "Sınav",
      "dogru": "İmtihan",
      "yanlis1": "Ödev",
      "yanlis2": "Teneffüs",
      "yanlis3": "Tatil",
    },
    {
      "kelime": "Şüphe",
      "dogru": "Kuşku",
      "yanlis1": "Emin",
      "yanlis2": "Kesin",
      "yanlis3": "Doğru",
    },
    {
      "kelime": "Toplum",
      "dogru": "Cemiyet",
      "yanlis1": "Birey",
      "yanlis2": "Şahıs",
      "yanlis3": "İnsan",
    },
    {
      "kelime": "Yurt",
      "dogru": "Vatan",
      "yanlis1": "Ev",
      "yanlis2": "Oda",
      "yanlis3": "Bahçe",
    },
    {
      "kelime": "Lisan",
      "dogru": "Dil",
      "yanlis1": "Konuşma",
      "yanlis2": "Ses",
      "yanlis3": "Yazı",
    },
    {
      "kelime": "Sene",
      "dogru": "Yıl",
      "yanlis1": "Ay",
      "yanlis2": "Gün",
      "yanlis3": "Hafta",
    },
    {
      "kelime": "Mısra",
      "dogru": "Dize",
      "yanlis1": "Kıta",
      "yanlis2": "Şiir",
      "yanlis3": "Yazar",
    },
    {
      "kelime": "Koku",
      "dogru": "Rayiha",
      "yanlis1": "Tat",
      "yanlis2": "Renk",
      "yanlis3": "Ses",
    },
    {
      "kelime": "Nitelik",
      "dogru": "Kalite",
      "yanlis1": "Nicelik",
      "yanlis2": "Miktar",
      "yanlis3": "Boyut",
    },
    {
      "kelime": "Kuvvet",
      "dogru": "Güç",
      "yanlis1": "Zayıflık",
      "yanlis2": "Yorgunluk",
      "yanlis3": "Hız",
    },
    {
      "kelime": "Mertebe",
      "dogru": "Derece",
      "yanlis1": "Sıra",
      "yanlis2": "Basamak",
      "yanlis3": "Kat",
    },
  ];

  late Map<String, String> _aktifSoru;
  List<String> _secenekler = [];
  int _puan = 0;
  int _soruSayaci = 0;
  final int _toplamSoru = 10;
  bool _cevapVerildi = false;
  String? _secilenCevap;

  @override
  void initState() {
    super.initState();
    _yeniSoruGetir();
  }

  void _yeniSoruGetir() {
    if (_soruSayaci >= _toplamSoru) {
      _oyunBittiDialogGoster();
      return;
    }

    setState(() {
      _cevapVerildi = false;
      _secilenCevap = null;
      _kelimeListesi.shuffle();
      _aktifSoru = _kelimeListesi.first;

      _secenekler = [
        _aktifSoru['dogru']!,
        _aktifSoru['yanlis1']!,
        _aktifSoru['yanlis2']!,
        _aktifSoru['yanlis3']!,
      ];
      _secenekler.shuffle(); // Seçeneklerin yerini karıştır
      _soruSayaci++;
    });
  }

  void _cevapKontrol(String secilen) {
    if (_cevapVerildi) return;

    setState(() {
      _cevapVerildi = true;
      _secilenCevap = secilen;
      if (secilen == _aktifSoru['dogru']) {
        _puan += 20;
      }
    });

    // 1.5 saniye bekleyip sonraki soruya geç
    Future.delayed(const Duration(milliseconds: 1500), () {
      _yeniSoruGetir();
    });
  }

  void _oyunBittiDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Oyun Bitti! 🏆"),
        content: Text("Tebrikler!\nToplam Puanın: $_puan / 100"),
        actions: [
          // Menüye Dön Butonu
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Diyaloğu kapat
              Navigator.pop(context); // Oyun ekranından Oyunlar Menüsü'ne dön
            },
            child: const Text(
              "Menüye Dön",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          // Tekrar Oyna Butonu
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Diyaloğu kapat
              setState(() {
                _puan = 0;
                _soruSayaci = 0;
                _yeniSoruGetir();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eş Anlamlı Kelimeler 📚"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Soru: $_soruSayaci/$_toplamSoru",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Puan: $_puan",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "Aşağıdaki kelimenin eş anlamlısı hangisidir?",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _aktifSoru['kelime']!,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _secenekler.length,
                itemBuilder: (context, index) {
                  String secenek = _secenekler[index];
                  Color butonRengi = Colors.white;
                  Color yaziRengi = Colors.black87;

                  if (_cevapVerildi) {
                    if (secenek == _aktifSoru['dogru']) {
                      butonRengi = Colors.green.shade100;
                      yaziRengi = Colors.green.shade800;
                    } else if (secenek == _secilenCevap) {
                      butonRengi = Colors.red.shade100;
                      yaziRengi = Colors.red.shade800;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: butonRengi,
                        foregroundColor: yaziRengi,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => _cevapKontrol(secenek),
                      child: Text(
                        secenek,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
