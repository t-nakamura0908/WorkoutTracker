import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var viewModel: WorkoutViewModel?
    @State private var showingTemplates = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    WorkoutContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(session.date.isToday ? "今日のトレーニング" : session.date.displayString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel {
                        Menu {
                            Button {
                                vm.showingAddExercise = true
                            } label: {
                                Label("種目を追加", systemImage: "plus")
                            }
                            Button {
                                showingTemplates = true
                            } label: {
                                Label("テンプレートを適用", systemImage: "rectangle.stack")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .onAppear {
            let repo = WorkoutRepository(modelContext: modelContext)
            viewModel = WorkoutViewModel(session: session, repository: repo)
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationStack {
                if let vm = viewModel {
                    TemplateListView { template in
                        vm.applyTemplate(template, context: modelContext)
                        showingTemplates = false
                    }
                }
            }
        }
    }
}

// MARK: - Content

private struct WorkoutContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WorkoutViewModel

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 16) {
                    // バナー分の余白
                    if viewModel.isIntervalRunning || viewModel.intervalFinished {
                        Color.clear.frame(height: 72)
                    }

                    if viewModel.session.sortedExercises.isEmpty {
                        EmptyStateView(
                            icon: "dumbbell.fill",
                            title: "種目がありません",
                            message: "右上の＋ボタンで種目を追加しましょう"
                        )
                        .frame(height: 300)
                    } else {
                        ForEach(viewModel.session.sortedExercises) { exercise in
                            ExerciseRowView(
                                exercise: exercise,
                                onAddSet: {
                                    viewModel.addSet(to: exercise, context: modelContext)
                                },
                                onDeleteSet: { set in
                                    viewModel.deleteSet(set, from: exercise, context: modelContext)
                                },
                                onDelete: {
                                    viewModel.deleteExercise(exercise, context: modelContext)
                                },
                                onCompleteSet: { set in
                                    viewModel.completeSet(set, exercise: exercise, context: modelContext)
                                    triggerHaptic()
                                }
                            )
                        }
                    }

                    notesSection
                }
                .padding()
            }

            // インターバルバナー（オーバーレイ）
            if viewModel.isIntervalRunning || viewModel.intervalFinished {
                IntervalBannerView(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: viewModel.isIntervalRunning)
        .animation(.spring(response: 0.4), value: viewModel.intervalFinished)
        .sheet(isPresented: $viewModel.showingAddExercise) {
            AddExerciseView { name in
                viewModel.addExercise(name: name, context: modelContext)
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ")
                .font(.headline)
            TextField("トレーニング全体のメモ", text: Binding(
                get: { viewModel.session.notes },
                set: { viewModel.updateNotes($0, context: modelContext) }
            ), axis: .vertical)
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - インターバルバナー

private struct IntervalBannerView: View {
    @Bindable var viewModel: WorkoutViewModel

    var body: some View {
        HStack(spacing: 12) {
            // プログレスリング
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: viewModel.intervalProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.intervalProgress)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                if viewModel.intervalFinished {
                    Text("インターバル終了！")
                        .font(.subheadline.bold())
                    Text("次のセットを始めましょう")
                        .font(.caption)
                        .opacity(0.85)
                } else {
                    Text("インターバル中")
                        .font(.subheadline.bold())
                    Text("残り \(viewModel.intervalDisplayTime)")
                        .font(.caption.monospacedDigit())
                        .opacity(0.85)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    viewModel.stopInterval()
                    viewModel.intervalFinished = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            viewModel.intervalFinished
                ? Color.green.gradient
                : Color.blue.gradient,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}
