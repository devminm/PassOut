import 'package:flutter/material.dart';
import 'package:passout/screens/home/home.dart';
import 'package:passout/screens/splash/splash.dart';

import 'screens/mnemonic/mnemonic.dart';

class AppRouter {
  static const String splashRoute = "/";
  static const String homeRoute = "/home";
  static const String mnemonicRoute = "/mnemonic";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      case homeRoute:
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      case mnemonicRoute:
        return MaterialPageRoute(builder: (context) => const MnemonicScreen());
      default:
        return MaterialPageRoute(
            builder: (context) => const Text("Screen not found!"));
    }
  }

  static navigate(BuildContext context, String route, {bool replace = true}) {
    if (replace) {
      return Navigator.pushReplacementNamed(context, route);
    }
    return Navigator.pushNamed(context, route);
  }
}
