// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class IstatistikServisi {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // İşlem kaydetme (Günlük bazda detaylı artış)
  static Future<void> islemKaydet({
    required String studentId,
    required String islemTuru, // Örn: 'oyun_hafiza', 'cesitli_Nöbetçi'
  }) async {
    if (studentId.isEmpty) return;

    // Bugünün tarihini YYYY-MM-DD formatında alıyoruz
    String bugun = DateFormat('yyyy-MM-dd').format(DateTime.now());

    DocumentReference docRef = _firestore
        .collection('students')
        .doc(studentId)
        .collection('istatistikler')
        .doc(bugun);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Eğer bugün ilk defa işlem yapılıyorsa dokümanı oluştur
          transaction.set(docRef, {
            'toplamEtkilesim': 1,
            'giris': islemTuru == 'giris' ? 1 : 0,
            'detaylar': {islemTuru: 1},
          });
        } else {
          // Mevcut verileri güncelle
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int mevcutToplam = data['toplamEtkilesim'] ?? 0;
          int mevcutGiris = data['giris'] ?? 0;

          Map<String, dynamic> detaylar = Map<String, dynamic>.from(
            data['detaylar'] ?? {},
          );
          int mevcutIslemSayisi = detaylar[islemTuru] ?? 0;

          detaylar[islemTuru] = mevcutIslemSayisi + 1;

          transaction.update(docRef, {
            'toplamEtkilesim': mevcutToplam + 1,
            'giris': islemTuru == 'giris' ? mevcutGiris + 1 : mevcutGiris,
            'detaylar': detaylar,
          });
        }
      });
    } catch (e) {
      print("İstatistik kaydedilemedi: $e");
    }
  }

  // Geliştirilmiş İstatistik Çekme Metodu (Özel Tarih, Hafta veya Ay aralığı desteğiyle)
  static Future<Map<String, dynamic>> ogrenciIstatistikGetir({
    required String studentId,
    required String
    periyot, // 'gunluk', 'haftalik', 'aylik', 'yillik', 'ozel_gun', 'ozel_hafta', 'ozel_ay'
    DateTime? hedefTarih, // 'ozel_gun' için seçilen tarih
    int? yil, // 'ozel_hafta' veya 'ozel_ay' için yıl
    int? haftaVeyaAyNo, // Hafta numarası (1-52) veya Ay numarası (1-12)
  }) async {
    DateTime simdi = DateTime.now();
    DateTime baslangicTarihi;
    DateTime bitisTarihi = simdi;

    if (periyot == 'gunluk') {
      baslangicTarihi = DateTime(simdi.year, simdi.month, simdi.day);
    } else if (periyot == 'haftalik') {
      baslangicTarihi = simdi.subtract(const Duration(days: 7));
    } else if (periyot == 'aylik') {
      baslangicTarihi = DateTime(simdi.year, simdi.month - 1, simdi.day);
    } else if (periyot == 'yillik') {
      baslangicTarihi = DateTime(simdi.year - 1, simdi.month, simdi.day);
    } else if (periyot == 'ozel_gun' && hedefTarih != null) {
      baslangicTarihi = DateTime(
        hedefTarih.year,
        hedefTarih.month,
        hedefTarih.day,
      );
      bitisTarihi = baslangicTarihi; // Tek bir gün
    } else if (periyot == 'ozel_ay' && yil != null && haftaVeyaAyNo != null) {
      // Belirtilen yılın seçilen ayı (haftaVeyaAyNo = Ay, örn: 1-12)
      baslangicTarihi = DateTime(yil, haftaVeyaAyNo, 1);
      // Ayın son günü
      bitisTarihi = (haftaVeyaAyNo == 12)
          ? DateTime(yil + 1, 1, 1).subtract(const Duration(days: 1))
          : DateTime(
              yil,
              haftaVeyaAyNo + 1,
              1,
            ).subtract(const Duration(days: 1));
    } else if (periyot == 'ozel_hafta' &&
        yil != null &&
        haftaVeyaAyNo != null) {
      // Yılın başından başlayarak seçilen hafta numarasına (1-52) göre hesaplama
      DateTime yilBasi = DateTime(yil, 1, 1);
      // ISO hafta hesaplamasına benzer şekilde yaklaşım
      baslangicTarihi = yilBasi.add(Duration(days: (haftaVeyaAyNo - 1) * 7));
      bitisTarihi = baslangicTarihi.add(const Duration(days: 6));
    } else {
      baslangicTarihi = DateTime(simdi.year, simdi.month, simdi.day);
    }

    String baslangicStr = DateFormat('yyyy-MM-dd').format(baslangicTarihi);
    String bitisStr = DateFormat('yyyy-MM-dd').format(bitisTarihi);

    // Firestore sorgusu (Belirtilen başlangıç ve bitiş tarihleri arasında)
    QuerySnapshot querySnapshot = await _firestore
        .collection('students')
        .doc(studentId)
        .collection('istatistikler')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: baslangicStr)
        .where(FieldPath.documentId, isLessThanOrEqualTo: bitisStr)
        .get();

    int toplamEtkilesim = 0;
    int toplamGiris = 0;
    Map<String, int> birletirilmisDetaylar = {};

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      toplamEtkilesim += (data['toplamEtkilesim'] as num?)?.toInt() ?? 0;
      toplamGiris += (data['giris'] as num?)?.toInt() ?? 0;

      Map<String, dynamic> detaylar = Map<String, dynamic>.from(
        data['detaylar'] ?? {},
      );
      detaylar.forEach((key, value) {
        int sayi = (value as num?)?.toInt() ?? 0;
        birletirilmisDetaylar[key] = (birletirilmisDetaylar[key] ?? 0) + sayi;
      });
    }

    return {
      'toplamEtkilesim': toplamEtkilesim,
      'giris': toplamGiris,
      'detaylar': birletirilmisDetaylar,
    };
  }
}
