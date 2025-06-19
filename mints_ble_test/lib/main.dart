import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterBluePlus.instance; // Initialize BLE
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scan Button App',
      home: BleScannerPage(),
    );
  }
}

class BleScannerPage extends StatefulWidget {
  @override
  _BleScannerPageState createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final List<ScanResult> scanResultsList = [];
  StreamSubscription<List<ScanResult>>? scanSubscription;
  String devicesText = '';

  void startScan() {
    setState(() {
      scanResultsList.clear();
      devicesText = 'Scanning...';
    });

    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!scanResultsList.any((sr) => sr.device.remoteId == r.device.remoteId)) {
          scanResultsList.add(r);
        }
      }

      setState(() {
        devicesText = scanResultsList.map((r) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : (r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : 'Unknown Device');
          return 'Name: $name\nMAC: ${r.device.remoteId}\nRSSI: ${r.rssi} dBm\n';
        }).join('\n');
      });
    });
  }

  void clearDevices() {
    setState(() {
      scanResultsList.clear();
      devicesText = '';
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BLE Device Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: startScan,
                  child: Text('Scan for BLE Devices'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: clearDevices,
                  child: Text('Clear List'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  devicesText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}