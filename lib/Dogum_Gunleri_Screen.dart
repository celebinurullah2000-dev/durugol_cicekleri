import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DogumGunleriScreen extends StatelessWidget {
  final String classId;
  const DogumGunleriScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sınıf Doğum Günleri Takvimi"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Kayıtlı öğrenci bulunamadı."));
          }

          var ogrenciler = snapshot.data!.docs; // .data! eklendi

          // Öğrencileri doğum günlerine kalan gün sayısına göre sıralayalım
          ogrenciler.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            int kalanA = dogumGununeKalanGunHesapla(dataA['dogumTarihi'] ?? '');
            int kalanB = dogumGununeKalanGunHesapla(dataB['dogumTarihi'] ?? '');
            return kalanA.compareTo(kalanB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ogrenciler.length, // .size yerine .length kullanıldı
            itemBuilder: (context, index) {
              var ogrenci = ogrenciler[index].data() as Map<String, dynamic>;
              String adSoyad =
                  ogrenci['adSoyad'] ??
                  "${ogrenci['firstName'] ?? ''} ${ogrenci['lastName'] ?? ''}";
              String dogumTarihi = ogrenci['dogumTarihi'] ?? '';

              int kalanGun = dogumGununeKalanGunHesapla(dogumTarihi);

              String sayacMetni;
              Color renk;
              if (kalanGun == 0) {
                sayacMetni = "🎉 Bugün Doğum Günü! İyi ki Doğdu! 🎂";
                renk = Colors.pink;
              } else if (kalanGun == 1) {
                sayacMetni = "Yarın Doğum Günü! 🎈";
                renk = Colors.orange;
              } else {
                sayacMetni = "Doğum gününe $kalanGun gün kaldı";
                renk = Colors.indigo;
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: renk.withValues(alpha: 0.2),
                    child: Icon(Icons.cake, color: renk),
                  ),
                  title: Text(
                    adSoyad,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Doğum Tarihi: $dogumTarihi",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sayacMetni,
                        style: TextStyle(
                          color: renk,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int dogumGununeKalanGunHesapla(String dogumTarihiStr) {
    try {
      List<String> parcalar = dogumTarihiStr.split('.');
      if (parcalar.length != 3) return 999;
      int gun = int.parse(parcalar[0]);
      int ay = int.parse(parcalar[1]);

      DateTime simdi = DateTime.now();
      DateTime buYilDogumGunu = DateTime(simdi.year, ay, gun);

      if (buYilDogumGunu.isBefore(
        DateTime(simdi.year, simdi.month, simdi.day),
      )) {
        buYilDogumGunu = DateTime(simdi.year + 1, ay, gun);
      }

      return buYilDogumGunu
          .difference(DateTime(simdi.year, simdi.month, simdi.day))
          .inDays;
    } catch (e) {
      return 999;
    }
  }
}
