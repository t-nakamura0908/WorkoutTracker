import SwiftUI

struct ScorePickerView: View {
    let title: String
    let icon: String
    @Binding var score: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(scoreColor(score))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            score = value
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(score >= value ? scoreColor(value) : Color.secondary.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Text("\(value)")
                                .font(.caption.bold())
                                .foregroundStyle(score >= value ? .white : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func scoreColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .blue
        }
    }
}

#Preview {
    @Previewable @State var score = 3
    ScorePickerView(title: "体調", icon: "heart.fill", score: $score)
        .padding()
}
