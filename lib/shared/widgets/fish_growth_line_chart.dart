import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FishGrowthLineChart extends StatelessWidget {
  final Stream<List<FishGrowthData>> stream;
  final String title;
  final String xLabel;
  final String yLabel;

  const FishGrowthLineChart({
    Key? key,
    required this.stream,
    this.title = 'Fish Growth Over Time',
    this.xLabel = 'Day',
    this.yLabel = 'Length (cm)',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double yInterval = 2;
    DateTime now = DateTime.now();
    int DaysInMonth = DateTime(now.year, now.month + 1 , 0).day;

    return StreamBuilder<List<FishGrowthData>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No growth data available'));
        }
        final data = snapshot.data!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: AspectRatio(
                aspectRatio: 1.7,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 2,
                        ),
                        axisNameWidget: Text(yLabel),
                        axisNameSize: 24,
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 7
                        ),
                        axisNameWidget: Text(xLabel),
                        axisNameSize: 24,
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    maxX: DaysInMonth.toDouble(),
                    maxY: ((data.map((e) => e.length).reduce(max) / yInterval).ceil() * yInterval),                    lineBarsData: [
                      LineChartBarData(
                        spots: data.map((e) => FlSpot(e.day.toDouble(), e.length)).toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class FishGrowthData {
  final int day;
  final double length;
  FishGrowthData({required this.day, required this.length});
}

// Example usage:
// FishGrowthLineChart(
//   stream: yourGrowthDataStream,
// ) 