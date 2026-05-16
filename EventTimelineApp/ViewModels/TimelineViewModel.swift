import Combine
import Foundation

@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var trackedTopics: [Topic] = []
    @Published private(set) var recommendedTopics: [Topic] = []
    @Published private(set) var entriesByTopic: [UUID: [TimelineEntry]] = [:]
    @Published var selectedTopicID: UUID?
    @Published var sortOrder: TimelineSortOrder = .chronological
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let service: TimelineService
    private let archiveThresholdDays = 45
    private let calendar: Calendar
    private let hourFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let monthFormatter: DateFormatter

    init(service: TimelineService) {
        self.service = service

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        self.calendar = calendar

        self.hourFormatter = TimelineViewModel.makeFormatter("M月d日 HH:00")
        self.dayFormatter = TimelineViewModel.makeFormatter("M月d日")
        self.monthFormatter = TimelineViewModel.makeFormatter("yyyy年M月")
    }

    var allTopics: [Topic] {
        var seen = Set<UUID>()
        return (trackedTopics + recommendedTopics).filter { topic in
            seen.insert(topic.id).inserted
        }
    }

    var selectedTopic: Topic? {
        allTopics.first(where: { $0.id == selectedTopicID }) ?? trackedTopics.first ?? recommendedTopics.first
    }

    var hotTopics: [Topic] {
        recommendedTopics.filter(\.isHot)
    }

    var timelineBuckets: [TimelineBucket] {
        guard let selectedTopic, let entries = entriesByTopic[selectedTopic.id] else {
            return []
        }

        let buckets = makeBuckets(from: entries, referenceDate: .now)

        switch sortOrder {
        case .chronological:
            return buckets.sorted { $0.periodStart < $1.periodStart }
        case .reverseChronological:
            return buckets.sorted { $0.periodStart > $1.periodStart }
        }
    }

    func loadInitialData(force: Bool = false) async {
        if isLoading || (!force && !trackedTopics.isEmpty) {
            if selectedTopicID == nil {
                selectedTopicID = trackedTopics.first?.id ?? recommendedTopics.first?.id
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            trackedTopics = try await service.fetchTrackedTopics()
            recommendedTopics = try await service.fetchRecommendedTopics()
            selectedTopicID = selectedTopicID ?? trackedTopics.first?.id ?? recommendedTopics.first?.id
            try await ensureTimelineLoaded(for: selectedTopicID)
        } catch {
            errorMessage = "初始化数据失败：\(error.localizedDescription)"
        }

        isLoading = false
    }

    func selectTopic(_ topic: Topic) {
        selectedTopicID = topic.id

        Task {
            try? await ensureTimelineLoaded(for: topic.id)
        }
    }

    func refreshTimeline() async {
        guard let topic = selectedTopic else { return }

        isRefreshing = true
        errorMessage = nil

        do {
            let entries = try await service.fetchTimeline(for: topic)
            entriesByTopic[topic.id] = entries.sorted { $0.timestamp < $1.timestamp }
        } catch {
            errorMessage = "刷新失败：\(error.localizedDescription)"
        }

        isRefreshing = false
    }

    func toggleSortOrder() {
        sortOrder = sortOrder == .chronological ? .reverseChronological : .chronological
    }

    func isFollowing(_ topic: Topic) -> Bool {
        trackedTopics.contains(topic)
    }

    func toggleFollow(_ topic: Topic) {
        if let index = trackedTopics.firstIndex(of: topic) {
            if trackedTopics.count == 1 {
                errorMessage = "至少保留一个关注事件。"
                return
            }

            trackedTopics.remove(at: index)

            if selectedTopicID == topic.id {
                selectedTopicID = trackedTopics.first?.id
            }

            return
        }

        trackedTopics.append(topic)
        selectedTopicID = topic.id

        Task {
            try? await ensureTimelineLoaded(for: topic.id)
        }
    }

    private func ensureTimelineLoaded(for topicID: UUID?) async throws {
        guard let topicID else { return }
        guard entriesByTopic[topicID] == nil else { return }
        guard let topic = allTopics.first(where: { $0.id == topicID }) else { return }

        let entries = try await service.fetchTimeline(for: topic)
        entriesByTopic[topic.id] = entries.sorted { $0.timestamp < $1.timestamp }
    }

    private func makeBuckets(from entries: [TimelineEntry], referenceDate: Date) -> [TimelineBucket] {
        struct Group {
            let start: Date
            let granularity: TimelineGranularity
            var entries: [TimelineEntry]
        }

        var groups: [String: Group] = [:]

        for entry in entries {
            let granularity = granularity(for: entry.timestamp, referenceDate: referenceDate)
            let start = bucketStart(for: entry.timestamp, granularity: granularity)
            let key = "\(granularity.rawValue)-\(Int(start.timeIntervalSince1970))"

            if var existing = groups[key] {
                existing.entries.append(entry)
                groups[key] = existing
            } else {
                groups[key] = Group(start: start, granularity: granularity, entries: [entry])
            }
        }

        return groups.values.map { group in
            let sortedEntries = group.entries.sorted { $0.timestamp > $1.timestamp }
            let headline = sortedEntries.first(where: \.isMajor)?.summary
                ?? sortedEntries.first?.summary
                ?? "暂无摘要"

            return TimelineBucket(
                periodStart: group.start,
                granularity: group.granularity,
                entries: sortedEntries,
                label: label(for: group.start, granularity: group.granularity),
                headline: headline
            )
        }
    }

    private func granularity(for date: Date, referenceDate: Date) -> TimelineGranularity {
        let ageInDays = referenceDate.timeIntervalSince(date) / 86_400

        if ageInDays < 1 {
            return .hour
        }

        if ageInDays > Double(archiveThresholdDays) {
            return .month
        }

        return .day
    }

    private func bucketStart(for date: Date, granularity: TimelineGranularity) -> Date {
        switch granularity {
        case .hour:
            return calendar.dateInterval(of: .hour, for: date)?.start ?? date
        case .day:
            return calendar.startOfDay(for: date)
        case .month:
            return calendar.dateInterval(of: .month, for: date)?.start ?? date
        }
    }

    private func label(for date: Date, granularity: TimelineGranularity) -> String {
        switch granularity {
        case .hour:
            return hourFormatter.string(from: date)
        case .day:
            return dayFormatter.string(from: date)
        case .month:
            return monthFormatter.string(from: date)
        }
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = format
        return formatter
    }
}

