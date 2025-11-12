import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/widgets/deferred_widget.dart';

import 'package:fl_chart/fl_chart.dart' deferred as fl_chart;

class PlayerRatingChart extends StatelessWidget {
  final List<RatingSnapshot> history;

  const PlayerRatingChart({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final recentHistory = history.take(10).toList().reversed.toList();
    if (recentHistory.isEmpty) {
      return const Center(child: Text('אין נתונים להצגה'));
    }

    return DeferredWidget(
      loadLibrary: fl_chart.loadLibrary,
      placeholder: const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
      builder: (context) {
        final ratings = recentHistory.map((snapshot) {
          return (snapshot.defense +
                  snapshot.passing +
                  snapshot.shooting +
                  snapshot.dribbling +
                  snapshot.physical +
                  snapshot.leadership +
                  snapshot.teamPlay +
                  snapshot.consistency) /
              8.0;
        }).toList();

        final spots = ratings.asMap().entries.map((entry) {
          return fl_chart.FlSpot(entry.key.toDouble(), entry.value);
        }).toList();

        return fl_chart.LineChart(
          fl_chart.LineChartData(
            gridData: fl_chart.FlGridData(show: true),
            titlesData: fl_chart.FlTitlesData(
              leftTitles: fl_chart.AxisTitles(
                sideTitles: fl_chart.SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: fl_chart.AxisTitles(
                sideTitles: fl_chart.SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= recentHistory.length) {
                      return const SizedBox.shrink();
                    }
                    final date = recentHistory[index].submittedAt;
                    return Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: const fl_chart.AxisTitles(
                sideTitles: fl_chart.SideTitles(showTitles: false),
              ),
              topTitles: const fl_chart.AxisTitles(
                sideTitles: fl_chart.SideTitles(showTitles: false),
              ),
            ),
            borderData: fl_chart.FlBorderData(show: true),
            lineBarsData: [
              fl_chart.LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: const fl_chart.FlDotData(show: true),
                belowBarData: fl_chart.BarAreaData(show: false),
              ),
            ],
            minY: 0,
            maxY: 10,
          ),
        );
      },
    );
  }
}
