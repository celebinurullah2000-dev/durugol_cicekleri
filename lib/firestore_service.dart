import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Öğrenci Ekleme
  Future<void> addStudent(Map<String, dynamic> studentData) async {
    await _db.collection('students').add(studentData);
  }

  // Öğretmen için: Öğrencinin şifresini güncelleme
  Future<void> updateStudentPassword(
    String studentId,
    String newPassword,
  ) async {
    await _db.collection('students').doc(studentId).update({
      'password': newPassword,
    });
  }

  // Öğretmen için: Davranış Kilitleme (Ceza sistemi)
  Future<void> lockBehavior(String studentId, bool isLocked) async {
    await _db.collection('students').doc(studentId).update({
      'isBehaviorLocked': isLocked,
      'lockedUntil': DateTime.now().add(const Duration(days: 3)),
    });
  }

  // Ödev Durumunu Güncelleme
  Future<void> updateAssignmentStatus(
    String assignmentId,
    String status,
  ) async {
    // status: 'yaptı', 'yapmadı', 'kısmen yaptı'
    await _db.collection('assignments').doc(assignmentId).update({
      'status': status,
    });
  }
}
