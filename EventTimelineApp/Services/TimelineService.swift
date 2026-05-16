import Foundation

protocol TimelineService {
    func fetchTrackedTopics() async throws -> [Topic]
    func fetchRecommendedTopics() async throws -> [Topic]
    func fetchTimeline(for topic: Topic) async throws -> [TimelineEntry]
}

