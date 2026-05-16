import SwiftUI

struct TimelineRowView: View {
    let bucket: TimelineBucket

    @State private var isExpanded = false
    @State private var showFullStory = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: bucket.containsMajorEvent ? "star.circle.fill" : "circle.fill")
                    .font(.title3)
                    .foregroundStyle(bucket.containsMajorEvent ? Color.orange : Color.indigo)
                    .frame(width: 28, height: 28)

                Rectangle()
                    .fill(Color.indigo.opacity(0.16))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(bucket.label)
                                .font(.headline)

                            Text(bucket.countLabel)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.indigo.opacity(0.1))
                                .foregroundStyle(.indigo)
                                .clipShape(Capsule())

                            if bucket.isArchived {
                                Text("归档")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.12))
                                    .foregroundStyle(.secondary)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(bucket.headline)
                            .font(.body.weight(.medium))
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "doc.text.fill" : "chevron.down.circle.fill")
                        .foregroundStyle(.secondary)
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bucket.entries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.title)
                                        .font(.subheadline.bold())

                                    if entry.isMajor {
                                        Text("重大")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.14))
                                            .foregroundStyle(.orange)
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(entry.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text(entry.timestamp, format: .dateTime.month().day().hour().minute())
                                    Spacer()
                                    Text(entry.sourceName)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            if entry.id != bucket.entries.last?.id {
                                Divider()
                            }
                        }

                        HStack {
                            Text("再次点击卡片查看全文")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("收起") {
                                withAnimation(.easeInOut) {
                                    isExpanded = false
                                }
                            }
                            .font(.footnote.weight(.semibold))
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onTapGesture {
                if isExpanded {
                    showFullStory = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                        isExpanded = true
                    }
                }
            }
        }
        .sheet(isPresented: $showFullStory) {
            FullStoryView(bucket: bucket)
        }
    }
}

private struct FullStoryView: View {
    @Environment(\.dismiss) private var dismiss
    let bucket: TimelineBucket

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(bucket.entries) { entry in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(entry.title)
                                    .font(.headline)

                                if entry.isMajor {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                }
                            }

                            Text(entry.summary)
                                .font(.subheadline.weight(.medium))

                            Text(entry.fullText)
                                .font(.body)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(entry.timestamp, format: .dateTime.year().month().day().hour().minute())
                                Spacer()
                                Text(entry.sourceName)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle(bucket.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

