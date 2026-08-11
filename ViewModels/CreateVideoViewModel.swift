import Foundation
import AppKit
import Combine

@MainActor
public class CreateVideoViewModel: ObservableObject {
    @Published public var config = ProjectConfiguration()
    @Published public var templates: [Template] = []
    @Published public var selectedTemplateID: UUID? {
        didSet {
            if let id = selectedTemplateID {
                PreferencesService.shared.lastTemplateID = id.uuidString
            }
        }
    }
    
    @Published public var parameters: [ProjectParameter] = []
    
    // Binding for DatePickers
    @Published public var dynamicDates: [UUID: Date] = [:]
    
    @Published public var isGenerating: Bool = false
    @Published public var errorMessage: String?
    
    @Published public var projectNameSeparator: String = "_" {
        didSet {
            PreferencesService.shared.projectNameSeparator = projectNameSeparator
            config.separator = projectNameSeparator
        }
    }
    
    @Published public var openInFinderAfterCreation: Bool = true {
        didSet { PreferencesService.shared.openInFinderAfterCreation = openInFinderAfterCreation }
    }
    
    @Published public var quitAfterCreation: Bool = false {
        didSet { PreferencesService.shared.quitAfterCreation = quitAfterCreation }
    }
    
    private let fileSystem = FileManagerService.shared
    private let preferences = PreferencesService.shared
    private let engine = TemplateEngineService()
    
    public init() {
        loadTemplates()
        reloadPreferences()
        
        if let dest = preferences.lastDestinationURL {
            config.destinationURL = dest
        }
        
        if let lastTpl = preferences.lastTemplateID, let id = UUID(uuidString: lastTpl), templates.contains(where: { $0.id == id }) {
            selectedTemplateID = id
        } else {
            selectedTemplateID = templates.first?.id
        }
    }
    
    public func reloadPreferences() {
        parameters = preferences.customParameters
        projectNameSeparator = preferences.projectNameSeparator
        openInFinderAfterCreation = preferences.openInFinderAfterCreation
        quitAfterCreation = preferences.quitAfterCreation
        config.separator = projectNameSeparator
        
        // Initialiser les valeurs dynamiques avec les valeurs par défaut
        var initialValues: [UUID: String] = [:]
        for param in parameters {
            if param.type == .date {
                let formatter = DateFormatter()
                formatter.dateFormat = param.defaultValue.isEmpty ? "yyyy-MM-dd" : param.defaultValue
                let now = Date()
                dynamicDates[param.id] = now
                initialValues[param.id] = formatter.string(from: now)
            } else {
                initialValues[param.id] = param.defaultValue
            }
        }
        config.dynamicValues = initialValues
    }
    
    public func updateDate(for id: UUID, date: Date, format: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = format.isEmpty ? "yyyy-MM-dd" : format
        config.dynamicValues[id] = formatter.string(from: date)
    }
    
    public func loadTemplates() {
        templates = fileSystem.getTemplates()
    }
    
    public var selectedTemplate: Template? {
        templates.first { $0.id == selectedTemplateID }
    }
    
    public func selectDestination() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Sélectionner la destination"
        
        if panel.runModal() == .OK, let url = panel.url {
            config.destinationURL = url
            preferences.lastDestinationURL = url
        }
    }
    
    public func generate() {
        guard let template = selectedTemplate else {
            errorMessage = "Veuillez sélectionner un template."
            return
        }
        
        guard config.destinationURL != nil else {
            errorMessage = "Veuillez sélectionner un dossier de destination."
            return
        }
        
        // Vérifier les champs requis
        for param in parameters where param.isRequired {
            let val = config.dynamicValues[param.id] ?? ""
            if val.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "Le champ '\(param.name)' est requis."
                return
            }
        }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let url = try await engine.generateProject(from: template, config: config, parameters: parameters)
                
                preferences.lastTemplateID = template.id.uuidString
                
                if openInFinderAfterCreation {
                    fileSystem.openInFinder(url: url)
                }
                
                if quitAfterCreation {
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                }
                
            } catch TemplateEngineServiceError.destinationExists {
                errorMessage = "Un dossier avec ce nom existe déjà à la destination."
            } catch {
                errorMessage = "Erreur lors de la génération : \(error.localizedDescription)"
            }
            
            isGenerating = false
        }
    }
}
