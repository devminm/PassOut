import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passout/dump_data.dart';

void main() {
  // test aes gcm cryptography
  test('AES GCM cryptography test', () async {
    const seed =
        "16d6b5ec01e233586f5d8b45898e55d07b678ed2b6fc615a8bf2c46c46455afd11a7fe47d45ef09ab49889694a875849f9ca7f547c8a5d532b46e9a119b31641";
    var metaData = <String>[];
    for (var account in accounts) {
      metaData.add(await account.encryptMetaData(secSeed: seed));
    }
    final plain = jsonEncode(metaData);
    final aes = AesGcm.with256bits();
    final pbkdf2 =
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 10000, bits: 256);
    // final nonce = aes.newNonce();
    // final secretKey =
    //     await pbkdf2.deriveKeyFromPassword(password: seed, nonce: nonce);
    // final encrypted = await aes.encrypt(
    //   utf8.encode(plain),
    //   secretKey: secretKey,
    //   nonce: nonce,
    // );

    // var base64Encoded = base64Encode(encrypted.concatenation());

    for (var enryptedAccount in jsonDecode(plain)) {
      final secretBox = SecretBox.fromConcatenation(
          base64Decode(enryptedAccount),
          macLength: 16,
          nonceLength: 12);
      final secretKey2 = await pbkdf2.deriveKeyFromPassword(
          password: seed, nonce: secretBox.nonce);

      final decrypted = await aes.decrypt(
        secretBox,
        secretKey: secretKey2,
      );
      print(utf8.decode(decrypted));
    }
  });
}
