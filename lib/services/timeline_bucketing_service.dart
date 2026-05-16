import 'package:intl/intl.dart';

import '../models/timeline_models.dart';

class TimelineBucketingService {
  const TimelineBucketingService();

  TimelineEntry? latestEntry(List<TimelineEntry> entries) {
    if (entries.isEmpty) {
      return null;
    }

    var latest = entries.first;
    for (final entry in entries.skip(1)) {
      if (entry.timestamp.isAfter(latest.timestamp)) {
        latest = entry;
      }
    }
    return latest;
  }

  List<TimelineBucket> makeBuckets(
    List<TimelineEntry> entries,
    DateTime now,
  ) {
    final grouped = <String, _BucketGroup>{};

    for (final entry in entries) {
      final granularity = granularityFor(entry.timestamp, now);
      final periodStart = bucketStartFor(entry.timestamp, granularity);
      final key = '${granularity.name}-${periodStart.millisecondsSinceEpoch}';

      grouped.putIfAbsent(
        key,
        () => _BucketGroup(
          periodStart: periodStart,
          granularity: granularity,
          entries: <TimelineEntry>[],
        ),
      );
      grouped[key]!.entries.add(entry);
    }

    return grouped.entries.map((groupEntry) {
      final group = groupEntry.value;
      group.entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final headline = group.entries.firstWhere(
        (entry) => entry.isMajor,
        orElse: () => group.entries.first,
      );

      return TimelineBucket(
        id: groupEntry.key,
        periodStart: group.periodStart,
        granularity: group.granularity,
        entries: group.entries,
        label: labelFor(group.periodStart, group.granularity),
        headline: headline.summary,
      );
    }).toList();
  }

  TimelineGranularity granularityFor(DateTime date, DateTime now) {
    final age = now.difference(date);
    if (age < const Duration(days: 1)) {
      return TimelineGranularity.hour;
    }
    if (age < const Duration(days: 90)) {
      return TimelineGranularity.day;
    }
    if (age.inDays < 365 * 3) {
      return TimelineGranularity.month;
    }
    if (age.inDays < 365 * 30) {
      return TimelineGranularity.year;
    }
    if (age.inDays < 365 * 300) {
      return TimelineGranularity.decade;
    }
    return TimelineGranularity.century;
  }

  DateTime bucketStartFor(DateTime date, TimelineGranularity granularity) {
    switch (granularity) {
      case TimelineGranularity.hour:
        return DateTime(date.year, date.month, date.day, date.hour);
      case TimelineGranularity.day:
        return DateTime(date.year, date.month, date.day);
      case TimelineGranularity.month:
        return DateTime(date.year, date.month);
      case TimelineGranularity.year:
        return DateTime(date.year);
      case TimelineGranularity.decade:
        final startYear = date.year > 0 && date.year < 10 ? 1 : (date.year ~/ 10) * 10;
        return DateTime(startYear);
      case TimelineGranularity.century:
        final startYear = ((date.year - 1) ~/ 100) * 100 + 1;
        return DateTime(startYear);
    }
  }

  String labelFor(DateTime date, TimelineGranularity granularity) {
    switch (granularity) {
      case TimelineGranularity.hour:
        return DateFormat('M月d日 HH:00', 'zh_CN').format(date);
      case TimelineGranularity.day:
        return DateFormat('M月d日', 'zh_CN').format(date);
      case TimelineGranularity.month:
        return formatTimelineDate(date, includeDay: false);
      case TimelineGranularity.year:
        return formatTimelineDate(
          date,
          includeMonth: false,
          includeDay: false,
        );
      case TimelineGranularity.decade:
        if (date.year >= 100) {
          return '${date.year}年代';
        }
        return '公元${date.year}年代';
      case TimelineGranularity.century:
        final century = ((date.year - 1) ~/ 100) + 1;
        if (date.year >= 100) {
          return '$century世纪';
        }
        return '公元$century世纪';
    }
  }
}

class _BucketGroup {
  _BucketGroup({
    required this.periodStart,
    required this.granularity,
    required this.entries,
  });

  final DateTime periodStart;
  final TimelineGranularity granularity;
  final List<TimelineEntry> entries;
}
