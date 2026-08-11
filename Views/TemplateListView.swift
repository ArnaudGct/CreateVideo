import SwiftUI

public struct TemplateListView: View {
    @ObservedObject var viewModel: CreateVideoViewModel
    @State private var templateToEdit: Template?
    @Environment(\.dismiss) var dismiss
    
    public init(viewModel: CreateVideoViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Colonne de gauche : Liste des templates avec CRUD
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(viewModel.templates) { template in
                                let isSelected = templateToEdit?.id == template.id
                                Text(template.name)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(isSelected ? Color.accentColor : Color.clear)
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(6)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        templateToEdit = template
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .onAppear {
                        if templateToEdit == nil {
                            templateToEdit = viewModel.templates.first
                        }
                    }
                    
                    Divider()
                    
                    // Toolbar ajout/suppression
                    HStack {
                        Button(action: createNewTemplate) {
                            Image(systemName: "plus")
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if let template = templateToEdit {
                                FileManagerService.shared.deleteItem(at: template.sourceURL)
                                viewModel.loadTemplates()
                                if viewModel.templates.isEmpty {
                                    templateToEdit = nil
                                } else if !viewModel.templates.contains(where: { $0.id == template.id }) {
                                    templateToEdit = viewModel.templates.first
                                }
                            }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(templateToEdit == nil)
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(nsColor: .windowBackgroundColor))
                }
                .frame(minWidth: 200, maxWidth: 300)
                .background(Color(nsColor: .windowBackgroundColor))
                
                // Colonne de droite : Éditeur d'arborescence
                VStack {
                    if let tpl = templateToEdit ?? viewModel.templates.first {
                        TemplateEditorView(template: tpl)
                    } else {
                        VStack {
                            Spacer()
                            Text("Aucun template sélectionné")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(minWidth: 700, minHeight: 500)
            
            Divider()
            
            HStack {
                Spacer()
                Button("Terminer") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }
    
    private func createNewTemplate() {
        if let newURL = FileManagerService.shared.createTemplate(name: "Nouveau Template") {
            viewModel.loadTemplates()
            templateToEdit = viewModel.templates.first(where: { $0.sourceURL == newURL })
        }
    }
}
