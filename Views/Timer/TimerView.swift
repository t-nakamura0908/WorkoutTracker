import SwiftUI

struct TimerView: View {
    @State private var viewModel = TimerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                timerRing

                presetButtons

                controlButtons

                Spacer()
            }
            .padding()
            .navigationTitle("タイマー")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished {
                triggerHaptic()
            }
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 16)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.isFinished ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)

            VStack(spacing: 8) {
                Text(viewModel.displayTime)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(viewModel.isFinished ? .green : .primary)

                if viewModel.isFinished {
                    Text("完了！")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: 260, height: 260)
        .padding()
    }

    private var presetButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プリセット")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.presets, id: \.self) { seconds in
                        Button {
                            withAnimation {
                                viewModel.setPreset(seconds)
                            }
                        } label: {
                            Text(formatPreset(seconds))
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.totalSeconds == seconds && !viewModel.isRunning
                                        ? Color.blue
                                        : Color.secondary.opacity(0.15),
                                    in: Capsule()
                                )
                                .foregroundStyle(
                                    viewModel.totalSeconds == seconds && !viewModel.isRunning
                                        ? .white
                                        : .primary
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 24) {
            Button {
                withAnimation {
                    viewModel.reset()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(.regularMaterial, in: Circle())
            }
            .foregroundStyle(.primary)

            Button {
                withAnimation {
                    if viewModel.isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                    }
                }
            } label: {
                Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(viewModel.isRunning ? Color.orange : Color.blue, in: Circle())
                    .foregroundStyle(.white)
            }

            Color.clear
                .frame(width: 60, height: 60)
        }
    }

    private func formatPreset(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)秒"
        } else {
            return "\(seconds / 60)分"
        }
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    TimerView()
}
