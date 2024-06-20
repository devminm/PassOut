import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage storage;

  SecureStorageService()
      : storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

  // Define the Android options to use encrypted SharedPreferences
  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  // Example method to write data
  Future<void> write({required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  // Example method to read data
  Future<String?> read({required String key}) async {
    return await storage.read(key: key);
  }
}
