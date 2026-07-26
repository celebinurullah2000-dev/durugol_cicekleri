import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciYuklemeScreen extends StatefulWidget {
  const OgrenciYuklemeScreen({super.key});

  @override
  State<OgrenciYuklemeScreen> createState() => _OgrenciYuklemeScreenState();
}

class _OgrenciYuklemeScreenState extends State<OgrenciYuklemeScreen> {
  bool _isUploading = false;
  String _durumMesaji = "Yüklemeye hazır.";

  // Her öğrenciye özel cinsiyet bilgisi ("K" veya "E") eklendi
  final List<Map<String, String>> ogrenciListesi = [
    {
      "tc": "65773088082",
      "no": "55",
      "adSoyad": "YUSUF ASAF BAYRAMLI",
      "cinsiyet": "E",
    },
    {
      "tc": "65824085176",
      "no": "64",
      "adSoyad": "KUMSAL NAZ ÖNCÜ",
      "cinsiyet": "K",
    },
    {
      "tc": "44084103240",
      "no": "66",
      "adSoyad": "ASEL BEREN YONDEMİR",
      "cinsiyet": "K",
    },
    {
      "tc": "33184546194",
      "no": "83",
      "adSoyad": "HAZAL DENİZ ÖZCAN",
      "cinsiyet": "K",
    },
    {
      "tc": "66088077754",
      "no": "86",
      "adSoyad": "YAMAÇ ARSLAN",
      "cinsiyet": "E",
    },
    {
      "tc": "65989079676",
      "no": "96",
      "adSoyad": "ALİ HARUN ÜNSAL",
      "cinsiyet": "E",
    },
    {
      "tc": "65653090778",
      "no": "103",
      "adSoyad": "ASYA PATKAVAK",
      "cinsiyet": "K",
    },
    {
      "tc": "65782086642",
      "no": "142",
      "adSoyad": "YUDUM ODABAŞ",
      "cinsiyet": "K",
    },
    {
      "tc": "41647895598",
      "no": "162",
      "adSoyad": "ÇINAR ALP GÖZÜTOK",
      "cinsiyet": "E",
    },
    {
      "tc": "62203325182",
      "no": "340",
      "adSoyad": "İPEK ÖZTOPRAK",
      "cinsiyet": "K",
    },
    {
      "tc": "66037079648",
      "no": "372",
      "adSoyad": "RÜZGAR GÜZELSU",
      "cinsiyet": "E",
    },
    {
      "tc": "48565184360",
      "no": "390",
      "adSoyad": "CANKAT İLKUTLU",
      "cinsiyet": "E",
    },
    {
      "tc": "65839086106",
      "no": "481",
      "adSoyad": "GÜLCE YAĞIZOĞLU",
      "cinsiyet": "K",
    },
    {
      "tc": "66253072348",
      "no": "509",
      "adSoyad": "CAN SAMSUNLU",
      "cinsiyet": "E",
    },
    {
      "tc": "66067077638",
      "no": "587",
      "adSoyad": "UMUT ALP YAZIM",
      "cinsiyet": "E",
    },
    {
      "tc": "65206402454",
      "no": "616",
      "adSoyad": "ELİSA SARE YILDIRIM",
      "cinsiyet": "K",
    },
    {
      "tc": "66241071704",
      "no": "761",
      "adSoyad": "DENİZ NİSA ARSLAN",
      "cinsiyet": "K",
    },
    {
      "tc": "56863094854",
      "no": "776",
      "adSoyad": "GÖRKEM TUNA BALCI",
      "cinsiyet": "E",
    },
    {
      "tc": "65935081906",
      "no": "795",
      "adSoyad": "ÖMER DENİZ KEÇECİ",
      "cinsiyet": "E",
    },
    {
      "tc": "33023471700",
      "no": "884",
      "adSoyad": "GİZEM AKÇAY",
      "cinsiyet": "K",
    },
    {
      "tc": "66196073570",
      "no": "888",
      "adSoyad": "GÜNEŞ KÜÇÜK",
      "cinsiyet": "K",
    },
    {
      "tc": "65821086770",
      "no": "967",
      "adSoyad": "ALYA AYDIN",
      "cinsiyet": "K",
    },
    {
      "tc": "44857157012",
      "no": "1000",
      "adSoyad": "LİNA TİRYAKİ",
      "cinsiyet": "K",
    },
    {
      "tc": "65887084680",
      "no": "1069",
      "adSoyad": "URAS SOĞUKSU",
      "cinsiyet": "E",
    },
    {
      "tc": "66193074488",
      "no": "1076",
      "adSoyad": "YUSUF YİĞİT AKSOY",
      "cinsiyet": "E",
    },
    {
      "tc": "65845085292",
      "no": "1123",
      "adSoyad": "ARDEN ODABAŞI",
      "cinsiyet": "E",
    },
    {
      "tc": "66328069594",
      "no": "1139",
      "adSoyad": "AYŞE ELA ŞEN",
      "cinsiyet": "K",
    },
    {
      "tc": "65848085688",
      "no": "1201",
      "adSoyad": "ELİSA DURU ŞAHİN",
      "cinsiyet": "K",
    },
    {
      "tc": "65941082522",
      "no": "1217",
      "adSoyad": "ESLEM SARE AKSU",
      "cinsiyet": "K",
    },
    {
      "tc": "66001080786",
      "no": "1261",
      "adSoyad": "ÖMER ASAF YAVUZARSLAN",
      "cinsiyet": "E",
    },
    {
      "tc": "66013079822",
      "no": "1387",
      "adSoyad": "YİĞİT ARSLAN",
      "cinsiyet": "E",
    },
    {
      "tc": "65827086552",
      "no": "1412",
      "adSoyad": "ZEYNEP KILIÇARSLAN",
      "cinsiyet": "K",
    },
  ];

  String _turkceKucukHarf(String metin) {
    return metin
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');
  }

  Future<void> _ogrencileriTopluYukle() async {
    setState(() {
      _isUploading = true;
      _durumMesaji = "Öğrenciler yükleniyor...";
    });

    try {
      final firestore = FirebaseFirestore.instance;
      const String hedefClassId =
          "PSN8VcMpfrBAF10UYLcr"; // Belirttiğiniz sınıf ID

      int sayac = 0;
      for (var ogrenci in ogrenciListesi) {
        String tamAd = ogrenci["adSoyad"] ?? "";
        List<String> parcalar = tamAd.split(" ");

        String soyad = parcalar.isNotEmpty ? parcalar.last : "";
        String ad = parcalar.length > 1
            ? parcalar.sublist(0, parcalar.length - 1).join(" ")
            : "";

        String sifre = _turkceKucukHarf(ad.replaceAll(' ', ''));

        await firestore.collection('students').add({
          'classId': hedefClassId,
          'tc': ogrenci["tc"],
          'schoolNumber': ogrenci["no"],
          'firstName': ad,
          'lastName': soyad,
          'gender': ogrenci["cinsiyet"], // Eklenen cinsiyet bilgisi
          'password': sifre,
          'dogumTarihi': '',
          'anneAdi': '',
          'babaAdi': '',
          'anneCep': '',
          'babaCep': '',
          'anneMeslegi': '',
          'babaMeslegi': '',
          'kardesleri': '',
        });
        sayac++;
      }

      setState(() {
        _durumMesaji =
            "Başarıyla $sayac öğrenci cinsiyetleriyle birlikte yüklendi!";
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _durumMesaji = "Hata oluştu: $e";
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Toplu Öğrenci Yükleme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _durumMesaji,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ogrenciListesi.length,
                itemBuilder: (context, index) {
                  final o = ogrenciListesi[index];
                  String tamAd = o["adSoyad"] ?? "";
                  List<String> parcalar = tamAd.split(" ");
                  String ad = parcalar.length > 1
                      ? parcalar.sublist(0, parcalar.length - 1).join(" ")
                      : "";
                  String hesaplananSifre = _turkceKucukHarf(
                    ad.replaceAll(' ', ''),
                  );

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: o["cinsiyet"] == "K"
                            ? Colors.pink[100]
                            : Colors.blue[100],
                        child: Text(o["no"] ?? ""),
                      ),
                      title: Text(o["adSoyad"] ?? ""),
                      subtitle: Text(
                        "No: ${o["no"]} | Cinsiyet: ${o["cinsiyet"]} | Şifre: $hesaplananSifre",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isUploading ? null : _ogrencileriTopluYukle,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Tüm Öğrencileri Firestore'a Yükle",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
