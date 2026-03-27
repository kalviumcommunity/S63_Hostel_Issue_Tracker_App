import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/issue_provider.dart';
import '../../services/analytics_service.dart';

class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final data = AnalyticsService.calculateAnalytics(issueProvider.issues);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Real-time view of hostel issues performance',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Top Summary Cards
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total Issues',
                    value: data.totalIssues.toString(),
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF6C63FF),
                    bgColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Avg Time',
                    value: AnalyticsService.formatDuration(data.averageResolutionTime),
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF3ECFCF),
                    bgColor: const Color(0xFF3ECFCF).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Top Category',
                    value: data.mostCommonCategory,
                    icon: Icons.stars_rounded,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Status Breakdown Pie Chart
            const Text(
              'Status Breakdown',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: data.totalIssues == 0 
                      ? const Center(child: Text('No data yet')) 
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFFEF4444),
                                value: data.pendingIssues.toDouble(),
                                title: '${data.pendingIssues}',
                                radius: 40,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFF59E0B),
                                value: data.inProgressIssues.toDouble(),
                                title: '${data.inProgressIssues}',
                                radius: 45,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF10B981),
                                value: data.resolvedIssues.toDouble(),
                                title: '${data.resolvedIssues}',
                                radius: 50,
                                titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Indicator(color: const Color(0xFFEF4444), text: 'Pending'),
                      _Indicator(color: const Color(0xFFF59E0B), text: 'In Progress'),
                      _Indicator(color: const Color(0xFF10B981), text: 'Resolved'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Last 7 days Bar Chart
            const Text(
              'Issues Trend (Last 7 Days)',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 24),
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (data.last7DaysCounts.values.isEmpty ? 0 : data.last7DaysCounts.values.reduce((a, b) => a > b ? a : b)).toDouble() + 2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12);
                          
                          int index = value.toInt();
                          if (index < 0 || index > 6) return const SizedBox();
                          // calculate date string based on index (0 is 6 days ago, 6 is today)
                          DateTime date = DateTime.now().subtract(Duration(days: 6 - index));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${date.day}/${date.month}', style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), // Hide left Y axis for clean look
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => 
                        FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1, dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (data.last7DaysCounts[i] ?? 0).toDouble(),
                          color: const Color(0xFF6C63FF),
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}
