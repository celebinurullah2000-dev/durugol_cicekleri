// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ToplamaOyunuScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  const ToplamaOyunuScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<ToplamaOyunuScreen> createState() => _ToplamaOyunuScreenState();
}

class _ToplamaOyunuScreenState extends State<ToplamaOyunuScreen> {
  int _secilenZorluk = 1;
  bool _surekliAyniSeviye =
      false; // Yeni: Mod seçimi (true: Sadece seçilen seviye, false: Seviye atlamalı)
  bool _oyunBasladi = false;

  int _sayi1 = 0;
  int _sayi2 = 0;
  int _dogruCevap = 0;

  int _soruSayaci = 0;
  int _dogruSayisi = 0;
  int _yanlisSayisi = 0;
  final int _maksimumSoru = 10;

  int _kalanCan = 5;
  int _kalanSure = 10;
  Timer? _timer;

  final TextEditingController _cevapController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _timer?.cancel();
    _cevapController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _oyunuBaslat() {
    setState(() {
      _oyunBasladi = true;
      _soruSayaci = 0;
      _dogruSayisi = 0;
      _yanlisSayisi = 0;
      _kalanCan = 5;
    });
    _yeniSoruUret();
  }

  int _seviyeSuresiGetir() {
    switch (_secilenZorluk) {
      case 1:
        return 10;
      case 2:
        return 15;
      case 3:
        return 20;
      case 4:
        return 25;
      case 5:
        return 30;
      default:
        return 10;
    }
  }

  void _sayaciBaslat() {
    _timer?.cancel();
    setState(() {
      _kalanSure = _seviyeSuresiGetir();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_kalanSure > 0) {
        setState(() {
          _kalanSure--;
        });
      } else {
        _timer?.cancel();
        _sureBittiIslemi();
      }
    });
  }

  void _sureBittiIslemi() {
    setState(() {
      _kalanCan--;
      _yanlisSayisi++;
    });

    if (_kalanCan <= 0) {
      _oyunBittiDialogGoster("Süren bitti ve tüm canların tükendi! 😢");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Süre bitti! Bir can kaybettin. Yeni soruya geçiliyor ⏰",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 1200),
        ),
      );
      _yeniSoruUret();
    }
  }

  void _yeniSoruUret() {
    if (_soruSayaci >= _maksimumSoru) {
      _timer?.cancel();
      _bolumBittiIslemi();
      return;
    }

    Random rnd = Random();
    int min1 = 1, max1 = 9;
    int min2 = 1, max2 = 9;

    switch (_secilenZorluk) {
      case 1: // 1 + 1 basamak
        min1 = 1;
        max1 = 9;
        min2 = 1;
        max2 = 9;
        break;
      case 2: // 2 + 1 basamak (Toplam 100'ü geçmesin)
        min1 = 10;
        max1 = 89;
        min2 = 1;
        max2 = 9;
        break;
      case 3: // 2 + 2 basamak (Toplam 100'ü geçmesin)
        min1 = 10;
        max1 = 89;
        min2 = 10;
        break;
      case 4: // 3 + 2 basamak (Toplam 1000'i geçmesin)
        min1 = 100;
        max1 = 899;
        min2 = 10;
        max2 = 99;
        break;
      case 5: // 3 + 3 basamak (Toplam 1000'i geçmesin)
        min1 = 100;
        max1 = 899;
        min2 = 100;
        break;
    }

    setState(() {
      _sayi1 = min1 + rnd.nextInt(max1 - min1 + 1);

      if (_secilenZorluk == 3) {
        // 2 basamaklı + 2 basamaklı toplamda sonuç 100'ü geçmesin
        int ustSinir = 99 - _sayi1;
        if (ustSinir < 10) ustSinir = 10;
        max2 = ustSinir;
        if (max2 < min2) max2 = min2;
        _sayi2 = min2 + rnd.nextInt(max2 - min2 + 1);
      } else if (_secilenZorluk == 5) {
        // 3 basamaklı + 3 basamaklı toplamda sonuç 1000'i geçmesin
        int ustSinir = 999 - _sayi1;
        if (ustSinir < 100) ustSinir = 100;
        max2 = ustSinir;
        if (max2 < min2) max2 = min2;
        _sayi2 = min2 + rnd.nextInt(max2 - min2 + 1);
      } else {
        _sayi2 = min2 + rnd.nextInt(max2 - min2 + 1);
      }

      _dogruCevap = _sayi1 + _sayi2;
      _soruSayaci++;
      _cevapController.clear();
    });

    _sayaciBaslat();

    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _bolumBittiIslemi() {
    if (_surekliAyniSeviye || _secilenZorluk >= 5) {
      // Tek seviye modundaysa veya son seviyedeyse tebrik dialogu göster
      _oyunBittiDialogGoster("Tebrikler Bölümü Tamamladın! 🏆");
    } else {
      // Seviye atlamalı moddaysa bir üst seviyeye geç ve can ödülü ver
      setState(() {
        _secilenZorluk++;
        _kalanCan = (_kalanCan < 5) ? _kalanCan + 1 : 5;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Tebrikler, Seviye Atladın! 🚀"),
          content: Text(
            "Harika iş! Yeni zorluk seviyesine geçiyorsun.\nÖdül olarak 1 can eklendi. Kalan Can: $_kalanCan",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _soruSayaci = 0;
                  _dogruSayisi = 0;
                  _yanlisSayisi = 0;
                });
                _yeniSoruUret();
              },
              child: const Text("Devam Et"),
            ),
          ],
        ),
      );
    }
  }

  void _cevabiKontrolEt() {
    if (_cevapController.text.isEmpty) return;
    int? girilenCevap = int.tryParse(_cevapController.text);

    if (girilenCevap == null) return;

    _timer?.cancel();

    setState(() {
      if (girilenCevap == _dogruCevap) {
        _dogruSayisi++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Doğru! 🎉"),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 600),
          ),
        );
        _yeniSoruUret();
      } else {
        _yanlisSayisi++;
        _kalanCan--;

        if (_kalanCan <= 0) {
          _oyunBittiDialogGoster("Canların bitti! Oyun sona erdi. 😢");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Yanlış! Doğru cevap: $_dogruCevap. Bir can kaybettin. ❌",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
          _yeniSoruUret();
        }
      }
    });
  }

  void _oyunBittiDialogGoster(String mesaj) {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Oyun Durumu"),
        content: Text(
          "$mesaj\n\n"
          "Doğru: $_dogruSayisi\n"
          "Yanlış: $_yanlisSayisi",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _oyunBasladi = false;
                _secilenZorluk = 1;
              });
            },
            child: const Text("Zorluk Seçimine Dön"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double ekranGenisligi = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _surekliAyniSeviye
              ? "Toplama Oyunu - Seviye $_secilenZorluk"
              : "Toplama Yarışması (Modlu)",
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !_oyunBasladi
            ? _buildZorlukSecimEkrani()
            : _buildOyunEkrani(ekranGenisligi),
      ),
    );
  }

  Widget _buildZorlukSecimEkrani() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Zorluk Seviyesi Seçin",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            _zorlukButonuOlustur(1, "1. Seviye (1 + 1 Basamak) - 10 Sn"),
            _zorlukButonuOlustur(2, "2. Seviye (2 + 1 Basamak) - 15 Sn"),
            _zorlukButonuOlustur(3, "3. Seviye (2 + 2 Basamak) - 20 Sn"),
            _zorlukButonuOlustur(4, "4. Seviye (3 + 2 Basamak) - 25 Sn"),
            _zorlukButonuOlustur(5, "5. Seviye (3 + 3 Basamak) - 30 Sn"),
            const SizedBox(height: 20),
            const Text(
              "Oyun Modu Seçin",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            // Mod Seçimi Segment / Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Seviye Atlamalı Mod"),
                  selected: !_surekliAyniSeviye,
                  onSelected: (bool selected) {
                    setState(() {
                      _surekliAyniSeviye = false;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Tek Seviye Modu"),
                  selected: _surekliAyniSeviye,
                  onSelected: (bool selected) {
                    setState(() {
                      _surekliAyniSeviye = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _oyunuBaslat,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text("Oyunu Başlat", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zorlukButonuOlustur(int seviye, String yazi) {
    bool secili = _secilenZorluk == seviye;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: 320,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _secilenZorluk = seviye;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: secili ? Colors.indigo : Colors.grey.shade200,
          foregroundColor: secili ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(yazi, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildOyunEkrani(double ekranGenisligi) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < _kalanCan ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  "$_kalanSure sn",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kalanSure <= 3 ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              "Soru: $_soruSayaci / $_maksimumSoru",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Doğru: $_dogruSayisi",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "Yanlış: $_yanlisSayisi",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const Divider(height: 20, thickness: 2),
        const Spacer(),
        Container(
          width: ekranGenisligi * 0.6,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.indigo.shade200, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$_sayi1",
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "+ ",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    "$_sayi2",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(width: 160, height: 3, color: Colors.indigo),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _cevapController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "Cevap",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _cevabiKontrolEt(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _cevabiKontrolEt,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text("Kontrol Et", style: TextStyle(fontSize: 16)),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            _timer?.cancel();
            setState(() {
              _oyunBasladi = false;
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text("Zorluk Seçimine Dön"),
        ),
      ],
    );
  }
}
