import Foundation
import AppKit

public enum TemplateEngineServiceError: Error {
    case destinationExists
    case copyFailed
    case renameFailed
}

public class TemplateEngineService {
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func generateProject(from template: Template, config: ProjectConfiguration, parameters: [ProjectParameter]) async throws -> URL {
        let finalName = config.finalProjectName(using: parameters)
        let destinationFolder = config.destinationURL!.appendingPathComponent(finalName)
        
        // 1. Vérifier si la destination existe
        if fileManager.fileExists(atPath: destinationFolder.path) {
            throw TemplateEngineServiceError.destinationExists
        }
        
        // 2. Copier l'arborescence complète
        do {
            try fileManager.copyItem(at: template.sourceURL, to: destinationFolder)
        } catch {
            throw TemplateEngineServiceError.copyFailed
        }
        
        // 3. Remplacement dynamique (Deep-first)
        try processDirectory(at: destinationFolder, config: config, parameters: parameters)
        
        return destinationFolder
    }
    
    private func processDirectory(at url: URL, config: ProjectConfiguration, parameters: [ProjectParameter]) throws {
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        
        for itemURL in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Appel récursif *avant* de renommer le dossier parent
                    try processDirectory(at: itemURL, config: config, parameters: parameters)
                }
                
                // Remplacement dans le nom du fichier/dossier
                let oldName = itemURL.lastPathComponent
                var newName = oldName
                
                // Replace [template] with the final project name
                let finalProjectName = config.finalProjectName(using: parameters)
                newName = newName.replacingOccurrences(of: "[template]", with: finalProjectName)
                
                // Replace any [Field Name] with its dynamic value
                for param in parameters {
                    let token = "[\(param.name)]"
                    if let value = config.dynamicValues[param.id], !value.isEmpty {
                        newName = newName.replacingOccurrences(of: token, with: value)
                    } else {
                        // Si vide, on retire juste les crochets ou on laisse vide selon le besoin
                        // Ici, on remplace par le nom du champ pour éviter des fichiers sans nom
                        newName = newName.replacingOccurrences(of: token, with: param.name)
                    }
                }
                
                if newName != oldName {
                    let newURL = itemURL.deletingLastPathComponent().appendingPathComponent(newName)
                    do {
                        try fileManager.moveItem(at: itemURL, to: newURL)
                    } catch {
                        throw TemplateEngineServiceError.renameFailed
                    }
                }
            }
        }
    }
}
