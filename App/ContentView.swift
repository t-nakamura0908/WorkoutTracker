import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
                .tag(1)

            ChartsView()
                .tabItem {
                    Label("グラフ", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            TimerView()
                .tabItem {
                    Label("タイマー", systemImage: "timer")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self], inMemory: true)
}
