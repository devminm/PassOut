import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:base85/base85.dart';
import 'package:cryptography/cryptography.dart';
import 'package:passout/helpers/string.dart';

import '../helpers/secure_storage.dart';

class Account {
  final String subdomain;
  String? _password;
  Completer<void>? _passwordCompleter;

  Future<String> password() async {
    if (_passwordCompleter != null) {
      await _passwordCompleter!.future;
    }
    return _password!;
  }

  String? companyName;
  final String username;
  int _nonce = 1;
  int get nonce => _nonce;
  final int maxLength = 32;
  final Encoding _encoding = Encoding.ascii85;
  static final SecureStorageService _secStorage = SecureStorageService();
  final Base85Codec base85 = Base85Codec(Alphabets.ascii85);
  Account(
      {required this.subdomain,
      this.companyName,
      required this.username,
      }) {
    companyName =
        subdomain.replaceAll("https://www.", "").replaceAll(".com", "").capitalize();
    generatePassword();
  }

  Future<void> generatePassword() async {
    _passwordCompleter = Completer<void>();
    final seed = await _secStorage.read(key: 'seed');
    final hash = await Sha512()
        .hash(utf8.encode(subdomain + username + nonce.toString() + seed!));
    _password = base85.encode(Uint8List.fromList(hash.bytes)).substring(0, maxLength);
    _passwordCompleter!.complete();
  }

  Future<void> newPass() async {
   _nonce++;
   await generatePassword();
  }

  factory Account.fromJson(String json) {
    var jsonData = jsonDecode(json);
    return Account(
      subdomain: jsonData['url'],
      username: jsonData['username'],
    );
  }


   Future<String> toJson() async {
     if (_passwordCompleter != null) {
       await _passwordCompleter!.future;
     }
     return jsonEncode({
      'url': subdomain,
      'username': username,
      'password': _password!,
    });
  }

   Future<String> encryptMetaData({String? secSeed}) async {
   return await encrypt(await toJson(), secSeed: secSeed);
  }

  static Future<String> encrypt(String data, {String? secSeed}) async {
    try {
      final seed = secSeed ?? (await _secStorage.read(key: 'seed'))!;
    final aes = AesGcm.with256bits();
    final pbkdf2 =
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 10000, bits: 256);
    final nonce = aes.newNonce();
    final secretKey =
    await pbkdf2.deriveKeyFromPassword(password: seed, nonce: nonce);
    final encrypted = await aes.encrypt(
    utf8.encode(data),
    secretKey: secretKey,
    nonce: nonce,
    );
    return base64Encode(encrypted.concatenation());
    } catch (e) {
    rethrow;
    }
  }

   Future<Account> decryptMetaData(String encryptedMetaData) async {
      return Account.fromJson(await decrypt(encryptedMetaData));
  }

  static Future<String> decrypt(String encryptedMetaData, {String? secSeed}) async {
    try {
      final aes = AesGcm.with256bits();
      final secStorage = SecureStorageService();
      final pbkdf2 =
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 10000, bits: 256);
      final secretBox = SecretBox.fromConcatenation(
          base64Decode(encryptedMetaData),
          macLength: 16,
          nonceLength: 12);
      final secretKey = await pbkdf2.deriveKeyFromPassword(
          password: (await secStorage.read(key: 'seed'))!,
          nonce: secretBox.nonce);

      final decrypted = await aes.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(decrypted);
    } catch (e) {
      rethrow;
    }
  }
}

class Accounts{
  List<Account> accounts = [];
}

enum Encoding { ascii85, base64 }