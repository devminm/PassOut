import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:passout/api/google/google_drive_api.dart';
import 'package:passout/dump_data.dart';
import 'package:passout/main.dart';
import 'package:passout/models/account.dart';
import 'package:passout/screens/home/home.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cryptography/cryptography.dart';

class Signaling {
  final WebSocketChannel _socket = WebSocketChannel.connect(Uri.parse('wss://der1.ezas.org:8080'));
  late RTCPeerConnection _peerConnection;
  late RTCDataChannel _dataChannel;
  final AesGcm _aes = AesGcm.with256bits();
  final HomeScreenState homeScreenState;
  String? _secretKey;
  set secretKey (String key) {
    _secretKey = key;
  }
  final ValueNotifier<int> connectionStatus = ValueNotifier<int>(0);

  Signaling(this.homeScreenState) {
    _init();
  }

  void _init() async {
    final configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _dataChannel = await _peerConnection.createDataChannel('textChannel', RTCDataChannelInit());

    _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _socket.sink.add(jsonEncode({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      }));
        };
    _peerConnection.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        connectionStatus.value = 1;
      } else{
        connectionStatus.value = 0;
      }
    };
    _peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        connectionStatus.value = 1;
      } else{
        connectionStatus.value = 0;
      }
    };
    _peerConnection.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _dataChannel.onMessage = (RTCDataChannelMessage message) {
        decryptText(message.text).then((value) {
          print('Received from web: ${value}');

          var jsonData = jsonDecode(value);
          if(jsonData['action'] == 'SEND_TO_DATA_CHANNEL_LOGIN'){
            _sendEntries(jsonData['data']);
          }else{
            _createOrUpdateAccountAndSend(jsonData);
          }
        });
      };
    };


    _socket.stream.listen((message) async {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'offer':
          var sdp = RTCSessionDescription(data['offer']['sdp'],data['type']);
          await _peerConnection.setRemoteDescription(sdp);
          final answer = await _peerConnection.createAnswer();
          await _peerConnection.setLocalDescription(answer);
          _socket.sink.add(jsonEncode({
            'type': 'answer',
            'answer': answer.sdp,
          }));
          break;
        case 'answer':
          print(data);
          await _peerConnection.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['type']));
          break;
        case 'candidate':
          final candidate = RTCIceCandidate(
            data['candidate']['candidate'],
            data['candidate']['sdpMid'],
            data['candidate']['sdpMLineIndex'],
          );
          _peerConnection.addCandidate(candidate);
          break;
      }
    });

  }

  Future<void> createOffer() async {
    final offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);
    _socket.sink.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));
  }

  Future<void> sendEncryptedText(String text) async {
    print(text);

    if (_secretKey == null) {
      ScaffoldMessenger.of(homeScreenState.context).showSnackBar(SnackBar(content: Text('No secret key found')));
      return Future.error('No secret key found');
    }
  final secretKey = SecretKey(base64Decode(_secretKey!));
    final nonce = _aes.newNonce();
    final encrypted = await _aes.encrypt(
      utf8.encode(text),
      secretKey: secretKey,
      nonce: nonce,
    );
    return _dataChannel.send(RTCDataChannelMessage(base64Encode(encrypted.concatenation())));
  }


  Future<String> decryptText(String text) async {
    if (_secretKey == null) return Future.error('No secret key found');
    final secretKey = SecretKey(base64Decode(_secretKey!));
    final secretBox = SecretBox.fromConcatenation(
        base64Decode(text),
        macLength: 16,
        nonceLength: 12);
    return _aes.decryptString(
      secretBox,
      secretKey: secretKey);
  }

  Future<void> _sendEntries(String value) async {
    List<Account> accountsForSubdomain = getIt<Accounts>().accounts.where((element) => element.subdomain.contains(value)).toList();
    var maps = [];
    for(var account in accountsForSubdomain){
      maps.add(await account.toJson());
    }
    sendEncryptedText(jsonEncode({"action" : "AUTOFILL_LOGIN", "data" : jsonEncode(maps)}));
  }

  Future<void> _createOrUpdateAccountAndSend(jsonData) async {
    String? subdomain = jsonData['data'];
    String? username = jsonData['username'];
    String? email = jsonData['email'];
    Account? account;
    for(var acc in getIt<Accounts>().accounts){
      if((acc.subdomain == subdomain && (acc.username == username || acc.username == email))){
        account = acc;
        break;
      }
    }
    if(account == null){
      account = Account(subdomain: subdomain ?? "", username: username!.isEmpty ? email ?? "" : username ,);
      getIt<Accounts>().accounts.add(account);
    }else{
      await account.newPass();
    }

    homeScreenState.uploadFile();
    sendEncryptedText(jsonEncode({"action" : "AUTOFILL_REGISTER", "data" : jsonEncode([await account.toJson()])}));
  }
}
