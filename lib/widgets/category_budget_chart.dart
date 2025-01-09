import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryBudgetChart extends StatefulWidget {
  @override
  _CategoryBudgetChartState createState() => _CategoryBudgetChartState();
}

class _CategoryBudgetChartState extends State<CategoryBudgetChart> {
  final DatabaseService _databaseService = DatabaseService.instance;
  double _totalBudget = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalBudget();
  }

  void _loadTotalBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalBudget = prefs.getDouble('monthlyBudget') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseService.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final categories = snapshot.data!;
        double totalCategoryBudget = categories.fold(0, (sum, category) => sum + (category['budget'] as double));

        List<PieChartSectionData> sections = categories.map((category) {
          double percentage = ((category['budget'] as double) / _totalBudget) * 100;
          return PieChartSectionData(
            color: Colors.primaries[categories.indexOf(category) % Colors.primaries.length],
            value: category['budget'] as double,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();

        if (totalCategoryBudget < _totalBudget) {
          sections.add(PieChartSectionData(
            color: Colors.grey,
            value: _totalBudget - totalCategoryBudget,
            title: 'Unallocated',
            radius: 100,
            titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ));
        }

        return Column(
          children: [
            SizedBox(height: 20),
            Text('Category Budget Allocation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 0,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Total Budget: \$${_totalBudget.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Allocated: \$${totalCategoryBudget.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

