import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const TestOtgApp());
}

class TestOtgApp extends StatelessWidget {
  const TestOtgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEST_OTG_v1',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String deviceStatus = 'Disconnected';
  String deviceName = 'Unknown';
  String receivedData = '';
  UsbPort? _port;

  Future<void> connectDevice() async {
    setState(() {
      deviceStatus = 'Searching for USB device...';
      deviceName = 'Unknown';
    });

    List<UsbDevice> devices = await UsbSerial.listDevices();
    for (var device in devices) {
      if ((device.productName ?? '').toLowerCase().contains("stm32")) {
        UsbPort? port = await device.create();
        if (port != null) {
          bool openResult = await port.open();
          if (openResult) {
            await port.setPortParameters(115200, 8, 1, UsbPort.PARITY_NONE);
            _port = port;

            setState(() {
              deviceStatus = 'Connected';
              deviceName = device.productName ?? 'STM32WB55';
            });

            port.inputStream?.listen((Uint8List data) {
              setState(() {
                receivedData += String.fromCharCodes(data);
              });
            });

            return;
          }
        }
      }
    }

    setState(() {
      deviceStatus = 'STM32 not found';
      deviceName = 'None';
    });
  }

  Future<void> disconnectDevice() async {
    if (_port != null) {
      await _port!.close();
      _port = null;

      setState(() {
        deviceStatus = 'Disconnected';
        deviceName = 'Unknown';
      });
    }
  }

  void sendData(String command) async {
    if (_port == null) {
      debugPrint('No USB connection');
      return;
    }

    try {
      await _port!.write(Uint8List.fromList(command.codeUnits));
      debugPrint("Sent: $command");
    } catch (e) {
      debugPrint("Failed to send: $e");
    }
  }

  void clearReceivedData() {
    setState(() {
      receivedData = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('TEST_OTG_v1')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: connectDevice,
                  child: const Text(
                    'CONNECT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: disconnectDevice,
                  child: const Text(
                    'DISCONNECT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Device Name: $deviceName'),
            Text('Status: $deviceStatus'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => sendData('1'),
                  child: const Text('LED ON'),
                ),
                ElevatedButton(
                  onPressed: () => sendData('0'),
                  child: const Text('LED OFF'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DATA:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: screenHeight * 0.5,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: SingleChildScrollView(
                child: Text(
                  receivedData,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: clearReceivedData,
                child: const Text(
                  'CLEAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
