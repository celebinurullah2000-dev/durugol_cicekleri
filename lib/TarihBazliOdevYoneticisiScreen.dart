import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TarihBazliOdevYoneticisiScreen extends StatefulWidget {
  final String classId;

  const TarihBazliOdevYoneticisiScreen({super.key, required this.classId});

  @override
  State<TarihBazliOdevYoneticisiScreen> createState() =>
      _TarihBazliOdevYoneticisiScreenState();
}

class _TarihBazliOdevYoneticisiScreenState
    extends State<TarihBazliOdevYoneticisiScreen> {
  // Sınıftaki tüm öğrencilerin o tarihteki belirli bir ödev kitabının durumunu toplu güncelleme
  Future<void> _topluDurumGuncelle(
    String tarihStr,
    int kitapIndex,
    String yeniDurum,
  ) async {
    var studentsSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: widget.classId)
        .get();

    for (var studentDoc in studentsSnapshot.docs) {
      var odevlerRef = studentDoc.reference.collection('odevler');
      var odevQuery = await odevlerRef
          .where('tarihStr', isEqualTo: tarihStr)
          .get();

      if (odevQuery.docs.isNotEmpty) {
        var docId = odevQuery.docs.first.id;
        var veri = odevQuery.docs.first.data();
        List kitaplar = List.from(veri['kitaplar'] ?? []);

        if (kitaplar.length > kitapIndex) {
          Map<String, dynamic> kitap = Map.from(kitaplar[kitapIndex]);
          kitap['durum'] = yeniDurum;
          kitaplar[kitapIndex] = kitap;

          await odevlerRef.doc(docId).update({'kitaplar': kitaplar});
        }
      }
    }

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Tüm sınıfın ödev durumu '$yeniDurum' olarak güncellendi.",
        ),
      ),
    );
  }

  // Tek bir öğrencinin ödev durumunu güncelleme
  Future<void> _tekilDurumGuncelle(
    String studentId,
    String tarihStr,
    int kitapIndex,
    String yeniDurum,
  ) async {
    var odevlerRef = FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .collection('odevler');
    var odevQuery = await odevlerRef
        .where('tarihStr', isEqualTo: tarihStr)
        .get();

    if (odevQuery.docs.isNotEmpty) {
      var docId = odevQuery.docs.first.id;
      var veri = odevQuery.docs.first.data();
      List kitaplar = List.from(veri['kitaplar'] ?? []);

      if (kitaplar.length > kitapIndex) {
        Map<String, dynamic> kitap = Map.from(kitaplar[kitapIndex]);
        kitap['durum'] = yeniDurum;
        kitaplar[kitapIndex] = kitap;

        await odevlerRef.doc(docId).update({'kitaplar': kitaplar});
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hızlı Ödev Durumu Düzenleme"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .limit(1)
            .snapshots(),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Sınıfta öğrenci bulunamadı."));
          }

          var sampleStudentId = studentSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(sampleStudentId)
                .collection('odevler')
                .snapshots(),
            builder: (context, odevSnapshot) {
              if (odevSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!odevSnapshot.hasData || odevSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Henüz verilmiş bir ödev bulunmuyor."),
                );
              }

              var odevler = odevSnapshot.data!.docs;

              return ListView.builder(
                itemCount: odevler.length,
                itemBuilder: (context, index) {
                  var odevData = odevler[index].data() as Map<String, dynamic>;
                  String tarihStr =
                      odevData['tarihStr'] ?? 'Tarih Belirtilmemiş';
                  List kitaplar = odevData['kitaplar'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        tarihStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "${kitaplar.length} adet ödev kitabı/kalemi bulunuyor",
                      ),
                      children: [
                        ...kitaplar.asMap().entries.map((kitapEntry) {
                          int kIndex = kitapEntry.key;
                          var k = kitapEntry.value;
                          String kitapAdi = k['kitapAdi'] ?? 'Kitap';
                          String sayfa = k['sayfaAraligi'] ?? '';

                          return ExpansionTile(
                            leading: const Icon(
                              Icons.book,
                              color: Colors.indigo,
                            ),
                            title: Text(
                              "$kitapAdi (Sayfa: $sayfa)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              "Öğrenci listesini görmek için dokun",
                              style: TextStyle(fontSize: 11),
                            ),
                            children: [
                              // TOPLU İŞLEM BUTONLARI
                              Container(
                                color: Colors.grey.shade100,
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    const Text(
                                      "Toplu:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _topluDurumGuncelle(
                                        tarihStr,
                                        kIndex,
                                        'yapildi',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 30),
                                      ),
                                      child: const Text(
                                        "Tümü Yapıldı",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _topluDurumGuncelle(
                                        tarihStr,
                                        kIndex,
                                        'bekliyor',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 30),
                                      ),
                                      child: const Text(
                                        "Tümü Bekliyor",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _topluDurumGuncelle(
                                        tarihStr,
                                        kIndex,
                                        'ogretmen_reddi',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 30),
                                      ),
                                      child: const Text(
                                        "Tümü Yapılmadı",
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // SINIFTAKİ ÖĞRENCİLERİN LİSTESİ VE TEKİL DURUMLARI
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('students')
                                    .where('classId', isEqualTo: widget.classId)
                                    .snapshots(),
                                builder: (context, sinifSnapshot) {
                                  if (!sinifSnapshot.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  var ogrenciler = sinifSnapshot.data!.docs;

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: ogrenciler.length,
                                    itemBuilder: (context, oIdx) {
                                      var ogrDoc = ogrenciler[oIdx];
                                      var ogrData =
                                          ogrDoc.data() as Map<String, dynamic>;
                                      String ogrAd =
                                          "${ogrData['firstName'] ?? ''} ${ogrData['lastName'] ?? ''}";
                                      String ogrId = ogrDoc.id;

                                      return FutureBuilder<DocumentSnapshot>(
                                        future: ogrDoc.reference
                                            .collection('odevler')
                                            .where(
                                              'tarihStr',
                                              isEqualTo: tarihStr,
                                            )
                                            .get()
                                            .then((value) => value.docs.first),
                                        builder: (context, ogrOdevSnap) {
                                          String mevcutDurum = 'bekliyor';
                                          if (ogrOdevSnap.hasData &&
                                              ogrOdevSnap.data!.exists) {
                                            try {
                                              var data =
                                                  ogrOdevSnap.data!.data()
                                                      as Map<String, dynamic>;
                                              List kList =
                                                  data['kitaplar'] ?? [];
                                              if (kList.length > kIndex) {
                                                mevcutDurum =
                                                    kList[kIndex]['durum'] ??
                                                    'bekliyor';
                                              }
                                            } catch (_) {}
                                          }

                                          Color durumRengi = Colors.orange;
                                          if (mevcutDurum == 'yapildi') {
                                            durumRengi = Colors.green;
                                          }
                                          if (mevcutDurum == 'ogretmen_reddi') {
                                            durumRengi = Colors.red;
                                          }

                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                              ogrAd,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            trailing: DropdownButton<String>(
                                              value:
                                                  [
                                                    'yapildi',
                                                    'bekliyor',
                                                    'ogretmen_reddi',
                                                  ].contains(mevcutDurum)
                                                  ? mevcutDurum
                                                  : 'bekliyor',
                                              dropdownColor: Colors.white,
                                              style: TextStyle(
                                                color: durumRengi,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'yapildi',
                                                  child: Text(
                                                    "Yapıldı",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'bekliyor',
                                                  child: Text(
                                                    "Bekliyor",
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'ogretmen_reddi',
                                                  child: Text(
                                                    "Yapılmadı",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (yeniDeger) {
                                                if (yeniDeger != null) {
                                                  _tekilDurumGuncelle(
                                                    ogrId,
                                                    tarihStr,
                                                    kIndex,
                                                    yeniDeger,
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        }),
                      ],
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
