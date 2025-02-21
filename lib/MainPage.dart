import 'package:flutter/material.dart';
import 'NotificationPage.dart';
import 'ProfilePage.dart';
import 'Help.dart';
import 'login_page.dart'; // Import LoginPage for navigation

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  /// Creates a futuristic dark app bar with settings & notifications.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 5,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/scoli_logo.png', // Ensure this logo is in the assets folder
          height: 100,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
        ),
        _buildSettingsDropdown(context),
      ],
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
            Colors.black, // Dark futuristic background
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade800,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 120, color: Colors.cyanAccent), // Futuristic fire icon
            SizedBox(height: 15),
            Text(
              "38",
              style: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 15),
            Text(
              "You've been wearing the scoliosis brace for 38 days!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 30),
            _buildConnectionButton(),
          ],
        ),
      ),
    );
  }

  /// Creates a futuristic connection button.
  Widget _buildConnectionButton() {
    return TextButton(
      onPressed: () {},
      child: Text(
        "Connected to the SmartScoliBrace",
        style: TextStyle(
          color: Colors.cyanAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  /// Creates a futuristic settings dropdown menu with Logout option.
  Widget _buildSettingsDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: Colors.cyanAccent),
      onSelected: (value) {
        if (value == "Profil") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Yardım") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
        } else if (value == "Çıkış Yap") {
          // Navigate to LoginPage when Logout is selected
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
          );
        }
      },
      color: Colors.blueGrey.shade900,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: "Profil",
            child: Text("Profil", style: TextStyle(color: Colors.cyanAccent)),
          ),
          PopupMenuItem<String>(
            value: "Yardım",
            child: Text("Yardım", style: TextStyle(color: Colors.cyanAccent)),
          ),
          PopupMenuDivider(), // Adds a separator
          PopupMenuItem<String>(
            value: "Çıkış Yap",
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
