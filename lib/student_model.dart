class Student {
  final String id; // Firestore döküman ID
  final String firstName;
  final String lastName;
  String password; // Öğretmen değiştirebilir
  final String schoolId;
  final String classId;

  // İsteğe bağlı alanlar
  String? schoolNumber;
  String? tcId;
  String? motherName;
  String? fatherName;
  int? siblingCount;
  String? motherPhone;
  String? fatherPhone;
  String? motherJob;
  String? fatherJob;
  String? motherEducation;
  String? fatherEducation;
  List<String>? specialConditions; // Hastalıklar, özel durumlar

  // Oyunlaştırma ve Veri
  int totalPageCount;
  int starCount;
  String currentTitle; // Kitap kurdu, kitap canavarı vb.

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.password,
    required this.schoolId,
    required this.classId,
    this.totalPageCount = 0,
    this.starCount = 0,
    this.currentTitle = "Kitap Çaylağı",
    // Diğer opsiyonel alanlar null olabilir
  });
}
