import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class OgretmenRandevuScreen extends StatefulWidget {
  final String classId;
  const OgretmenRandevuScreen({super.key, required this.classId});

  @override
  State<OgretmenRandevuScreen> createState() => _OgretmenRandevuScreenState();
}

class _OgretmenRandevuScreenState extends State<OgretmenRandevuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğretmen Randevu Yönetimi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: "Takvim & Slotlar"),
            Tab(icon: Icon(Icons.list_alt), text: "Randevular"),
            Tab(icon: Icon(Icons.school), text: "Öğrenciler"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: Takvim ve Günlük Saat/Slot Yönetimi
          TakvimVeSaatYonetimiTab(classId: widget.classId),

          // 2. SEKME: Alınmış Aktif ve Geçmiş Randevular Listesi
          RandevularListesiTab(classId: widget.classId),

          // 3. SEKME: Türkçe Alfabetik Öğrenci Listesi
          OgrenciListesiTab(classId: widget.classId),
        ],
      ),
    );
  }
}

// ==========================================
// 1. SEKME: TAKVİM VE GÜNLÜK SAAT YÖNETİMİ
// ==========================================
class TakvimVeSaatYonetimiTab extends StatefulWidget {
  final String classId;
  const TakvimVeSaatYonetimiTab({super.key, required this.classId});

  @override
  State<TakvimVeSaatYonetimiTab> createState() =>
      _TakvimVeSaatYonetimiTabState();
}

class _TakvimVeSaatYonetimiTabState extends State<TakvimVeSaatYonetimiTab> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<String> _gununSaatleriniUret(DateTime tarih) {
    if (tarih.weekday == DateTime.sunday) return [];
    List<String> saatler = [];
    int baslangicDakika;
    int bitisSaat;

    if (tarih.weekday == DateTime.saturday) {
      baslangicDakika = 14 * 60 + 30; // 14:30
      bitisSaat = 19; // 19:00
    } else {
      baslangicDakika = 16 * 60 + 30; // 16:30
      bitisSaat = 20; // 20:00
    }

    int simdikidakika = baslangicDakika;
    while (simdikidakika < bitisSaat * 60) {
      int saat = simdikidakika ~/ 60;
      int dakika = simdikidakika % 60;
      String slot =
          "${saat.toString().padLeft(2, '0')}:${dakika.toString().padLeft(2, '0')}";
      saatler.add(slot);
      simdikidakika += 30;
    }
    return saatler;
  }

  // Tekil slot kilitleme / açma
  Future<void> _slotuKilitleVeyaAc(
    DateTime secilenTarih,
    String saat,
    bool mevcutKilitDurumu,
  ) async {
    String tarihKey = DateFormat('yyyy-MM-dd').format(secilenTarih);
    DocumentReference takvimRef = FirebaseFirestore.instance
        .collection('randevu_takvimi')
        .doc(tarihKey);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(takvimRef);

      Map<String, dynamic> slotlar = {};
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['slotlar'] != null) {
          slotlar = Map<String, dynamic>.from(data['slotlar']);
        }
      }

      Map<String, dynamic> slotDetay = slotlar[saat] != null
          ? Map<String, dynamic>.from(slotlar[saat])
          : {'dolu': false, 'kilitli': false};

      slotDetay['kilitli'] = !mevcutKilitDurumu;
      slotlar[saat] = slotDetay;

      transaction.set(takvimRef, {
        'tarih': tarihKey,
        'slotlar': slotlar,
      }, SetOptions(merge: true));
    });
  }

  // Tüm günü toplu kilitleme veya açma fonksiyonu
  Future<void> _tumGunuKilitleVeyaAc(List<String> musaitSaatler) async {
    if (musaitSaatler.isEmpty) return;

    String tarihKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
    DocumentReference takvimRef = FirebaseFirestore.instance
        .collection('randevu_takvimi')
        .doc(tarihKey);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(takvimRef);

      Map<String, dynamic> slotlar = {};
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['slotlar'] != null) {
          slotlar = Map<String, dynamic>.from(data['slotlar']);
        }
      }

      // O güne ait tüm müsait saatlerin kilitli olup olmadığını kontrol et (Hepsi kilitli mi?)
      bool hepsiKilitliMi = true;
      for (var saat in musaitSaatler) {
        var detay = slotlar[saat];
        if (detay == null || detay['kilitli'] != true) {
          hepsiKilitliMi = false;
          break;
        }
      }

      // Eğer hepsi kilitliyse hepsini aç, değilse tüm boş slotları kilitle
      bool yeniDurum = !hepsiKilitliMi;

      for (var saat in musaitSaatler) {
        Map<String, dynamic> slotDetay = slotlar[saat] != null
            ? Map<String, dynamic>.from(slotlar[saat])
            : {'dolu': false, 'kilitli': false};

        // Dolu olan randevuları etkilememe kuralı (Sadece boş veya kilitli olanlar)
        if (slotDetay['dolu'] != true) {
          slotDetay['kilitli'] = yeniDurum;
          slotlar[saat] = slotDetay;
        }
      }

      transaction.set(takvimRef, {
        'tarih': tarihKey,
        'slotlar': slotlar,
      }, SetOptions(merge: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> musaitSaatler = _gununSaatleriniUret(_selectedDay);
    String tarihKey = DateFormat('yyyy-MM-dd').format(_selectedDay);

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 60)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.twoWeeks,
          locale: 'tr_TR',
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.indigoAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Divider(thickness: 2),

        // Başlık ve Tüm Günü Kilitle/Aç Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              if (_selectedDay.weekday != DateTime.sunday)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 32),
                  ),
                  onPressed: () => _tumGunuKilitleVeyaAc(musaitSaatler),
                  icon: const Icon(Icons.lock_clock, size: 16),
                  label: const Text(
                    "Tüm Günü Kilitle / Aç",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: _selectedDay.weekday == DateTime.sunday
              ? const Center(
                  child: Text(
                    "Pazar günleri kapalıdır.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('randevu_takvimi')
                      .doc(tarihKey)
                      .snapshots(),
                  builder: (context, snapshot) {
                    Map<String, dynamic> gunlukVeri = {};
                    if (snapshot.hasData && snapshot.data!.exists) {
                      gunlukVeri =
                          snapshot.data!.data() as Map<String, dynamic>;
                    }
                    Map<String, dynamic> slotlar = gunlukVeri['slotlar'] ?? {};

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: musaitSaatler.length,
                      itemBuilder: (context, index) {
                        String saat = musaitSaatler[index];
                        Map<String, dynamic>? slotDetay = slotlar[saat];

                        bool doluMu =
                            slotDetay != null && slotDetay['dolu'] == true;
                        bool kilitliMi =
                            slotDetay != null && slotDetay['kilitli'] == true;
                        String? ogrenciAdi = slotDetay != null
                            ? slotDetay['ogrenciAdi']
                            : null;

                        Color renk = Colors.green;
                        String metin = saat;

                        if (doluMu) {
                          renk = Colors.red;
                          metin = "$saat\n${ogrenciAdi ?? 'Dolu'}";
                        } else if (kilitliMi) {
                          renk = Colors.grey;
                          metin = "$saat\n(Kilitli)";
                        }

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: renk,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: doluMu
                              ? null
                              : () => _slotuKilitleVeyaAc(
                                  _selectedDay,
                                  saat,
                                  kilitliMi,
                                ),
                          child: Text(
                            metin,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. SEKME: ALINMIŞ RANDEVULAR LİSTESİ
// ==========================================
// ==========================================
// 2. SEKME: ALINMIŞ RANDEVULAR LİSTESİ
// ==========================================
class RandevularListesiTab extends StatelessWidget {
  final String classId;
  const RandevularListesiTab({super.key, required this.classId});

  Future<void> _randevuyuSil(
    BuildContext context,
    String docId,
    String tarih,
    String saat,
  ) async {
    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Randevuyu Sil"),
        content: Text(
          "$tarih - $saat saatindeki randevuyu silmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (onay != true) return;

    await FirebaseFirestore.instance
        .collection('randevular')
        .doc(docId)
        .delete();

    DocumentReference takvimRef = FirebaseFirestore.instance
        .collection('randevu_takvimi')
        .doc(tarih);
    var docSnap = await takvimRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      var data = docSnap.data() as Map<String, dynamic>;
      if (data['slotlar'] != null) {
        Map<String, dynamic> slotlar = Map<String, dynamic>.from(
          data['slotlar'],
        );
        if (slotlar[saat] != null) {
          slotlar[saat] = {'dolu': false, 'kilitli': false};
          await takvimRef.update({'slotlar': slotlar});
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Randevu başarıyla silindi ve saat boşa çıkarıldı."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('randevular')
          .where('classId', isEqualTo: classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Bu sınıfa ait aktif randevu bulunmuyor.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        var randevuDocs = snapshot.data!.docs;

        randevuDocs.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          String tarihA = dataA['tarih'] ?? '';
          String tarihB = dataB['tarih'] ?? '';
          int tarihKarsilastirma = tarihA.compareTo(tarihB);
          if (tarihKarsilastirma != 0) return tarihKarsilastirma;

          String saatA = dataA['saat'] ?? '';
          String saatB = dataB['saat'] ?? '';
          return saatA.compareTo(saatB);
        });

        return ListView.builder(
          itemCount: randevuDocs.length,
          itemBuilder: (context, index) {
            var docId = randevuDocs[index].id;
            var veri = randevuDocs[index].data() as Map<String, dynamic>;
            String ogrenciAdi = veri['ogrenciAdi'] ?? 'İsimsiz Öğrenci';
            String tarih = veri['tarih'] ?? '';
            String saat = veri['saat'] ?? '';
            String durum = veri['durum'] ?? 'aktif';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                // Başlık kısmına doğrudan öğrenci adını yerleştirdik
                title: Text(
                  ogrenciAdi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Alt satırda tarih ve saat bilgisi
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Tarih: $tarih | Saat: $saat",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        durum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: durum == 'aktif'
                          ? Colors.green
                          : Colors.grey,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _randevuyuSil(context, docId, tarih, saat),
                      tooltip: "Randevuyu Sil",
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. SEKME: TÜRKÇE ALFABETİK ÖĞRENCİ LİSTESİ
// ==========================================
class OgrenciListesiTab extends StatelessWidget {
  final String classId;
  const OgrenciListesiTab({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    int turkishCompare(String a, String b) {
      const trAlphabet = 'aâbcçdefgğhıijklmnoöprsştuüvyz';
      String strA = a.toLowerCase().replaceAll('İ', 'i').replaceAll('I', 'ı');
      String strB = b.toLowerCase().replaceAll('İ', 'i').replaceAll('I', 'ı');

      for (int i = 0; i < strA.length && i < strB.length; i++) {
        int indexA = trAlphabet.indexOf(strA[i]);
        int indexB = trAlphabet.indexOf(strB[i]);

        if (indexA != indexB) {
          if (indexA == -1) return 1;
          if (indexB == -1) return -1;
          return indexA.compareTo(indexB);
        }
      }
      return strA.compareTo(strB);
    }

    return StreamBuilder<QuerySnapshot>(
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
            child: Text(
              "Bu sınıfta kayıtlı öğrenci bulunamadı.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        var ogrenciDocs = snapshot.data!.docs;

        ogrenciDocs.sort((x, y) {
          var dataA = x.data() as Map<String, dynamic>;
          var dataB = y.data() as Map<String, dynamic>;
          String adA = "${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}"
              .trim();
          String adB = "${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}"
              .trim();
          return turkishCompare(adA, adB);
        });

        return ListView.builder(
          itemCount: ogrenciDocs.length,
          itemBuilder: (context, index) {
            var ogrenciData = ogrenciDocs[index].data() as Map<String, dynamic>;
            String ogrenciId = ogrenciDocs[index].id;

            String firstName = ogrenciData['firstName'] ?? '';
            String lastName = ogrenciData['lastName'] ?? '';
            String adSoyad = "$firstName $lastName".trim();
            if (adSoyad.isEmpty) adSoyad = "İsimsiz Öğrenci";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.school, color: Colors.white),
                ),
                title: Text(
                  adSoyad,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OgrenciGecmisRandevulariScreen(
                        studentId: ogrenciId,
                        ogrenciAdSoyad: adSoyad,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// ÖĞRENCİ GEÇMİŞ GÖRÜŞMELERİ DETAY EKRANI
// ==========================================
class OgrenciGecmisRandevulariScreen extends StatelessWidget {
  final String studentId;
  final String ogrenciAdSoyad;

  const OgrenciGecmisRandevulariScreen({
    super.key,
    required this.studentId,
    required this.ogrenciAdSoyad,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$ogrenciAdSoyad - Geçmiş Görüşmeler"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('randevular')
            .where('ogrenciId', isEqualTo: studentId)
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Bu öğrenci ile yapılmış geçmiş görüşme bulunmuyor.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var gecmisDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: gecmisDocs.length,
            itemBuilder: (context, index) {
              var veri = gecmisDocs[index].data() as Map<String, dynamic>;
              String tarih = veri['tarih'] ?? '';
              String saat = veri['saat'] ?? '';
              String durum = veri['durum'] ?? 'aktif';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.event_available,
                    color: Colors.indigo,
                  ),
                  title: Text(
                    "Tarih: $tarih - Saat: $saat",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Durum: $durum"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
