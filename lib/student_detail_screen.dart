import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils.dart';

class StudentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentData,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${studentData['firstName']} ${studentData['lastName']} - Detaylar",
        ),
      ),

      body: Column(
        children: [
          // 1. Öğrenci Özet Bilgisi

          // 2. Okunan Kitaplar Listesi (StreamBuilder ile)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .collection('okunan_kitaplar')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var kitaplar = snapshot.data!.docs;
                int toplamKitap = kitaplar.length;
                int toplamSayfa = 0;
                for (var doc in kitaplar) {
                  toplamSayfa += (doc['sayfaSayisi'] as num).toInt();
                }
                String mevcutUnvan = Oyunlastirma.getUnvan(toplamSayfa);
                String mevcutOdul = Oyunlastirma.getOdul(toplamSayfa);
                return Column(
                  children: [
                    // TEK BİR KART: Bilgiler + İstatistikler
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sınıf No: ${studentData['schoolNumber'] ?? 'Belirtilmemiş'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Şifre: ${studentData['password'] ?? 'Tanımlanmamış'}",
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _istatistikWidget("Kitap", "$toplamKitap"),
                                _istatistikWidget("Sayfa", "$toplamSayfa"),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  "Ünvan: $mevcutUnvan",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Ödül: $mevcutOdul",
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Kitap Listesi Başlığı (İsteğe bağlı, kartın dışına aldık)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Okunan Kitaplar:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Kitap Listesi
                    Expanded(
                      child: ListView.builder(
                        itemCount: kitaplar.length,
                        itemBuilder: (context, index) {
                          var doc = kitaplar[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.book,
                              color: Colors.indigo,
                            ),
                            title: Text(doc['kitapAdi']),
                            trailing: Text("${doc['sayfaSayisi']} Sayfa"),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _istatistikWidget(String baslik, String deger) {
  return Column(
    children: [
      Text(baslik, style: const TextStyle(color: Colors.grey)),
      Text(
        deger,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
