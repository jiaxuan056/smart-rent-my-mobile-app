import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_my/app.dart';

void main() {
  testWidgets('shared project foundation starts successfully', (tester) async {
    await tester.pumpWidget(const SmartRentApp());

    final application = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(application.title, 'SmartRent MY');
  });
}
