import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:passout/helpers/string.dart';

import '../helpers/secure_storage.dart';

class Account {
  final String url;
  String? password;
  String? companyName;
  final String username;
  final int index;
  final SecureStorageService _secStorage = SecureStorageService();
  Account(
      {required this.url,
      this.companyName,
      required this.username,
      required this.index}) {
    companyName =
        url.replaceAll("https://www.", "").replaceAll(".com", "").capitalize();
    generatePassword();
  }

  Future<void> generatePassword() async {
    final seed = await _secStorage.read(key: 'seed');
    final hash = await Sha512()
        .hash(utf8.encode(url + username + index.toString() + seed!));
    password = base64Encode(hash.bytes);
  }

  factory Account.fromJson(String json) {
    var jsonData = jsonDecode(json);
    return Account(
      url: jsonData['url'],
      username: jsonData['username'],
      index: jsonData['index'],
    );
  }

  String toJson() {
    return jsonEncode({
      'url': url,
      'username': username,
      'index': index,
    });
  }

  Future<String> encryptMetaData({String? secSeed}) async {
    try {
      final seed = secSeed ?? (await _secStorage.read(key: 'seed'))!;
      final aes = AesGcm.with256bits();
      final pbkdf2 =
          Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 10000, bits: 256);
      final nonce = aes.newNonce();
      final secretKey =
          await pbkdf2.deriveKeyFromPassword(password: seed, nonce: nonce);
      final encrypted = await aes.encrypt(
        utf8.encode(toJson()),
        secretKey: secretKey,
        nonce: nonce,
      );
      return base64Encode(encrypted.concatenation());
    } catch (e) {
      rethrow;
    }
  }

  static Future<Account> decryptMetaData(String encryptedMetaData) async {
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
      return Account.fromJson(utf8.decode(decrypted));
    } catch (e) {
      rethrow;
    }
  }

  @override
  String toString() => toJson();
}
