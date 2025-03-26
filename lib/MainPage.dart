import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'NotificationPage.dart';
import 'ProfilePage.dart';
import 'Help.dart';
import 'login_page.dart';
import 'ScanDevicesPage.dart';
import 'EnterCodePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _connectionStatus = "Not Connected";
  List<String> _devices = [];
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _loadStoredDevices();
    _checkExistingConnections();
  }

  /// Load stored devices from SharedPreferences
  Future<void> _loadStoredDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleSpecificDataString = prefs.getString('roleSpecificData');

    if (roleSpecificDataString != null) {
      final roleSpecificData = jsonDecode(roleSpecificDataString);
      List<dynamic> deviceList = roleSpecificData['devices'] ?? [];

      setState(() {
        _devices = deviceList.map<String>((device) => device['name'].toString()).toList();
      });
    }
  }

  /// Check if there is an already connected device and listen for disconnects
  Future<void> _checkExistingConnections() async {
    List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;

    if (devices.isNotEmpty) {
      _connectedDevice = devices.first;
      _setupConnectionListeners(_connectedDevice!);
      setState(() {
        _connectionStatus = "Connected to ${_connectedDevice!.name}";
      });
    }
  }

  /// Listen for connection state changes and update UI
  void _setupConnectionListeners(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        setState(() {
          _connectionStatus = "Not Connected";
          _connectedDevice = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${device.name} disconnected."),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Updates the connection status when a device is connected or disconnected.
  void _updateConnectionStatus(String deviceName) async {
    setState(() {
      _connectionStatus = (deviceName == "Not Connected" || deviceName.isEmpty)
          ? "Not Connected"
          : "Connected to $deviceName";
    });

    if (deviceName != "Not Connected") {
      List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        if (device.name == deviceName) {
          _connectedDevice = device;
          _setupConnectionListeners(_connectedDevice!);
          return;
        }
      }

      // If device is not found, set _connectedDevice to null
      _connectedDevice = null;
    }
  }

  /// Determines navigation based on device availability.
  void _checkAndNavigate(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDeviceName = prefs.getString('deviceName');

    print("Stored Device Name: $storedDeviceName"); // Debug log

    if (storedDeviceName != null && storedDeviceName.isNotEmpty) {
      // Device name exists, go to ScanDevicesPage
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanDevicesPage(
            onDeviceConnected: _updateConnectionStatus,
            initialConnectedDevice: storedDeviceName,
          ),
        ),
      );

      if (result != null) {
        _updateConnectionStatus(result);
      }
    } else {
      // No device name, go to EnterCodePage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EnterCodePage()),
      );
    }
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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotificationPage()));
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
          colors: [
            Colors.black,
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade800
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFullCircleGauge(),
            SizedBox(height: 15),
            Text("Congratulations!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent)),
            SizedBox(height: 5),
            Text("You have worn the scoliosis brace for 38 days.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70)),
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
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
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
      onPressed: () => _checkAndNavigate(context),
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
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Help") {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HelpPage()));
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