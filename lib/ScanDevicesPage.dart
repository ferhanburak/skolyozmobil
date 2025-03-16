import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanDevicesPage extends StatefulWidget {
  final Function(String) onDeviceConnected;
  final String? initialConnectedDevice;

  ScanDevicesPage({required this.onDeviceConnected, required this.initialConnectedDevice});

  @override
  _ScanDevicesPageState createState() => _ScanDevicesPageState();
}

class _ScanDevicesPageState extends State<ScanDevicesPage> {
  List<ScanResult> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  String _connectedDeviceName = "Not Connected";

  @override
  void initState() {
    super.initState();
    if (widget.initialConnectedDevice != null) {
      _connectedDeviceName = widget.initialConnectedDevice!;
      _restoreConnectedDevice(); // Restore the connected device
    }
  }

  /// Restores the connected device when returning from MainPage
  Future<void> _restoreConnectedDevice() async {
    await Future.delayed(Duration(seconds: 1)); // Allow time for reconnection

    List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
    for (var device in devices) {
      if (device.name == _connectedDeviceName) {
        setState(() {
          _connectedDevice = device;
        });
        print("Restored connected device: ${device.name}");
        break;
      }
    }
  }

  /// Starts scanning for Bluetooth devices.
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
          _devices = results.where((r) => r.device.name.isNotEmpty).toList();
        });
      });

      await Future.delayed(Duration(seconds: 10));
      setState(() => _isScanning = false);
      FlutterBluePlus.stopScan();
    } else {
      print("Bluetooth scan permission denied.");
    }
  }

  /// Handles device selection and connection.
  void _connectToDevice(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();

    try {
      await device.connect();

      // Listen to incoming data
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              print("Data from Device: ${String.fromCharCodes(value)}");
            });
          }
        }
      }

      // Update UI with connected device
      setState(() {
        _connectedDevice = device;
        _connectedDeviceName = device.name;
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

  /// Handles device disconnection.
  void _disconnectDevice() async {
    if (_connectedDevice == null) {
      print("No device to disconnect");
      return;
    }

    try {
      await _connectedDevice!.disconnect();
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

      print("Device disconnected successfully.");

    } catch (e) {
      print("Disconnection error: $e");
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Scan Devices",
          style: TextStyle(color: Colors.cyanAccent), // Set title color to cyan
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.cyanAccent), // Set back button color to cyan
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
                    title: Text(
                      device.name,
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
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
