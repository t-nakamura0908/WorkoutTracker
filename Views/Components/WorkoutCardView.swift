import SwiftUI

struct WorkoutCardView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(session.date.displayString)
                    .font(.subheadline.bold())
                Spacer()
                if session.date.isToday {
                    Text("今日")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue, in: Capsule())
                }
            }

            if !session.sortedExercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.sortedExercises.prefix(3)) { exercise in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.blue.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text(exercise.name)
                                .font(.caption)
                            Spacer()
                            Text("\(exercise.sets.count)セット")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if session.sortedExercises.count > 3 {
                        Text("他 \(session.sortedExercises.count - 3) 種目")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 16) {
                Label("\(session.totalSets)セット", systemImage: "repeat")
                Label(String(format: "%.0fkg", session.totalVolume), systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
