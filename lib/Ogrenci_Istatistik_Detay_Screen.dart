// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'istatistik_servisi.dart';

class OgrenciIstatistikDetayScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const OgrenciIstatistikDetayScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<OgrenciIstatistikDetayScreen> createState() =>
      _OgrenciIstatistikDetayScreenState();
}

class _OgrenciIstatistikDetayScreenState
    extends State<OgrenciIstatistikDetayScreen> {
  String _secilenPeriyot = 'gunluk'; // 'gunluk', 'haftalik', 'aylik', 'yillik'

  // Özel seçimler için değişkenler
  DateTime? _secilenTarih;
  int _secilenYil = DateTime.now().year;
  int _secilenAy = DateTime.now().month;
  int _secilenHafta = 1;

  bool _isLoading = true;
  int _toplamEtkilesim = 0;
  int _toplamGiris = 0;
  Map<String, int> _detaylar = {};

  @override
  void initState() {
    super.initState();
    _secilenTarih = DateTime.now();
    _istatistikleriYukle();
  }

  Future<void> _istatistikleriYukle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> sonuc;

      if (_secilenPeriyot == 'gunluk') {
        sonuc = await IstatistikServisi.ogrenciIstatistikGetir(
          studentId: widget.studentId,
          periyot: 'ozel_gun',
          hedefTarih: _secilenTarih ?? DateTime.now(),
        );
      } else if (_secilenPeriyot == 'haftalik') {
        sonuc = await IstatistikServisi.ogrenciIstatistikGetir(
          studentId: widget.studentId,
          periyot: 'ozel_hafta',
          yil: _secilenYil,
          haftaVeyaAyNo: _secilenHafta,
        );
      } else if (_secilenPeriyot == 'aylik') {
        sonuc = await IstatistikServisi.ogrenciIstatistikGetir(
          studentId: widget.studentId,
          periyot: 'ozel_ay',
          yil: _secilenYil,
          haftaVeyaAyNo: _secilenAy,
        );
      } else {
        // Yıllık veya varsayılan
        sonuc = await IstatistikServisi.ogrenciIstatistikGetir(
          studentId: widget.studentId,
          periyot: _secilenPeriyot,
        );
      }

      setState(() {
        _toplamEtkilesim = sonuc['toplamEtkilesim'] ?? 0;
        _toplamGiris = sonuc['giris'] ?? 0;
        _detaylar = Map<String, int>.from(sonuc['detaylar'] ?? {});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("İstatistikler yüklenirken hata: $e");
    }
  }

  // Tarih seçimi için takvim dialogu
  Future<void> _tarihSec(BuildContext context) async {
    DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (secilen != null) {
      setState(() {
        _secilenTarih = secilen;
      });
      _istatistikleriYukle();
    }
  }

  String _islemAdiDuzenle(String key) {
    switch (key) {
      case 'giris':
        return 'Uygulama Giriş Sıklığı';
      case 'okudugum_kitaplar':
        return 'Okuduğum Kitaplar';
      case 'odevlerim':
        return 'Ödevlerim';
      case 'odevlerim_sekmesi':
        return 'Ödevlerim Sekmesi';
      case 'gorevlerim_sekmesi':
        return 'Görevlerim Sekmesi';
      case 'Davranışlarım':
        return 'Davranışlarım';
      case 'Denemelerim':
        return 'Denemelerim';
      case 'oyun_hafiza':
        return 'Oyun: Hafıza Oyunu';
      case 'oyun_es_anlamli':
        return 'Oyun: Eş Anlamlılar';
      case 'oyun_zit_anlamli':
        return 'Oyun: Zıt Anlamlılar';
      case 'oyun_toplama':
        return 'Oyun: Toplama Oyunu';
      case 'oyun_cikarma':
        return 'Oyun: Çıkarma Oyunu';
      default:
        if (key.startsWith('cesitli_')) {
          return 'Çeşitli İşler: ${key.replaceFirst('cesitli_', '')}';
        }
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.studentName} - İstatistikleri"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Periyot Seçim Butonları
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPeriyotButonu('Günlük', 'gunluk'),
                _buildPeriyotButonu('Haftalık', 'haftalik'),
                _buildPeriyotButonu('Aylık', 'aylik'),
                _buildPeriyotButonu('Yıllık', 'yillik'),
              ],
            ),
          ),

          // Seçilen Periyoda Göre Dinamik Filtre Satırı (Takvim veya Dropdownlar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.indigo.shade100.withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_secilenPeriyot == 'gunluk') ...[
                  Text(
                    "Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(_secilenTarih ?? DateTime.now())}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _tarihSec(context),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text("Gün Değiştir"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ] else if (_secilenPeriyot == 'haftalik') ...[
                  const Text(
                    "Yıl:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _secilenYil,
                    items: [2025, 2026, 2027].map((yil) {
                      return DropdownMenuItem(value: yil, child: Text("$yil"));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenYil = val);
                        _istatistikleriYukle();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Hafta (1-52):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _secilenHafta,
                    items: List.generate(52, (index) => index + 1).map((hafta) {
                      return DropdownMenuItem(
                        value: hafta,
                        child: Text("$hafta. Hafta"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenHafta = val);
                        _istatistikleriYukle();
                      }
                    },
                  ),
                ] else if (_secilenPeriyot == 'aylik') ...[
                  const Text(
                    "Yıl:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _secilenYil,
                    items: [2025, 2026, 2027].map((yil) {
                      return DropdownMenuItem(value: yil, child: Text("$yil"));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenYil = val);
                        _istatistikleriYukle();
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Ay:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _secilenAy,
                    items:
                        [
                          {'no': 1, 'ad': 'Ocak'},
                          {'no': 2, 'ad': 'Şubat'},
                          {'no': 3, 'ad': 'Mart'},
                          {'no': 4, 'ad': 'Nisan'},
                          {'no': 5, 'ad': 'Mayıs'},
                          {'no': 6, 'ad': 'Haziran'},
                          {'no': 7, 'ad': 'Temmuz'},
                          {'no': 8, 'ad': 'Ağustos'},
                          {'no': 9, 'ad': 'Eylül'},
                          {'no': 10, 'ad': 'Ekim'},
                          {'no': 11, 'ad': 'Kasım'},
                          {'no': 12, 'ad': 'Aralık'},
                        ].map((ay) {
                          return DropdownMenuItem<int>(
                            value: ay['no'] as int,
                            child: Text(ay['ad'] as String),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenAy = val);
                        _istatistikleriYukle();
                      }
                    },
                  ),
                ] else ...[
                  Text(
                    "Son 1 Yıllık Özet Veriler",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // İçerik Alanı
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Özet Kartları
                        Row(
                          children: [
                            Expanded(
                              child: _buildOzetKarti(
                                baslik: "Toplam Etkileşim",
                                deger: "$_toplamEtkilesim",
                                renk: Colors.indigo,
                                ikon: Icons.insights,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOzetKarti(
                                baslik: "Giriş Sayısı",
                                deger: "$_toplamGiris",
                                renk: Colors.teal,
                                ikon: Icons.login,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Detay Başlığı
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Buton Bazlı Tıklama Dağılımı",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Detaylı Liste
                        Expanded(
                          child: _detaylar.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Bu periyotta henüz işlem kaydı bulunmuyor.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _detaylar.length,
                                  itemBuilder: (context, index) {
                                    String key = _detaylar.keys.elementAt(
                                      index,
                                    );
                                    int count = _detaylar[key]!;
                                    String gorunenAd = _islemAdiDuzenle(key);

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Colors.indigoAccent,
                                          child: Icon(
                                            Icons.touch_app,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        title: Text(
                                          gorunenAd,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "$count kez",
                                            style: TextStyle(
                                              color: Colors.indigo.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPeriyotButonu(String baslik, String periyotKodu) {
    bool secili = _secilenPeriyot == periyotKodu;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _secilenPeriyot = periyotKodu;
        });
        _istatistikleriYukle();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: secili ? Colors.indigo : Colors.white,
        foregroundColor: secili ? Colors.white : Colors.indigo,
        elevation: secili ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.indigo),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      child: Text(
        baslik,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildOzetKarti({
    required String baslik,
    required String deger,
    required Color renk,
    required IconData ikon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  fontSize: 13,
                  color: renk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(ikon, color: renk, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deger,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}
