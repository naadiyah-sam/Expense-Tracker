import 'package:flutter/material.dart';
import 'package:finance_tracker/screens/auth_screen.dart';
import 'package:finance_tracker/screens/pin_screen.dart';
import 'package:finance_tracker/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<bool>(
        future: _checkPin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == true) {
              return PinScreen();
            } else {
              return AuthScreen();
            }
          }
          return CircularProgressIndicator();
        },
      ),
      routes: {
        '/pin': (context) => PinScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }

  Future<bool> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pin') != null;
  }
}

