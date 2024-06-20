import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Convert String of List to List of String', () {
    final stringList = '["apple", "banana", "cherry"]';
    final jsonDecoded = jsonDecode(stringList);
    final list = List<String>.from(jsonDecoded);
    expect(list, ['apple', 'banana', 'cherry']);
  });

  test('Convert List to String', () {
    final list = ['apple', 'banana', 'cherry'];
    final jsonString = jsonEncode(list);
    expect(jsonString, '["apple","banana","cherry"]');
  });
}
