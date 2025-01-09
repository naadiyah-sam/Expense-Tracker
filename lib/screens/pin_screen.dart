import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  void _checkExistingPin() async {
    final prefs = await SharedPreferences.getInstance();
    final existingPin = prefs.getString('pin');
    if (existingPin != null) {
      setState(() => _isVerifying = true);
    }
  }

  void _submitPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isVerifying) {
      final storedPin = prefs.getString('pin');
      if (pin == storedPin) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect PIN')));
      }
    } else {
      await prefs.setString('pin', pin);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isVerifying ? 'Verify PIN' : 'Create PIN')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isVerifying ? 'Enter your PIN' : 'Create a 4-digit PIN'),
            SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
              ),
              animationDuration: Duration(milliseconds: 300),
              onCompleted: _submitPin,
              onChanged: (value) => {}, //This line is added to avoid error
            ),
          ],
        ),
      ),
    );
  }
}

