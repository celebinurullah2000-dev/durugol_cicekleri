import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OdevlerimScreen extends StatefulWidget {
  final String studentId;

  const OdevlerimScreen({super.key, required this.studentId});

  @override
  State<OdevlerimScreen> createState() => _OdevlerimScreenState();
}

class _OdevlerimScreenState extends State<OdevlerimScreen> {
  // Tekil ödev kitabının durumunu güncelleme fonksiyonu
  Future<void> _odevKitabiDurumGuncelle(
    String odevId,
    List mevcutKitaplar,
    int index,
  ) async {
    Map<String, dynamic> secilenKitap = Map.from(mevcutKitaplar[index]);
    String mevcutDurum = secilenKitap['durum'] ?? 'bekliyor';

    // Eğer öğretmen kilitlediyse öğrenci değiştiremez
    if (mevcutDurum == 'ogretmen_reddi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bu ödev kitabı öğretmeniniz tarafından kilitlendiği için değiştirilemez!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Durumu değiştir: yapildi <-> bekliyor
    secilenKitap['durum'] = (mevcutDurum == 'yapildi') ? 'bekliyor' : 'yapildi';
    mevcutKitaplar[index] = secilenKitap;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .collection('odevler')
        .doc(odevId)
        .update({'kitaplar': mevcutKitaplar});

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ödevlerim")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .collection('odevler')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz verilmiş bir ödeviniz yok.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final odevler = snapshot.data!.docs;

          return ListView.builder(
            itemCount: odevler.length,
            itemBuilder: (context, index) {
              var odevDoc = odevler[index];
              var odevData = odevDoc.data() as Map<String, dynamic>;

              String tarihStr = odevData['tarihStr'] ?? 'Tarih Belirtilmemiş';
              List kitaplar = odevData['kitaplar'] ?? [];

              // O günkü tüm ödev kitapları bitti mi kontrolü
              bool tumuYapildi =
                  kitaplar.isNotEmpty &&
                  kitaplar.every((k) => k['durum'] == 'yapildi');
              bool herhangiRed = kitaplar.any(
                (k) => k['durum'] == 'ogretmen_reddi',
              );

              Color kartRengi = Colors.black87;
              if (tumuYapildi) kartRengi = Colors.green;
              if (herhangiRed) kartRengi = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    tarihStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kartRengi,
                    ),
                  ),
                  subtitle: Text(
                    herhangiRed
                        ? "Durum: Kilitli ödevleriniz var"
                        : (tumuYapildi
                              ? "Durum: Tüm ödevler tamamlandı"
                              : "Durum: Bekleyen ödevleriniz var"),
                    style: TextStyle(color: kartRengi, fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bu Tarihteki Ödev Kitapları ve Yönergeler:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...kitaplar.asMap().entries.map((entry) {
                            int kIndex = entry.key;
                            var k = entry.value;

                            String kAd = k['kitapAdi'] ?? '';
                            String kSayfa = k['sayfaAraligi'] ?? '';
                            String kAciklama = k['aciklama'] ?? '';
                            String kDurum = k['durum'] ?? 'bekliyor';

                            Color itemRengi = Colors.black87;
                            IconData itemIcon = Icons.radio_button_unchecked;
                            String durumAciklama =
                                "Yapılmadı (İşaretlemek için dokun)";

                            if (kDurum == 'yapildi') {
                              itemRengi = Colors.green;
                              itemIcon = Icons.check_circle;
                              durumAciklama = "Yapıldı (Tebrikler!)";
                            } else if (kDurum == 'ogretmen_reddi') {
                              itemRengi = Colors.red;
                              itemIcon = Icons.cancel;
                              durumAciklama =
                                  "Öğretmeniniz 'yapılmadı' olarak işaretledi!";
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: itemRengi.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: itemRengi.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$kAd (Sayfa: $kSayfa)",
                                          style: TextStyle(
                                            color: itemRengi,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (kAciklama.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              "Yönerge: $kAciklama",
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          durumAciklama,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: itemRengi,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      itemIcon,
                                      color: itemRengi,
                                      size: 28,
                                    ),
                                    onPressed: () => _odevKitabiDurumGuncelle(
                                      odevDoc.id,
                                      kitaplar,
                                      kIndex,
                                    ),
                                    tooltip: "Bu Ödev Kitabını İşaretle",
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
