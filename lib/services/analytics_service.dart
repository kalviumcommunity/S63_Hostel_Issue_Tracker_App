import '../models/issue_model.dart';

class AnalyticsData {
  final int totalIssues;
  final int pendingIssues; // Includes both pending and assigned
  final int inProgressIssues;
  final int resolvedIssues;
  
  // Advanced Insights
  final String mostCommonCategory;
  final String mostProblematicBlock;
  final int peakHourOfDay; // 0-23
  final double weeklyGrowthRate; // % difference vs last week
  final int issuesThisWeek;
  final int issuesLastWeek;
  
  final Duration averageResolutionTime;
  final Map<String, int> issueCategoryCounts;
  final Map<String, int> blockCounts;
  final Map<int, int> last7DaysCounts; // Day index -> count
  final Map<int, int> hourlyTrends; // Hour -> count

  AnalyticsData({
    required this.totalIssues,
    required this.pendingIssues,
    required this.inProgressIssues,
    required this.resolvedIssues,
    required this.mostCommonCategory,
    required this.mostProblematicBlock,
    required this.peakHourOfDay,
    required this.weeklyGrowthRate,
    required this.issuesThisWeek,
    required this.issuesLastWeek,
    required this.averageResolutionTime,
    required this.issueCategoryCounts,
    required this.blockCounts,
    required this.last7DaysCounts,
    required this.hourlyTrends,
  });
}

class AnalyticsService {
  static AnalyticsData calculateAnalytics(List<IssueModel> issues) {
    if (issues.isEmpty) {
      return AnalyticsData(
        totalIssues: 0,
        pendingIssues: 0,
        inProgressIssues: 0,
        resolvedIssues: 0,
        mostCommonCategory: 'N/A',
        mostProblematicBlock: 'N/A',
        peakHourOfDay: 0,
        weeklyGrowthRate: 0,
        issuesThisWeek: 0,
        issuesLastWeek: 0,
        averageResolutionTime: Duration.zero,
        issueCategoryCounts: {},
        blockCounts: {},
        last7DaysCounts: {for (var i = 0; i < 7; i++) i: 0},
        hourlyTrends: {for (var i = 0; i < 24; i++) i: 0},
      );
    }

    int pending = 0;
    int inP = 0;
    int resolved = 0;
    int issuesThisWeek = 0;
    int issuesLastWeek = 0;
    
    Map<String, int> categories = {};
    Map<String, int> blocks = {};
    Map<int, int> hourlyTrends = {for (var i = 0; i < 24; i++) i: 0};
    
    Duration totalResolutionTime = Duration.zero;
    int resolvedWithTimeCount = 0;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    Map<int, int> last7Days = {for (var i = 6; i >= 0; i--) i: 0};

    for (var issue in issues) {
      // 1. Basic Status counts
      if (issue.status == statusPending || issue.status == statusAssigned) pending++;
      if (issue.status == statusInProgress) inP++;
      if (issue.status == statusResolved) resolved++;

      // 2. Weekly comparison
      if (issue.createdAt.isAfter(sevenDaysAgo)) {
        issuesThisWeek++;
      } else if (issue.createdAt.isAfter(fourteenDaysAgo)) {
        issuesLastWeek++;
      }

      // 3. Category & Block frequencies
      categories[issue.category] = (categories[issue.category] ?? 0) + 1;
      
      // Extraction of Block (Assumption: location is "Block X - Room Y")
      final blockName = issue.location.split(' - ').first;
      blocks[blockName] = (blocks[blockName] ?? 0) + 1;

      // 4. Hourly Trends
      hourlyTrends[issue.createdAt.hour] = (hourlyTrends[issue.createdAt.hour] ?? 0) + 1;

      // 5. Resolution time
      if (issue.status == statusResolved && (issue.resolvedAt != null || issue.updatedAt != null)) {
        final resolveDate = issue.resolvedAt ?? issue.updatedAt!;
        final diff = resolveDate.difference(issue.createdAt);
        if (diff.inSeconds > 0) {
          totalResolutionTime += diff;
          resolvedWithTimeCount++;
        }
      }

      // 6. Last 7 days trend
      final issueMidnight = DateTime(
          issue.createdAt.year, issue.createdAt.month, issue.createdAt.day);
      final differenceInDays = todayMidnight.difference(issueMidnight).inDays;
      if (differenceInDays >= 0 && differenceInDays <= 6) {
        last7Days[6 - differenceInDays] = (last7Days[6 - differenceInDays] ?? 0) + 1;
      }
    }

    // Determine highest category
    String commonCategory = _getTopKey(categories);
    String topBlock = _getTopKey(blocks);
    int peakHour = 0;
    int maxHourFreq = 0;
    hourlyTrends.forEach((k, v) {
      if (v > maxHourFreq) {
        maxHourFreq = v;
        peakHour = k;
      }
    });

    // Growth Rate calculation
    double growth = 0;
    if (issuesLastWeek > 0) {
      growth = ((issuesThisWeek - issuesLastWeek) / issuesLastWeek) * 100;
    } else if (issuesThisWeek > 0) {
      growth = 100; // 100% growth if there was nothing last week
    }

    Duration avgTime = resolvedWithTimeCount > 0
        ? Duration(milliseconds: totalResolutionTime.inMilliseconds ~/ resolvedWithTimeCount)
        : Duration.zero;

    return AnalyticsData(
      totalIssues: issues.length,
      pendingIssues: pending,
      inProgressIssues: inP,
      resolvedIssues: resolved,
      mostCommonCategory: commonCategory,
      mostProblematicBlock: topBlock,
      peakHourOfDay: peakHour,
      weeklyGrowthRate: growth,
      issuesThisWeek: issuesThisWeek,
      issuesLastWeek: issuesLastWeek,
      averageResolutionTime: avgTime,
      issueCategoryCounts: categories,
      blockCounts: blocks,
      last7DaysCounts: last7Days,
      hourlyTrends: hourlyTrends,
    );
  }

  static String _getTopKey(Map<String, int> map) {
    if (map.isEmpty) return 'N/A';
    String topKey = 'N/A';
    int maxVal = -1;
    map.forEach((k, v) {
      if (v > maxVal) {
        maxVal = v;
        topKey = k;
      }
    });
    return topKey;
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
