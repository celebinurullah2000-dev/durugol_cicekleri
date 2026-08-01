// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ogrenci_istatistik_detay_screen.dart'; // Detay ekranının importu
import 'istatistik_servisi.dart';

class SinifIstatistikSiralamaScreen extends StatefulWidget {
  final String classId;

  const SinifIstatistikSiralamaScreen({super.key, required this.classId});

  @override
  State<SinifIstatistikSiralamaScreen> createState() =>
      _SinifIstatistikSiralamaScreenState();
}

class _SinifIstatistikSiralamaScreenState
    extends State<SinifIstatistikSiralamaScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _siraliOgrenciler = [];
  String _secilenKriter = 'toplamEtkilesim'; // 'toplamEtkilesim' veya 'giris'
  String _secilenPeriyot = 'gunluk'; // 'gunluk', 'haftalik', 'aylik', 'yillik'

  // Özel seçimler için değişkenler
  DateTime? _secilenTarih;
  int _secilenYil = DateTime.now().year;
  int _secilenAy = DateTime.now().month;
  int _secilenHafta = 1;

  @override
  void initState() {
    super.initState();
    _secilenTarih = DateTime.now();
    _verileriGetirVeSirala();
  }

  Future<void> _verileriGetirVeSirala() async {
    setState(() => _isLoading = true);
    try {
      // 1. Sınıftaki öğrencileri çekelim
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      List<Map<String, dynamic>> ogrenciPuanlari = [];

      // 2. Her öğrenci için IstatistikServisi kullanarak seçilen periyottaki verileri toplayalım
      for (var doc in studentSnapshot.docs) {
        var data = doc.data();
        String studentId = doc.id;
        String adSoyad = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
            .trim();

        Map<String, dynamic> istatistikSonuc;

        if (_secilenPeriyot == 'gunluk') {
          istatistikSonuc = await IstatistikServisi.ogrenciIstatistikGetir(
            studentId: studentId,
            periyot: 'ozel_gun',
            hedefTarih: _secilenTarih ?? DateTime.now(),
          );
        } else if (_secilenPeriyot == 'haftalik') {
          istatistikSonuc = await IstatistikServisi.ogrenciIstatistikGetir(
            studentId: studentId,
            periyot: 'ozel_hafta',
            yil: _secilenYil,
            haftaVeyaAyNo: _secilenHafta,
          );
        } else if (_secilenPeriyot == 'aylik') {
          istatistikSonuc = await IstatistikServisi.ogrenciIstatistikGetir(
            studentId: studentId,
            periyot: 'ozel_ay',
            yil: _secilenYil,
            haftaVeyaAyNo: _secilenAy,
          );
        } else {
          istatistikSonuc = await IstatistikServisi.ogrenciIstatistikGetir(
            studentId: studentId,
            periyot: _secilenPeriyot,
          );
        }

        int toplamDeger = 0;
        if (_secilenKriter == 'toplamEtkilesim') {
          toplamDeger = istatistikSonuc['toplamEtkilesim'] ?? 0;
        } else if (_secilenKriter == 'giris') {
          toplamDeger = istatistikSonuc['giris'] ?? 0;
        }

        ogrenciPuanlari.add({
          'id': studentId,
          'adSoyad': adSoyad,
          'skor': toplamDeger,
        });
      }

      // 3. Çoktan aza sıralama yapalım
      ogrenciPuanlari.sort(
        (a, b) => (b['skor'] as int).compareTo(a['skor'] as int),
      );

      setState(() {
        _siraliOgrenciler = ogrenciPuanlari;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      _verileriGetirVeSirala();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf İstatistik Sıralaması"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Üst Kısım: Periyot Seçim Butonları (Günlük, Haftalık, Aylık, Yıllık)
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
                    "Tarih: ${DateFormat('dd.MM.yyyy').format(_secilenTarih ?? DateTime.now())}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _tarihSec(context),
                    icon: const Icon(Icons.calendar_month, size: 14),
                    label: const Text(
                      "Değiştir",
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                    ),
                  ),
                ] else if (_secilenPeriyot == 'haftalik') ...[
                  const Text(
                    "Yıl:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: _secilenYil,
                    isDense: true,
                    items: [2025, 2026, 2027].map((yil) {
                      return DropdownMenuItem(
                        value: yil,
                        child: Text(
                          "$yil",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenYil = val);
                        _verileriGetirVeSirala();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Hafta:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: _secilenHafta,
                    isDense: true,
                    items: List.generate(52, (index) => index + 1).map((hafta) {
                      return DropdownMenuItem(
                        value: hafta,
                        child: Text(
                          "$hafta.H",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenHafta = val);
                        _verileriGetirVeSirala();
                      }
                    },
                  ),
                ] else if (_secilenPeriyot == 'aylik') ...[
                  const Text(
                    "Yıl:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: _secilenYil,
                    isDense: true,
                    items: [2025, 2026, 2027].map((yil) {
                      return DropdownMenuItem(
                        value: yil,
                        child: Text(
                          "$yil",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenYil = val);
                        _verileriGetirVeSirala();
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Ay:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: _secilenAy,
                    isDense: true,
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
                            child: Text(
                              ay['ad'] as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _secilenAy = val);
                        _verileriGetirVeSirala();
                      }
                    },
                  ),
                ] else ...[
                  Text(
                    "Son 1 Yıllık Sıralama",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // İkinci Kısım: Sıralama Kriteri Seçimi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sıralama Ölçütü:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                DropdownButton<String>(
                  value: _secilenKriter,
                  items: const [
                    DropdownMenuItem(
                      value: 'toplamEtkilesim',
                      child: Text(
                        "Toplam Etkileşim",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'giris',
                      child: Text(
                        "Uygulama Giriş Sıklığı",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (String? yeniDeger) {
                    if (yeniDeger != null) {
                      setState(() {
                        _secilenKriter = yeniDeger;
                      });
                      _verileriGetirVeSirala();
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste Alanı
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _siraliOgrenciler.isEmpty
                ? const Center(
                    child: Text("Bu periyotta öğrenci verisi bulunmuyor."),
                  )
                : ListView.builder(
                    itemCount: _siraliOgrenciler.length,
                    itemBuilder: (context, index) {
                      var ogrenci = _siraliOgrenciler[index];
                      String studentId = ogrenci['id'];
                      String adSoyad = ogrenci['adSoyad'];
                      int skor = ogrenci['skor'];

                      // İlk 3 öğrenciye özel renk/madalya vurgusu
                      Color siraRengi = Colors.grey.shade700;
                      if (index == 0) {
                        siraRengi = Colors.amber.shade700; // 1. Altın
                      } else if (index == 1) {
                        siraRengi = Colors.blueGrey; // 2. Gümüş
                      } else if (index == 2) {
                        siraRengi = Colors.brown; // 3. Bronz
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 2,
                        child: ListTile(
                          onTap: () {
                            // Öğrenciye tıklandığında detay ekranına yönlendiriyoruz
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OgrenciIstatistikDetayScreen(
                                      studentId: studentId,
                                      studentName: adSoyad,
                                    ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: siraRengi.withValues(alpha: 0.2),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: siraRengi,
                              ),
                            ),
                          ),
                          title: Text(
                            adSoyad,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            "Detayları görmek için dokunun",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: Text(
                            "$skor Puan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo.shade700,
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

  Widget _buildPeriyotButonu(String baslik, String periyotKodu) {
    bool secili = _secilenPeriyot == periyotKodu;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _secilenPeriyot = periyotKodu;
        });
        _verileriGetirVeSirala();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: secili ? Colors.indigo : Colors.white,
        foregroundColor: secili ? Colors.white : Colors.indigo,
        elevation: secili ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.indigo),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      child: Text(
        baslik,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
