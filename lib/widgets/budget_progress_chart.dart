import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetProgressChart extends StatelessWidget {
  final double totalBudget;
  final double spentAmount;

  BudgetProgressChart({required this.totalBudget, required this.spentAmount});

  @override
  Widget build(BuildContext context) {
    final double percentage = (spentAmount / totalBudget).clamp(0.0, 1.0);
    final double remainingPercentage = 1 - percentage;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 50, // Reduced from 70
            sections: [
              PieChartSectionData(
                color: Colors.blue,
                value: percentage * 100,
                title: '${(percentage * 100).toStringAsFixed(1)}%',
                radius: 50, // Reduced from 60
                titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              PieChartSectionData(
                color: Colors.grey[300],
                value: remainingPercentage * 100,
                title: '',
                radius: 50, // Reduced from 60
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${spentAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'of \$${totalBudget.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

