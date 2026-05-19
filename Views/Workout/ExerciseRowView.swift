import SwiftUI

private let intervalPresets: [(label: String, seconds: Int)] = [
    ("30秒", 30), ("1分", 60), ("90秒", 90),
    ("2分", 120), ("3分", 180), ("5分", 300)
]

struct ExerciseRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var exercise: WorkoutExercise
    let onAddSet: () -> Void
    let onDeleteSet: (ExerciseSet) -> Void
    let onDelete: () -> Void
    let onCompleteSet: (ExerciseSet) -> Void

    @State private var isExpanded = true
    @State private var showingIntervalPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            if isExpanded {
                Divider().padding(.horizontal)

                intervalSettingRow
                    .padding(.horizontal)
                    .padding(.top, 10)

                setsHeader
                    .padding(.horizontal)
                    .padding(.top, 6)

                ForEach(exercise.sortedSets) { set in
                    SetInputRow(
                        set: set,
                        onComplete: { onCompleteSet(set) },
                        onDelete: { onDeleteSet(set) }
                    )
                    .padding(.horizontal)
                }

                Button(action: onAddSet) {
                    Label("セットを追加", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }

                memoField
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        let completed = exercise.sortedSets.filter(\.isCompleted).count
                        Text("\(completed)/\(exercise.sets.count) セット完了")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding()
    }

    private var intervalSettingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("インターバル")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(intervalPresets, id: \.seconds) { preset in
                        Button(preset.label) {
                            withAnimation(.spring(response: 0.2)) {
                                exercise.defaultIntervalSeconds = preset.seconds
                            }
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            exercise.defaultIntervalSeconds == preset.seconds
                                ? Color.blue
                                : Color.secondary.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            exercise.defaultIntervalSeconds == preset.seconds ? .white : .primary
                        )
                        .animation(.spring(response: 0.2), value: exercise.defaultIntervalSeconds)
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var setsHeader: some View {
        HStack {
            Text("セット")
                .frame(width: 44, alignment: .center)
            Text("重量 (kg)")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("回数")
                .frame(maxWidth: .infinity, alignment: .center)
            // 完了ボタン列幅確保
            Spacer().frame(width: 84)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.bottom, 2)
    }

    private var memoField: some View {
        TextField("種目メモ", text: $exercise.memo)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textFieldStyle(.roundedBorder)
    }
}

// MARK: - SetInputRow

private struct SetInputRow: View {
    @Bindable var set: ExerciseSet
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.subheadline.bold())
                .foregroundStyle(set.isCompleted ? .white : .secondary)
                .frame(width: 28, height: 28)
                .background(set.isCompleted ? Color.green : Color.clear, in: Circle())
                .frame(width: 44)

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .disabled(set.isCompleted)
                .opacity(set.isCompleted ? 0.5 : 1)

            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .disabled(set.isCompleted)
                .opacity(set.isCompleted ? 0.5 : 1)

            HStack(spacing: 4) {
                // 完了ボタン
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onComplete()
                    }
                } label: {
                    Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(set.isCompleted ? .green : .blue)
                        .symbolEffect(.bounce, value: set.isCompleted)
                }
                .disabled(set.isCompleted)

                // 削除ボタン
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
            .frame(width: 84)
        }
        .padding(.vertical, 5)
        .background(
            set.isCompleted
                ? Color.green.opacity(0.08)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }
}
