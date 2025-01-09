import 'package:flutter/material.dart';
import 'package:finance_tracker/widgets/budget_progress_chart.dart';
import 'package:finance_tracker/screens/category_screen.dart';
import 'package:finance_tracker/screens/transaction_screen.dart';
import 'package:finance_tracker/screens/articles_screen.dart';
import 'package:finance_tracker/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/widgets/category_spending_chart.dart';
import 'package:finance_tracker/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeContent(),
    CategoryScreen(),
    TransactionScreen(),
    ArticlesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {  // TransactionScreen index
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransactionScreen()),
      );
      if (result == true) {
        // Refresh HomeContent if a transaction was added
        setState(() {
          _screens[0] = HomeContent(key: UniqueKey());
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Transaction'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Articles'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = '';
  double _monthlyBudget = 0;
  double _spentAmount = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('Starting to load data');
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      await _loadMonthlyBudget();
      print('Monthly budget loaded: $_monthlyBudget');
      await _calculateSpentAmount();
      print('Spent amount calculated: $_spentAmount');
      await _loadTransactions();
      print('Transactions loaded: ${_transactions.length}');
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      print('Finished loading data');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 0;
    });
    if (_monthlyBudget == 0) {
      _showBudgetSetupDialog();
    }
  }

  void _showBudgetSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String budgetInput = '';
        return AlertDialog(
          title: Text('Set Monthly Budget'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter your monthly budget'),
            onChanged: (value) => budgetInput = value,
          ),
          actions: [
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                if (budgetInput.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('monthlyBudget', double.parse(budgetInput));
                  setState(() {
                    _monthlyBudget = double.parse(budgetInput);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateSpentAmount() async {
    try {
      double total = await _databaseService.getTotalSpentAmount();
      setState(() {
        _spentAmount = total;
      });
    } catch (e) {
      print('Error calculating spent amount: $e');
      setState(() {
        _errorMessage = 'Error calculating spent amount: ${e.toString()}';
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      List<Map<String, dynamic>> transactions = await _databaseService.getTransactions();
      setState(() {
        _transactions = transactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _errorMessage = 'Error loading transactions: ${e.toString()}';
      });
    }
  }

  void _showQuickAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String amount = '';
        String category = '';
        return AlertDialog(
          title: Text('Quick Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) => amount = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Category'),
                onChanged: (value) => category = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                if (amount.isNotEmpty && category.isNotEmpty) {
                  try {
                    await _databaseService.addTransaction({
                      'amount': double.parse(amount),
                      'category': category,
                      'date': DateTime.now().toIso8601String(),
                    });
                    Navigator.of(context).pop();
                    await _loadData();
                  } catch (e) {
                    print('Error adding transaction: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding transaction: ${e.toString()}')),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showQuickAddTransactionDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          Text('Budget Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: BudgetProgressChart(totalBudget: _monthlyBudget, spentAmount: _spentAmount),
                          ),
                          SizedBox(height: 40),
                          Text('Category Spending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: CategorySpendingChart(),
                          ),
                          SizedBox(height: 30),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Search Transactions',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),
                          Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10),
                          _buildTransactionList(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTransactionList() {
    final filteredTransactions = _transactions.where((transaction) {
      final category = transaction['category'].toString().toLowerCase();
      final amount = transaction['amount'].toString();
      final searchLower = _searchQuery.toLowerCase();
      return category.contains(searchLower) || amount.contains(searchLower);
    }).toList();

    if (filteredTransactions.isEmpty) {
      return Text('No transactions found.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return ListTile(
          title: Text(transaction['category']),
          subtitle: Text(DateTime.parse(transaction['date']).toString().split(' ')[0]),
          trailing: Text('\$${transaction['amount'].toStringAsFixed(2)}'),
        );
      },
    );
  }
}

