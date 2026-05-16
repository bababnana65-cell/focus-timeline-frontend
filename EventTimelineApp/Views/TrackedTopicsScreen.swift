import SwiftUI

struct TrackedTopicsScreen: View {
    @EnvironmentObject private var viewModel: TimelineViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("已关注事件")
                        .font(.title3.bold())

                    Text("注册后可维护多个关注专题。当前专题会同步到时间轴页。")
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.trackedTopics) { topic in
                        TrackedTopicCard(
                            topic: topic,
                            isSelected: viewModel.selectedTopicID == topic.id
                        ) {
                            viewModel.selectTopic(topic)
                        } onRemove: {
                            withAnimation {
                                viewModel.toggleFollow(topic)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的关注")
        }
    }
}

private struct TrackedTopicCard: View {
    let topic: Topic
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.indigo : Color.secondary)

                Text(topic.name)
                    .font(.headline)
            }

            Text(topic.tagline)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(topic.followerCount) 人关注", systemImage: "person.2")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("设为当前") {
                    onSelect()
                }
                .buttonStyle(.bordered)

                Button("取消关注", role: .destructive) {
                    onRemove()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

