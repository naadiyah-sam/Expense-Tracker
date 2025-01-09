import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _fullName = '';
  bool _isLogin = true;
  String _password = ''; // Added _password declaration


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_isLogin) {
          // For simplicity, we'll check if the email and password match
          final storedEmail = prefs.getString('userEmail');
          final storedPassword = prefs.getString('userPassword');
          if (storedEmail == _email && storedPassword == _password) {
            Navigator.pushReplacementNamed(context, '/pin');
          } else {
            throw Exception('Invalid email or password');
          }
        } else {
          // Store user info in SharedPreferences
          await prefs.setString('userEmail', _email);
          await prefs.setString('userPassword', _password);
          await prefs.setString('userFullName', _fullName);
          Navigator.pushReplacementNamed(context, '/pin');
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (!_isLogin)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                  onSaved: (value) => _fullName = value!,
                ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                onSaved: (value) => _email = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Create an account' : 'I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

