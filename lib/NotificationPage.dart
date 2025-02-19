import 'package:flutter/material.dart';
import 'ProfilePage.dart';
import 'Help.dart';

class NotificationPage extends StatelessWidget {
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.cyanAccent),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.cyanAccent),
          onPressed: () {},
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildNotificationTable(),
          ],
        ),
      ),
    );
  }

  /// Creates a futuristic table for notifications.
  Widget _buildNotificationTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
        },
        children: [
          _buildTableRow("Notification", "Date", isHeader: true),
          _buildTableRow("Device Disconnected", "02/18/2025"),
          _buildTableRow("Battery Low", "02/17/2025"),
          _buildTableRow("New Firmware Available", "02/16/2025"),
          _buildTableRow("Device Connected", "02/15/2025"),
        ],
      ),
    );
  }

  /// Creates a futuristic row for the table.
  TableRow _buildTableRow(String text1, String text2, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.blueGrey.shade900 : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            text1,
            style: TextStyle(
              color: isHeader ? Colors.cyanAccent : Colors.white70,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 18 : 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            text2,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHeader ? Colors.cyanAccent : Colors.white70,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 18 : 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Creates a futuristic settings dropdown menu.
  Widget _buildSettingsDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: Colors.cyanAccent),
      onSelected: (value) {
        if (value == "Profil") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Yardım") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
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
        ];
      },
    );
  }
}
