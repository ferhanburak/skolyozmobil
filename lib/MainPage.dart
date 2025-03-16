import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'NotificationPage.dart';
import 'ProfilePage.dart';
import 'Help.dart';
import 'login_page.dart';
import 'ScanDevicesPage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _connectionStatus = "Not Connected";

  /// Updates the connection status when a device is connected or disconnected.
  void _updateConnectionStatus(String deviceName) {
    setState(() {
      _connectionStatus = (deviceName == "Not Connected" || deviceName.isEmpty)
          ? "Not Connected"
          : "Connected to $deviceName";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 5,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/scoli_logo.png', height: 100),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
          },
        ),
        _buildSettingsDropdown(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.blueGrey.shade900, Colors.blueGrey.shade800],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFullCircleGauge(),
            SizedBox(height: 15),
            Text("Congratulations!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            SizedBox(height: 5),
            Text("You have worn the scoliosis brace for 38 days.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white70)),
            SizedBox(height: 30),
            _buildConnectionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCircleGauge() {
    return SizedBox(
      height: 250,
      width: 250,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 365,
            startAngle: 270,
            endAngle: 270,
            showLabels: false,
            showTicks: false,
            axisLineStyle: AxisLineStyle(
              thickness: 15,
              color: Colors.grey.shade400,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: 38,
                width: 15,
                color: Colors.cyanAccent,
                enableAnimation: true,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  '38',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                positionFactor: 0.0,
                angle: 90,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        // Navigate to ScanDevicesPage and wait for the result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanDevicesPage(
              onDeviceConnected: _updateConnectionStatus,
              initialConnectedDevice: _connectionStatus == "Not Connected"
                  ? null
                  : _connectionStatus.replaceFirst("Connected to ", ""),
            ),
          ),
        );

        // If a result is returned from ScanDevicesPage (e.g., disconnected), update status
        if (result != null) {
          _updateConnectionStatus(result);
        }
      },
      child: Text(
        _connectionStatus,
        style: TextStyle(
          color: Colors.cyanAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSettingsDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: Colors.cyanAccent),
      onSelected: (value) {
        if (value == "Profile") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Help") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
        } else if (value == "Logout") {
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
            value: "Profile",
            child: Text("Profile", style: TextStyle(color: Colors.cyanAccent)),
          ),
          PopupMenuItem<String>(
            value: "Help",
            child: Text("Help", style: TextStyle(color: Colors.cyanAccent)),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: "Logout",
            child: Row(
              children: [
                Icon(Icons.logout, color: Colors.redAccent),
                SizedBox(width: 10),
                Text("Logout", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
