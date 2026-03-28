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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        physics: const ClampingScrollPhysics(),
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

            // Advanced Insight Metrics
            Row(
              children: [
                Expanded(
                  child: _InsightMiniCard(
                    title: 'Growth (Weekly)',
                    value: '${data.weeklyGrowthRate > 0 ? '+' : ''}${data.weeklyGrowthRate.toStringAsFixed(1)}%',
                    icon: data.weeklyGrowthRate > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: data.weeklyGrowthRate > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InsightMiniCard(
                    title: 'Peak Activity',
                    value: '${data.peakHourOfDay}:00 ${data.peakHourOfDay >= 12 ? 'PM' : 'AM'}',
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HighlightBanner(
              title: 'Hottest Zone',
              subtitle: '${data.mostProblematicBlock} has the most reports (${data.blockCounts[data.mostProblematicBlock]} active issues)',
              icon: Icons.location_on_rounded,
              color: const Color(0xFFF59E0B),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFF59E0B),
                                value: data.inProgressIssues.toDouble(),
                                title: '${data.inProgressIssues}',
                                radius: 50,
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFF10B981),
                                value: data.resolvedIssues.toDouble(),
                                title: '${data.resolvedIssues}',
                                radius: 55,
                                titleStyle: const TextStyle(
                                    fontSize: 14,
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

            // Geographic Breakdown (Block Charts)
            const Text(
              'Geographic Breakdown',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                children: data.blockCounts.entries.map((entry) {
                  final percent = entry.value / data.totalIssues;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${entry.value} Issues', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: const Color(0xFF6C63FF),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Peak Hours Trend (Line Chart)
            const Text(
              'Hourly Heatmap',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.only(top: 24, bottom: 8, left: 16, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 6,
                        getTitlesWidget: (v, m) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.hourlyTrends.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                      isCurved: true,
                      color: const Color(0xFF6C63FF),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true, 
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Shows frequency of issues by hour of the day', 
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 40),

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

class _InsightMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HighlightBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
              ],
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
