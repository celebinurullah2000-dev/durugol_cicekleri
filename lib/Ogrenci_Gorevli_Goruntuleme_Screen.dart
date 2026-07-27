// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciGorevliGoruntulemeScreen extends StatefulWidget {
  final String classId;
  final String studentId;
  const OgrenciGorevliGoruntulemeScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  State<OgrenciGorevliGoruntulemeScreen> createState() =>
      _OgrenciGorevliGoruntulemeScreenState();
}

class _OgrenciGorevliGoruntulemeScreenState
    extends State<OgrenciGorevliGoruntulemeScreen> {
  bool _veriYukleniyor = true;
  Map<String, dynamic>? _aktifKizGorevli;
  Map<String, dynamic>? _aktifErkekGorevli;
  DateTime? _kizBaslangicTarihi;
  DateTime? _erkekBaslangicTarihi;

  @override
  void initState() {
    super.initState();
    _aktifGorevlileriGetir();
  }

  Future<void> _aktifGorevlileriGetir() async {
    setState(() => _veriYukleniyor = true);
    try {
      var aktifDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('aktifGorevliler')
          .doc('mevcut')
          .get();

      if (aktifDoc.exists) {
        var data = aktifDoc.data();
        if (data != null) {
          _aktifKizGorevli = data['kiz'];
          _kizBaslangicTarihi = (data['kizBaslangic'] as Timestamp?)?.toDate();

          _aktifErkekGorevli = data['erkek'];
          _erkekBaslangicTarihi = (data['erkekBaslangic'] as Timestamp?)
              ?.toDate();
        }
      }

      setState(() => _veriYukleniyor = false);
    } catch (e) {
      setState(() => _veriYukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veriler yüklenirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _gecmisGorevlileriGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eski Sınıf Görevlileri Arşivi"),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('gecmisGorevliler')
                .orderBy('bitisTarihi', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Henüz geçmiş görevli kaydı bulunmuyor.");
              }
              var docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String ad = data['adSoyad'] ?? '';
                  String cinsiyet = data['cinsiyet'] ?? '';
                  int gun = data['gorevdeKaldigiGun'] ?? 0;
                  Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
                  String tarihStr = bitis != null
                      ? "${bitis.toDate().day}.${bitis.toDate().month}.${bitis.toDate().year}"
                      : "";

                  return ListTile(
                    leading: Icon(
                      cinsiyet == 'Kız' ? Icons.girl : Icons.boy,
                      color: Colors.indigo,
                    ),
                    title: Text(
                      ad,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Görev Süresi: $gun gün\nBitiş Tarihi: $tarihStr",
                    ),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_veriYukleniyor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Görevlileri"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: "Eski Görevliler Arşivi",
            onPressed: _gecmisGorevlileriGoster,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "Bu Haftanın Sınıf Görevlileri",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _gorevliKarti(
                          "Kız Görevli",
                          _aktifKizGorevli,
                          _kizBaslangicTarihi,
                          Icons.girl,
                        ),
                        _gorevliKarti(
                          "Erkek Görevli",
                          _aktifErkekGorevli,
                          _erkekBaslangicTarihi,
                          Icons.boy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _gecmisGorevlileriGoster,
              icon: const Icon(Icons.history),
              label: const Text("Geçmiş Görevli Arşivini Görüntüle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gorevliKarti(
    String baslik,
    Map<String, dynamic>? gorevli,
    DateTime? baslangicTarihi,
    IconData ikon,
  ) {
    String ad = gorevli != null
        ? (gorevli['adSoyad'] ?? 'Atanmadı')
        : 'Henüz Seçilmedi';
    String tarihStr = '';
    if (baslangicTarihi != null) {
      tarihStr =
          "Başlangıç: ${baslangicTarihi.day}.${baslangicTarihi.month}.${baslangicTarihi.year}";
    }

    return Column(
      children: [
        Icon(ikon, size: 45, color: Colors.indigo),
        const SizedBox(height: 8),
        Text(baslik, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          ad,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (tarihStr.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            tarihStr,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ],
    );
  }
}
