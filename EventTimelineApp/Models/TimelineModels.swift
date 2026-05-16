import Foundation

enum TimelineGranularity: String, CaseIterable, Identifiable, Codable {
    case hour
    case day
    case month

    var id: String { rawValue }

    var unitLabel: String {
        switch self {
        case .hour:
            return "小时"
        case .day:
            return "天"
        case .month:
            return "月"
        }
    }
}

enum TimelineSortOrder: String, CaseIterable, Identifiable {
    case chronological
    case reverseChronological

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chronological:
            return "正序"
        case .reverseChronological:
            return "倒序"
        }
    }

    var description: String {
        switch self {
        case .chronological:
            return "最近事件在底部"
        case .reverseChronological:
            return "最近事件在顶部"
        }
    }
}

struct Topic: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let tagline: String
    let followerCount: Int
    let isHot: Bool
}

struct TimelineEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let topicID: UUID
    let title: String
    let summary: String
    let detail: String
    let fullText: String
    let sourceName: String
    let timestamp: Date
    let isMajor: Bool
}

struct TimelineBucket: Identifiable, Hashable {
    let periodStart: Date
    let granularity: TimelineGranularity
    let entries: [TimelineEntry]
    let label: String
    let headline: String

    var id: String {
        "\(granularity.rawValue)-\(Int(periodStart.timeIntervalSince1970))"
    }

    var containsMajorEvent: Bool {
        entries.contains(where: \.isMajor)
    }

    var eventCount: Int {
        entries.count
    }

    var isArchived: Bool {
        granularity == .month
    }

    var countLabel: String {
        "\(eventCount) 条 / \(granularity.unitLabel)"
    }
}

