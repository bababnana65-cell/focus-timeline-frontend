import 'package:event_timeline/models/timeline_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats compact node dates for today, yesterday, and older dates', () {
    final now = DateTime(2026, 4, 26, 9, 0);

    expect(
      formatCompactNodeTimeLabel(
        DateTime(2026, 4, 26, 13, 21),
        now: now,
      ),
      '今日\n13:21',
    );
    expect(
      formatCompactNodeTimeLabel(
        DateTime(2026, 4, 25, 12, 29),
        now: now,
      ),
      '昨日\n12:29',
    );
    expect(
      formatCompactNodeTimeLabel(
        DateTime(2026, 4, 24, 8, 30),
        now: now,
      ),
      '4月24日',
    );
    expect(
      formatCompactNodeTimeLabel(
        DateTime(2025, 11, 21, 8, 30),
        now: now,
      ),
      '2025年11月21日',
    );
    expect(
      formatCompactNodeTimeLabel(
        DateTime(2026, 4, 26, 13, 21),
        now: now,
        singleLine: true,
        todayLabel: '今天',
        yesterdayLabel: '昨天',
      ),
      '今天 13:21',
    );
  });

  test('formats archived header dates with compact bucket labels', () {
    expect(
      formatTimelineHeaderDateLabel(
        DateTime(605),
        bucketLabel: '601年-700年',
        granularity: TimelineGranularity.century,
      ),
      '7世纪',
    );
    expect(
      formatTimelineHeaderDateLabel(
        DateTime(2026, 4, 16),
        granularity: TimelineGranularity.day,
      ),
      '2026.04.16',
    );
    expect(
      formatTimelineHeaderDateLabel(
        DateTime(1950),
        bucketLabel: '1950年代',
        granularity: TimelineGranularity.decade,
      ),
      '1950年代',
    );
  });

  test('formats recent header dates before archived bucket ranges', () {
    expect(
      formatTimelineHeaderDateLabel(
        DateTime(2026, 5, 3, 22, 27),
        bucketLabel: '2001年-2100年',
        granularity: TimelineGranularity.century,
        now: DateTime(2026, 5, 4, 9),
        relativeRecent: true,
      ),
      '昨天 22:27',
    );
  });

  test('formats bucket labels with the same compact node rules', () {
    expect(
      formatTimelineBucketDateLabel(
        TimelineBucket(
          id: 'century-601',
          periodStart: DateTime(601),
          granularity: TimelineGranularity.century,
          entries: <TimelineEntry>[
            _entry(DateTime(605)),
          ],
          label: '601年-700年',
          headline: '起点',
        ),
        now: DateTime(2026, 5, 4, 9),
      ),
      '7世纪',
    );

    expect(
      formatTimelineBucketDateLabel(
        TimelineBucket(
          id: 'century-2001',
          periodStart: DateTime(2001),
          granularity: TimelineGranularity.century,
          entries: <TimelineEntry>[
            _entry(DateTime(2026, 5, 3, 22, 27)),
          ],
          label: '2001年-2100年',
          headline: '最新节点',
        ),
        now: DateTime(2026, 5, 4, 9),
      ),
      '昨天 22:27',
    );

    expect(
      formatTimelineBucketDateLabel(
        TimelineBucket(
          id: 'day-2025-11-21',
          periodStart: DateTime(2025, 11, 21),
          granularity: TimelineGranularity.day,
          entries: <TimelineEntry>[
            _entry(DateTime(2025, 11, 21, 8, 30)),
          ],
          label: '2025年11月21日',
          headline: '跨年节点',
        ),
        now: DateTime(2026, 5, 4, 9),
      ),
      '2025年11月21日',
    );
  });

  test('formats tracking duration adaptively for long-running timelines', () {
    expect(
      formatTimelineTrackingDuration(
        DateTime(605),
        now: DateTime(2026),
      ),
      '约1421年',
    );
    expect(
      formatTimelineTrackingDuration(
        DateTime(2026, 4, 1),
        now: DateTime(2026, 4, 18),
      ),
      '18天',
    );
  });
}

TimelineEntry _entry(DateTime timestamp) {
  return TimelineEntry(
    id: timestamp.microsecondsSinceEpoch.toString(),
    topicId: 'topic',
    title: '节点',
    summary: '节点摘要',
    detail: '节点详情',
    fullText: '节点详情',
    sourceName: '测试来源',
    timestamp: timestamp,
    isMajor: false,
  );
}
