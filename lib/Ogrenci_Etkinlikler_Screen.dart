import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciEtkinliklerScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciEtkinliklerScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Etkinliklerim"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('etkinlikler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz kayıtlı etkinlik bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;
          DateTime simdi = DateTime.now();

          List<QueryDocumentSnapshot> aktifEtkinlikler = [];
          List<QueryDocumentSnapshot> gecmisEtkinlikler = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
            if (bitis != null && bitis.toDate().isAfter(simdi)) {
              aktifEtkinlikler.add(doc);
            } else {
              gecmisEtkinlikler.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                "🟢 Aktif Etkinlikler",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              if (aktifEtkinlikler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Aktif etkinlik bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...aktifEtkinlikler.map(
                (doc) => _ogrenciEtkinlikKarti(context, doc, true),
              ),
              const SizedBox(height: 20),
              const Text(
                "📁 Geçmiş Etkinlikler",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              if (gecmisEtkinlikler.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Geçmiş etkinlik bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...gecmisEtkinlikler.map(
                (doc) => _ogrenciEtkinlikKarti(context, doc, false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ogrenciEtkinlikKarti(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool aktifMi,
  ) {
    var data = doc.data() as Map<String, dynamic>;
    String ad = data['etkinlik Adi'] ?? '';
    Timestamp? baslangic = data['baslangicTarihi'] as Timestamp?;
    Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
    Map<String, dynamic> katilanlarMap = data['katilanOgrenciler'] ?? {};
    bool katildiMi = katilanlarMap[studentId] == true;

    String baslaStr = baslangic != null
        ? "${baslangic.toDate().day}.${baslangic.toDate().month}.${baslangic.toDate().year}"
        : "";
    String bitisStr = bitis != null
        ? "${bitis.toDate().day}.${bitis.toDate().month}.${bitis.toDate().year}"
        : "";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Başlangıç: $baslaStr | Bitiş: $bitisStr\nDurumunuz: ${katildiMi ? 'Tamamlandı ✅' : (aktifMi ? 'Devam Ediyor' : 'Süresi Doldu')}",
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.people, color: Colors.indigo),
        onTap: () {
          // Öğrenci, etkinlik adına veya sağdaki ikona basınca detay ve katılım listesini görür (Tik atma alanı YOK)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OgrenciEtkinlikDetayScreen(
                classId: classId,
                etkinlikId: doc.id,
                etkinlikAdi: ad,
                aciklama: data['aciklama'] ?? '',
                aktifMi: aktifMi,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------
// ÖĞRENCİ İÇİN SALT OKUNUR ETKİNLİK DETAY VE KATILIM LİSTESİ
// ------------------------------------------------------------------
class OgrenciEtkinlikDetayScreen extends StatelessWidget {
  final String classId;
  final String etkinlikId;
  final String etkinlikAdi;
  final String aciklama;
  final bool aktifMi;

  const OgrenciEtkinlikDetayScreen({
    super.key,
    required this.classId,
    required this.etkinlikId,
    required this.etkinlikAdi,
    required this.aciklama,
    required this.aktifMi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(etkinlikAdi), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Açıklama:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              aciklama.isEmpty ? "Açıklama girilmemiş." : aciklama,
              style: const TextStyle(fontSize: 15),
            ),
            const Divider(height: 30),
            const Text(
              "Sınıf Katılım Durumları:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('etkinlikler')
                    .doc(etkinlikId)
                    .snapshots(),
                builder: (context, etkinlikSnap) {
                  if (etkinlikSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var etkinlikData =
                      etkinlikSnap.data?.data() as Map<String, dynamic>? ?? {};
                  Map<String, dynamic> katilanlarMap =
                      etkinlikData['katilanOgrenciler'] ?? {};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('classId', isEqualTo: classId)
                        .snapshots(),
                    builder: (context, studentSnap) {
                      if (studentSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!studentSnap.hasData ||
                          studentSnap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text("Bu sınıfta öğrenci bulunamadı."),
                        );
                      }

                      var students = studentSnap.data!.docs;

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          var studentDoc = students[index];
                          var studentData =
                              studentDoc.data() as Map<String, dynamic>;
                          String adSoyad =
                              "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

                          // Öğrencinin kendi ID'sini eşleştirmek yerine doğrudan map kontrolü
                          String studentId = studentDoc.id;
                          bool yapildiMi = katilanlarMap[studentId] == true;

                          Color renk = Colors.black87;
                          String durumMetni = "";

                          if (yapildiMi) {
                            renk = Colors.green.shade700;
                            durumMetni = "Tamamladı ✅";
                          } else if (aktifMi) {
                            renk = Colors
                                .black87; // Aktif etkinlikte henüz yapmayanlar siyah
                            durumMetni = "Henüz Yapmadı";
                          } else {
                            renk = Colors
                                .red
                                .shade700; // Süresi geçmiş etkinlikte yapmayanlar kırmızı
                            durumMetni = "Yapmadı ❌";
                          }

                          return ListTile(
                            title: Text(
                              adSoyad,
                              style: TextStyle(
                                color: renk,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              durumMetni,
                              style: TextStyle(color: renk, fontSize: 12),
                            ),
                            // Checkbox tamamen kaldırıldı, öğrenciler sadece listeyi görüntüler.
                          );
                        },
                      );
                    },
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
