import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgretmenDavranisScreen extends StatelessWidget {
  final String classId;
  final String className;
  final bool isTeacher;

  const OgretmenDavranisScreen({
    super.key,
    required this.classId,
    this.className = "",
    this.isTeacher = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$className - Davranış Takip Modülü"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bu sınıfta kayıtlı öğrenci bulunamadı."),
            );
          }

          var students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              var studentDoc = students[index];
              var studentData = studentDoc.data() as Map<String, dynamic>;
              String studentId = studentDoc.id;
              String adSoyad =
                  "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('davranislar')
                    .doc(studentId)
                    .snapshots(),
                builder: (context, davranisSnap) {
                  int hamSari = 0;
                  int hamYesil = 0;

                  if (davranisSnap.hasData && davranisSnap.data!.exists) {
                    var data =
                        davranisSnap.data!.data() as Map<String, dynamic>? ??
                        {};
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

                  // Mahsuplaşma sonrası barda gösterilecek net kartlar:
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

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Öğrenci Adı
                          Text(
                            adSoyad,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Denge barını çağırırken mahsuplaşmış değerleri veriyoruz:
                          _buildDengeBari(
                            gosterilecekSari,
                            gosterilecekKirmizi,
                            gosterilecekYesil,
                            gosterilecekAltin,
                            netPuan,
                          ),
                          const SizedBox(height: 12),

                          // ORTA KISIM: Olumsuz Davranışlar (Sarı & Kırmızı)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Sarı: $kalanSari | Kırmızı: $hamKirmizi",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(70, 32),
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () => _kartGuncelle(
                                        classId,
                                        studentId,
                                        hamSari + 1,
                                        hamYesil,
                                      ),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        "Sarı Ekle",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: "Olumsuz Kartı Azalt",
                                      onPressed: hamSari > 0
                                          ? () => _kartGuncelle(
                                              classId,
                                              studentId,
                                              hamSari - 1,
                                              hamYesil,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // ALT KISIM: Olumlu Davranışlar (Yeşil & Altın)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Yeşil: $kalanYesil | Altın: $hamAltin",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(70, 32),
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () => _kartGuncelle(
                                        classId,
                                        studentId,
                                        hamSari,
                                        hamYesil + 1,
                                      ),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        "Yeşil Ekle",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      tooltip: "Olumlu Kartı Azalt",
                                      onPressed: hamYesil > 0
                                          ? () => _kartGuncelle(
                                              classId,
                                              studentId,
                                              hamSari,
                                              hamYesil - 1,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  // Firestore Veri Güncelleme Fonksiyonu
  void _kartGuncelle(
    String classId,
    String studentId,
    int yeniSari,
    int yeniYesil,
  ) async {
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(classId)
        .collection('davranislar')
        .doc(studentId)
        .set({
          'sariKart': yeniSari < 0 ? 0 : yeniSari,
          'yesilKart': yeniYesil < 0 ? 0 : yeniYesil,
          'guncellemeTarihi': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // Ortası Sıfır Olan Denge Barı ve Dinamik Emoji Göstergesi
  Widget _buildDengeBari(
    int sari,
    int kirmizi,
    int yesil,
    int altin,
    int netPuan,
  ) {
    // Net puana göre dinamik smiley/emoji belirleme mantığı
    String emojiDurum = "😐"; // Denge (0)
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
              "Davranış Denge Barı",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Emoji ve net puan göstergesi
            Row(
              children: [
                Text(emojiDurum, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  netPuan == 0
                      ? "Denge (0)"
                      : (netPuan > 0 ? "Artı: +$netPuan" : "Eksi: $netPuan"),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: durumRengi,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400, width: 0.8),
          ),
          child: Row(
            children: [
              // SOL TARAF (Negatif / Eksi Yönü)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (kirmizi > 0)
                        Container(
                          height: 14,
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
                          height: 14,
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

              // ORTA ÇİZGİ (Sıfır Noktası / Denge Noktası)
              Container(width: 2, color: Colors.black87),

              // SAĞ TARAF (Pozitif / Artı Yönü)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (yesil > 0)
                        Container(
                          height: 14,
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
                          height: 14,
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
