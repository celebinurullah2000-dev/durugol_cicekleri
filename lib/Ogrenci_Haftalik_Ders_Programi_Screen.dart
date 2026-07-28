import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OgrenciHaftalikDersProgramiScreen extends StatefulWidget {
  final String classId;

  const OgrenciHaftalikDersProgramiScreen({super.key, required this.classId});

  @override
  State<OgrenciHaftalikDersProgramiScreen> createState() =>
      _OgrenciHaftalikDersProgramiScreenState();
}

class _OgrenciHaftalikDersProgramiScreenState
    extends State<OgrenciHaftalikDersProgramiScreen> {
  final List<String> gunler = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
  ];

  // Saatler ve ders matrisi için veriler
  final List<String> saatListesi = List.generate(
    15,
    (index) => "${9 + (index ~/ 2)}:00",
  );
  late List<List<String>> dersMatrisi;

  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    dersMatrisi = List.generate(15, (_) => List.generate(5, (_) => 'Teneffüs'));
    programiGetir();
  }

  // Firestore'dan kayıtlı programı çekme
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
            saatListesi[i] = savedSaatler[i].toString();
          }
        }

        // 2. Satırları ve günleri matrise aktar
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
      // Hata yönetimi
    }
    setState(() {
      yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Haftalık Ders Programı"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
                        // Başlık Satırı (Günler ve Saatler)
                        Container(
                          color: Colors.indigo.shade50,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 95,
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
                        // 15 Satırlık İçerik Tablosu
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
                                  // Saatler Sütunu (Salt Okunur)
                                  SizedBox(
                                    width: 95,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Text(
                                          saatListesi[i],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
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
                                  // Normal Ders Hücreleri (Salt Okunur)
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
                                          child: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1,
                                                  ),
                                              child: Text(
                                                dersMatrisi[i][gunIndex],
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
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
    );
  }
}
