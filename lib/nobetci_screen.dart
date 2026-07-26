import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class NobetciScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  final bool isTeacher; // Eklendi: Öğretmen mi öğrenci mi?

  const NobetciScreen({
    super.key,
    required this.studentId,
    required this.classId,
    this.isTeacher = false, // Varsayılan olarak öğrenci kabul edilir
  });

  @override
  State<NobetciScreen> createState() => _NobetciScreenState();
}

class _NobetciScreenState extends State<NobetciScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _nobetTakviminiAc(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime focusedDay = DateTime.now();
            DateTime? selectedDay = DateTime.now();

            return AlertDialog(
              title: const Text("Nöbet Tutulmayacak Günler"),
              content: SizedBox(
                width: 350,
                height: 420,
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('engellenen_tarihler')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Firestore'dan gelen engellenen tarihleri Set olarak alıyoruz
                    Set<String> engellenenTarihStrleri = {};
                    if (snapshot.hasData) {
                      engellenenTarihStrleri = snapshot.data!.docs
                          .map((doc) => doc.id)
                          .toSet();
                    }

                    String tarihKeyFormat(DateTime tarih) {
                      return "${tarih.year}-${tarih.month.toString().padLeft(2, '0')}-${tarih.day.toString().padLeft(2, '0')}";
                    }

                    return TableCalendar(
                      firstDay: DateTime(2026, 1, 1),
                      lastDay: DateTime(3000, 12, 31),
                      focusedDay: focusedDay,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      daysOfWeekStyle: DaysOfWeekStyle(
                        dowTextFormatter: (date, locale) {
                          const days = [
                            'Pzt',
                            'Sal',
                            'Çar',
                            'Per',
                            'Cum',
                            'Cmt',
                            'Paz',
                          ];
                          return days[date.weekday - 1];
                        },
                      ),

                      headerStyle: HeaderStyle(
                        formatButtonVisible:
                            false, // "2 weeks" düğmesini gizler
                        titleCentered: true,
                        // Türkçe Ay ve Yıl Başlığı
                        titleTextFormatter: (date, locale) {
                          const months = [
                            'Ocak',
                            'Şubat',
                            'Mart',
                            'Nisan',
                            'Mayıs',
                            'Haziran',
                            'Temmuz',
                            'Ağustos',
                            'Eylül',
                            'Ekim',
                            'Kasım',
                            'Aralık',
                          ];
                          return '${months[date.month - 1]} ${date.year}';
                        },
                      ),
                      selectedDayPredicate: (day) =>
                          isSameDay(selectedDay, day),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          String key = tarihKeyFormat(day);
                          if (engellenenTarihStrleri.contains(key)) {
                            return Container(
                              margin: const EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      onDaySelected: (secilen, odaklanan) async {
                        String tarihStr = tarihKeyFormat(secilen);
                        var ref = FirebaseFirestore.instance
                            .collection('classes')
                            .doc(widget.classId)
                            .collection('engellenen_tarihler')
                            .doc(tarihStr);

                        var doc = await ref.get();
                        if (doc.exists) {
                          await ref.delete();
                        } else {
                          await ref.set({'engellendiMi': true});
                        }

                        // Dialog içindeki ekranın anında yeniden çizilmesini sağlar
                        setDialogState(() {
                          selectedDay = secilen;
                          focusedDay = odaklanan;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.indigoAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Kapat"),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
    // ÖNEMLİ: Bugün öğretmen tarafından engellenen (tatil vb.) günler arasında mı kontrol et
    DocumentSnapshot engelDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('engellenen_tarihler')
        .doc(dateKey)
        .get();

    if (engelDoc.exists) {
      setState(() {
        _isWeekend = true; // Veya özel bir mesaj değişkeni
        _isLoading = false;
      });
      return;
    }
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
        actions: [
          // Yalnızca öğretmen ise takvim butonunu göster
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: "Nöbet Tatil Takvimi",
              onPressed: () {
                _nobetTakviminiAc(
                  context,
                ); // Aşağıdaki modal fonksiyonunu çağırır
              },
            ),
        ],
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
                                // Türkçe karakter duyarlı yardımcı karşılaştırma fonksiyonu
                                int turkceKarsilastir(String a, String b) {
                                  const String turkceAlfabe =
                                      'aabcçdefgğhıijklmnoöprsştuüvyz';

                                  String aKucuk = a
                                      .toLowerCase()
                                      .replaceAll('İ', 'i')
                                      .replaceAll('I', 'ı')
                                      .replaceAll('Ç', 'ç')
                                      .replaceAll('Ğ', 'ğ')
                                      .replaceAll('Ö', 'ö')
                                      .replaceAll('Ş', 'ş')
                                      .replaceAll('Ü', 'ü');

                                  String bKucuk = b
                                      .toLowerCase()
                                      .replaceAll('İ', 'i')
                                      .replaceAll('I', 'ı')
                                      .replaceAll('Ç', 'ç')
                                      .replaceAll('Ğ', 'ğ')
                                      .replaceAll('Ö', 'ö')
                                      .replaceAll('Ş', 'ş')
                                      .replaceAll('Ü', 'ü');

                                  int minLength = aKucuk.length < bKucuk.length
                                      ? aKucuk.length
                                      : bKucuk.length;

                                  for (int i = 0; i < minLength; i++) {
                                    int indexA = turkceAlfabe.indexOf(
                                      aKucuk[i],
                                    );
                                    int indexB = turkceAlfabe.indexOf(
                                      bKucuk[i],
                                    );

                                    if (indexA == -1 || indexB == -1) {
                                      int comp = aKucuk
                                          .codeUnitAt(i)
                                          .compareTo(bKucuk.codeUnitAt(i));
                                      if (comp != 0) return comp;
                                    } else if (indexA != indexB) {
                                      return indexA.compareTo(indexB);
                                    }
                                  }

                                  return aKucuk.length.compareTo(bKucuk.length);
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
                                  return turkceKarsilastir(nameA, nameB);
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

                                    // Öğrencinin nöbet müracaat/müsaitlik durumu (Varsayılan: true)
                                    bool nobetMusait =
                                        studentData['nobetMusait'] ?? true;

                                    // Renk ve Durum Belirleme Mantığı
                                    Color textColor = Colors.black87;
                                    String durumMetni = "Sıra Bekliyor";

                                    if (!nobetMusait) {
                                      textColor = Colors.grey;
                                      durumMetni = "Nöbet İptal Edildi (Pasif)";
                                    } else if (studentId == _bugunKizId ||
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
                                      // Öğrenci isminin önüne nöbet durumunu değiştiren Checkbox eklendi
                                      // Öğretmen değilse Checkbox'ı gizleyebilir veya tıklanamaz yapabiliriz
                                      leading: widget.isTeacher
                                          ? Checkbox(
                                              value: nobetMusait,
                                              activeColor: Colors.indigo,
                                              onChanged:
                                                  (bool? yeniDeger) async {
                                                    if (yeniDeger != null) {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'students',
                                                          )
                                                          .doc(studentId)
                                                          .update({
                                                            'nobetMusait':
                                                                yeniDeger,
                                                          });
                                                    }
                                                  },
                                            )
                                          : CircleAvatar(
                                              backgroundColor:
                                                  Colors.indigo.shade100,
                                              child: Text(
                                                (index + 1).toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                      title: Text(
                                        adSoyad,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: nobetMusait
                                              ? TextDecoration.none
                                              : TextDecoration.lineThrough,
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
