// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_network_example/main.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  test("description", () async {
    for (var i = 0; i < 10; i++) {
      createRandomFile("directoryPath", 1024 * 1024 * 10);
    }
  });
}

void createRandomFile(String directoryPath, int fileSize) {
  const uuid = Uuid();
  var fileName = uuid.v4();
  var filePath = path.join(directoryPath, fileName);
  var file = File(filePath);
  var random = Random.secure();
  var bytes = List<int>.generate(fileSize, (i) => random.nextInt(256));
  file.writeAsBytesSync(bytes);
}
