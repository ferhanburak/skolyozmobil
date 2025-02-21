import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'forgot_password_page.dart'; // Importing ForgotPasswordPage for back navigation
import 'login_page.dart';           // Importing LoginPage for success navigation

class ResetPasswordPage extends StatefulWidget {
  final String email;

  /// Constructor to accept email for password reset
  ResetPasswordPage({required this.email});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;

  /// API integration for resetting the password
  Future<void> resetPassword() async {
    if (codeController.text.isEmpty || newPasswordController.text.isEmpty) {
      _showErrorDialog('Lütfen tüm alanları doldurun.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String url = 'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/Auth/reset-password';

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
        print('Şifre sıfırlama başarılı.');
        _showSuccessDialog('Şifre sıfırlama başarılı. Şimdi giriş yapabilirsiniz.');
      } else {
        print('Şifre sıfırlama başarısız: Status Code: ${response.statusCode}');
        print('Hata Detayı: ${response.body}');

        String errorMessage = 'Şifre sıfırlama başarısız.';
        if (response.body.isNotEmpty) {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('Hata oluştu: $e');
      _showErrorDialog('Bağlantı hatası. Lütfen tekrar deneyin.');
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

  /// Success Dialog and Navigate to LoginPage
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
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
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  /// Creates a futuristic dark app bar with a back button.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.cyanAccent),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                (route) => false,
          );
        },
      ),
      title: Text(
        "Şifreyi Sıfırla",
        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  /// Creates the main futuristic body content.
  Widget _buildBody() {
    return Container(
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
      onPressed: isLoading ? null : () {
        resetPassword();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
