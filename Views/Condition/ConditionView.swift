import SwiftUI
import SwiftData

struct ConditionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingCondition: DailyCondition?
    let onSave: () -> Void

    @State private var viewModel: ConditionViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    ConditionFormView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(existingCondition == nil ? "コンディション記録" : "コンディション編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel {
                        Button("保存") {
                            Task {
                                await vm.save(context: modelContext)
                                if vm.errorMessage == nil {
                                    onSave()
                                    dismiss()
                                }
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            let repo = WorkoutRepository(modelContext: modelContext)
            let condition = existingCondition ?? DailyCondition(date: .now)
            viewModel = ConditionViewModel(condition: condition, repository: repo, isNew: existingCondition == nil)
        }
    }
}

private struct ConditionFormView: View {
    @Bindable var viewModel: ConditionViewModel

    var body: some View {
        List {
            // MARK: コンディションスコア
            Section("コンディション") {
                ScorePickerView(
                    title: "体調",
                    icon: "heart.fill",
                    score: $viewModel.condition.conditionScore
                )
                .padding(.vertical, 4)

                ScorePickerView(
                    title: "睡眠の質",
                    icon: "moon.fill",
                    score: $viewModel.condition.sleepScore
                )
                .padding(.vertical, 4)

                ScorePickerView(
                    title: "疲労度（5=元気）",
                    icon: "bolt.fill",
                    score: $viewModel.condition.fatigueScore
                )
                .padding(.vertical, 4)
            }

            // MARK: 身体データ
            Section("身体データ") {
                numberRow(
                    title: "体重",
                    unit: "kg",
                    icon: "scalemass.fill",
                    value: $viewModel.condition.bodyWeight
                )
                numberRow(
                    title: "体脂肪率",
                    unit: "%",
                    icon: "percent",
                    value: $viewModel.condition.bodyFatPercentage
                )
                numberRow(
                    title: "タンパク質摂取量",
                    unit: "g",
                    icon: "fork.knife",
                    value: $viewModel.condition.proteinIntake
                )
            }

            // MARK: メモ
            Section("メモ") {
                TextField("体調や食事の詳細など", text: $viewModel.condition.notes, axis: .vertical)
                    .lineLimit(3...6)
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

    private func numberRow(title: String, unit: String, icon: String, value: Binding<Double>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

#Preview {
    ConditionView(existingCondition: nil, onSave: {})
        .modelContainer(for: [DailyCondition.self], inMemory: true)
}
