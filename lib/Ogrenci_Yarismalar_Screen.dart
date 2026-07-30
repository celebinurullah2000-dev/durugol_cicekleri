import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciYarismalarScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciYarismalarScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Yarışmalarım"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('yarismalar')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz kayıtlı yarışma bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;
          DateTime simdi = DateTime.now();

          List<QueryDocumentSnapshot> aktifYarismalar = [];
          List<QueryDocumentSnapshot> gecmisYarismalar = [];

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? bitis = data['bitisTarihi'] as Timestamp?;
            if (bitis != null && bitis.toDate().isAfter(simdi)) {
              aktifYarismalar.add(doc);
            } else {
              gecmisYarismalar.add(doc);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                "🏆 Aktif Yarışmalar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Divider(),
              if (aktifYarismalar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Aktif yarışma bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...aktifYarismalar.map(
                (doc) => _ogrenciYarismaKarti(context, doc, true),
              ),
              const SizedBox(height: 20),
              const Text(
                "📁 Geçmiş Yarışmalar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              if (gecmisYarismalar.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Geçmiş yarışma bulunmuyor.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...gecmisYarismalar.map(
                (doc) => _ogrenciYarismaKarti(context, doc, false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ogrenciYarismaKarti(
    BuildContext context,
    QueryDocumentSnapshot doc,
    bool aktifMi,
  ) {
    var data = doc.data() as Map<String, dynamic>;
    String ad = data['yarismaAdi'] ?? '';
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
          "Başlangıç: $baslaStr | Bitiş: $bitisStr\nDurumunuz: ${katildiMi ? 'Katıldınız ✅' : (aktifMi ? 'Devam Ediyor' : 'Süresi Doldu')}",
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.people, color: Colors.indigo),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OgrenciYarismaDetayScreen(
                classId: classId,
                yarismaId: doc.id,
                yarismaAdi: ad,
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

// Öğrenci İçin Salt Okunur Yarışma Detay ve Katılım Listesi
class OgrenciYarismaDetayScreen extends StatelessWidget {
  final String classId;
  final String yarismaId;
  final String yarismaAdi;
  final String aciklama;
  final bool aktifMi;

  const OgrenciYarismaDetayScreen({
    super.key,
    required this.classId,
    required this.yarismaId,
    required this.yarismaAdi,
    required this.aciklama,
    required this.aktifMi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(yarismaAdi), centerTitle: true),
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
                    .collection('yarismalar')
                    .doc(yarismaId)
                    .snapshots(),
                builder: (context, yarismaSnap) {
                  if (yarismaSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var yarismaData =
                      yarismaSnap.data?.data() as Map<String, dynamic>? ?? {};
                  Map<String, dynamic> katilanlarMap =
                      yarismaData['katilanOgrenciler'] ?? {};

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
                          String studentId = studentDoc.id;
                          String adSoyad =
                              "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

                          bool yapildiMi = katilanlarMap[studentId] == true;

                          Color renk = Colors.black87;
                          String durumMetni = "";

                          if (yapildiMi) {
                            renk = Colors.green.shade700;
                            durumMetni = "Katıldı ✅";
                          } else if (aktifMi) {
                            renk = Colors.black87;
                            durumMetni = "Henüz Katılmadı";
                          } else {
                            renk = Colors.red.shade700;
                            durumMetni = "Katılmadı ❌";
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
