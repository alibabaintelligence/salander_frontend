import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../classes/analysis_results.dart';

class VelocityTimeGraph extends StatelessWidget {
  final AnalysisResults analysisResults;
  final int maxDataPoints = 1000;

  const VelocityTimeGraph({
    Key? key,
    required this.analysisResults,
  }) : super(key: key);

  List<FlSpot> _downsampleData() {
    final data = analysisResults.velocityPlots;
    if (data.length <= maxDataPoints)
      return data.map((plot) => FlSpot(plot.time, plot.velocity)).toList();

    final step = data.length ~/ maxDataPoints;
    return List.generate(maxDataPoints, (index) {
      final i = index * step;
      return FlSpot(data[i].time, data[i].velocity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final downsampledData = _downsampleData();

    final minTime = downsampledData.first.x;
    final maxTime = downsampledData.last.x;
    final minVelocity =
        downsampledData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxVelocity =
        downsampledData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    print(
        "Number of detection windows: ${analysisResults.detectionWindows.length}");
    if (analysisResults.detectionWindows.isNotEmpty) {
      print(
          "First window: Start=${analysisResults.detectionWindows[0].start}, End=${analysisResults.detectionWindows[0].end}, Percentage=${analysisResults.detectionWindows[0].percentage}");
    }
    print("Data time range: $minTime to $maxTime");

    return Container(
      padding: const EdgeInsets.only(right: 30.0, top: 25.0, bottom: 15.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 21, 21, 21),
        borderRadius: BorderRadius.circular(12.0),
      ),
      height: 400.0,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 15,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
                interval: (maxTime - minTime) / 5,
              ),
              axisNameSize: 15,
              axisNameWidget: Text(
                'Time (s)',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsExponential(1)}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
                interval: (maxVelocity - minVelocity) / 5,
              ),
              axisNameSize: 40,
              axisNameWidget: Text(
                'Velocity (m/s)',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: downsampledData,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            ...analysisResults.detectionWindows.map(
              (window) => LineChartBarData(
                spots: [
                  FlSpot(window.start, minVelocity),
                  FlSpot(window.start, maxVelocity),
                  FlSpot(window.end, maxVelocity),
                  FlSpot(window.end, minVelocity),
                ],
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                isStrokeCapRound: false,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Color.fromARGB(255, 255, 225, 106).withOpacity(0.5),
                ),
              ),
            ),
          ],
          minX: minTime,
          maxX: maxTime,
          minY: minVelocity,
          maxY: maxVelocity,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final window = analysisResults.detectionWindows.firstWhere(
                    (w) => touchedSpot.x >= w.start && touchedSpot.x <= w.end,
                    orElse: () =>
                        DetectionWindow(start: 0, end: 0, percentage: 0),
                  );
                  if (window.start != 0) {
                    return LineTooltipItem(
                      'Window: ${window.start.toStringAsFixed(2)}s - ${window.end.toStringAsFixed(2)}s\n${window.percentage != null ? 'Chance of seism: ${(window.percentage)?.toStringAsFixed(2)}%' : ''}',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  } else {
                    // return LineTooltipItem(
                    //   'Time: ${touchedSpot.x.toStringAsFixed(2)}s\n'
                    //   'Velocity: ${touchedSpot.y.toStringAsExponential(2)} m/s',
                    //   const TextStyle(color: Colors.white),
                    // );
                  }
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
