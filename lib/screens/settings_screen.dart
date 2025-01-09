import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:finance_tracker/services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  double _monthlyBudget = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadMonthlyBudget();
    _loadDarkModePreference();
  }

  void _loadMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 0;
    });
  }

  void _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _updateMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', _monthlyBudget);
  }

  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please restart the app to apply theme changes')),
    );
  }

  void _exportTransactions() async {
    List<Map<String, dynamic>> transactions = await _databaseService.getTransactions();

    List<List<dynamic>> rows = [
      ['Date', 'Category', 'Amount']
    ];

    for (var transaction in transactions) {
      rows.add([
        transaction['date'],
        transaction['category'],
        transaction['amount'].toString(),
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions_export.csv';
    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transactions exported to $path')),
    );
  }

  void _importTransactions() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String csvString = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvString);

      // Skip the header row
      for (var row in rowsAsListOfValues.skip(1)) {
        await _databaseService.addTransaction({
          'date': row[0],
          'category': row[1],
          'amount': double.parse(row[2]),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transactions imported successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter monthly budget',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _monthlyBudget.toString()),
              onChanged: (value) {
                setState(() {
                  _monthlyBudget = double.tryParse(value) ?? 0;
                });
              },
              onSubmitted: (_) => _updateMonthlyBudget(),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dark Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _exportTransactions,
              child: Text('Export Transactions'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _importTransactions,
              child: Text('Import Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}

