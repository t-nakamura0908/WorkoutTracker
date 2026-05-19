import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate?
    let onSave: () -> Void

    @State private var editorVM: TemplateEditorViewModel?
    @State private var showingAddExercise = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = editorVM {
                    TemplateEditorContentView(
                        vm: vm,
                        showingAddExercise: $showingAddExercise
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(template == nil ? "新規テンプレート" : "テンプレート編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = editorVM {
                        Button("保存") {
                            vm.save(context: modelContext)
                            if vm.errorMessage == nil {
                                onSave()
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!vm.isValid)
                    }
                }
            }
        }
        .onAppear {
            editorVM = TemplateEditorViewModel(template: template)
        }
        .sheet(isPresented: $showingAddExercise) {
            if let vm = editorVM {
                AddExerciseView { name in
                    vm.addExercise(name: name)
                }
            }
        }
    }
}

private struct TemplateEditorContentView: View {
    @Bindable var vm: TemplateEditorViewModel
    @Binding var showingAddExercise: Bool

    var body: some View {
        List {
            Section("テンプレート名") {
                TextField("例: 胸・肩の日", text: $vm.name)
            }

            Section {
                if vm.exercises.isEmpty {
                    Text("種目がありません\n下のボタンで追加してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    ForEach($vm.exercises) { $ex in
                        TemplateExerciseRow(exercise: $ex)
                    }
                    .onDelete { vm.deleteExercise(at: $0) }
                    .onMove { vm.moveExercise(from: $0, to: $1) }
                }
            } header: {
                HStack {
                    Text("種目")
                    Spacer()
                    Text("長押しで並び替え")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Button {
                    showingAddExercise = true
                } label: {
                    Label("種目を追加", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .alert("エラー", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}

private struct TemplateExerciseRow: View {
    @Binding var exercise: TemplateExercise

    private let intervalPresets: [(String, Int)] = [
        ("30秒", 30), ("1分", 60), ("90秒", 90),
        ("2分", 120), ("3分", 180), ("5分", 300)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.subheadline.bold())

            HStack(spacing: 16) {
                stepperField(title: "セット", value: $exercise.defaultSets, range: 1...10)
                Divider().frame(height: 32)
                numericField(title: "重量(kg)", value: $exercise.defaultWeight)
                Divider().frame(height: 32)
                stepperField(title: "回数", value: $exercise.defaultReps, range: 1...100)
            }
            .font(.caption)

            // インターバル選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(intervalPresets, id: \.1) { label, seconds in
                        Button(label) {
                            exercise.defaultIntervalSeconds = seconds
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            exercise.defaultIntervalSeconds == seconds
                                ? Color.blue : Color.secondary.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            exercise.defaultIntervalSeconds == seconds ? .white : .primary
                        )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func stepperField(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                    Image(systemName: "minus.circle").foregroundStyle(.blue)
                }
                Text("\(value.wrappedValue)").frame(minWidth: 20)
                Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                    Image(systemName: "plus.circle").foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func numericField(title: String, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TemplateDetailView(template: nil, onSave: {})
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}
