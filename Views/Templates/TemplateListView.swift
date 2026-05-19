import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TemplateViewModel?
    @State private var showingCreate = false
    @State private var editingTemplate: WorkoutTemplate?

    /// nil なら選択モードなし（管理画面として使用）
    var onSelect: ((WorkoutTemplate) -> Void)? = nil

    var body: some View {
        Group {
            if let vm = viewModel {
                TemplateListContentView(
                    viewModel: vm,
                    onSelect: onSelect,
                    onEdit: { editingTemplate = $0 }
                )
            } else {
                ProgressView()
            }
        }
        .navigationTitle("テンプレート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onSelect != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            let repo = WorkoutRepository(modelContext: modelContext)
            let vm = TemplateViewModel(repository: repo)
            viewModel = vm
            await vm.loadTemplates()
        }
        .sheet(isPresented: $showingCreate) {
            TemplateDetailView(template: nil) {
                Task { await viewModel?.loadTemplates() }
            }
        }
        .sheet(item: $editingTemplate) { template in
            TemplateDetailView(template: template) {
                Task { await viewModel?.loadTemplates() }
            }
        }
    }
}

private struct TemplateListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TemplateViewModel
    let onSelect: ((WorkoutTemplate) -> Void)?
    let onEdit: (WorkoutTemplate) -> Void

    var body: some View {
        List {
            if viewModel.templates.isEmpty {
                EmptyStateView(
                    icon: "rectangle.stack.badge.plus",
                    title: "テンプレートなし",
                    message: "右上の＋でよく使うメニューを\nテンプレートとして保存できます"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .frame(height: 280)
            } else {
                ForEach(viewModel.templates) { template in
                    TemplateRowView(
                        template: template,
                        onSelect: onSelect != nil ? { onSelect?(template) } : nil,
                        onEdit: { onEdit(template) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteTemplate(template, context: modelContext)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        Button {
                            onEdit(template)
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct TemplateRowView: View {
    let template: WorkoutTemplate
    let onSelect: (() -> Void)?
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Text("\(template.exercises.count)種目")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !template.sortedExercises.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(template.sortedExercises) { ex in
                        HStack(spacing: 6) {
                            Circle().fill(.blue.opacity(0.4)).frame(width: 5, height: 5)
                            Text(ex.name)
                                .font(.caption)
                            Spacer()
                            Text("\(ex.defaultSets)×\(ex.defaultReps)回")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let onSelect {
                Button("このテンプレートを適用", action: onSelect)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
