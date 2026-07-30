import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciDenemelerScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciDenemelerScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deneme Sınavı Sonuçlarım"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('denemeler')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Henüz eklenmiş deneme sınavı bulunmuyor."),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String sinavAdi = data['sinavAdi'] ?? '';
              Timestamp? tarih = data['tarih'] as Timestamp?;
              String tarihStr = tarih != null
                  ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
                  : "";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('denemeler')
                    .doc(doc.id)
                    .collection('sonuclar')
                    .doc(studentId)
                    .get(),
                builder: (context, sonucSnap) {
                  bool girildiMi = sonucSnap.hasData && sonucSnap.data!.exists;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        sinavAdi,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Tarih: $tarihStr\nDurum: ${girildiMi ? 'Sonuçlar Açıklandı ✅' : 'Sonuçlar Henüz Girilmedi ⏳'}",
                      ),
                      isThreeLine: true,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.indigo,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OgrenciDenemeDetayScreen(
                              classId: classId,
                              sinavId: doc.id,
                              sinavAdi: sinavAdi,
                              studentId: studentId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------
// ÖĞRENCİ İÇİN SALT OKUNUR DENEME DETAY VE SONUÇ EKRANI
// ------------------------------------------------------------------
class OgrenciDenemeDetayScreen extends StatelessWidget {
  final String classId;
  final String sinavId;
  final String sinavAdi;
  final String studentId;

  const OgrenciDenemeDetayScreen({
    super.key,
    required this.classId,
    required this.sinavId,
    required this.sinavAdi,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> dersler = [
      "Türkçe",
      "Matematik",
      "Hayat Bilgisi",
      "Fen Bilimleri",
      "İngilizce",
    ];

    return Scaffold(
      appBar: AppBar(title: Text(sinavAdi), centerTitle: true),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('denemeler')
            .doc(sinavId)
            .collection('sonuclar')
            .doc(studentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Bu sınav için henüz sonuçlarınız girilmemiş.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Toplamları hesapla
          int toplamDogru = 0;
          int toplamYanlis = 0;
          int toplamBos = 0;

          for (var ders in dersler) {
            if (data.containsKey(ders)) {
              var dersData = data[ders] as Map<String, dynamic>? ?? {};
              toplamDogru += (dersData['d'] ?? 0) as int;
              toplamYanlis += (dersData['y'] ?? 0) as int;
              toplamBos += (dersData['b'] ?? 0) as int;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toplam Özet Kartı
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Toplam Doğru",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "$toplamDogru",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Toplam Yanlış",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            "$toplamYanlis",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            "Toplam Boş",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "$toplamBos",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Ders Bazlı Sonuçlarınız:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: dersler.length,
                    itemBuilder: (context, index) {
                      String ders = dersler[index];
                      var dersData = data[ders] as Map<String, dynamic>? ?? {};
                      int d = dersData['d'] ?? 0;
                      int y = dersData['y'] ?? 0;
                      int b = dersData['b'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ders,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Doğru: $d",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Yanlış: $y",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Boş: $b",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
