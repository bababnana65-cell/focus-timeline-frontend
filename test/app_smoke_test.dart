import 'package:event_timeline/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders home shell for guests', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('时间轴'), findsOneWidget);
    expect(find.text('创建'), findsOneWidget);
    expect(find.text('未登录'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsWidgets);
  });
}
