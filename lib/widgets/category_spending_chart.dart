import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_tracker/services/database_service.dart';

class CategorySpendingChart extends StatefulWidget {
  CategorySpendingChart({Key? key}) : super(key: key);

  @override
  State<CategorySpendingChart> createState() => _CategorySpendingChartState();
}

class _CategorySpendingChartState extends State<CategorySpendingChart> {
  final DatabaseService _databaseService = DatabaseService.instance;
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final categories = snapshot.data!;
        return FutureBuilder<Map<String, double>>(
          future: _getCategoryTotals(categories),
          builder: (context, totalsSnapshot) {
            if (!totalsSnapshot.hasData) return CircularProgressIndicator();

            final categoryTotals = totalsSnapshot.data!;
            List<PieChartSectionData> sections = [];
            int colorIndex = 0;
            categoryTotals.forEach((category, total) {
              sections.add(PieChartSectionData(
                color: Colors.primaries[colorIndex % Colors.primaries.length],
                value: total,
                title: category,
                radius: 65,
                titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ));
              colorIndex++;
            });

            return Column(
              children: [
                SizedBox(height: 10),
                SizedBox(
                  height: 170,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 25,
                      sectionsSpace: 0,
                      pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      }),
                    ),
                    swapAnimationDuration: Duration(milliseconds: 150),
                    swapAnimationCurve: Curves.linear,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, double>> _getCategoryTotals(List<Map<String, dynamic>> categories) async {
    Map<String, double> totals = {};
    for (var category in categories) {
      double total = await _databaseService.getCategorySpentAmount(category['name']);
      totals[category['name']] = total;
    }
    return totals;
  }

  Widget indicator(Color color, String text, double value, bool isSquare) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 12),
        )
      ],
    );
  }
}

