import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circuit.dart';

class ResultsSection extends StatelessWidget {
  const ResultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final circuit = context.watch<CircuitState>();
    final results = circuit.lastResults;
    final counts = results['counts'] as Map<String, dynamic>?;

    if (circuit.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (circuit.error != null) {
      return Center(
        child: Text(
          "Error: ${circuit.error}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (counts == null || counts.isEmpty) {
      return const Center(
        child: Text(
          "Run simulation to see results",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final totalShots = results['shots'] as int? ?? 1;
    final List<BarChartGroupData> bars = [];
    int index = 0;

    // Convert counts to probabilities for height
    counts.forEach((state, count) {
      final prob = (count as int) / totalShots;
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: prob,
              color: const Color(0xFF03DAC6),
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
      index++;
    });

    // We need to map index back to state label for bottom titles
    final keys = counts.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        swapAnimationDuration: const Duration(milliseconds: 500),
        swapAnimationCurve: Curves.easeInOut,
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() < keys.length && val.toInt() >= 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        keys[val.toInt()],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
        ),
      ),
    );
  }
}
