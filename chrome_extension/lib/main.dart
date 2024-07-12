import 'package:chrome_extension/api/webrtc/signaling.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

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

  late Signaling _signaling;
  final String message = "";

  @override
  void initState() {
    super.initState();
    _signaling = Signaling();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Click Counter'),

      ),
      body: Center(
        child: Text(
          'You have pushed the button this many times:',
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: (){
              _signaling.sendText("Hi from extension");
            },
            tooltip: 'Increment',
            child: const Icon(Icons.send_outlined),
          ),

          SizedBox(height: 20,),
          FloatingActionButton(
            onPressed: (){
              _signaling.createOffer();
            },
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
