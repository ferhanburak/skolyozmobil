import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Full name için tek TextEditingController
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // API bağlantısı ve register fonksiyonu
  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final String url = 'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/Auth/register/patient';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',  // Accept header'ı eklendi
        },
        body: jsonEncode({
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Kayıt başarılı.');
        _showSuccessDialog('Kayıt başarılı. Şimdi giriş yapabilirsiniz.');

        // Login sayfasına yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // Daha detaylı hata mesajı göster
        print('Kayıt başarısız: Status Code: ${response.statusCode}');
        print('Hata Detayı: ${response.body}');
        _showErrorDialog('Kayıt başarısız: ${response.body}');
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Başarılı'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Kayıt Ol",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: fullNameController,
                  hintText: "Ad ve Soyad",
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: emailController,
                  hintText: "E-posta",
                ),
                SizedBox(height: 10),
                _buildTextField(
                  controller: passwordController,
                  hintText: "Şifre",
                  obscureText: true,
                ),
                SizedBox(height: 20),
                _buildRegisterButton(),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    "Zaten bir hesabın var mı? Giriş Yap",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : () {
        registerUser();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(double.infinity, 50),
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.blue.shade900)
          : Text(
        "Kayıt Ol",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
