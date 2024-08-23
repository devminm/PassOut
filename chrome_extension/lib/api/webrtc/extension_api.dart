
import 'dart:convert';

import 'package:chrome_extension/chrome.dart';
import 'package:chrome_extension/runtime.dart';
import 'package:chrome_extension/tabs.dart' as ch_tabs;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';

class ExtensionApi {
final ChromeRuntime r = chrome.runtime;
final ChromeTabs t = chrome.tabs;
final ValueNotifier<int> connectionStatus = ValueNotifier<int>(0);

ExtensionApi(){
  sendToBackground("CHECK_CONNECTION");
  r.onMessage.listen((event) {
    final message = event.message;
    print('Message from background: ${message}');
    var data = jsonDecode(message.toString());
    try{
      connectionStatus.value = data['connection'] as int;
      print('Connection success status: ${connectionStatus.value}');
    }catch(e){
      print('Error: $e');
    }
  });
}
  Future<void> sendToContent(String action, {dynamic data}) async {
    var dataToSend = {"target":"content","action" : action, "data" : data ?? {}};
    t.query(ch_tabs.QueryInfo(active: true, currentWindow: true)).then((tabs) {
      if (tabs.isNotEmpty) {
        t.sendMessage(tabs[0].id!, dataToSend, ch_tabs.SendMessageOptions()).then((response) {
          var data = jsonDecode(response.toString());
          print('Response: $data');
          try{
              connectionStatus.value = data['connection'] as int;
              print('Connection success status: ${connectionStatus.value}');
          }catch(e){
            print('Error: $e');
          }
        }).catchError((error) {
          print('Error: $error');
        });
      }
    }).catchError((error) {
      print('Error: $error');
    });

  }

  Future<void> sendToBackground(String action, {dynamic data}) async {
    var dataToSend = {"target":"background", "action" : action, "data" : data ?? {}};
    r.sendMessage(r.id,dataToSend, SendMessageOptions()).then((response) {
      print("Raw response from background: $response");
      var data = jsonDecode(response.toString());
      print('Response: $data');
      try{
        connectionStatus.value = data['connection'] as int;
        print('Connection success status: ${connectionStatus.value}');
      }catch(e){
        print('Error: $e');
      }
    }).catchError((error) {
      print('Error: $error');
    });
  }


void createOffer() {
  if (connectionStatus.value == 1) {
    sendToBackground('RESET_WEBRTC');
  } else {
    sendToBackground('START_WEBRTC');
  }
}
}
