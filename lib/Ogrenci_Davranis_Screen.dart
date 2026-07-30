import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciDavranisScreen extends StatelessWidget {
  final String classId;
  final String studentId;

  const OgrenciDavranisScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Davranış Durumum"), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('davranislar')
            .doc(studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          int hamSari = 0;
          int hamYesil = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            hamSari = data['sariKart'] ?? 0;
            hamYesil = data['yesilKart'] ?? 0;
          }

          int hamKirmizi = hamSari ~/ 3;
          int kalanSari = hamSari % 3;

          int hamAltin = hamYesil ~/ 3;
          int kalanYesil = hamYesil % 3;

          int toplamNegatifPuan = (hamKirmizi * 3) + kalanSari;
          int toplamPozitifPuan = (hamAltin * 3) + kalanYesil;
          int netPuan = toplamPozitifPuan - toplamNegatifPuan;

          int gosterilecekSari = 0;
          int gosterilecekKirmizi = 0;
          int gosterilecekYesil = 0;
          int gosterilecekAltin = 0;

          if (netPuan < 0) {
            int eksiKalan = -netPuan;
            gosterilecekKirmizi = eksiKalan ~/ 3;
            gosterilecekSari = eksiKalan % 3;
          } else if (netPuan > 0) {
            int artiKalan = netPuan;
            gosterilecekAltin = artiKalan ~/ 3;
            gosterilecekYesil = artiKalan % 3;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Genel Davranış Denge Durumun",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Denge Barı Kartı
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDengeBari(
                      gosterilecekSari,
                      gosterilecekKirmizi,
                      gosterilecekYesil,
                      gosterilecekAltin,
                      netPuan,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Kart Detayların:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Olumlu Kartlar Özeti
                Card(
                  color: Colors.green.shade50,
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 30,
                    ),
                    title: const Text(
                      "Olumlu Kartların",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Yeşil Kart: $kalanYesil | Altın Kart: $hamAltin",
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Olumsuz Kartlar Özeti
                Card(
                  color: Colors.red.shade50,
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                    title: const Text(
                      "Geliştirilmesi Gerekenler",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Sarı Kart: $kalanSari | Kırmızı Kart: $hamKirmizi",
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Öğrenci Ekranı İçin Denge Barı Widget'ı
  Widget _buildDengeBari(
    int sari,
    int kirmizi,
    int yesil,
    int altin,
    int netPuan,
  ) {
    String emojiDurum = "😐";
    Color durumRengi = Colors.grey;

    if (netPuan > 0) {
      durumRengi = Colors.green.shade700;
      if (netPuan <= 3) {
        emojiDurum = "😊";
      } else if (netPuan <= 6) {
        emojiDurum = "😁";
      } else if (netPuan <= 9) {
        emojiDurum = "😍";
      } else {
        emojiDurum = "👑💖";
      }
    } else if (netPuan < 0) {
      durumRengi = Colors.red.shade700;
      int eksiDeger = -netPuan;
      if (eksiDeger <= 3) {
        emojiDurum = "😕";
      } else if (eksiDeger <= 6) {
        emojiDurum = "😟";
      } else {
        emojiDurum = "😢";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Denge Barı",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(emojiDurum, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  netPuan == 0
                      ? "Denge (0)"
                      : (netPuan > 0 ? "Artı: +$netPuan" : "Eksi: $netPuan"),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (kirmizi > 0)
                        Container(
                          height: 16,
                          width: (kirmizi * 12.0).clamp(0.0, 80.0),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      const SizedBox(width: 1),
                      if (sari > 0)
                        Container(
                          height: 16,
                          width: (sari * 10.0).clamp(0.0, 60.0),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: kirmizi == 0
                                ? const BorderRadius.horizontal(
                                    left: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(width: 2, color: Colors.black87),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (yesil > 0)
                        Container(
                          height: 16,
                          width: (yesil * 10.0).clamp(0.0, 60.0),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: altin == 0
                                ? const BorderRadius.horizontal(
                                    right: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                        ),
                      const SizedBox(width: 1),
                      if (altin > 0)
                        Container(
                          height: 16,
                          width: (altin * 12.0).clamp(0.0, 80.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
