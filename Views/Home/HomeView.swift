import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showingWorkout = false
    @State private var showingCondition = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    HomeContentView(
                        viewModel: vm,
                        showingWorkout: $showingWorkout,
                        showingCondition: $showingCondition
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            let vm = HomeViewModel(container: modelContext.container)
            viewModel = vm
            await vm.loadData()
        }
        // 保存・キャンセルに関わらず閉じたら今日のトレーニングを再読み込み
        .sheet(isPresented: $showingWorkout, onDismiss: {
            guard let vm = viewModel else { return }
            Task { @MainActor in await vm.loadData() }
        }) {
            WorkoutView(sessionDate: .now)
        }
        .sheet(isPresented: $showingCondition) {
            ConditionView(existingCondition: viewModel?.todayCondition) {
                Task { await viewModel?.loadData() }
            }
        }
    }
}

private struct HomeContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HomeViewModel
    @Binding var showingWorkout: Bool
    @Binding var showingCondition: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                conditionSection
                todaySection
                statsSection
                recentSection
            }
            .padding()
        }
        .refreshable { await viewModel.loadData() }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: コンディションセクション

    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("コンディション")
                    .font(.headline)
                Spacer()
                Button(viewModel.todayCondition == nil ? "記録する" : "編集") {
                    showingCondition = true
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }

            if let condition = viewModel.todayCondition {
                ConditionCardView(condition: condition)
                    .onTapGesture { showingCondition = true }
            } else {
                Button {
                    showingCondition = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("今日のコンディションを記録")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.blue)
                }
            }
        }
    }

    // MARK: トレーニングセクション

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日のトレーニング")
                .font(.headline)

            if let session = viewModel.todaySession {
                WorkoutCardView(session: session)
                    .onTapGesture { showingWorkout = true }
            } else {
                Button {
                    showingWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("トレーニングを開始")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .font(.headline)
                }
            }
        }
    }

    // MARK: 統計セクション

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の実績")
                .font(.headline)
            HStack(spacing: 12) {
                StatCardView(
                    title: "トレーニング",
                    value: "\(viewModel.weeklyCount)",
                    unit: "回",
                    icon: "flame.fill",
                    color: .orange
                )
                StatCardView(
                    title: "総ボリューム",
                    value: String(format: "%.0f", viewModel.totalVolume),
                    unit: "kg",
                    icon: "scalemass.fill",
                    color: .blue
                )
                StatCardView(
                    title: "継続記録",
                    value: "\(viewModel.currentStreak)",
                    unit: "日",
                    icon: "trophy.fill",
                    color: .yellow
                )
            }
        }
    }

    // MARK: 最近の記録

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近の記録")
                .font(.headline)

            if viewModel.recentSessions.isEmpty {
                EmptyStateView(
                    icon: "dumbbell",
                    title: "記録なし",
                    message: "トレーニングを始めて記録をつけましょう"
                )
                .frame(height: 160)
            } else {
                ForEach(viewModel.recentSessions) { session in
                    WorkoutCardView(session: session)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(
            for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self, DailyCondition.self],
            inMemory: true
        )
}
