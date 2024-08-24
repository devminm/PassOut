
import 'dart:convert';

import 'package:chrome_extension/chrome.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'api/webrtc/extension_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String _title = 'Flutter Stateful Clicker Counter';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        // useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  late ExtensionApi _extensionApi;

  @override
  void initState() {
    super.initState();
    _extensionApi = ExtensionApi();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure hash-based password manager'),

      ),
      body: Center(
        child: FutureBuilder<String>(
          future: getKey(),
          builder: (context,message) {
            print("kire khar ${message.data}");
            if (message.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            _extensionApi.sendToBackground("KEY", data: message.data);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: message.data!,
                    size: 200.0,
                    padding: EdgeInsets.all(20),
                  ),
                  const SizedBox(height: 20,),
                  const Text("1. Scan the QR code with your mobile device\n2. Press the button to connect to the mobile app."),
                ],
              ),
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _extensionApi.createOffer();
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _extensionApi.connectionStatus,
          builder: (context, value, child) {
            return Icon(value == 1 ? Icons.done_outlined : Icons.connect_without_contact_outlined,
            color : value == 1 ? Colors.green : Colors.red,);
          },
        )
      ),
    );
  }

   Future<String> getKey() async {
    var key = await chrome.storage.local.get(["aes_key"]);
    if (key.containsKey("aes_key")) {
      return key["aes_key"];
    }
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKey();
    return base64Encode((await secretKey.extract()).bytes);
  }
}

