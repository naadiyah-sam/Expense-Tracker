import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/services/database_service.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  String _amount = '';
  String _category = '';
  DateTime _date = DateTime.now();
  List<String> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final categories = await _databaseService.getCategories();
      setState(() {
        _categories = categories.map((c) => c['name'] as String).toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        print('Submitting transaction: $_amount, $_category, $_date');
        await _databaseService.addTransaction({
          'amount': double.parse(_amount),
          'category': _category,
          'date': _date.toIso8601String(),
        });
        print('Transaction submitted successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction added successfully')),
        );
        Navigator.pop(context, true);  // Pass true to indicate successful addition
      } catch (e) {
        print('Error submitting transaction: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding transaction: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
                      onSaved: (value) => _amount = value!,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    ListTile(
                      title: Text('Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) setState(() => _date = pickedDate);
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitTransaction,
                      child: Text('Add Transaction'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

