import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter bindings are initialized
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MINTS - AI',
      theme: ThemeData(primarySwatch: Colors.blue),
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

  void startScan() {
    setState(() {
      scanResultsList.clear();
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        final deviceName = r.device.platformName;
        final advName = r.advertisementData.advName;

        // Filter only Raspberry Pi (e.g., device named 'PiBLE')
        if ((deviceName == 'PiBLE' || advName == 'PiBLE') &&
            !scanResultsList.any((sr) => sr.device.remoteId == r.device.remoteId)) {
          scanResultsList.add(r);
        }
      }
      setState(() {});
    });
    }

  void clearDevices() {
    setState(() {
      scanResultsList.clear();
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
      appBar: AppBar(title: const Text('MINTS - AI')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: startScan,
                  child: const Text('Scan for BLE Devices'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: clearDevices,
                  child: const Text('Clear List'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: scanResultsList.isEmpty
                  ? const Center(child: Text('No devices found.'))
                  : ListView.builder(
                itemCount: scanResultsList.length,
                itemBuilder: (context, index) {
                  final result = scanResultsList[index];
                  final name = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : (result.advertisementData.advName.isNotEmpty
                      ? result.advertisementData.advName
                      : 'Unknown Device');

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        'MAC: ${result.device.remoteId}\nRSSI: ${result.rssi} dBm',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await result.device.connect();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connected to $name')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connection failed: $e')),
                            );
                          }
                        },
                        child: const Text('Connect'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
