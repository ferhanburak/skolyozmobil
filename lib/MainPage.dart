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
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
  final int maxMessages = 10;
  int _animatedListLength = 0;

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
        _animatedListLength--;
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
      int insertIndex = _latestMessages.length - 1;

      if (insertIndex >= 0 && insertIndex <= _animatedListLength) {
        _listKey.currentState!.insertItem(
          insertIndex,
          duration: Duration(milliseconds: 300),
        );
        _animatedListLength++;

        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _scrollController.dispose();
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

  void _updateConnectionStatus(String deviceName) {
    setState(() {
      _connectionStatus = (deviceName == "Not Connected" || deviceName.isEmpty)
          ? "Not Connected"
          : "Connected to $deviceName";
    });
  }

  void _checkAndNavigate(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isPaired = prefs.getBool('isPaired');

    if (isPaired == true) {
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
                  _buildBraceUsageGraphPage(),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
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
              controller: _scrollController,
              initialItemCount: _animatedListLength,
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

  Widget _buildBraceUsageGraphPage() {
    return BraceUsageGraphPage();
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
      children: List.generate(3, (index) {
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

// Add this to the bottom of the file
class BraceUsageGraphPage extends StatefulWidget {
  @override
  _BraceUsageGraphPageState createState() => _BraceUsageGraphPageState();
}

class _BraceUsageGraphPageState extends State<BraceUsageGraphPage> {
  List<Map<String, dynamic>> _usageData = [];
  bool _isLoading = false;

  bool _isWeekView = true;
  int _viewOffset = 0; // 0 = latest week/month, -1 = one step back

  DateTime? _latestAvailableDate;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    setState(() => _isLoading = true);

    final uri = Uri.parse(
        'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/User/brace-usage'
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        print("No token found");
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> result = json.decode(response.body);
        List<Map<String, dynamic>> newData = result
            .map<Map<String, dynamic>>((e) => {
          "date": DateTime.parse(e['date']),
          "minutes": e['minutesUsed']
        })
            .toList();

        newData.sort((a, b) => a["date"].compareTo(b["date"]));

        setState(() {
          _usageData = newData;
          _latestAvailableDate = _usageData.last['date'];
          _isLoading = false;
        });
      } else {
        print("Failed to fetch usage data: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error during usage fetch: $e");
      setState(() => _isLoading = false);
    }
  }

  void _changeOffset(int delta) {
    setState(() {
      _viewOffset += delta;
    });
  }

  List<Map<String, dynamic>> _getDisplayedData() {
    if (_usageData.isEmpty) return [];

    DateTime end;
    DateTime start;

    if (_isWeekView) {
      DateTime base = _latestAvailableDate ?? DateTime.now();
      base = base.subtract(Duration(days: base.weekday - 1));
      start = base.add(Duration(days: 7 * _viewOffset));
      end = start.add(Duration(days: 6));
    } else {
      DateTime base = _latestAvailableDate ?? DateTime.now();
      DateTime monthStart = DateTime(base.year, base.month, 1);
      start = DateTime(monthStart.year, monthStart.month + _viewOffset, 1);
      end = DateTime(start.year, start.month + 1, 0);
    }

    final filtered = _usageData
        .where((entry) =>
    entry['date'].isAfter(start.subtract(Duration(days: 1))) &&
        entry['date'].isBefore(end.add(Duration(days: 1))))
        .toList();

    List<Map<String, dynamic>> filled;

    if (_isWeekView) {
      filled = List.generate(7, (i) {
        final d = start.add(Duration(days: i));
        final existing = filtered.firstWhere(
                (e) => _sameDate(e['date'], d),
            orElse: () => {"date": d, "minutes": 0});
        return existing;
      });
    } else {
      int daysInMonth = end.day;
      filled = List.generate(daysInMonth, (i) {
        final d = DateTime(start.year, start.month, i + 1);
        final existing = filtered.firstWhere(
                (e) => _sameDate(e['date'], d),
            orElse: () => {"date": d, "minutes": 0});
        return existing;
      });
    }

    return filled;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final displayData = _getDisplayedData();
    final maxEntry = displayData.reduce((a, b) =>
    (a['minutes'] as num) > (b['minutes'] as num) ? a : b);
    double maxMinutes = (maxEntry['minutes'] as num).toDouble();
    if (maxMinutes == 0) maxMinutes = 1;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            _changeOffset(-1); // Swipe left → older
          } else if (details.primaryVelocity! > 0) {
            if (_viewOffset < 0) _changeOffset(1); // Swipe right → newer
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isWeekView
                      ? "Week of ${DateFormat('yMMMd').format(displayData.first['date'])}"
                      : DateFormat('MMMM yyyy').format(displayData.first['date']),
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isWeekView = !_isWeekView);
                  },
                  child: Text(
                    _isWeekView ? "Month View" : "Week View",
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                )
              ],
            ),
            SizedBox(height: 6),
            // Total duration
            Text(
              "${(displayData.map((e) => e['minutes']).reduce((a, b) => a + b) ~/ 60)}h ${(displayData.map((e) => e['minutes']).reduce((a, b) => a + b) % 60)}m",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 16),
            // Chart container
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent, width: 1),
              ),
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displayData
                    .map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      Text(
                        (entry == maxEntry)
                            ? "${(entry['minutes'] ~/ 60)}h\n${(entry['minutes'] % 60)}m"
                            : '',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: ((entry['minutes'] as num).toDouble() / maxMinutes * 120)
                            .clamp(10, 120),
                        width: _isWeekView ? 20 : 12,
                        decoration: BoxDecoration(
                          color: entry == maxEntry
                              ? Colors.cyanAccent
                              : Colors.blueGrey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _isWeekView
                            ? DateFormat('E').format(entry['date'])
                            : DateFormat('d').format(entry['date']),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              )
          ],
        ),
      ),
    );
  }
}
