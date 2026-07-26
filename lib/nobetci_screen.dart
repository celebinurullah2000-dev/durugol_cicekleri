import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NobetciScreen extends StatefulWidget {
  final String studentId;
  final String classId;

  const NobetciScreen({
    super.key,
    required this.studentId,
    required this.classId,
  });

  @override
  State<NobetciScreen> createState() => _NobetciScreenState();
}

class _NobetciScreenState extends State<NobetciScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _bugunKizNovetciAdi;
  String? _bugunErkekNovetciAdi;
  String? _bugunKizId;
  String? _bugunErkekId;
  bool _isWeekend = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAndAssignDuty();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Bugün için nöbetçi kontrolü ve otomatik atama algoritması
  Future<void> _checkAndAssignDuty() async {
    setState(() => _isLoading = true);

    DateTime now = DateTime.now();
    // Hafta sonu kontrolü (6: Cumartesi, 7: Pazar)
    if (now.weekday == 6 || now.weekday == 7) {
      setState(() {
        _isWeekend = true;
        _isLoading = false;
      });
      return;
    }

    String dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      // 1. Bugün için daha önce nöbetçi atanmış mı kontrol et
      DocumentReference dutyDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('duty_records')
          .doc(dateKey);

      DocumentSnapshot dutySnapshot = await dutyDocRef.get();

      if (dutySnapshot.exists) {
        // Bugün için kayıt zaten var
        var data = dutySnapshot.data() as Map<String, dynamic>;
        _bugunKizId = data['girlId'];
        _bugunErkekId = data['boyId'];
        _bugunKizNovetciAdi = data['girlName'];
        _bugunErkekNovetciAdi = data['boyName'];
      } else {
        // 2. Kayıt yok, sıradaki kız ve erkeği seç
        QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: widget.classId)
            .get();

        var students = studentSnapshot.docs;

        // Cinsiyet alanına göre filtreleme (gender == 'K' veya 'E')
        // Cinsiyet alanına göre filtreleme (gender == 'K' veya 'E')
        var girls = students
            .where(
              (doc) => (doc.data() as Map<String, dynamic>)['gender'] == 'K',
            )
            .toList();
        var boys = students
            .where(
              (doc) => (doc.data() as Map<String, dynamic>)['gender'] == 'E',
            )
            .toList();

        // Alfabetik sıralama garantisi
        girls.sort((a, b) {
          var nameA =
              "${(a.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          var nameB =
              "${(b.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          return nameA.compareTo(nameB);
        });

        boys.sort((a, b) {
          var nameA =
              "${(a.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          var nameB =
              "${(b.data() as Map<String, dynamic>)['firstName'] ?? ''}";
          return nameA.compareTo(nameB);
        });

        // Güvenli seçim ve sıfırlama mantığı
        QueryDocumentSnapshot? nextGirl;
        for (var doc in girls) {
          var data = doc.data() as Map<String, dynamic>;
          if ((data['hasBeenOnDuty'] ?? false) == false) {
            nextGirl = doc;
            break;
          }
        }
        // Eğer tüm kızlar nöbet tuttuysa, listeyi başa sar (sıfırla)
        if (nextGirl == null && girls.isNotEmpty) {
          nextGirl = girls.first;
          for (var doc in girls) {
            await FirebaseFirestore.instance
                .collection('students')
                .doc(doc.id)
                .update({'hasBeenOnDuty': false});
          }
        }

        QueryDocumentSnapshot? nextBoy;
        for (var doc in boys) {
          var data = doc.data() as Map<String, dynamic>;
          if ((data['hasBeenOnDuty'] ?? false) == false) {
            nextBoy = doc;
            break;
          }
        }
        // Eğer tüm erkekler nöbet tuttuysa, listeyi başa sar (sıfırla)
        if (nextBoy == null && boys.isNotEmpty) {
          nextBoy = boys.first;
          for (var doc in boys) {
            await FirebaseFirestore.instance
                .collection('students')
                .doc(doc.id)
                .update({'hasBeenOnDuty': false});
          }
        }

        if (nextGirl == null || nextBoy == null) {
          setState(() => _isLoading = false);
          return;
        }

        _bugunKizId = nextGirl.id;
        _bugunErkekId = nextBoy.id;

        var girlData = nextGirl.data() as Map<String, dynamic>;
        var boyData = nextBoy.data() as Map<String, dynamic>;

        _bugunKizNovetciAdi =
            "${girlData['firstName']} ${girlData['lastName']}";
        _bugunErkekNovetciAdi =
            "${boyData['firstName']} ${boyData['lastName']}";

        // Firestore'a bugünün kaydını yaz
        await dutyDocRef.set({
          'date': dateKey,
          'girlId': _bugunKizId,
          'girlName': _bugunKizNovetciAdi,
          'boyId': _bugunErkekId,
          'boyName': _bugunErkekNovetciAdi,
        });

        // Öğrencilerin nöbet durumunu güncelle (tuttu olarak işaretle)
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunKizId)
            .update({'hasBeenOnDuty': true});
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunErkekId)
            .update({'hasBeenOnDuty': true});

        // Öğrencilerin nöbet durumunu güncelle (tuttu olarak işaretle)
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunKizId)
            .update({'hasBeenOnDuty': true});
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_bugunErkekId)
            .update({'hasBeenOnDuty': true});
      }
    } catch (e) {
      debugPrint("Nöbet atama hatası: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String bugunTarihStr =
        "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nöbetçi Öğrenci Takibi"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Güncel Nöbetçiler & Liste", icon: Icon(Icons.today)),
            Tab(text: "Geçmiş Nöbetler", icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: Güncel Durum ve Alfabetik Liste
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // ÜST KISIM: Bugünün Nöbetçileri Kartı
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Tarih: $bugunTarihStr",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo,
                          ),
                        ),
                        const Divider(height: 20),
                        _isWeekend
                            ? const Text(
                                "Bugün hafta sonu, nöbetçi öğrenci bulunmuyor.",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : _isLoading
                            ? const CircularProgressIndicator()
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        "Kız Nöbetçi",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bugunKizNovetciAdi ?? "Atanmadı",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const VerticalDivider(),
                                  Column(
                                    children: [
                                      const Text(
                                        "Erkek Nöbetçi",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bugunErkekNovetciAdi ?? "Atanmadı",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ALT KISIM: Tüm Öğrencilerin Alfabetik Listesi ve Renk Kodları
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Sınıf Öğrenci Listesi ve Nöbet Durumları",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('students')
                                  .where('classId', isEqualTo: widget.classId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      "Bu sınıfta öğrenci bulunamadı.",
                                    ),
                                  );
                                }

                                var students = snapshot.data!.docs;

                                // Dart tarafında isme göre alfabetik sıralama
                                students.sort((a, b) {
                                  var dataA = a.data() as Map<String, dynamic>;
                                  var dataB = b.data() as Map<String, dynamic>;
                                  String nameA =
                                      "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}";
                                  String nameB =
                                      "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}";
                                  return nameA.compareTo(nameB);
                                });

                                return ListView.builder(
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    var studentDoc = students[index];
                                    var studentData =
                                        studentDoc.data()
                                            as Map<String, dynamic>;
                                    String studentId = studentDoc.id;
                                    String adSoyad =
                                        "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}";
                                    bool hasBeenOnDuty =
                                        studentData['hasBeenOnDuty'] ?? false;

                                    // Renk ve Durum Belirleme Mantığı
                                    Color textColor = Colors.black87;
                                    String durumMetni = "Sıra Bekliyor";

                                    if (studentId == _bugunKizId ||
                                        studentId == _bugunErkekId) {
                                      textColor = Colors
                                          .green
                                          .shade700; // Bugün nöbetçi: Yeşil
                                      durumMetni = "Bugün Nöbetçi 🟢";
                                    } else if (hasBeenOnDuty) {
                                      textColor = Colors
                                          .red
                                          .shade300; // Daha önce nöbet tuttu: Açık Kırmızı
                                      durumMetni = "Nöbet Tuttu";
                                    }

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.indigo.shade100,
                                        child: Text(
                                          (index + 1).toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      title: Text(
                                        adSoyad,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        durumMetni,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SEKME: Geçmiş Nöbetler Arşivi
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .collection('duty_records')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("Henüz geçmiş nöbet kaydı bulunmuyor."),
                );
              }

              var records = snapshot.data!.docs;

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  var record = records[index].data() as Map<String, dynamic>;
                  String tarih = record['date'] ?? '';
                  String kiz = record['girlName'] ?? '';
                  String erkek = record['boyName'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.indigo,
                      ),
                      title: Text(
                        "Tarih: $tarih",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Kız: $kiz\nErkek: $erkek"),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
