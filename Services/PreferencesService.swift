import Foundation

public class PreferencesService {
    public static let shared = PreferencesService()
    
    private let defaults = UserDefaults.standard
    
    private let lastDestinationKey = "lastDestinationURL"
    private let lastTemplateKey = "lastTemplateID"
    private let parametersKey = "customParameters"
    private let separatorKey = "projectNameSeparator"
    private let openInFinderKey = "openInFinderAfterCreation"
    private let quitAfterCreationKey = "quitAfterCreation"
    
    public var lastDestinationURL: URL? {
        get {
            if let path = defaults.string(forKey: lastDestinationKey) {
                return URL(fileURLWithPath: path)
            }
            return nil
        }
        set {
            defaults.set(newValue?.path, forKey: lastDestinationKey)
        }
    }
    
    public var customParameters: [ProjectParameter] {
        get {
            if let data = defaults.data(forKey: parametersKey),
               let params = try? JSONDecoder().decode([ProjectParameter].self, from: data) {
                return params
            }
            return [
                ProjectParameter(name: "Client", type: .text),
                ProjectParameter(name: "Nom du Projet", isRequired: true, type: .text)
            ]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: parametersKey)
            }
        }
    }
    
    public var lastTemplateID: String? {
        get { defaults.string(forKey: lastTemplateKey) }
        set { defaults.set(newValue, forKey: lastTemplateKey) }
    }
    
    public var projectNameSeparator: String {
        get { defaults.string(forKey: separatorKey) ?? "_" }
        set { defaults.set(newValue, forKey: separatorKey) }
    }
    
    public var openInFinderAfterCreation: Bool {
        get { defaults.object(forKey: openInFinderKey) == nil ? true : defaults.bool(forKey: openInFinderKey) }
        set { defaults.set(newValue, forKey: openInFinderKey) }
    }
    
    public var quitAfterCreation: Bool {
        get { defaults.bool(forKey: quitAfterCreationKey) }
        set { defaults.set(newValue, forKey: quitAfterCreationKey) }
    }
}
