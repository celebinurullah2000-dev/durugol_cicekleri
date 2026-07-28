import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KisiselDeyimlerScreen extends StatefulWidget {
  final String classId;
  final bool isTeacher;

  const KisiselDeyimlerScreen({
    super.key,
    required this.classId,
    required this.isTeacher,
  });

  @override
  State<KisiselDeyimlerScreen> createState() => _KisiselDeyimlerScreenState();
}

class _KisiselDeyimlerScreenState extends State<KisiselDeyimlerScreen> {
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';

  @override
  void initState() {
    super.initState();
    _aramaController.addListener(() {
      setState(() {
        _aramaMetni = _aramaController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  // Türkçe alfabetik sıralama fonksiyonu
  int _turkceKarsilastir(String a, String b) {
    const String turkceAlfabe = 'aabcçdefgğhıijklmnoöprsştuüvyz';

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
      int indexA = turkceAlfabe.indexOf(aKucuk[i]);
      int indexB = turkceAlfabe.indexOf(bKucuk[i]);

      if (indexA == -1 || indexB == -1) {
        int comp = aKucuk.codeUnitAt(i).compareTo(bKucuk.codeUnitAt(i));
        if (comp != 0) return comp;
      } else if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
    }

    return aKucuk.length.compareTo(bKucuk.length);
  }

  // Yeni Deyim Ekleme Dialogu (Sadece Öğretmen)
  void _yeniDeyimDialogGoster(BuildContext context) {
    final TextEditingController deyimController = TextEditingController();
    final TextEditingController anlamController = TextEditingController();
    final TextEditingController cumle1Controller = TextEditingController();
    final TextEditingController cumle2Controller = TextEditingController();
    final TextEditingController cumle3Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yeni Deyim Ekle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deyimController,
                decoration: const InputDecoration(labelText: "Deyim"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: anlamController,
                decoration: const InputDecoration(labelText: "Anlamı"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cumle1Controller,
                decoration: const InputDecoration(labelText: "Örnek Cümle 1"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cumle2Controller,
                decoration: const InputDecoration(labelText: "Örnek Cümle 2"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cumle3Controller,
                decoration: const InputDecoration(labelText: "Örnek Cümle 3"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              String deyim = deyimController.text.trim();
              String anlam = anlamController.text.trim();
              List<String> cumleler = [
                cumle1Controller.text.trim(),
                cumle2Controller.text.trim(),
                cumle3Controller.text.trim(),
              ].where((c) => c.isNotEmpty).toList();

              if (deyim.isNotEmpty && anlam.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('deyimler')
                    .add({
                      'deyim': deyim,
                      'anlam': anlam,
                      'cumleler': cumleler,
                      'tarih': Timestamp.now(),
                    });

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Deyim başarıyla eklendi.")),
                );
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Deyim Detay / Anlam Gösterim Dialogu
  void _deyimDetayGoster(Map<String, dynamic> data) {
    String deyim = data['deyim'] ?? '';
    String anlam = data['anlam'] ?? '';
    List<dynamic> cumleler = data['cumleler'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          deyim,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Anlamı:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                anlam,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Örnek Cümleler:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (cumleler.isEmpty)
                const Text(
                  "Örnek cümle eklenmemiş.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                ...cumleler.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${entry.key + 1}. \"${entry.value}\"",
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deyimler ve Atasözleri"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Arama / Filtreleme Çubuğu
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _aramaController,
              decoration: InputDecoration(
                hintText: "Deyimlerde ilk harflere göre ara...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: _aramaMetni.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => _aramaController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('deyimler')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Henüz eklenmiş bir deyim veya atasözü yok.",
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                List<Map<String, dynamic>> deyimListesi = [];
                for (var doc in docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String deyimAdi = (data['deyim'] ?? '').toLowerCase();

                  // Sadece kelimenin başından itibaren girilen harf sayısı kadar eşleşme kontrolü (startsWith)
                  if (_aramaMetni.isEmpty ||
                      (deyimAdi.length >= _aramaMetni.length &&
                          deyimAdi.substring(0, _aramaMetni.length) ==
                              _aramaMetni)) {
                    deyimListesi.add({'id': doc.id, ...data});
                  }
                }

                if (deyimListesi.isEmpty) {
                  return const Center(
                    child: Text(
                      "Bu harflerle başlayan deyim bulunamadı.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  );
                }

                // Türkçe alfabetik sıralama uygulaması
                deyimListesi.sort((a, b) {
                  return _turkceKarsilastir(a['deyim'] ?? '', b['deyim'] ?? '');
                });

                return ListView.builder(
                  itemCount: deyimListesi.length,
                  itemBuilder: (context, index) {
                    var item = deyimListesi[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        title: Text(
                          item['deyim'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          item['anlam'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isTeacher)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('classes')
                                      .doc(widget.classId)
                                      .collection('deyimler')
                                      .doc(item['id'])
                                      .delete();
                                },
                              ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                        onTap: () => _deyimDetayGoster(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              onPressed: () => _yeniDeyimDialogGoster(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
