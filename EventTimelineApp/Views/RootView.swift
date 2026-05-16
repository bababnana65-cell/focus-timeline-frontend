import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: TimelineViewModel
    @AppStorage("eventTimeline.isRegistered") private var isRegistered = false

    var body: some View {
        Group {
            if isRegistered {
                MainTabView()
            } else {
                RegistrationGateView(isRegistered: $isRegistered)
            }
        }
        .alert("提示", isPresented: errorBinding) {
            Button("知道了") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: isRegistered) { _, newValue in
            guard newValue else { return }
            Task {
                await viewModel.loadInitialData(force: true)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

private struct RegistrationGateView: View {
    @Binding var isRegistered: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.14), Color.indigo.opacity(0.08), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                Text("事件时间轴")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("不是刷新闻，而是持续追踪一个事件从萌芽到转折的全过程。")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureLine(icon: "calendar", text: "按小时 / 天 / 月自动聚合")
                    FeatureLine(icon: "sparkles", text: "重大节点高亮，快速识别拐点")
                    FeatureLine(icon: "rectangle.stack.person.crop", text: "注册后管理多个关注事件")
                }

                Button {
                    isRegistered = true
                } label: {
                    Text("模拟注册并进入")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text("当前为 MVP 骨架，注册流程已用本地模拟代替。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(24)
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            TimelineScreen()
                .tabItem {
                    Label("时间轴", systemImage: "calendar.badge.clock")
                }

            RecommendationsScreen()
                .tabItem {
                    Label("推荐", systemImage: "flame.fill")
                }

            TrackedTopicsScreen()
                .tabItem {
                    Label("我的关注", systemImage: "list.bullet.rectangle.portrait")
                }
        }
    }
}

private struct FeatureLine: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.indigo)
                .frame(width: 22)

            Text(text)
                .font(.body)
        }
    }
}

