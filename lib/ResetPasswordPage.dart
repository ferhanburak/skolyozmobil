import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'forgot_password_page.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  ResetPasswordPage({required this.email});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> resetPassword() async {
    if (codeController.text.isEmpty || newPasswordController.text.isEmpty) {
      _showErrorDialog('Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String url =
        'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/Auth/reset-password';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'code': codeController.text.trim(),
          'newPassword': newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('Şifre sıfırlama başarılı.');
      } else {
        _showErrorDialog('Şifre sıfırlama başarısız.');
      }
    } catch (e) {
      _showErrorDialog('Bağlantı hatası.');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Başarılı'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
            );
          },
        ),
        title: Text(
          "Şifreyi Sıfırla",
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade800,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 100, color: Colors.cyanAccent),
                SizedBox(height: 20),
                Text(
                  "Şifreyi Sıfırla",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: codeController,
                  hintText: "Kod",
                  icon: Icons.vpn_key,
                ),
                SizedBox(height: 15),
                _buildTextField(
                  controller: newPasswordController,
                  hintText: "Yeni Şifre",
                  obscureText: true,
                  icon: Icons.lock,
                ),
                SizedBox(height: 30),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.blueGrey.shade800,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : resetPassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: Size(double.infinity, 50),
        shadowColor: Colors.cyanAccent.withOpacity(0.5),
        elevation: 10,
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.black)
          : Text(
        "Şifreyi Sıfırla",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
