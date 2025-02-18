import 'package:flutter/material.dart';
import 'NotificationPage.dart';
import 'ProfilePage.dart';
import 'Help.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'), // Add your logo here
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          _buildSettingsDropdown(context),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 100, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              "38",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "You've been wearing the scoliosis brace for 38 days!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: Text(
                "Connected to the SmartScoliBrace",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: Colors.black),
      onSelected: (value) {
        if (value == "Profil") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Yardım") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: "Profil",
            child: Text("Profil"),
          ),
          PopupMenuItem<String>(
            value: "Yardım",
            child: Text("Yardım"),
          ),
        ];
      },
    );
  }
}
