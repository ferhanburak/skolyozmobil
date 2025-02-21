import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ResetPasswordPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  /// Email validation function
  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
        r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  /// API integration for requesting password reset
  Future<void> requestPasswordReset() async {
    if (emailController.text.isEmpty) {
      _showErrorDialog('Lütfen e-posta adresini girin.');
      return;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showErrorDialog('Lütfen geçerli bir e-posta adresi girin.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String url = 'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/Auth/forgot-password';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        print('Şifre sıfırlama isteği gönderildi.');

        /// Show Success Dialog and Navigate to ResetPasswordPage
        _showSuccessDialog('Şifre sıfırlama isteği gönderildi. Lütfen e-postanızı kontrol edin.');
      } else {
        print('İstek başarısız: Status Code: ${response.statusCode}');
        print('Hata Detayı: ${response.body}');

        String errorMessage = 'İstek başarısız.';
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

  /// Success Dialog and Navigate to ResetPasswordPage
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

              /// Navigate to ResetPasswordPage with the entered email
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordPage(email: emailController.text.trim()),
                ),
              );
            },
            child: Text('Devam Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Icon(Icons.lock_outline, size: 100, color: Colors.cyanAccent),
                SizedBox(height: 20),
                Text(
                  "Şifremi Unuttum",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                _buildTextField(
                  controller: emailController,
                  hintText: "E-posta",
                  icon: Icons.email,
                ),
                SizedBox(height: 30),
                _buildRequestButton(),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Geri Dön",
                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Futuristic Text Field with consistent neon cyan borders
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
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

  /// Modern, futuristic Request button
  Widget _buildRequestButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        requestPasswordReset();
      },
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
        "Şifre Sıfırlama İsteği Gönder",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
