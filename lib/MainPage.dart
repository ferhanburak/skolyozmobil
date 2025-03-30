import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'NotificationPage.dart';
import 'ProfilePage.dart';
import 'Help.dart';
import 'login_page.dart';
import 'ScanDevicesPage.dart';
import 'EnterCodePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_service.dart' as my_ble;

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _connectionStatus = "Not Connected";
  List<String> _devices = [];
  BluetoothDevice? _connectedDevice;

  PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> _latestMessages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final int maxMessages = 10;

  double _daysWorn = 0;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadStoredDevices();
    _fetchBraceUsageDays();

    _statusSubscription = my_ble.MyBluetoothService().statusStream.listen((entry) {
      if (!mounted || _listKey.currentState == null) return;

      if (_latestMessages.length >= maxMessages) {
        final removed = _latestMessages.removeAt(0);
        _listKey.currentState!.removeItem(
          0,
              (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: _buildLiveMessage(removed),
          ),
          duration: Duration(milliseconds: 300),
        );
      }

      _latestMessages.add(entry);
      _listKey.currentState!.insertItem(
        _latestMessages.length - 1,
        duration: Duration(milliseconds: 300),
      );
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchBraceUsageDays() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('deviceId');

    if (deviceId != null && deviceId.isNotEmpty) {
      final url = Uri.parse(
        'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/Device/usage/$deviceId',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          double days = (data['hours'] ?? 0) / 12;

          if (mounted) {
            setState(() {
              _daysWorn = days;
            });
          }
        }
      } catch (e) {
        print("Error fetching usage data: $e");
      }
    }
  }

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

  void _updateConnectionStatus(String deviceName) async {
    setState(() {
      _connectionStatus = (deviceName == "Not Connected" || deviceName.isEmpty)
          ? "Not Connected"
          : "Connected to $deviceName";
    });
  }

  void _checkAndNavigate(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDeviceName = prefs.getString('deviceName');

    if (storedDeviceName != null && storedDeviceName.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanDevicesPage(
            onDeviceConnected: _updateConnectionStatus,
          ),
        ),
      );

      if (result != null) {
        _updateConnectionStatus(result);
      }
    } else {
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
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
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildGaugePage(),
                  _buildLiveDataPage(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(child: _buildConnectionButton(context)),
          ),
        ],
      ),
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

  Widget _buildGaugePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFullCircleGauge(),
          SizedBox(height: 15),
          Text("Congratulations!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          SizedBox(height: 5),
          Text("You have worn the scoliosis brace for ${_daysWorn.toStringAsFixed(0)} days.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70)),
          SizedBox(height: 30),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildLiveDataPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors, size: 80, color: Colors.cyanAccent),
          SizedBox(height: 20),
          Text("Live Sensor Data",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Container(
            height: 200,
            width: 320,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade800,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _latestMessages.length,
              itemBuilder: (context, index, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: _buildLiveMessage(_latestMessages[index]),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildLegend("✅", "Sent"),
                _buildLegend("📦", "Stored"),
                _buildLegend("❌", "Error"),
              ],
            ),
          ),
          SizedBox(height: 30),
          _buildPageIndicator(),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildLegend(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: 18)),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildLiveMessage(Map<String, String> entry) {
    String emoji = entry["status"] == "success"
        ? "✅"
        : entry["status"] == "stored"
        ? "📦"
        : "❌";
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        "${entry["msg"]} $emoji",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.cyanAccent,
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
                value: _daysWorn,
                width: 15,
                color: Colors.cyanAccent,
                enableAnimation: true,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  _daysWorn.toStringAsFixed(0),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else if (value == "Help") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
        } else if (value == "Logout") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.blueGrey.shade800,
                title: Text("Confirm Logout", style: TextStyle(color: Colors.white)),
                content: Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    child: Text("Cancel", style: TextStyle(color: Colors.cyanAccent)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text("Logout", style: TextStyle(color: Colors.redAccent)),
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.of(context).pop();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                            (route) => false,
                      );
                    },
                  ),
                ],
              );
            },
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

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          height: 10,
          width: isActive ? 12 : 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.cyanAccent : Colors.white30,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
