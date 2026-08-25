import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/app_bottom_nav.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyCompletionProvider);
    final streaksAsync = ref.watch(habitStreaksProvider);
    final obligationSummaryAsync = ref.watch(obligationSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistika')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Zadnjih 7 dana',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 200,
            child: weeklyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Greška: $err')),
              data: (days) => _WeeklyBarChart(days: days),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Nizovi (streakovi)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          streaksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Greška: $err')),
            data: (streaks) => streaks.isEmpty
                ? const Text('Nemaš još navika za praćenje.')
                : Column(
                    children: streaks
                        .map((s) => _StreakTile(streak: s))
                        .toList(),
                  ),
          ),

          const SizedBox(height: 32),
          Text('Obveze', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          obligationSummaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Greška: $err')),
            data: (summary) => _ObligationSummaryCard(summary: summary),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }
}

/// Bar chart koji prikazuje postotak odrađenih navika po danu
class _WeeklyBarChart extends StatelessWidget {
  final List days;

  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 1.0,
        alignment: BarChartAlignment.spaceAround,

        barGroups: days.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: day.percentage,
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),

        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox();

                final label = DateFormat('E').format(days[index].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  final dynamic streak;

  const _StreakTile({required this.streak});

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(streak.habitColorHex.replaceFirst('#', '0xFF')),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.local_fire_department, color: color),
        ),
        title: Text(streak.habitName),
        trailing: Text(
          '${streak.currentStreak} ${streak.currentStreak == 1 ? "dan" : "dana"}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ObligationSummaryCard extends StatelessWidget {
  final Map<String, int> summary;

  const _ObligationSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final done = summary['done'] ?? 0;
    final total = summary['total'] ?? 0;
    final percentage = total == 0 ? 0 : ((done / total) * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(value: '$done', label: 'Završeno'),
            _StatColumn(value: '$total', label: 'Ukupno'),
            _StatColumn(value: '$percentage%', label: 'Stopa uspjeha'),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
