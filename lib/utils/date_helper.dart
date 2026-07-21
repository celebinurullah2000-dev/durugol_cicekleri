// lib/utils/date_helper.dart

class DateHelper {
  static bool isNew(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt).inDays;
    return difference <= 7;
  }
}
