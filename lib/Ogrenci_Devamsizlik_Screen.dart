import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OgrenciDevamsizlikScreen extends StatelessWidget {
  final String classId;
  final String studentId; // Giriş yapan öğrencinin ID'si

  const OgrenciDevamsizlikScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devamsızlık Bilgilerim"),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('devamsizliklar')
            .orderBy(
              'tarih',
              descending: true,
            ) // Bugünden geçmişe doğru sıralama
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz devamsızlık kaydı bulunmuyor.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          var devamsizlikDocs = snapshot.data!.docs;
          List<String> gelmedigiTarihler = [];

          // Kayıtları tarayıp bu öğrencinin devamsız olduğu tarihleri ayıklayalım
          for (var doc in devamsizlikDocs) {
            var data = doc.data() as Map<String, dynamic>;
            String tarihStr = data['tarih'] ?? '';
            var ogrencilerMap =
                data['ogrenciler'] as Map<String, dynamic>? ?? {};

            if (ogrencilerMap[studentId] == true) {
              // Tarihi GG.AA.YYYY formatına çevirelim
              String formatliTarih = tarihStr;
              try {
                List<String> parts = tarihStr.split('-');
                if (parts.length == 3) {
                  formatliTarih = "${parts[2]}.${parts[1]}.${parts[0]}";
                }
              } catch (_) {}

              gelmedigiTarihler.add(formatliTarih);
            }
          }

          return Column(
            children: [
              // Özet Kartı
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: gelmedigiTarihler.isEmpty
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gelmedigiTarihler.isEmpty
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Toplam Devamsızlık",
                      style: TextStyle(
                        fontSize: 16,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${gelmedigiTarihler.length} Gün",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: gelmedigiTarihler.isEmpty
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gelmedigiTarihler.isEmpty
                          ? "Harika! Hiç devamsızlığınız yok."
                          : "Aşağıdaki tarihlerde okula gelmediğiniz kaydedilmiştir.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Gelmediğiniz Tarihler",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Liste
              Expanded(
                child: gelmedigiTarihler.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: gelmedigiTarihler.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(
                                  Icons.event_busy,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                gelmedigiTarihler[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Text(
                                "Gelmedi",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
