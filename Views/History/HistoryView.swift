import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var selectedSession: WorkoutSession?
    @State private var showingCalendar = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    HistoryContentView(
                        viewModel: vm,
                        selectedSession: $selectedSession
                    )
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
        }
        .task {
            let repo = WorkoutRepository(modelContext: modelContext)
            let vm = HistoryViewModel(repository: repo)
            viewModel = vm
            await vm.loadData()
        }
        .sheet(isPresented: $showingCalendar) {
            if let vm = viewModel {
                CalendarView(historyViewModel: vm)
            }
        }
        .sheet(item: $selectedSession) { session in
            WorkoutView(session: session)
                .onDisappear {
                    Task { await viewModel?.loadData() }
                }
        }
    }
}

private struct HistoryContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: HistoryViewModel
    @Binding var selectedSession: WorkoutSession?

    var body: some View {
        List {
            if viewModel.filteredSessions.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "履歴なし",
                    message: "トレーニングを記録すると\nここに表示されます"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.groupedSessions, id: \.0) { month, sessions in
                    Section(month) {
                        ForEach(sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                WorkoutCardView(session: session)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteSession(session, context: modelContext)
                                    }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $viewModel.searchText, prompt: "種目名で検索")
        .refreshable {
            await viewModel.loadData()
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
}

#Preview {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, ExerciseSet.self], inMemory: true)
}
