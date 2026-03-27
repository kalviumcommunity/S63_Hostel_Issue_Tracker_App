class SLAService {
  static const String priorityHigh = 'High';
  static const String priorityMedium = 'Medium';
  static const String priorityLow = 'Low';

  /// Calculates the deadline based on priority.
  static DateTime calculateDeadline(DateTime createdAt, String priority) {
    switch (priority) {
      case priorityHigh:
        return createdAt.add(const Duration(hours: 24));
      case priorityMedium:
        return createdAt.add(const Duration(hours: 48));
      case priorityLow:
      default:
        return createdAt.add(const Duration(hours: 72));
    }
  }

  /// Checks if the issue has breached the SLA.
  static bool isDelayed(DateTime deadline, String status) {
    // If it's already resolved, it stops being "currently delayed". 
    // It may have breached its SLA in the past, but the prompt implies we want 
    // to highlight active issues that missed the deadline. 
    // But for metrics, we just check against DateTime.now() if not resolved.
    if (status == 'resolved') return false; 
    return DateTime.now().isAfter(deadline);
  }

  /// Creates a formatted remaining string
  static String getRemainingTimeStr(DateTime deadline) {
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      final diff = now.difference(deadline);
      return 'Delayed by ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } else {
      final diff = deadline.difference(now);
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
    }
  }
}
