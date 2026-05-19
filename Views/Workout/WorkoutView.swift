import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    @State private var viewModel: WorkoutViewModel?

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
                        Button {
                            vm.showingAddExercise = true
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
    }
}

private struct WorkoutContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WorkoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                            onAddSet: { viewModel.addSet(to: exercise, context: modelContext) },
                            onDeleteSet: { set in
                                viewModel.deleteSet(set, from: exercise, context: modelContext)
                            },
                            onDelete: { viewModel.deleteExercise(exercise, context: modelContext) }
                        )
                    }
                }

                notesSection
            }
            .padding()
        }
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
}
