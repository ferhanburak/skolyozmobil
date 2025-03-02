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

  /// Creates a futuristic dark app bar with only a back button and title.
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
      title: Text(
        "Bildirimler",
        style: TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
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
            Colors.black, // Dark futuristic background
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade800,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            _buildNotificationTable(),
          ],
        ),
      ),
    );
  }

  /// Creates a futuristic table for notifications with proper spacing and visible border corners.
  Widget _buildNotificationTable() {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Table(
          columnWidths: {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
          },
          children: _buildTableRows(),
        ),
      ),
    );
  }

  /// Generates the table rows dynamically and removes the line from the last row.
  List<TableRow> _buildTableRows() {
    List<Map<String, String>> notifications = [
      {"Bildirim": "Cihaz Bağlantısı Kesildi", "Tarih": "02/18/2025"},
      {"Bildirim": "Düşük Pil Seviyesi", "Tarih": "02/17/2025"},
      {"Bildirim": "Yeni Yazılım Güncellemesi", "Tarih": "02/16/2025"},
      {"Bildirim": "Cihaz Bağlandı", "Tarih": "02/15/2025"},
    ];

    List<TableRow> rows = [
      _buildTableRow("Bildirim", "Tarih", isHeader: true), // Header row
    ];

    for (int i = 0; i < notifications.length; i++) {
      bool isLastRow = i == notifications.length - 1;
      rows.add(_buildTableRow(notifications[i]["Bildirim"]!, notifications[i]["Tarih"]!, isLastRow: isLastRow));
    }

    return rows;
  }

  /// Creates a futuristic row for the table.
  TableRow _buildTableRow(String text1, String text2, {bool isHeader = false, bool isLastRow = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.blueGrey.shade800 : Colors.transparent,
        border: isLastRow
            ? null // No bottom border for the last row
            : Border(bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.5))),
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
}
