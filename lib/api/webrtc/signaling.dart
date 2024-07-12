import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:passout/models/account.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
class Signaling {
  final WebSocketChannel _socket = WebSocketChannel.connect(Uri.parse('ws://der1.ezas.org:8080'));
  late RTCPeerConnection _peerConnection;
  late RTCDataChannel _dataChannel;

  Signaling() {
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

    _peerConnection.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _dataChannel.onMessage = (RTCDataChannelMessage message) {
        print('Received from web: ${message.text}');
      };
    };


    _socket.stream.listen((message) async {
      final data = jsonDecode(utf8.decode(message));

      switch (data['type']) {
        case 'offer':
          await _peerConnection.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
          final answer = await _peerConnection.createAnswer();
          await _peerConnection.setLocalDescription(answer);
          _socket.sink.add(jsonEncode({
            'type': 'answer',
            'sdp': answer.sdp,
          }));
          break;
        case 'answer':
          await _peerConnection.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
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
    String encryptedText = await Account.encrypt(text);
    _dataChannel.send(RTCDataChannelMessage(encryptedText));
  }


  Future<String> decryptText(String text) async {
    return await Account.decrypt(text);
  }
}
