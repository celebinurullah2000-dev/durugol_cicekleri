import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OdevlerimScreen extends StatefulWidget {
  final String studentId;
  final String classId; // Sınıf ID'sini de ekrana alıyoruz

  const OdevlerimScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<OdevlerimScreen> createState() => _OdevlerimScreenState();
}

class _OdevlerimScreenState extends State<OdevlerimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tekil ödev kitabının durumunu güncelleme fonksiyonu
  Future<void> _odevKitabiDurumGuncelle(
    String odevId,
    List mevcutKitaplar,
    int index,
  ) async {
    Map<String, dynamic> secilenKitap = Map.from(mevcutKitaplar[index]);
    String mevcutDurum = secilenKitap['durum'] ?? 'bekliyor';

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
      appBar: AppBar(
        title: const Text("Ödevlerim ve Etkinliklerim"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Ödevlerim", icon: Icon(Icons.book, size: 20)),
            Tab(text: "Görevlerim", icon: Icon(Icons.assignment, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: Mevcut Kitap Ödevleri Listesi
          _buildKitapOdevleriView(),

          // 2. SEKME: Yeni Eklenen Sınıf İşleri ve Öğrenci Takip Listesi
          _buildSinifIsleriView(),
        ],
      ),
    );
  }

  // 1. Sekme İçeriği (Eski Kitap Ödevleriniz)
  Widget _buildKitapOdevleriView() {
    return StreamBuilder<QuerySnapshot>(
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
              "Henüz verilmiş bir kitap ödeviniz yok.",
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
    );
  }

  // 2. Sekme İçeriği (Öğretmenin Sınıf İşleri / Etkinlik Takibi)
  Widget _buildSinifIsleriView() {
    if (widget.classId.isEmpty) {
      return const Center(
        child: Text(
          "Sınıf bilgisi bulunamadı.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('sinif_isleri')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Henüz öğretmeniniz tarafından eklenmiş bir sınıf işi/etkinlik yok.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          );
        }

        var isler = snapshot.data!.docs;

        return ListView.builder(
          itemCount: isler.length,
          itemBuilder: (context, index) {
            var isDoc = isler[index];
            var isData = isDoc.data() as Map<String, dynamic>;
            String isAdi = isData['isAdi'] ?? '';
            String veriTuru = isData['veriTuru'] ?? 'artı_eksi';
            String isId = isDoc.id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(widget.studentId)
                  .collection('is_verileri')
                  .doc(isId)
                  .get(),
              builder: (context, veriSnap) {
                String deger = '-';
                if (veriSnap.hasData && veriSnap.data!.exists) {
                  var vData = veriSnap.data!.data() as Map<String, dynamic>;
                  deger = vData['deger'] ?? '-';
                }

                Color durumRengi = Colors.grey;
                if (veriTuru == 'artı_eksi') {
                  durumRengi = (deger == '+') ? Colors.green : Colors.red;
                } else {
                  durumRengi = (deger != '-' && deger.isNotEmpty)
                      ? Colors.indigo
                      : Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: durumRengi.withValues(alpha: 0.15),
                      child: Icon(
                        veriTuru == 'artı_eksi'
                            ? (deger == '+' ? Icons.check : Icons.close)
                            : Icons.assignment_turned_in,
                        color: durumRengi,
                      ),
                    ),
                    title: Text(
                      isAdi,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // subtitle: Text("Tür: ${veriTuru.toUpperCase()}"), (Bu satırı sildim)
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: durumRengi.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: durumRengi),
                      ),
                      child: Text(
                        deger,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: durumRengi,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
