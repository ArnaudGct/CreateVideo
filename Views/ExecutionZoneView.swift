import SwiftUI

public struct ExecutionZoneView: View {
    @ObservedObject var viewModel: CreateVideoViewModel
    
    @State private var isShowingTemplatesConfig = false
    @State private var isShowingParametersConfig = false
    
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    public init(viewModel: CreateVideoViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Colonne de gauche : Templates
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Templates")
                        .font(.headline)
                    Spacer()
                    Button {
                        isShowingTemplatesConfig = true
                    } label: {
                        Label("Configurer", systemImage: "gearshape")
                    }
                    .controlSize(.small)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(viewModel.templates) { template in
                            let isSelected = viewModel.selectedTemplateID == template.id
                            Text(template.name)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(isSelected ? Color.accentColor : Color.clear)
                                .foregroundColor(isSelected ? .white : .primary)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedTemplateID = template.id
                                }
                        }
                    }
                    .padding(8)
                }
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Colonne de droite : Paramètres Dynamiques
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Nouveau Projet")
                        .font(.headline)
                    Spacer()
                    Button {
                        isShowingParametersConfig = true
                    } label: {
                        Label("Configurer", systemImage: "gearshape")
                    }
                    .controlSize(.small)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.parameters) { param in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(param.name)
                                        .font(.headline)
                                    if param.isRequired {
                                        Text("*").foregroundColor(.red)
                                    }
                                }
                                
                                if param.type == .date {
                                    DatePicker("", selection: Binding(
                                        get: { viewModel.dynamicDates[param.id] ?? Date() },
                                        set: { newDate in
                                            viewModel.dynamicDates[param.id] = newDate
                                            viewModel.updateDate(for: param.id, date: newDate, format: param.defaultValue)
                                        }
                                    ), displayedComponents: .date)
                                    .labelsHidden()
                                } else {
                                    TextField("", text: Binding(
                                        get: { viewModel.config.dynamicValues[param.id] ?? "" },
                                        set: { viewModel.config.dynamicValues[param.id] = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                        
                        // Preview
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
                        .padding(.top, 8)
                        
                        Divider().padding(.vertical, 8)
                        
                        // Destination
                        PathRowView(
                            title: "Dossier de Destination",
                            pathURL: viewModel.config.destinationURL,
                            action: { viewModel.selectDestination() }
                        )
                        
                    }
                    .padding(6)
                }
                
                Spacer()
                
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Ouvrir dans le Finder après création", isOn: $viewModel.openInFinderAfterCreation)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Fermer l'application après création", isOn: $viewModel.quitAfterCreation)
                        .toggleStyle(.checkbox)
                }
                .padding(.vertical, 4)
                .font(.caption)
                .foregroundColor(.secondary)
                
                Button(action: { viewModel.generate() }) {
                    Text(viewModel.isGenerating ? "Génération..." : "Créer le projet")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isGenerating)
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
            .frame(minWidth: 400, maxWidth: .infinity)
        }
        .sheet(isPresented: $isShowingTemplatesConfig) {
            TemplateListView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingParametersConfig) {
            ConfigurationZoneView(viewModel: viewModel)
        }
    }
}
