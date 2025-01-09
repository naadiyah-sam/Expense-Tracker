import 'package:flutter/material.dart';
import 'package:finance_tracker/widgets/category_budget_chart.dart';
import 'package:finance_tracker/services/database_service.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final categories = await _databaseService.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Category Name'),
              onSubmitted: (value) async {
                Navigator.of(context).pop();
                try {
                  await _databaseService.addCategory({
                    'name': value,
                    'budget': 0,
                  });
                  _loadCategories();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding category: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editCategory(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Category Name'),
              controller: TextEditingController(text: category['name']),
              onChanged: (value) async {
                try {
                  await _databaseService.updateCategory(category['id'], {'name': value});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category name: ${e.toString()}')),
                  );
                }
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Budget'),
              controller: TextEditingController(text: category['budget'].toString()),
              keyboardType: TextInputType.number,
              onChanged: (value) async {
                try {
                  await _databaseService.updateCategory(category['id'], {'budget': double.parse(value)});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category budget: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
              _loadCategories();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Category Management')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CategoryBudgetChart(),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return ListTile(
                  title: Text(category['name']),
                  subtitle: Text('Budget: \$${category['budget'].toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editCategory(category),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: Icon(Icons.add),
      ),
    );
  }
}

