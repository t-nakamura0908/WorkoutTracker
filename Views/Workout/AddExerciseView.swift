import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseName = ""
    @State private var searchText = ""
    @State private var recentNames: [String] = []
    let onAdd: (String) -> Void

    private let presetExercises = [
        "ベンチプレス", "スクワット", "デッドリフト", "ショルダープレス",
        "ラットプルダウン", "ベントオーバーロウ", "ダンベルカール",
        "トライセプスプッシュダウン", "レッグプレス", "チェストフライ",
        "インクラインベンチプレス", "ワイドスクワット", "ルーマニアンデッドリフト",
        "サイドレイズ", "フェイスプル", "プルアップ", "ディップス",
        "プランク", "クランチ", "レッグレイズ"
    ]

    private var filteredPresets: [String] {
        if searchText.isEmpty {
            return presetExercises
        }
        return presetExercises.filter { $0.contains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("種目名を入力") {
                    HStack {
                        TextField("例: ベンチプレス", text: $exerciseName)
                        if !exerciseName.isEmpty {
                            Button("追加") {
                                add(name: exerciseName)
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }

                if !recentNames.isEmpty {
                    Section("最近使った種目") {
                        ForEach(recentNames, id: \.self) { name in
                            Button(name) { add(name: name) }
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Section("プリセット") {
                    ForEach(filteredPresets, id: \.self) { name in
                        Button(name) { add(name: name) }
                            .foregroundStyle(.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "種目を検索")
            .navigationTitle("種目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .onAppear {
                loadRecentNames()
            }
        }
    }

    private func add(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        onAdd(name)
        dismiss()
    }

    private func loadRecentNames() {
        let repo = WorkoutRepository(modelContext: modelContext)
        recentNames = (try? repo.fetchAllExerciseNames()) ?? []
    }
}

#Preview {
    AddExerciseView { _ in }
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self], inMemory: true)
}
