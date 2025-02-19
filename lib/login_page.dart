import 'package:flutter/material.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'MainPage.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          _buildLoginForm(context),
        ],
      ),
    );
  }

  /// Creates a futuristic dark background with a gradient effect.
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black, // Deep black for a high-tech look
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade800,
          ],
        ),
      ),
    );
  }

  /// Creates the login form with futuristic UI elements.
  Widget _buildLoginForm(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/scoli_logo.png',
              height: 150, // Increased logo size
            ),
            SizedBox(height: 30), // More spacing for a clean look
            Text(
              "Giriş Yap",
              style: TextStyle(
                color: Colors.cyanAccent, // Futuristic neon color
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 25),
            _buildTextField(hintText: "E-posta", icon: Icons.email),
            SizedBox(height: 15),
            _buildTextField(hintText: "Şifre", obscureText: true, icon: Icons.lock),
            SizedBox(height: 30),
            _buildLoginButton(context),
          ],
        ),
      ),
    );
  }

  /// Custom futuristic text field with neon glow effect.
  Widget _buildTextField({required String hintText, bool obscureText = false, required IconData icon}) {
    return TextField(
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent), // Icon with neon effect
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1), // Slight transparency for futuristic UI
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.7)), // Neon border effect
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.cyanAccent, width: 2), // Stronger glow when focused
        ),
      ),
    );
  }

  /// Creates a modern, glowing login button.
  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainPage()));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyanAccent.withOpacity(0.8), // Neon glow effect
        foregroundColor: Colors.black,
        shadowColor: Colors.cyanAccent.withOpacity(0.5), // Glowing effect
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(double.infinity, 55),
      ),
      child: Text(
        "Giriş Yap",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
