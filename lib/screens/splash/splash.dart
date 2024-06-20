import 'dart:async';

import 'package:flutter/material.dart';
import 'package:passout/widgets/gap.dart';

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
      Timer(const Duration(seconds: 3), () async {
        final secStorage = SecureStorageService();
        final seed = await secStorage.read(key: 'seed');
        if (seed == null) {
          AppRouter.navigate(context, AppRouter.mnemonicRoute);
        } else {
          AppRouter.navigate(context, AppRouter.homeRoute);
        }
      });
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
}
