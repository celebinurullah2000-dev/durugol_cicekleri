// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VeliRandevuScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classId;

  const VeliRandevuScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.classId,
  });

  @override
  State<VeliRandevuScreen> createState() => _VeliRandevuScreenState();
}

class _VeliRandevuScreenState extends State<VeliRandevuScreen>
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
        title: Text("Randevu İşlemleri - ${widget.studentName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: "Randevu Al"),
            Tab(icon: Icon(Icons.event_available), text: "Aktif Randevularım"),
            Tab(icon: Icon(Icons.history), text: "Geçmiş Randevularım"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SEKME: Randevu Al (Mevcut Ekran)
          RandevuAlTab(
            studentId: widget.studentId,
            studentName: widget.studentName,
            classId: widget.classId,
          ),

          // 2. SEKME: Aktif Randevularım
          AktifRandevularimTab(studentId: widget.studentId),

          // 3. SEKME: Geçmiş Randevularım
          GecmisRandevularimTab(studentId: widget.studentId),
        ],
      ),
    );
  }
}

// ==========================================
// 1. SEKME: RANDEVU AL
// ==========================================
class RandevuAlTab extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String classId;

  const RandevuAlTab({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.classId,
  });

  @override
  State<RandevuAlTab> createState() => _RandevuAlTabState();
}

class _RandevuAlTabState extends State<RandevuAlTab> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = false;

  List<String> _gununSaatAraliklariniGetir(DateTime tarih) {
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

  // --- BURAYA: Öğretmene bildirim fırlatan fonksiyonu ekliyoruz ---
  Future<void> _ogretmeneBildirimGonder(String tarih, String saat) async {
    try {
      // 1. Öğretmenin FCM token'ını Firestore'daki 'teacher_tokens' koleksiyonundan alıyoruz
      var doc = await FirebaseFirestore.instance
          .collection('teacher_tokens')
          .doc(widget.classId)
          .get();

      if (!doc.exists) return;

      String? teacherToken = doc.data()?['token'];
      if (teacherToken == null || teacherToken.isEmpty) return;

      // Not: Firebase Server Key değerini Firebase Console > Project Settings > Cloud Messaging sekmesinden alıp buraya yazmalısın.
      const String serverKey = 'SENIN_FIREBASE_SERVER_KEY_DEGERI';

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'title': 'Yeni Randevu Alındı! 📌',
            'body':
                '${widget.studentName}, $tarih tarihi saat $saat için randevu aldı.',
          },
          'priority': 'high',
          'to': teacherToken,
        }),
      );
    } catch (e) {
      debugPrint("Bildirim gönderme hatası: $e");
    }
  }

  Future<void> _randevuAl(
    String saat,
    Map<String, dynamic> mevcutSlotlar,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Randevu Onayı"),
        content: Text(
          "${DateFormat('dd.MM.yyyy').format(_selectedDay)} tarihi saat $saat için randevu oluşturulsun mu?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              String tarihKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
              DocumentReference takvimRef = FirebaseFirestore.instance
                  .collection('randevu_takvimi')
                  .doc(tarihKey);

              Map<String, dynamic> slotlar = Map.from(mevcutSlotlar);
              String gonderilecekAd = widget.studentName.isNotEmpty
                  ? widget.studentName
                  : "İsimsiz Öğrenci";

              slotlar[saat] = {
                'dolu': true,
                'kilitli': false,
                'ogrenciId': widget.studentId,
                'ogrenciAdi': gonderilecekAd,
              };

              await takvimRef.set({
                'tarih': tarihKey,
                'slotlar': slotlar,
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance.collection('randevular').add({
                'ogrenciId': widget.studentId,
                'ogrenciAdi': gonderilecekAd,
                'classId': widget.classId,
                'tarih': tarihKey,
                'saat': saat,
                'durum': 'aktif',
                'olusturulmaTarihi': FieldValue.serverTimestamp(),
              });

              await _ogretmeneBildirimGonder(tarihKey, saat);

              if (!mounted) return;
              setState(() => _isLoading = false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Randevunuz başarıyla oluşturuldu!"),
                ),
              );
            },
            child: const Text("Onayla"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> musaitSaatler = _gununSaatAraliklariniGetir(_selectedDay);
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
            if (selectedDay.weekday == DateTime.sunday) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pazar günleri randevu kapalıdır."),
                ),
              );
              return;
            }
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay)} Tarihine Ait Saatler",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
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
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    Map<String, dynamic> gunlukVeri = {};
                    if (snapshot.hasData && snapshot.data!.exists) {
                      gunlukVeri =
                          snapshot.data!.data() as Map<String, dynamic>;
                    }

                    Map<String, dynamic> slotlar = gunlukVeri['slotlar'] ?? {};

                    if (musaitSaatler.isEmpty) {
                      return const Center(
                        child: Text(
                          "Bu gün için uygun saat bulunmuyor.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
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
                        String? alanOgrenciId = slotDetay != null
                            ? slotDetay['ogrenciId']
                            : null;
                        bool benimRandevumMu =
                            alanOgrenciId == widget.studentId;

                        Color renk = Colors.green;
                        String durumMetni = saat;

                        if (benimRandevumMu) {
                          renk = Colors.blue;
                          durumMetni = "$saat\n(Randevunuz)";
                        } else if (doluMu) {
                          renk = Colors.red;
                          durumMetni = "$saat\n(Dolu)";
                        } else if (kilitliMi) {
                          renk = Colors.grey;
                          durumMetni = "$saat\n(Kapalı)";
                        } else {
                          durumMetni = "$saat\n(Müsait)";
                        }

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: renk,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: (doluMu || kilitliMi)
                              ? null
                              : () => _randevuAl(saat, slotlar),
                          child: Text(
                            durumMetni,
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
// 2. SEKME: AKTİF RANDEVULARIM
// ==========================================
class AktifRandevularimTab extends StatelessWidget {
  final String studentId;
  const AktifRandevularimTab({super.key, required this.studentId});

  // Öğrencinin randevuyu iptal etme fonksiyonu
  Future<void> _randevuyuIptalEt(
    BuildContext context,
    String docId,
    String tarih,
    String saat,
  ) async {
    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Randevuyu İptal Et"),
        content: Text(
          "$tarih - $saat saatindeki randevunuzu iptal etmek istediğinize emin misiniz?",
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
            child: const Text("İptal Et"),
          ),
        ],
      ),
    );

    if (onay != true) return;

    // 1. 'randevular' koleksiyonundaki kaydı sil
    await FirebaseFirestore.instance
        .collection('randevular')
        .doc(docId)
        .delete();

    // 2. 'randevu_takvimi' içerisindeki ilgili saat slotunu tekrar boş hale getir
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
        const SnackBar(content: Text("Randevunuz başarıyla iptal edildi.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String bugunStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('randevular')
          .where('ogrenciId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Aktif randevunuz bulunmuyor.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        var randevular = snapshot.data!.docs.where((doc) {
          var veri = doc.data() as Map<String, dynamic>;
          String durum = veri['durum'] ?? 'aktif';
          String tarih = veri['tarih'] ?? '';
          return durum == 'aktif' && tarih.compareTo(bugunStr) >= 0;
        }).toList();

        randevular.sort((a, b) {
          var dataA = a.data() as Map<String, dynamic>;
          var dataB = b.data() as Map<String, dynamic>;
          String tarihA = dataA['tarih'] ?? '';
          String tarihB = dataB['tarih'] ?? '';
          int karsilastirma = tarihA.compareTo(tarihB);
          if (karsilastirma != 0) return karsilastirma;
          String saatA = dataA['saat'] ?? '';
          String saatB = dataB['saat'] ?? '';
          return saatA.compareTo(saatB);
        });

        if (randevular.isEmpty) {
          return const Center(
            child: Text(
              "Aktif randevunuz bulunmuyor.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: randevular.length,
          itemBuilder: (context, index) {
            var docId = randevular[index].id;
            var veri = randevular[index].data() as Map<String, dynamic>;
            String tarih = veri['tarih'] ?? '';
            String saat = veri['saat'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.event_available, color: Colors.white),
                ),
                title: Text(
                  "Tarih: $tarih",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Saat: $saat"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Chip(
                      label: Text(
                        "Aktif",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _randevuyuIptalEt(context, docId, tarih, saat),
                      tooltip: "Randevuyu İptal Et",
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
// 3. SEKME: GEÇMİŞ RANDEVULARIM
// ==========================================
class GecmisRandevularimTab extends StatelessWidget {
  final String studentId;
  const GecmisRandevularimTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    String bugunStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('randevular')
          .where('ogrenciId', isEqualTo: studentId)
          .where('tarih', isLessThan: bugunStr)
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Geçmiş randevunuz bulunmuyor.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        var gecmisRandevular = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: gecmisRandevular.length,
          itemBuilder: (context, index) {
            var veri = gecmisRandevular[index].data() as Map<String, dynamic>;
            String tarih = veri['tarih'] ?? '';
            String saat = veri['saat'] ?? '';
            String durum = veri['durum'] ?? 'tamamlandı';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.history, color: Colors.white),
                ),
                title: Text(
                  "Tarih: $tarih",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Saat: $saat"),
                trailing: Chip(
                  label: Text(
                    durum,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
