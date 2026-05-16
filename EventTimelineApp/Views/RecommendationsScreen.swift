import SwiftUI

struct RecommendationsScreen: View {
    @EnvironmentObject private var viewModel: TimelineViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("热门事件推荐")
                        .font(.title3.bold())

                    Text("根据热度和持续讨论度推荐，关注后会立即出现在你的时间轴里。")
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.hotTopics) { topic in
                        RecommendationCard(
                            topic: topic,
                            isFollowing: viewModel.isFollowing(topic)
                        ) {
                            withAnimation {
                                viewModel.toggleFollow(topic)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("热门推荐")
        }
    }
}

private struct RecommendationCard: View {
    let topic: Topic
    let isFollowing: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(topic.name)
                            .font(.headline)

                        if topic.isHot {
                            Text("HOT")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.16))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }

                    Text(topic.tagline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack {
                Label("\(topic.followerCount) 人关注", systemImage: "person.2.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(isFollowing ? "已关注" : "关注") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .tint(isFollowing ? .gray : .indigo)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

