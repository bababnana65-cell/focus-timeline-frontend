import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/widgets/source_attribution_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('source badges show provider channel and concrete source name',
      (tester) async {
    final entry = TimelineEntry(
      id: 'entry-1',
      topicId: 'topic-1',
      title: '事故调查出现新进展',
      summary: '官方通报和媒体报道提供了新的事实节点。',
      detail: '官方通报和媒体报道提供了新的事实节点。',
      fullText: '官方通报和媒体报道提供了新的事实节点。',
      sourceName: '百度百科',
      sourceUrl: 'https://baike.baidu.com/item/example',
      sourceProvider: 'serpapi_baidu',
      sourceKind: SourceKind.aggregator,
      sourceReliability: SourceReliability.medium,
      timestamp: DateTime.utc(2026, 5, 10),
      isMajor: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SourceAttributionBadges(entry: entry, compact: true),
        ),
      ),
    );

    expect(find.text('百度搜索'), findsOneWidget);
    expect(find.text('百度百科'), findsOneWidget);
    expect(find.text('整理'), findsOneWidget);
    expect(find.text('待核验'), findsOneWidget);
  });
}
