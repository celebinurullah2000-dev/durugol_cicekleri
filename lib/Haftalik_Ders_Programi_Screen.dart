import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HaftalikDersProgramiScreen extends StatefulWidget {
  final String classId;
  final bool isTeacher;

  const HaftalikDersProgramiScreen({
    super.key,
    required this.classId,
    required this.isTeacher,
  });

  @override
  State<HaftalikDersProgramiScreen> createState() =>
      _HaftalikDersProgramiScreenState();
}

class _HaftalikDersProgramiScreenState
    extends State<HaftalikDersProgramiScreen> {
  final List<String> gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
  ];

  // Seçilebilir Ders Listesi ("Boş / Teneffüs" yerine sadece "Teneffüs")
  final List<String> dersSecenekleri = [
    'Teneffüs',
    'Türkçe',
    'Matematik',
    'Hayat Bilgisi',
    'İngilizce',
    'Görsel Sanatlar',
    'Müzik',
    'Beden Eğitimi ve Oyun',
    'Serbest Etkinlikler',
    'Oyun ve Fiziki Etkinlikler',
    'Modern Dans',
    'Halk Oyunları',
    'Zeka Oyunları',
    'Flüt',
    'Ödev',
  ];

  late List<TextEditingController> saatControllers;
  late List<List<String>> dersMatrisi;

  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    saatControllers = List.generate(
      15,
      (index) => TextEditingController(text: "${9 + (index ~/ 2)}:00"),
    );
    dersMatrisi = List.generate(15, (_) => List.generate(5, (_) => 'Teneffüs'));
    programiGetir();
  }

  Future<void> programiGetir() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('program')
          .doc('haftalik')
          .get();

      if (doc.exists) {
        var data = doc.data()!;

        // 1. Saatleri al
        if (data.containsKey('saatler')) {
          List<dynamic> savedSaatler = data['saatler'];
          for (int i = 0; i < savedSaatler.length && i < 15; i++) {
            saatControllers[i].text = savedSaatler[i].toString();
          }
        }

        // 2. Satırları ve günleri güvenli bir şekilde matrise aktar
        if (data.containsKey('satirlar')) {
          List<dynamic> savedSatirlar = data['satirlar'];
          for (int i = 0; i < savedSatirlar.length && i < 15; i++) {
            var satirItem = savedSatirlar[i];
            if (satirItem is Map && satirItem.containsKey('gunler')) {
              List<dynamic> gunlerListesi = satirItem['gunler'];
              for (int j = 0; j < gunlerListesi.length && j < 5; j++) {
                dersMatrisi[i][j] = gunlerListesi[j].toString();
              }
            }
          }
        }
      }
    } catch (e) {
      // Hata durumunda konsola yazdırabilirsiniz
    }
    setState(() {
      yukleniyor = false;
    });
  }

  Future<void> programiKaydet() async {
    setState(() => yukleniyor = true);
    try {
      List<String> saatlerListesi = saatControllers
          .map((c) => c.text.trim())
          .toList();

      // Ders matrisini Firestore'un destekleyeceği şekilde güvenli Map listesine dönüştürüyoruz
      List<Map<String, dynamic>> matrisVerisi = [];
      for (int i = 0; i < dersMatrisi.length; i++) {
        List<String> satirListesi = [];
        for (int j = 0; j < dersMatrisi[i].length; j++) {
          satirListesi.add(dersMatrisi[i][j]);
        }
        matrisVerisi.add({'gunler': satirListesi});
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('program')
          .doc('haftalik')
          .set({'saatler': saatlerListesi, 'satirlar': matrisVerisi});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Haftalık ders programı ve dersler başarıyla kaydedildi!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kaydedilirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => yukleniyor = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Haftalık Ders Programı"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.save, size: 28),
              tooltip: "Programı Kaydet",
              onPressed: programiKaydet,
            ),
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      children: [
                        // Başlık Satırı
                        Container(
                          color: Colors.indigo.shade50,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 65,
                                child: Text(
                                  "Saatler",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              for (var gun in gunler)
                                Expanded(
                                  child: Text(
                                    gun,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        // 15 Satırlık İçerik
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 15,
                          itemBuilder: (context, i) {
                            bool isTeneffusSatiri =
                                (i == 1 ||
                                i == 3 ||
                                i == 5 ||
                                i == 9 ||
                                i == 11 ||
                                i == 13);
                            bool isOgleArasi = (i == 7);
                            bool isTenOrOgle = isTeneffusSatiri || isOgleArasi;

                            return Container(
                              height: isTenOrOgle ? 30 : 52,
                              decoration: BoxDecoration(
                                color: isTenOrOgle
                                    ? Colors.grey.shade100
                                    : Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Saatler Sütunu
                                  SizedBox(
                                    width: 120,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: widget.isTeacher
                                          ? TextField(
                                              controller: saatControllers[i],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                            )
                                          : Text(
                                              saatControllers[i].text,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: Colors.grey.shade300,
                                  ),

                                  // Teneffüs Satırları
                                  if (isTeneffusSatiri)
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          "T   E   N   E   F   F   Ü   S",
                                          style: TextStyle(
                                            letterSpacing: 2.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    )
                                  // Öğle Arası Satırı
                                  else if (isOgleArasi)
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: const Text(
                                          "Ö   Ğ   L   E      A   R   A   S   I",
                                          style: TextStyle(
                                            letterSpacing: 2.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    )
                                  // Ders Satırları (Ekranı tam kaplayan 5 gün sütunu)
                                  else
                                    for (
                                      int gunIndex = 0;
                                      gunIndex < 5;
                                      gunIndex++
                                    )
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: widget.isTeacher
                                              ? Padding(
                                                  // Öğretmen için Dropdown kodları...
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 1,
                                                      ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      isExpanded: true,
                                                      value:
                                                          dersSecenekleri.contains(
                                                            dersMatrisi[i][gunIndex],
                                                          )
                                                          ? dersMatrisi[i][gunIndex]
                                                          : 'Teneffüs',
                                                      items: dersSecenekleri.map((
                                                        String ders,
                                                      ) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: ders,
                                                          child: Text(
                                                            ders,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 9.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  ders ==
                                                                      'Teneffüs'
                                                                  ? Colors.grey
                                                                  : Colors
                                                                        .black87,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (String? yeniDeger) {
                                                            if (yeniDeger !=
                                                                null) {
                                                              setState(() {
                                                                dersMatrisi[i][gunIndex] =
                                                                    yeniDeger;
                                                              });
                                                            }
                                                          },
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  // ÖĞRENCİ İÇİN: Salt okunur, sade metin görünümü
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 1,
                                                        ),
                                                    child: Text(
                                                      dersMatrisi[i][gunIndex],
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            dersMatrisi[i][gunIndex] ==
                                                                'Teneffüs'
                                                            ? Colors.grey
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: widget.isTeacher
          ? Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: programiKaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "Değişiklikleri ve Programı Kaydet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}
