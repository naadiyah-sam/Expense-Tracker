import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    print('Initializing database...');
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print('Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) => print('Database opened successfully'),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    print('Creating database tables...');
    await db.execute('''
    CREATE TABLE transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      budget REAL NOT NULL
    )
    ''');
    print('Database tables created successfully');
  }

  Future<int> addTransaction(Map<String, dynamic> transaction) async {
    try {
      print('Adding transaction: $transaction');
      final db = await instance.database;
      final id = await db.insert('transactions', transaction);
      print('Transaction added successfully with id: $id');
      return id;
    } catch (e) {
      print('Error adding transaction: $e');
      throw Exception('Failed to add transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      print('Fetching transactions...');
      final db = await instance.database;
      final transactions = await db.query('transactions', orderBy: 'date DESC');
      print('Fetched ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<double> getTotalSpentAmount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting total spent amount: $e');
      throw Exception('Failed to get total spent amount: $e');
    }
  }

  Future<double> getCategorySpentAmount(String category) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM transactions WHERE category = ?',
        [category],
      );
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('Error getting category spent amount: $e');
      throw Exception('Failed to get category spent amount: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final db = await instance.database;
      return await db.query('categories');
    } catch (e) {
      print('Error getting categories: $e');
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<int> addCategory(Map<String, dynamic> category) async {
    try {
      final db = await instance.database;
      return await db.insert('categories', category);
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('Failed to add category: $e');
    }
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    try {
      final db = await instance.database;
      return await db.update(
        'categories',
        category,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating category: $e');
      throw Exception('Failed to update category: $e');
    }
  }
}

