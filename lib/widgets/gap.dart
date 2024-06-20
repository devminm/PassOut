import 'package:flutter/cupertino.dart';

class Gap {
  static Widget vertical([double? height]) => SizedBox(
        height: height ?? 16,
      );
  static Widget horizontal({double? width}) => SizedBox(
        width: width ?? 16,
      );
}
