import SwiftUI

struct ExerciseRowView: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: WorkoutExercise
    let onAddSet: () -> Void
    let onDeleteSet: (ExerciseSet) -> Void
    let onDelete: () -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            if isExpanded {
                Divider()
                    .padding(.horizontal)

                setsHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(exercise.sortedSets) { set in
                    SetInputRow(
                        set: set,
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

                if !exercise.memo.isEmpty || true {
                    memoField
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

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
                        Text("\(exercise.sets.count)セット")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding()
    }

    private var setsHeader: some View {
        HStack {
            Text("セット")
                .frame(width: 44, alignment: .center)
            Text("重量 (kg)")
                .frame(maxWidth: .infinity, alignment: .center)
            Text("回数")
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
                .frame(width: 44)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var memoField: some View {
        TextField("種目メモ", text: Binding(
            get: { exercise.memo },
            set: { exercise.memo = $0 }
        ))
        .font(.caption)
        .foregroundStyle(.secondary)
        .textFieldStyle(.roundedBorder)
    }
}

private struct SetInputRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var set: ExerciseSet
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .center)

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .frame(width: 44, alignment: .center)
        }
        .padding(.vertical, 4)
    }
}
