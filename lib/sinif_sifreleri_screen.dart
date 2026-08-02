// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SinifSifreleriScreen extends StatefulWidget {
  final String classId;
  final String className;

  const SinifSifreleriScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<SinifSifreleriScreen> createState() => _SinifSifreleriScreenState();
}

class _SinifSifreleriScreenState extends State<SinifSifreleriScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _ogrenciListesi = [];

  @override
  void initState() {
    super.initState();
    _ogrenciSifreleriniGetir();
  }

  // Türkçe alfabetik sıralama için kıyaslama fonksiyonu
  int _turkceKarsilastir(String a, String b) {
    const String turkceAlfabe = 'aabcçdefgğhıijklmnoöprsştuüvyz';

    String aKucuk = a
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');

    String bKucuk = b
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .replaceAll('Ç', 'ç')
        .replaceAll('Ğ', 'ğ')
        .replaceAll('Ö', 'ö')
        .replaceAll('Ş', 'ş')
        .replaceAll('Ü', 'ü');

    int minLength = aKucuk.length < bKucuk.length
        ? aKucuk.length
        : bKucuk.length;

    for (int i = 0; i < minLength; i++) {
      int indexA = turkceAlfabe.indexOf(aKucuk[i]);
      int indexB = turkceAlfabe.indexOf(bKucuk[i]);

      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  // Sınıftaki öğrencileri ve güncel şifrelerini çekelim
  Future<void> _ogrenciSifreleriniGetir() async {
    setState(() => _isLoading = true);
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      List<Map<String, dynamic>> liste = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        liste.add({
          'id': doc.id,
          'adSoyad': "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
              .trim(),
          'sifre': data['password'] ?? '',
          'okulNo': data['schoolNumber'] ?? '-',
        });
      }

      // Türkçe alfabetik sıralama uygulaması
      liste.sort((a, b) => _turkceKarsilastir(a['adSoyad'], b['adSoyad']));

      setState(() {
        _ogrenciListesi = liste;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Şifreler yüklenirken hata: $e");
    }
  }

  // Şifre değiştirme dialogu
  void _sifreGuncelleDialog(
    String studentId,
    String adSoyad,
    String mevcutSifre,
  ) {
    final TextEditingController sifreController = TextEditingController(
      text: mevcutSifre,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$adSoyad - Şifre Güncelle"),
        content: TextField(
          controller: sifreController,
          decoration: const InputDecoration(labelText: "Yeni Şifre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String yeniSifre = sifreController.text.trim();
              if (yeniSifre.isEmpty) return;

              // 1. Öğrencinin ana dokümanındaki şifreyi güncelle
              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .update({'password': yeniSifre});

              // 2. Merkezi sınıflar koleksiyonuna da yansıtma
              await FirebaseFirestore.instance
                  .collection('sinif_sifreleri')
                  .doc(widget.classId)
                  .set({
                    'sifreler': {
                      studentId: {'adSoyad': adSoyad, 'sifre': yeniSifre},
                    },
                  }, SetOptions(merge: true));

              Navigator.pop(context);
              _ogrenciSifreleriniGetir();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Şifre başarıyla güncellendi.")),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.className} - Öğrenci Şifreleri"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ogrenciListesi.isEmpty
          ? const Center(child: Text("Bu sınıfta kayıtlı öğrenci bulunmuyor."))
          : ListView.builder(
              itemCount: _ogrenciListesi.length,
              itemBuilder: (context, index) {
                var ogrenci = _ogrenciListesi[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    title: Text(
                      ogrenci['adSoyad'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Okul No: ${ogrenci['okulNo']} | Şifre: ${ogrenci['sifre']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.key, color: Colors.orange),
                      onPressed: () => _sifreGuncelleDialog(
                        ogrenci['id'],
                        ogrenci['adSoyad'],
                        ogrenci['sifre'],
                      ),
                      tooltip: "Şifreyi Değiştir",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
