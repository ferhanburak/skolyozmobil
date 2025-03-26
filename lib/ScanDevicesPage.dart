import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';

class ScanDevicesPage extends StatefulWidget {
  final Function(String) onDeviceConnected;
  final String? initialConnectedDevice;

  ScanDevicesPage({
    required this.onDeviceConnected,
    required this.initialConnectedDevice,
  });

  @override
  _ScanDevicesPageState createState() => _ScanDevicesPageState();
}

class _ScanDevicesPageState extends State<ScanDevicesPage> {
  List<ScanResult> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  String _connectedDeviceName = "Not Connected";
  String _bluetoothBuffer = "";
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final RegExp validSensorNameRegex = RegExp(r'^FSR\d+$');
  final Map<Guid, StreamSubscription<List<int>>> _notifySubscriptions = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialConnectedDevice != null) {
      _connectedDeviceName = widget.initialConnectedDevice!;
      _restoreConnectedDevice();
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.wifi) {
        _trySendingUnsentData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _cancelAllNotifySubscriptions();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _cancelAllNotifySubscriptions() {
    for (var sub in _notifySubscriptions.values) {
      sub.cancel();
    }
    _notifySubscriptions.clear();
  }

  Future<void> _restoreConnectedDevice() async {
    await Future.delayed(Duration(seconds: 1));
    List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
    for (var device in devices) {
      if (device.name == _connectedDeviceName) {
        BluetoothConnectionState state = await device.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
          _setupConnectionListeners(device);
          setState(() => _connectedDevice = device);
        } else {
          setState(() {
            _connectedDevice = null;
            _connectedDeviceName = "Not Connected";
          });
        }
        break;
      }
    }
  }

  Future<void> _startScan() async {
    var status = await Permission.bluetoothScan.request();
    if (status.isGranted) {
      setState(() {
        _isScanning = true;
        _devices.clear();
      });

      FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _devices = results
              .where((r) =>
          r.device.name.isNotEmpty &&
              r.device.name != _connectedDeviceName)
              .toList();
        });
      });

      await Future.delayed(Duration(seconds: 10));
      setState(() => _isScanning = false);
      FlutterBluePlus.stopScan();
    } else {
      print("Bluetooth scan permission denied.");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();

    try {
      await device.connect();
      BluetoothConnectionState state = await device.connectionState.first;
      if (state != BluetoothConnectionState.connected) return;

      _setupConnectionListeners(device);

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);

            // Cancel any previous subscription
            _notifySubscriptions[characteristic.uuid]?.cancel();

            // Create a new subscription and store it
            final sub = characteristic.value.listen((value) {
              _handleIncomingData(value);
            });

            _notifySubscriptions[characteristic.uuid] = sub;
          }
        }
      }

      setState(() {
        _connectedDevice = device;
        _connectedDeviceName = device.name;
        _devices.removeWhere((d) => d.device.id == device.id);
      });

      widget.onDeviceConnected(device.name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to ${device.name} successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Connection error: $e");
    }
  }

  void _setupConnectionListeners(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _cancelAllNotifySubscriptions();
        setState(() {
          _connectedDevice = null;
          _connectedDeviceName = "Not Connected";
        });
        widget.onDeviceConnected("Not Connected");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${device.name} disconnected."),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _handleIncomingData(List<int> value) {
    String newData = String.fromCharCodes(value);
    _bluetoothBuffer += newData;

    if (_bluetoothBuffer.contains("\n")) {
      List<String> messages = _bluetoothBuffer.split("\n");

      for (int i = 0; i < messages.length - 1; i++) {
        String rawMessage = messages[i].trim();
        print("Received: $rawMessage");

        if (rawMessage.contains(":")) {
          List<String> parts = rawMessage.split(":");
          if (parts.length == 2) {
            String sensorName = parts[0].trim();
            String rawValue = parts[1].trim();
            int? sensorValue = int.tryParse(rawValue);

            if (!validSensorNameRegex.hasMatch(sensorName)) {
              print("❌ Invalid sensor name: $sensorName");
              continue;
            }

            if (sensorValue == null) {
              print("❌ Invalid sensor value: $rawValue");
              continue;
            }

            _sendSensorData(sensorName, sensorValue);
          }
        }
      }

      _bluetoothBuffer = messages.last;
    }
  }

  Future<void> _sendSensorData(String sensorName, int value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) return;

    final timeStamp = DateTime.now()
        .toUtc()
        .subtract(Duration(seconds: 2))
        .toIso8601String()
        .split('.')
        .first + 'Z';

    final isWifi = await _isWifiConnected();

    final dataPoint = {
      "timeStamp": timeStamp,
      "value": value.toDouble(),
    };

    if (isWifi) {
      final url = Uri.parse(
        'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/SensorData/by-name',
      );

      final data = {
        "sensorName": sensorName,
        "value": value.toDouble(),
        "timeStamp": timeStamp,
      };

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(data),
        );

        print("📡 Sent to single endpoint: ${response.statusCode} ${response.body}");

        if (response.statusCode != 200 && response.statusCode != 201) {
          await _storeUnsentData(sensorName, dataPoint);
        }

        await _sendUnsentSensorData(token);
      } catch (e) {
        print("❌ Error sending single data, storing locally: $e");
        await _storeUnsentData(sensorName, dataPoint);
      }
    } else {
      await _storeUnsentData(sensorName, dataPoint);
      print("📦 Stored locally (offline): $sensorName");
    }
  }

  Future<void> _storeUnsentData(String sensorName, Map<String, dynamic> dataPoint) async {
    if (!validSensorNameRegex.hasMatch(sensorName)) {
      print("❌ Refusing to store invalid sensor name: $sensorName");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String key = "unsent_$sensorName";
    List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(dataPoint));
    await prefs.setStringList(key, existing);
    print("📦 Stored unsent data locally for $sensorName");
  }

  Future<void> _trySendingUnsentData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token != null && token.isNotEmpty) {
      await _sendUnsentSensorData(token);
    }
  }

  Future<void> _sendUnsentSensorData(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('unsent_'));

    for (String key in keys) {
      String sensorName = key.replaceFirst('unsent_', '');

      if (!validSensorNameRegex.hasMatch(sensorName)) {
        print("🗑️ Deleting invalid stored key: $sensorName");
        await prefs.remove(key);
        continue;
      }

      List<String> rawDataList = prefs.getStringList(key) ?? [];
      if (rawDataList.isEmpty) continue;

      List<Map<String, dynamic>> dataPoints = rawDataList
          .map((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>)
          .toList();

      bool success = await _sendBatchData(sensorName, dataPoints, token);
      if (success) {
        await prefs.remove(key);
        print("✅ Sent and cleared local data for $sensorName");
      }
    }
  }

  Future<bool> _sendBatchData(String sensorName, List<Map<String, dynamic>> dataPoints, String token) async {
    final url = Uri.parse(
      'https://scolisensemvpserver-azhpd3hchqgsc8bm.germanywestcentral-01.azurewebsites.net/api/SensorData/batch/by-name',
    );

    final payload = {
      "sensorName": sensorName,
      "dataPoints": dataPoints,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      print("📡 Batch response ${response.statusCode}: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Batch send error: $e");
      return false;
    }
  }

  Future<bool> _isWifiConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  void _disconnectDevice() async {
    if (_connectedDevice == null) return;
    try {
      await _connectedDevice!.disconnect();
      _cancelAllNotifySubscriptions();
      setState(() {
        _connectedDevice = null;
        _connectedDeviceName = "Not Connected";
      });
      widget.onDeviceConnected("Not Connected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Disconnected successfully!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print("Disconnection error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Devices", style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.blueGrey.shade900, Colors.blueGrey.shade800],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            if (_connectedDevice != null) _buildConnectedDeviceTile(),
            _isScanning
                ? CircularProgressIndicator(color: Colors.cyanAccent)
                : ElevatedButton(
              onPressed: _startScan,
              child: Text("Scan Devices", style: TextStyle(color: Colors.cyanAccent)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
            Expanded(
              child: _devices.isEmpty
                  ? Center(child: Text("No devices found", style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = _devices[index].device;
                  return ListTile(
                    title: Text(device.name, style: TextStyle(color: Colors.cyanAccent)),
                    subtitle: Text(device.id.toString(), style: TextStyle(color: Colors.white70)),
                    onTap: () => _connectToDevice(device),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceTile() {
    return Card(
      color: Colors.blueGrey.shade900,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(Icons.bluetooth_connected, color: Colors.greenAccent),
        title: Text(
          _connectedDeviceName,
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Connected", style: TextStyle(color: Colors.white70)),
        trailing: TextButton(
          onPressed: _disconnectDevice,
          child: Text("Disconnect", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
