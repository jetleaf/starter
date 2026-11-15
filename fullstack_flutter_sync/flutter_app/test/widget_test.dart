import 'package:flutter_test/flutter_test.dart';

import 'package:fullstack_sync_flutter/main.dart';

void main() {
  testWidgets('Notes screen renders (error banner or content)', (WidgetTester tester) async {
    await tester.pumpWidget(const FullstackSyncApp());
    expect(find.text('Full-Stack Sync 🍃'), findsOneWidget);
  });
}
