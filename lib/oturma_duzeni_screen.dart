// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManuelOturmaScreen extends StatefulWidget {
  final String classId;

  const ManuelOturmaScreen({super.key, required this.classId});

  @override
  State<ManuelOturmaScreen> createState() => _ManuelOturmaScreenState();
}

class _ManuelOturmaScreenState extends State<ManuelOturmaScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];

  // Oluşturulan manuel sıralar listesi: [ {'ogrenci1': {...}, 'ogrenci2': {...}}, ... ]
  final List<Map<String, dynamic>> _manuelSiralar = [];

  @override
  void initState() {
    super.initState();
    _ogrencileriGetir();
  }

  Future<void> _ogrencileriGetir() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: widget.classId)
          .get();

      var docs = snapshot.docs;
      if (docs.isEmpty) {
        var all = await FirebaseFirestore.instance.collection('students').get();
        // DÜZELTME: snapshot.docs yerine all.docs üzerinden filtreleme yapıyoruz
        docs = all.docs
            .where(
              (d) =>
                  d.data()['classId'] == widget.classId ||
                  d.data()['sinifId'] == widget.classId,
            )
            .toList();
      }

      setState(() {
        _allStudents = docs.map((doc) {
          var data = doc.data();
          String f = data['firstName'] ?? '';
          String l = data['lastName'] ?? '';
          return {
            'id': doc.id,
            'adSoyad': "$f $l".trim().isEmpty ? 'İsimsiz' : "$f $l".trim(),
            'gender': data['gender'] ?? data['cinsiyet'] ?? 'K',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Öğrenci çekme hatası: $e");
      setState(() => _isLoading = false);
    }
  }

  // Öğrenci Seçim Diyaloğu
  void _siraEkleDialog() {
    Map<String, dynamic>? secilen1;
    Map<String, dynamic>? secilen2;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Yeni Sıra / Çift Ekle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Öğrenci Seçimi
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: "1. Öğrenci"),
                    items: _allStudents.map((ogrenci) {
                      return DropdownMenuItem(
                        value: ogrenci,
                        child: Text(
                          "${ogrenci['adSoyad']} (${ogrenci['gender']})",
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => secilen1 = val),
                  ),
                  const SizedBox(height: 16),
                  // 2. Öğrenci Seçimi
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      labelText: "2. Öğrenci (Opsiyonel)",
                    ),
                    items: _allStudents.map((ogrenci) {
                      return DropdownMenuItem(
                        value: ogrenci,
                        child: Text(
                          "${ogrenci['adSoyad']} (${ogrenci['gender']})",
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => secilen2 = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (secilen1 == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("En az 1. öğrenciyi seçmelisiniz!"),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _manuelSiralar.add({
                        'ogrenci1': secilen1,
                        'ogrenci2': secilen2, // null olabilir (tekli oturma)
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Listeye Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Firestore'a Kaydetme Fonksiyonu
  Future<void> _kaydetVeUygula() async {
    if (_manuelSiralar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kaydedilecek sıra bulunmuyor!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var batch = FirebaseFirestore.instance.batch();
      var oturmaRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('oturma_duzeni');

      // Eski düzeni temizle
      var eskiDuzen = await oturmaRef.get();
      for (var doc in eskiDuzen.docs) {
        batch.delete(doc.reference);
      }

      // Yeni manuel düzeni yaz
      for (int i = 0; i < _manuelSiralar.length; i++) {
        var sira = _manuelSiralar[i];
        var yeniSiraRef = oturmaRef.doc('sira_${i + 1}');
        batch.set(yeniSiraRef, {
          'siraNo': i + 1,
          'ogrenci1Id': sira['ogrenci1']?['id'],
          'ogrenci1Ad': sira['ogrenci1']?['adSoyad'],
          'ogrenci2Id': sira['ogrenci2']?['id'],
          'ogrenci2Ad': sira['ogrenci2']?['adSoyad'],
        });
      }

      // Geçmiş oturmalara da işleyelim ki otomatik algoritma gelecekte dikkate alsın
      var gecmisRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('gecmis_oturmalar');

      for (var sira in _manuelSiralar) {
        var o1 = sira['ogrenci1'];
        var o2 = sira['ogrenci2'];
        if (o1 != null && o2 != null) {
          String id1 = o1['id'];
          String id2 = o2['id'];
          batch.set(gecmisRef.doc("${id1}_$id2"), {
            'ogrenci1Id': id1,
            'ogrenci2Id': id2,
            'tarih': FieldValue.serverTimestamp(),
          });
          batch.set(gecmisRef.doc("${id2}_$id1"), {
            'ogrenci1Id': id2,
            'ogrenci2Id': id1,
            'tarih': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Manuel oturma düzeni başarıyla kaydedildi!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Kayıt hatası: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manuel Oturma Planı Oluştur"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Düzeni Kaydet",
            onPressed: _kaydetVeUygula,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _siraEkleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Yeni Sıra / Çift Ekle"),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _manuelSiralar.isEmpty
                        ? const Center(
                            child: Text(
                              "Henüz sıra eklenmedi. Yukarıdan çift ekleyin.",
                            ),
                          )
                        : ListView.builder(
                            itemCount: _manuelSiralar.length,
                            itemBuilder: (context, index) {
                              var sira = _manuelSiralar[index];
                              String ad1 =
                                  sira['ogrenci1']?['adSoyad'] ?? 'Boş';
                              String ad2 =
                                  sira['ogrenci2']?['adSoyad'] ?? 'Boş';

                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text("Sıra ${index + 1}"),
                                  subtitle: Text("$ad1  -  $ad2"),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _manuelSiralar.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class OturmaDuzeniScreen extends StatefulWidget {
  final String classId;
  final bool isTeacher;

  const OturmaDuzeniScreen({
    super.key,
    required this.classId,
    required this.isTeacher,
  });

  @override
  State<OturmaDuzeniScreen> createState() => _OturmaDuzeniScreenState();
}

class _OturmaDuzeniScreenState extends State<OturmaDuzeniScreen> {
  bool _isLoading = false;

  // Akıllı Yerleştirme Algoritması
  // Otomatik Yerleştirme Butonuna Basıldığında Çağrılacak Fonksiyon
  void _otomatikYerlestirTiklandi() {
    bool gecmisleriDikkateAl = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Otomatik Yerleştirme Seçenekleri"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sınıf oturma düzeni otomatik olarak oluşturulacak. Nasıl ilerlemek istersiniz?",
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Geçmiş Eşleşmeleri Dikkate Al"),
                    subtitle: const Text(
                      "Daha önce birlikte oturanlar tekrar yan yana gelmez.",
                    ),
                    value: gecmisleriDikkateAl,
                    onChanged: (val) {
                      setDialogState(() {
                        gecmisleriDikkateAl = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _otomatikYerlestir(gecmisleriDikkateAl);
                  },
                  child: const Text("Başlat"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Asıl Algoritma Fonksiyonu (Parametre alacak şekilde güncellendi)
  Future<void> _otomatikYerlestir(bool gecmisleriKoru) async {
    setState(() => _isLoading = true);

    try {
      // 1. Öğrencileri çek
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      List<Map<String, dynamic>> ogrenciler = [];
      for (var doc in studentSnapshot.docs) {
        var data = doc.data();
        String? cId = data['classId'] ?? data['sinifId'];
        if (cId == widget.classId) {
          String f = data['firstName'] ?? '';
          String l = data['lastName'] ?? '';
          ogrenciler.add({
            'id': doc.id,
            'adSoyad': "$f $l".trim().isEmpty ? 'İsimsiz' : "$f $l".trim(),
            'gender': (data['gender'] ?? data['cinsiyet'] ?? 'K')
                .toString()
                .toUpperCase(),
          });
        }
      }

      if (ogrenciler.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Otomatik yerleştirme için en az 2 öğrenci gereklidir!",
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Eğer geçmiş korunacaksa, geçmiş eşleşmeleri Firestore'dan çekelim
      Set<String> yasakliCiftler = {};
      if (gecmisleriKoru) {
        var gecmisSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('gecmis_oturmalar')
            .get();

        for (var doc in gecmisSnapshot.docs) {
          var d = doc.data();
          String? id1 = d['ogrenci1Id'];
          String? id2 = d['ogrenci2Id'];
          if (id1 != null && id2 != null) {
            yasakliCiftler.add("${id1}_$id2");
          }
        }
      }

      // 3. Basit ve adil bir karıştırma/eşleştirme mantığı
      ogrenciler.shuffle(); // Rastgele karıştır

      // Kız ve Erkek olarak ayıralım (1 kız / 1 erkek dengesi için)
      List<Map<String, dynamic>> kizlar = ogrenciler
          .where((o) => o['gender'] == 'K' || o['gender'] == 'KIZ')
          .toList();
      List<Map<String, dynamic>> erkekler = ogrenciler
          .where((o) => o['gender'] == 'E' || o['gender'] == 'ERKEK')
          .toList();

      kizlar.shuffle();
      erkekler.shuffle();

      List<Map<String, dynamic>> olusturulanSiralar = [];
      List<Map<String, dynamic>> havuz = List.from(ogrenciler);

      int siraNo = 1;
      while (havuz.length >= 2) {
        Map<String, dynamic>? ogrenci1 = havuz.removeAt(0);
        Map<String, dynamic>? ogrenci2;

        // Uygun eş arama (Geçmişte oturmamış olanlardan)
        int uygunIndex = -1;
        for (int i = 0; i < havuz.length; i++) {
          String adayId = havuz[i]['id'];
          String ciftKey = "${ogrenci1['id']}_$adayId";

          if (!gecmisleriKoru || !yasakliCiftler.contains(ciftKey)) {
            uygunIndex = i;
            break;
          }
        }

        // Eğer tüm adaylar geçmişte birlikte oturmuşsa, mecburen listedekilerden ilkini al
        if (uygunIndex != -1) {
          ogrenci2 = havuz.removeAt(uygunIndex);
        } else {
          ogrenci2 = havuz.removeAt(0);
        }

        olusturulanSiralar.add({
          'siraNo': siraNo++,
          'ogrenci1Id': ogrenci1['id'],
          'ogrenci1Ad': ogrenci1['adSoyad'],
          'ogrenci2Id': ogrenci2['id'],
          'ogrenci2Ad': ogrenci2['adSoyad'],
        });
      }

      // Tek kalan öğrenci varsa son sıraya tekli olarak ekle
      if (havuz.isNotEmpty) {
        var tekOgrenci = havuz.removeAt(0);
        olusturulanSiralar.add({
          'siraNo': siraNo++,
          'ogrenci1Id': tekOgrenci['id'],
          'ogrenci1Ad': tekOgrenci['adSoyad'],
          'ogrenci2Id': null,
          'ogrenci2Ad': null,
        });
      }

      // 4. Firestore'a yeni düzeni kaydet ve geçmişe yeni eşleşmeleri işle
      var batch = FirebaseFirestore.instance.batch();
      var oturmaRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('oturma_duzeni');

      // Eski düzeni sil
      var eskiDuzen = await oturmaRef.get();
      for (var doc in eskiDuzen.docs) {
        batch.delete(doc.reference);
      }

      // Yeni düzeni yaz
      var gecmisRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('gecmis_oturmalar');

      for (var sira in olusturulanSiralar) {
        var docRef = oturmaRef.doc('sira_${sira['siraNo']}');
        batch.set(docRef, sira);

        String? id1 = sira['ogrenci1Id'];
        String? id2 = sira['ogrenci2Id'];

        if (id1 != null && id2 != null) {
          batch.set(gecmisRef.doc("${id1}_$id2"), {
            'ogrenci1Id': id1,
            'ogrenci2Id': id2,
            'tarih': FieldValue.serverTimestamp(),
          });
          batch.set(gecmisRef.doc("${id2}_$id1"), {
            'ogrenci1Id': id2,
            'ogrenci2Id': id1,
            'tarih': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Otomatik oturma düzeni başarıyla oluşturuldu!"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Otomatik yerleştirme hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /*Future<void> _matrisGecmisleriniAktar() async {
    setState(() => _isLoading = true);

    // Görseldeki matristen çıkarılan ikili öğrenci adları listesi
    List<List<String>> isimCiftleri = [
      ["ALİ HARUN ÜNSAL", "ALYA AYDIN"],
      ["ALİ HARUN ÜNSAL", "AYŞE ELA ŞEN"],
      ["ALİ HARUN ÜNSAL", "İPEK ÖZTOPRAK"],
      ["ALİ HARUN ÜNSAL", "ÖMER ASAF YAVUZARSLAN"],
      ["ALİ HARUN ÜNSAL", "ÖMER DENİZ KEÇECİ"],
      ["ALİ HARUN ÜNSAL", "URAS SOĞUKSU"],
      ["ALİ HARUN ÜNSAL", "YAMAÇ ARSLAN"],
      ["ALİ HARUN ÜNSAL", "YUSUF YİĞİT AKSOY"],
      ["ALYA AYDIN", "ARDEN ODABAŞI"],
      ["ALYA AYDIN", "ASYA PATKAVAK"],
      ["ALYA AYDIN", "CAN SAMSUNLU"],
      ["ALYA AYDIN", "CANKAT İLKUTLU"],
      ["ALYA AYDIN", "ÇINAR ALP GÖZÜTOK"],
      ["ALYA AYDIN", "DENİZ NİSA ARSLAN"],
      ["ALYA AYDIN", "GİZEM AKÇAY"],
      ["ALYA AYDIN", "GÖRKEM TUNA BALCI"],
      ["ALYA AYDIN", "LİNA TİRYAKİ"],
      ["ALYA AYDIN", "ÖMER DENİZ KEÇECİ"],
      ["ALYA AYDIN", "YAMAÇ ARSLAN"],
      ["ARDEN ODABAŞI", "ASEL BEREN YONDEMİR"],
      ["ARDEN ODABAŞI", "ÇINAR ALP GÖZÜTOK"],
      ["ARDEN ODABAŞI", "DENİZ NİSA ARSLAN"],
      ["ARDEN ODABAŞI", "GÖRKEM TUNA BALCI"],
      ["ARDEN ODABAŞI", "ÖMER DENİZ KEÇECİ"],
      ["ARDEN ODABAŞI", "RÜZGAR GÜZELSU"],
      ["ASEL BEREN YONDEMİR", "ASYA PATKAVAK"],
      ["ASEL BEREN YONDEMİR", "ELİSA DURU ŞAHİN"],
      ["ASEL BEREN YONDEMİR", "GÖRKEM TUNA BALCI"],
      ["ASEL BEREN YONDEMİR", "HAZAL DENİZ ÖZCAN"],
      ["ASEL BEREN YONDEMİR", "İPEK ÖZTOPRAK"],
      ["ASEL BEREN YONDEMİR", "ÖMER ASAF YAVUZARSLAN"],
      ["ASEL BEREN YONDEMİR", "ÖMER DENİZ KEÇECİ"],
      ["ASYA PATKAVAK", "AYŞE ELA ŞEN"],
      ["ASYA PATKAVAK", "CAN SAMSUNLU"],
      ["ASYA PATKAVAK", "ESLEM SARE AKSU"],
      ["ASYA PATKAVAK", "GÖRKEM TUNA BALCI"],
      ["ASYA PATKAVAK", "GÜNEŞ KÜÇÜK"],
      ["ASYA PATKAVAK", "ÖMER DENİZ KEÇECİ"],
      ["ASYA PATKAVAK", "YUDUM ODABAŞ"],
      ["AYŞE ELA ŞEN", "CAN SAMSUNLU"],
      ["AYŞE ELA ŞEN", "CANKAT İLKUTLU"],
      ["AYŞE ELA ŞEN", "HAZAL DENİZ ÖZCAN"],
      ["AYŞE ELA ŞEN", "KUMSAL NAZ ÖNCÜ"],
      ["AYŞE ELA ŞEN", "UMUT ALP YAZIM"],
      ["AYŞE ELA ŞEN", "YİĞİT ARSLAN"],
      ["CAN SAMSUNLU", "CANKAT İLKUTLU"],
      ["CAN SAMSUNLU", "ÇINAR ALP GÖZÜTOK"],
      ["CAN SAMSUNLU", "ÖMER ASAF YAVUZARSLAN"],
      ["CAN SAMSUNLU", "ÖMER DENİZ KEÇECİ"],
      ["CAN SAMSUNLU", "YUSUF ASAF BAYRAMLI"],
      ["CAN SAMSUNLU", "YUSUF YİĞİT AKSOY"],
      ["CANKAT İLKUTLU", "ÇINAR ALP GÖZÜTOK"],
      ["CANKAT İLKUTLU", "ÖMER ASAF YAVUZARSLAN"],
      ["CANKAT İLKUTLU", "UMUT ALP YAZIM"],
      ["CANKAT İLKUTLU", "YİĞİT ARSLAN"],
      ["ÇINAR ALP GÖZÜTOK", "DENİZ NİSA ARSLAN"],
      ["ÇINAR ALP GÖZÜTOK", "ELİSA DURU ŞAHİN"],
      ["ÇINAR ALP GÖZÜTOK", "GİZEM AKÇAY"],
      ["ÇINAR ALP GÖZÜTOK", "HAZAL DENİZ ÖZCAN"],
      ["ÇINAR ALP GÖZÜTOK", "URAS SOĞUKSU"],
      ["DENİZ NİSA ARSLAN", "ELİSA DURU ŞAHİN"],
      ["DENİZ NİSA ARSLAN", "GÖRKEM TUNA BALCI"],
      ["DENİZ NİSA ARSLAN", "GÜLÇE YAĞIZOĞLU"],
      ["DENİZ NİSA ARSLAN", "KUMSAL NAZ ÖNCÜ"],
      ["DENİZ NİSA ARSLAN", "LİNA TİRYAKİ"],
      ["DENİZ NİSA ARSLAN", "ÖMER ASAF YAVUZARSLAN"],
      ["DENİZ NİSA ARSLAN", "URAS SOĞUKSU"],
      ["ELİSA DURU ŞAHİN", "ELİSA SARE YILDIRIM"],
      ["ELİSA DURU ŞAHİN", "GÖRKEM TUNA BALCI"],
      ["ELİSA DURU ŞAHİN", "İPEK ÖZTOPRAK"],
      ["ELİSA SARE YILDIRIM", "ESLEM SARE AKSU"],
      ["ELİSA SARE YILDIRIM", "GÖRKEM TUNA BALCI"],
      ["ELİSA SARE YILDIRIM", "GÜLÇE YAĞIZOĞLU"],
      ["ELİSA SARE YILDIRIM", "UMUT ALP YAZIM"],
      ["ELİSA SARE YILDIRIM", "YİĞİT ARSLAN"],
      ["ESLEM SARE AKSU", "GÜLÇE YAĞIZOĞLU"],
      ["ESLEM SARE AKSU", "ÖMER ASAF YAVUZARSLAN"],
      ["ESLEM SARE AKSU", "ÖMER DENİZ KEÇECİ"],
      ["ESLEM SARE AKSU", "URAS SOĞUKSU"],
      ["ESLEM SARE AKSU", "YAMAÇ ARSLAN"],
      ["GİZEM AKÇAY", "GÖRKEM TUNA BALCI"],
      ["GİZEM AKÇAY", "HAZAL DENİZ ÖZCAN"],
      ["GİZEM AKÇAY", "KUMSAL NAZ ÖNCÜ"],
      ["GİZEM AKÇAY", "ÖMER ASAF YAVUZARSLAN"],
      ["GİZEM AKÇAY", "ÖMER DENİZ KEÇECİ"],
      ["GİZEM AKÇAY", "URAS SOĞUKSU"],
      ["GÖRKEM TUNA BALCI", "GÜLÇE YAĞIZOĞLU"],
      ["GÖRKEM TUNA BALCI", "KUMSAL NAZ ÖNCÜ"],
      ["GÖRKEM TUNA BALCI", "YUSUF YİĞİT AKSOY"],
      ["GÜLÇE YAĞIZOĞLU", "ÖMER DENİZ KEÇECİ"],
      ["GÜLÇE YAĞIZOĞLU", "RÜZGAR GÜZELSU"],
      ["GÜLÇE YAĞIZOĞLU", "YAMAÇ ARSLAN"],
      ["GÜLÇE YAĞIZOĞLU", "ZEYNEP KILIÇARSLAN"],
      ["GÜNEŞ KÜÇÜK", "ÖMER ASAF YAVUZARSLAN"],
      ["GÜNEŞ KÜÇÜK", "ÖMER DENİZ KEÇECİ"],
      ["HAZAL DENİZ ÖZCAN", "İPEK ÖZTOPRAK"],
      ["HAZAL DENİZ ÖZCAN", "UMUT ALP YAZIM"],
      ["HAZAL DENİZ ÖZCAN", "URAS SOĞUKSU"],
      ["HAZAL DENİZ ÖZCAN", "YUSUF ASAF BAYRAMLI"],
      ["HAZAL DENİZ ÖZCAN", "ZEYNEP KILIÇARSLAN"],
      ["İPEK ÖZTOPRAK", "ÖMER DENİZ KEÇECİ"],
      ["İPEK ÖZTOPRAK", "UMUT ALP YAZIM"],
      ["İPEK ÖZTOPRAK", "YAMAÇ ARSLAN"],
      ["İPEK ÖZTOPRAK", "YUDUM ODABAŞ"],
      ["İPEK ÖZTOPRAK", "YUSUF ASAF BAYRAMLI"],
      ["KUMSAL NAZ ÖNCÜ", "ÖMER ASAF YAVUZARSLAN"],
      ["KUMSAL NAZ ÖNCÜ", "UMUT ALP YAZIM"],
      ["KUMSAL NAZ ÖNCÜ", "YUSUF ASAF BAYRAMLI"],
      ["LİNA TİRYAKİ", "ÖMER DENİZ KEÇECİ"],
      ["LİNA TİRYAKİ", "RÜZGAR GÜZELSU"],
      ["LİNA TİRYAKİ", "UMUT ALP YAZIM"],
      ["LİNA TİRYAKİ", "YUDUM ODABAŞ"],
      ["LİNA TİRYAKİ", "YUSUF YİĞİT AKSOY"],
      ["ÖMER ASAF YAVUZARSLAN", "ÖMER DENİZ KEÇECİ"],
      ["ÖMER ASAF YAVUZARSLAN", "UMUT ALP YAZIM"],
      ["ÖMER DENİZ KEÇECİ", "RÜZGAR GÜZELSU"],
      ["ÖMER DENİZ KEÇECİ", "YUDUM ODABAŞ"],
      ["RÜZGAR GÜZELSU", "UMUT ALP YAZIM"],
      ["RÜZGAR GÜZELSU", "URAS SOĞUKSU"],
      ["RÜZGAR GÜZELSU", "YUDUM ODABAŞ"],
      ["RÜZGAR GÜZELSU", "ZEYNEP KILIÇARSLAN"],
      ["UMUT ALP YAZIM", "URAS SOĞUKSU"],
      ["UMUT ALP YAZIM", "YUSUF ASAF BAYRAMLI"],
      ["UMUT ALP YAZIM", "ZEYNEP KILIÇARSLAN"],
      ["URAS SOĞUKSU", "YUSUF ASAF BAYRAMLI"],
      ["URAS SOĞUKSU", "YUSUF YİĞİT AKSOY"],
      ["YAMAÇ ARSLAN", "YUDUM ODABAŞ"],
      ["YİĞİT ARSLAN", "ZEYNEP KILIÇARSLAN"],
      ["YUDUM ODABAŞ", "YUSUF YİĞİT AKSOY"],
      ["YUSUF ASAF BAYRAMLI", "YUSUF YİĞİT AKSOY"],
    ];

    try {
      // 1. Sınıftaki tüm öğrencileri çekip İsim-Soyisim -> ID haritası oluşturalım
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      Map<String, String> isimToIdMap = {};
      for (var doc in studentSnapshot.docs) {
        var data = doc.data();
        // Sınıf filtresi (classId veya sinifId eşleşmesi)
        String? cId = data['classId'] ?? data['sinifId'];
        if (cId == widget.classId) {
          String f = (data['firstName'] ?? '').toString().trim().toUpperCase();
          String l = (data['lastName'] ?? '').toString().trim().toUpperCase();
          String adSoyad = "$f $l".trim();
          if (adSoyad.isNotEmpty) {
            isimToIdMap[adSoyad] = doc.id;
          }
        }
      }

      var batch = FirebaseFirestore.instance.batch();
      var gecmisRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('gecmis_oturmalar');

      int basariliSayisi = 0;
      int bulunamayanSayisi = 0;

      for (var cift in isimCiftleri) {
        String ad1 = cift[0].toUpperCase();
        String ad2 = cift[1].toUpperCase();

        String? id1 = isimToIdMap[ad1];
        String? id2 = isimToIdMap[ad2];

        if (id1 != null && id2 != null) {
          var docRef1 = gecmisRef.doc("${id1}_$id2");
          var docRef2 = gecmisRef.doc("${id2}_$id1");

          var veri = {
            'ogrenci1Id': id1,
            'ogrenci2Id': id2,
            'tarih': FieldValue.serverTimestamp(),
          };

          batch.set(docRef1, veri);
          batch.set(docRef2, veri);
          basariliSayisi++;
        } else {
          bulunamayanSayisi++;
          debugPrint(
            "Eşleşmeyen öğrenci: $ad1 veya $ad2 (Firestore'da bulunamadı)",
          );
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Aktarım tamamlandı! Başarılı: $basariliSayisi çift, Bulunamayan: $bulunamayanSayisi",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Matris aktarım hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Oturma Düzeni"),
        actions: [
          if (widget.isTeacher) ...[
            // 1. Otomatik Yerleştir Butonu
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: "Otomatik Yerleştir",
              onPressed: _otomatikYerlestirTiklandi,
            ),
            // 2. Manuel Yerleştirme Ekranına Geçiş Butonu
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: "Manuel Oturma Planı",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ManuelOturmaScreen(classId: widget.classId),
                  ),
                );
              },
            ),
            // 3. Matris Geçmişlerini Yükleme Butonu (YENİ)
            /*IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: "Matris Geçmişlerini Yükle",
              onPressed: _matrisGecmisleriniAktar,
            ),*/
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('oturma_duzeni')
                  .orderBy('siraNo')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text("Henüz oturma düzeni oluşturulmamış."),
                  );
                }

                var siralar = snapshot.data!.docs;

                if (siralar.isEmpty) {
                  return Center(
                    key: const Key('empty_oturma_duzeni'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Henüz bir oturma planı yapılmadı."),
                        if (widget.isTeacher) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _otomatikYerlestirTiklandi,
                            icon: const Icon(Icons.shuffle),
                            label: const Text("Otomatik Plan Oluştur"),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: siralar.length,
                  itemBuilder: (context, index) {
                    var data = siralar[index].data() as Map<String, dynamic>;
                    int siraNo = data['siraNo'] ?? (index + 1);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text('$siraNo'),
                        ),
                        title: Text(
                          "Sıra $siraNo",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${data['ogrenci1Ad'] ?? 'Boş'}   /   ${data['ogrenci2Ad'] ?? 'Boş'}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: widget.isTeacher
                            ? IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  // İleride manuel değiştirme penceresi eklenebilir
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
