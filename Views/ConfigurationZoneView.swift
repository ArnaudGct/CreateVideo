import SwiftUI

public struct ConfigurationZoneView: View {
    @ObservedObject var viewModel: CreateVideoViewModel
    @State private var selectedParam: ProjectParameter.ID?
    @Environment(\.dismiss) var dismiss
    
    public init(viewModel: CreateVideoViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // 2. Liste des Paramètres
            VStack(alignment: .leading, spacing: 8) {
                Text("Champs Personnalisés")
                    .font(.headline)
                Text("L'ordre et la valeur de ces champs définissent la structure finale du nom de vos projets.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aperçu du dossier généré :")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.config.finalProjectName(using: viewModel.parameters))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Caractère de séparation :")
                        Picker("", selection: $viewModel.projectNameSeparator) {
                            Text("Espace Tiret Espace ( - )").tag(" - ")
                            Text("Espace Underscore Espace ( _ )").tag(" _ ")
                            Text("Tiret (-)").tag("-")
                            Text("Underscore (_)").tag("_")
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                }
                .padding(.vertical, 8)
                
                Table(viewModel.parameters, selection: $selectedParam) {
                    TableColumn("Nom", value: \.name)
                    TableColumn("Type") { param in
                        Text(param.type.rawValue)
                    }
                    TableColumn("Requis") { param in
                        Text(param.isRequired ? "Oui" : "Non")
                    }
                }
                .frame(minHeight: 200)
                .background(Color(nsColor: .windowBackgroundColor))
                
                // Toolbar Ajout/Suppression
                HStack {
                    Button(action: {
                        let newParam = ProjectParameter(name: "Nouveau Champ")
                        viewModel.parameters.append(newParam)
                        PreferencesService.shared.customParameters = viewModel.parameters
                    }) {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if let idToRemove = selectedParam {
                            selectedParam = nil
                            DispatchQueue.main.async {
                                viewModel.parameters.removeAll { $0.id == idToRemove }
                                PreferencesService.shared.customParameters = viewModel.parameters
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedParam == nil)
                    
                    Divider()
                        .frame(height: 16)
                    
                    Button(action: {
                        if let idToMove = selectedParam,
                           let index = viewModel.parameters.firstIndex(where: { $0.id == idToMove }),
                           index > 0 {
                            viewModel.parameters.swapAt(index, index - 1)
                            PreferencesService.shared.customParameters = viewModel.parameters
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedParam == nil || viewModel.parameters.first?.id == selectedParam)
                    
                    Button(action: {
                        if let idToMove = selectedParam,
                           let index = viewModel.parameters.firstIndex(where: { $0.id == idToMove }),
                           index < viewModel.parameters.count - 1 {
                            viewModel.parameters.swapAt(index, index + 1)
                            PreferencesService.shared.customParameters = viewModel.parameters
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedParam == nil || viewModel.parameters.last?.id == selectedParam)
                    
                    Spacer()
                }
                .padding(.top, 8)
                
                if let id = selectedParam, let index = viewModel.parameters.firstIndex(where: { $0.id == id }) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Édition du champ")
                            .font(.subheadline).bold()
                        
                        Form {
                            TextField("Nom", text: Binding(
                                get: { viewModel.parameters[index].name },
                                set: { 
                                    viewModel.parameters[index].name = $0
                                    PreferencesService.shared.customParameters = viewModel.parameters
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            LabeledContent("Type") {
                                HStack {
                                    Picker("", selection: Binding(
                                        get: { viewModel.parameters[index].type },
                                        set: {
                                            viewModel.parameters[index].type = $0
                                            if $0 == .date {
                                                viewModel.parameters[index].defaultValue = "yyyy-MM-dd"
                                            } else {
                                                viewModel.parameters[index].defaultValue = ""
                                            }
                                            PreferencesService.shared.customParameters = viewModel.parameters
                                        }
                                    )) {
                                        ForEach(ParameterType.allCases) { t in
                                            Text(t.rawValue).tag(t)
                                        }
                                    }
                                    .labelsHidden()
                                    
                                    if viewModel.parameters[index].type == .date {
                                        Picker("", selection: Binding(
                                            get: { viewModel.parameters[index].defaultValue },
                                            set: { 
                                                viewModel.parameters[index].defaultValue = $0
                                                PreferencesService.shared.customParameters = viewModel.parameters
                                            }
                                        )) {
                                            Text("yyyy-MM-dd").tag("yyyy-MM-dd")
                                            Text("dd-MM-yyyy").tag("dd-MM-yyyy")
                                            Text("MM-dd-yyyy").tag("MM-dd-yyyy")
                                            Text("yyyyMMdd").tag("yyyyMMdd")
                                            Text("ddMMyyyy").tag("ddMMyyyy")
                                            Text("yy-MM-dd").tag("yy-MM-dd")
                                            Text("dd-MM-yy").tag("dd-MM-yy")
                                        }
                                        .labelsHidden()
                                    }
                                }
                            }
                            
                            Toggle("Requis (obligatoire)", isOn: Binding(
                                get: { viewModel.parameters[index].isRequired },
                                set: { 
                                    viewModel.parameters[index].isRequired = $0
                                    PreferencesService.shared.customParameters = viewModel.parameters
                                }
                            ))
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding()
                    .background(Color(nsColor: .windowBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Terminer") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 500)
    }
}
