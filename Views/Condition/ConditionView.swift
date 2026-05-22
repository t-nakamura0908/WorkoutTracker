import SwiftUI
import SwiftData

struct ConditionView: View {
    @Environment(\.modelContext) private var mainContext
    @Environment(\.dismiss) private var dismiss

    let existingCondition: DailyCondition?

    @State private var editContext: ModelContext?
    @State private var viewModel: ConditionViewModel?
    @State private var showingCancelConfirmation = false
    @State private var didSave = false

    private var hasUnsavedChanges: Bool {
        viewModel?.isDirty == true && !didSave
    }

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
                    Button {
                        if hasUnsavedChanges {
                            showingCancelConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.medium)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel, let ctx = editContext {
                        Button("保存") {
                            do {
                                try ctx.save()
                                didSave = true
                                dismiss()
                            } catch {
                                vm.errorMessage = error.localizedDescription
                            }
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

    private func setupEditContext() {
        let ctx = ModelContext(mainContext.container)
        ctx.autosaveEnabled = false
        editContext = ctx

        let repo = WorkoutRepository(modelContext: ctx)
        let condition: DailyCondition
        if let existing = existingCondition,
           let fetched = try? repo.fetchCondition(for: existing.date) {
            condition = fetched
        } else {
            condition = DailyCondition(date: .now)
            ctx.insert(condition)
        }
        viewModel = ConditionViewModel(condition: condition)
    }
}

// MARK: - ConditionFormView

private struct ConditionFormView: View {
    @Bindable var viewModel: ConditionViewModel

    enum Field: Hashable {
        case bodyWeight, bodyFat, protein, notes
    }
    @FocusState private var focusedField: Field?

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
                .onChange(of: viewModel.condition.conditionScore) { _, _ in viewModel.isDirty = true }

                ScorePickerView(
                    title: "睡眠の質",
                    icon: "moon.fill",
                    score: $viewModel.condition.sleepScore
                )
                .padding(.vertical, 4)
                .onChange(of: viewModel.condition.sleepScore) { _, _ in viewModel.isDirty = true }

                ScorePickerView(
                    title: "疲労度（5=元気）",
                    icon: "bolt.fill",
                    score: $viewModel.condition.fatigueScore
                )
                .padding(.vertical, 4)
                .onChange(of: viewModel.condition.fatigueScore) { _, _ in viewModel.isDirty = true }
            }

            // MARK: 身体データ
            Section("身体データ") {
                numberRow(
                    title: "体重",
                    unit: "kg",
                    icon: "scalemass.fill",
                    value: $viewModel.condition.bodyWeight,
                    field: .bodyWeight,
                    next: .bodyFat
                )
                numberRow(
                    title: "体脂肪率",
                    unit: "%",
                    icon: "percent",
                    value: $viewModel.condition.bodyFatPercentage,
                    field: .bodyFat,
                    next: .protein
                )
                numberRow(
                    title: "タンパク質摂取量",
                    unit: "g",
                    icon: "fork.knife",
                    value: $viewModel.condition.proteinIntake,
                    field: .protein,
                    next: .notes
                )
            }

            // MARK: メモ
            Section("メモ") {
                TextField("体調や食事の詳細など", text: $viewModel.condition.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .notes)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                    .onChange(of: viewModel.condition.notes) { _, _ in viewModel.isDirty = true }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("エラー", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func numberRow(
        title: String,
        unit: String,
        icon: String,
        value: Binding<Double>,
        field: Field,
        next: Field
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(focusedField == field ? .blue : .secondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.15), value: focusedField)

            Text(title)

            Spacer()

            TextField("未入力", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { focusedField = next }
                .onChange(of: value.wrappedValue) { _, _ in viewModel.isDirty = true }

            Text(unit)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedField = field }
    }
}

#Preview {
    ConditionView(existingCondition: nil)
        .modelContainer(for: [DailyCondition.self], inMemory: true)
}
