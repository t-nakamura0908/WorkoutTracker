import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var mainContext  // container 取得のみに使用
    @Environment(\.dismiss) private var dismiss
    /// 編集対象の日付。WorkoutView はこの日付を基に内部で専用 context を作成する。
    let sessionDate: Date
    @State private var editContext: ModelContext?
    @State private var viewModel: WorkoutViewModel?
    @State private var showingTemplates = false
    @State private var showingCancelConfirmation = false
    @State private var didSave = false

    private var hasUnsavedChanges: Bool {
        viewModel?.isDirty == true && !didSave
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel, let ctx = editContext {
                    WorkoutContentView(viewModel: vm)
                        // 編集専用 context を注入することで主 context（HomeView）に
                        // 変更が漏れず、キャンセル時にも主 context のデータは一切変わらない
                        .environment(\.modelContext, ctx)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(sessionDate.isToday ? "今日" : sessionDate.displayString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ❌ キャンセル
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel?.isDirty == true {
                            showingCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.medium)
                    }
                }
                // 種目追加メニュー
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
                // 保存
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel, let ctx = editContext {
                        Button("保存") {
                            didSave = true
                            vm.save(context: ctx)
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .onAppear {
            setupEditContext()
        }
        // キャンセル: edit context を保存しないまま破棄するだけ。主 context は無変更。
        // 保存:      edit context.save() 済み。onDismiss で呼ばれる loadData() が主 context を再読み込み。
        .sheet(isPresented: $showingTemplates) {
            NavigationStack {
                if let vm = viewModel, let ctx = editContext {
                    TemplateListView { template in
                        vm.applyTemplate(template, context: ctx)
                        showingTemplates = false
                    }
                }
            }
        }
        .confirmationDialog(
            "変更を破棄しますか？",
            isPresented: $showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("破棄する", role: .destructive) {
                dismiss()
            }
            Button("続ける", role: .cancel) {}
        } message: {
            Text("変更内容は保存されません")
        }
    }

    // MARK: - Edit Context セットアップ

    private func setupEditContext() {
        let ctx = ModelContext(mainContext.container)
        ctx.autosaveEnabled = false
        editContext = ctx

        let repo = WorkoutRepository(modelContext: ctx)

        // 指定日の session を edit context 内で取得。
        // 存在すれば編集モード、なければ新規作成モード。
        // 主 context の session オブジェクトは一切参照しないため観察の漏れが発生しない。
        if let existing = try? repo.fetchSession(for: sessionDate) {
            viewModel = WorkoutViewModel(session: existing, repository: repo)
        } else {
            let newSession = WorkoutSession(date: sessionDate)
            ctx.insert(newSession)
            viewModel = WorkoutViewModel(session: newSession, repository: repo)
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
