import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';
import 'package:intl/intl.dart';

class AnalyticsData {
  final int totalIssues;
  final int pendingIssues;
  final int inProgressIssues;
  final int resolvedIssues;
  final String mostCommonCategory;
  final Duration averageResolutionTime;
  final Map<String, int> issueCategoryCounts;
  final Map<int, int> last7DaysCounts; // Day index -> count

  AnalyticsData({
    required this.totalIssues,
    required this.pendingIssues,
    required this.inProgressIssues,
    required this.resolvedIssues,
    required this.mostCommonCategory,
    required this.averageResolutionTime,
    required this.issueCategoryCounts,
    required this.last7DaysCounts,
  });
}

class AnalyticsService {
  /// We process analytics locally from the Stream's already fetched issues.
  /// This completely eliminates extra Firestore read costs.
  static AnalyticsData calculateAnalytics(List<IssueModel> issues) {
    if (issues.isEmpty) {
      return AnalyticsData(
        totalIssues: 0,
        pendingIssues: 0,
        inProgressIssues: 0,
        resolvedIssues: 0,
        mostCommonCategory: 'N/A',
        averageResolutionTime: Duration.zero,
        issueCategoryCounts: {},
        last7DaysCounts: {},
      );
    }

    int pending = 0;
    int inP = 0;
    int resolved = 0;
    Map<String, int> categories = {};
    Duration totalResolutionTime = Duration.zero;
    int resolvedWithTimeCount = 0;

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    Map<int, int> last7Days = {for (var i = 6; i >= 0; i--) i: 0};

    for (var issue in issues) {
      // 1. Status loop
      if (issue.status == statusPending) pending++;
      if (issue.status == statusInProgress) inP++;
      if (issue.status == statusResolved) resolved++;

      // 2. Category frequencies
      categories[issue.category] = (categories[issue.category] ?? 0) + 1;

      // 3. Resolution time (if resolved and has both timestamps)
      if (issue.status == statusResolved && issue.updatedAt != null) {
        // Just as an estimate, diff between created and updated
        final diff = issue.updatedAt!.difference(issue.createdAt);
        if (diff.inMinutes > 0) { // filter out instant glitches
          totalResolutionTime += diff;
          resolvedWithTimeCount++;
        }
      }

      // 4. Last 7 days trend
      final issueMidnight = DateTime(
          issue.createdAt.year, issue.createdAt.month, issue.createdAt.day);
      final differenceInDays = todayMidnight.difference(issueMidnight).inDays;
      if (differenceInDays >= 0 && differenceInDays <= 6) {
        last7Days[6 - differenceInDays] = (last7Days[6 - differenceInDays] ?? 0) + 1;
      }
    }

    // Determine highest category
    String commonCategory = 'N/A';
    int maxCatCount = 0;
    categories.forEach((key, val) {
      if (val > maxCatCount) {
        maxCatCount = val;
        commonCategory = key;
      }
    });

    // Averaging time
    Duration avgTime = Duration.zero;
    if (resolvedWithTimeCount > 0) {
      avgTime = Duration(
          milliseconds:
              totalResolutionTime.inMilliseconds ~/ resolvedWithTimeCount);
    }

    return AnalyticsData(
      totalIssues: issues.length,
      pendingIssues: pending,
      inProgressIssues: inP,
      resolvedIssues: resolved,
      mostCommonCategory: maxCatCount > 0 ? commonCategory : 'N/A',
      averageResolutionTime: avgTime,
      issueCategoryCounts: categories,
      last7DaysCounts: last7Days,
    );
  }

  static String formatDuration(Duration d) {
    if (d == Duration.zero) return 'N/A';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    if (days > 0) return '$days days, $hours hrs';
    if (hours > 0) return '$hours hrs, ${d.inMinutes.remainder(60)} mins';
    return '${d.inMinutes} mins';
  }
}
