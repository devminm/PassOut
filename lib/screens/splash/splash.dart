import 'dart:async';

import 'package:flutter/material.dart';
import 'package:passout/widgets/gap.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app_router.dart';
import '../../helpers/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkPermissionsAndNavigate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 200, height: 200, child: Card()),
              Gap.vertical(),
              Text(
                "Secure Hash-based Password Manager",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkPermissionsAndNavigate(BuildContext context) async {
    // Request necessary Bluetooth permissions
    final bluetoothPermissionsGranted = await _requestBluetoothPermissions();

    if (bluetoothPermissionsGranted) {
      // Delay navigation for 3 seconds
      Timer(const Duration(seconds: 3), () async {
        // Access secure storage to check for seed
        final secStorage = SecureStorageService();
        final seed = await secStorage.read(key: 'seed');

        // Navigate based on the presence of the seed
        if (seed == null) {
          AppRouter.navigate(context, AppRouter.mnemonicRoute);
        } else {
          AppRouter.navigate(context, AppRouter.homeRoute);
        }
      });
    } else {
      // If permissions are not granted, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permissions are required to use this app'),
        ),
      );
      checkPermissionsAndNavigate(context);
    }
  }

  Future<bool> _requestBluetoothPermissions() async {
    // Request and check all Bluetooth permissions
    final permissions = [


    ];

    for (final permission in permissions) {
      if (!await permission.request().isGranted) {
        print(permission);
        return false; // If any permission is not granted, return false
      }
    }

    return true; // All permissions granted
  }
}
