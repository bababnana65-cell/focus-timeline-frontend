import SwiftUI

struct TimelineScreen: View {
    @EnvironmentObject private var viewModel: TimelineViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.timelineBuckets.isEmpty {
                    ProgressView("正在加载时间轴…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.selectedTopic == nil {
                    ContentUnavailableView("暂无关注事件", systemImage: "tray", description: Text("先在推荐页添加一个关注专题。"))
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                topicSelector
                                summaryCard

                                ForEach(viewModel.timelineBuckets) { bucket in
                                    TimelineRowView(bucket: bucket)
                                        .id(bucket.id)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color(.systemGroupedBackground))
                        .refreshable {
                            await viewModel.refreshTimeline()
                        }
                        .task(id: scrollAnchorID) {
                            guard viewModel.sortOrder == .chronological else { return }
                            guard let lastID = viewModel.timelineBuckets.last?.id else { return }

                            try? await Task.sleep(for: .milliseconds(180))
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("事件时间轴")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.toggleSortOrder()
                    } label: {
                        Label(viewModel.sortOrder.title, systemImage: viewModel.sortOrder == .chronological ? "arrow.down.to.line" : "arrow.up.to.line")
                    }

                    Button {
                        Task {
                            await viewModel.refreshTimeline()
                        }
                    } label: {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    private var topicSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.trackedTopics) { topic in
                    Button {
                        viewModel.selectTopic(topic)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.name)
                                .font(.subheadline.weight(.semibold))
                            Text(topic.tagline)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 230, alignment: .leading)
                        .background(viewModel.selectedTopicID == topic.id ? Color.indigo : Color.white)
                        .foregroundStyle(viewModel.selectedTopicID == topic.id ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.indigo.opacity(viewModel.selectedTopicID == topic.id ? 0 : 0.2), lineWidth: 1)
                        }
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedTopic?.name ?? "未选择专题")
                .font(.title3.bold())

            Text(viewModel.selectedTopic?.tagline ?? "")
                .foregroundStyle(.secondary)

            HStack {
                Label(viewModel.sortOrder.description, systemImage: "arrow.up.arrow.down")
                Spacer()
                Label("45 天前自动按月归档", systemImage: "archivebox")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var scrollAnchorID: String {
        "\(viewModel.sortOrder.rawValue)-" + viewModel.timelineBuckets.map(\.id).joined(separator: "|")
    }
}
