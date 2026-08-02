// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.studentId,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late final TextEditingController _tcController;
  late final TextEditingController _dogumTarihiController;
  late final TextEditingController _anneAdiController;
  late final TextEditingController _babaAdiController;
  late final TextEditingController _anneCepController;
  late final TextEditingController _babaCepController;
  late final TextEditingController _anneMeslegiController;
  late final TextEditingController _babaMeslegiController;
  late final TextEditingController _kardesleriController;

  bool _isSaving = false;
  String? ogrenciResmiBase64; // <-- Öğrenci resmini tutacağımız değişken

  @override
  void initState() {
    super.initState();
    // Gelen verilerle controller'ları başlatıyoruz
    _tcController = TextEditingController(text: widget.studentData['tc'] ?? '');
    _dogumTarihiController = TextEditingController(
      text: widget.studentData['dogumTarihi'] ?? '',
    );
    _anneAdiController = TextEditingController(
      text: widget.studentData['anneAdi'] ?? '',
    );
    _babaAdiController = TextEditingController(
      text: widget.studentData['babaAdi'] ?? '',
    );
    _anneCepController = TextEditingController(
      text: widget.studentData['anneCep'] ?? '',
    );
    _babaCepController = TextEditingController(
      text: widget.studentData['babaCep'] ?? '',
    );
    _anneMeslegiController = TextEditingController(
      text: widget.studentData['anneMeslegi'] ?? '',
    );
    _babaMeslegiController = TextEditingController(
      text: widget.studentData['babaMeslegi'] ?? '',
    );
    _kardesleriController = TextEditingController(
      text: widget.studentData['kardesleri'] ?? '',
    );

    // Var olan resmi değişkene aktarıyoruz
    ogrenciResmiBase64 = widget.studentData['resimBase64'];
  }

  @override
  void dispose() {
    _tcController.dispose();
    _dogumTarihiController.dispose();
    _anneAdiController.dispose();
    _babaAdiController.dispose();
    _anneCepController.dispose();
    _babaCepController.dispose();
    _anneMeslegiController.dispose();
    _babaMeslegiController.dispose();
    _kardesleriController.dispose();
    super.dispose();
  }

  void _resmiTamBoyutGoster() {
    if (ogrenciResmiBase64 == null || ogrenciResmiBase64!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(ogrenciResmiBase64!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Resim seçme ve güncelleme fonksiyonu
  Future<void> _resimSecveGuncelle(String studentId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30, // Boyutu küçültmek için kaliteyi biraz düşürelim
      );

      if (image != null) {
        // Web ve mobil uyumlu olması için doğrudan readAsBytes kullanıyoruz
        Uint8List bytes = await image.readAsBytes();
        String base64String = base64Encode(bytes);

        // Firestore'a kaydetmeyi deniyoruz
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .update({'resimBase64': base64String});

        // Yerel önbelleği güncelle
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('studentProfileImage_$studentId', base64String);

        if (!mounted) return;

        setState(() {
          ogrenciResmiBase64 = base64String;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Öğrenci resmi başarıyla güncellendi ve Firestore'a kaydedildi!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print(
        "RESİM YÜKLEME HATASI: $e",
      ); // Debug konsolunda hatayı görebilmek için
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Resim yüklenirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bilgileriKaydet() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .update({
            'tc': _tcController.text.trim(),
            'dogumTarihi': _dogumTarihiController.text.trim(),
            'anneAdi': _anneAdiController.text.trim(),
            'babaAdi': _babaAdiController.text.trim(),
            'anneCep': _anneCepController.text.trim(),
            'babaCep': _babaCepController.text.trim(),
            'anneMeslegi': _anneMeslegiController.text.trim(),
            'babaMeslegi': _babaMeslegiController.text.trim(),
            'kardesleri': _kardesleriController.text.trim(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Öğrenci bilgileri başarıyla kaydedildi."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        "${widget.studentData['firstName'] ?? ''} ${widget.studentData['lastName'] ?? ''}";

    return Scaffold(
      appBar: AppBar(
        title: Text("$fullName - Öğrenci Bilgileri"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- PROFIL FOTOĞRAFI ALANI BURAYA EKLENDİ ---
            Center(
              child: Stack(
                children: [
                  // Fotoğrafın kendisine tıklayınca TAM BOYUT AÇILIR
                  GestureDetector(
                    onTap: _resmiTamBoyutGoster,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage:
                          (ogrenciResmiBase64 != null &&
                              ogrenciResmiBase64!.isNotEmpty)
                          ? MemoryImage(base64Decode(ogrenciResmiBase64!))
                          : null,
                      child:
                          (ogrenciResmiBase64 == null ||
                              ogrenciResmiBase64!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.indigo,
                            )
                          : null,
                    ),
                  ),
                  // Sadece kamera ikonuna tıklayınca YENİ RESİM SEÇME AÇILIR
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _resimSecveGuncelle(widget.studentId),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.indigo,
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------
            TextField(
              controller: _tcController,
              decoration: const InputDecoration(labelText: "T.C. Kimlik No"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dogumTarihiController,
              decoration: const InputDecoration(labelText: "Doğum Tarihi"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneAdiController,
              decoration: const InputDecoration(labelText: "Anne Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaAdiController,
              decoration: const InputDecoration(labelText: "Baba Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneCepController,
              decoration: const InputDecoration(labelText: "Anne Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaCepController,
              decoration: const InputDecoration(labelText: "Baba Cep Telefonu"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _anneMeslegiController,
              decoration: const InputDecoration(labelText: "Anne Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _babaMeslegiController,
              decoration: const InputDecoration(labelText: "Baba Mesleği"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kardesleriController,
              decoration: const InputDecoration(labelText: "Kardeşleri"),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _bilgileriKaydet,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Değişiklikleri Kaydet",
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
