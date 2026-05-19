import SwiftUI

struct ConditionCardView: View {
    let condition: DailyCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今日のコンディション")
                    .font(.subheadline.bold())
                Spacer()
                Text(condition.date.displayString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                scoreColumn(label: "体調", score: condition.conditionScore, icon: "heart.fill", color: .pink)
                Divider().frame(height: 40).padding(.horizontal, 8)
                scoreColumn(label: "睡眠", score: condition.sleepScore, icon: "moon.fill", color: .indigo)
                Divider().frame(height: 40).padding(.horizontal, 8)
                scoreColumn(label: "疲労度", score: condition.fatigueScore, icon: "bolt.fill", color: .orange)

                if condition.bodyWeight > 0 {
                    Divider().frame(height: 40).padding(.horizontal, 8)
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", condition.bodyWeight))
                            .font(.subheadline.bold())
                        Text("kg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func scoreColumn(label: String, score: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            scoreDots(score: score, color: color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func scoreDots(score: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= score ? color : color.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
