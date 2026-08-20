import Foundation
import AppKit

public class FileManagerService {
    public static let shared = FileManagerService()
    private let fileManager = FileManager.default
    
    // Default location: ~/Documents/ProjectBuilderTemplates
    public var defaultTemplatesDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let templatesPath = docs.appendingPathComponent("ProjectBuilderTemplates")
        if !fileManager.fileExists(atPath: templatesPath.path) {
            try? fileManager.createDirectory(at: templatesPath, withIntermediateDirectories: true, attributes: nil)
            createDefaultTemplate(at: templatesPath)
        }
        return templatesPath
    }
    
    private func createDefaultTemplate(at root: URL) {
        let templateName = "Template_Montage Vidéo"
        let defaultTemplate = root.appendingPathComponent(templateName)
        
        if let resourceURL = Bundle.module.url(forResource: "Template_Montage_Video", withExtension: nil) {
            try? fileManager.copyItem(at: resourceURL, to: defaultTemplate)
        } else {
            // Fallback (ne devrait normalement pas arriver si le bundle est correct)
            try? fileManager.createDirectory(at: defaultTemplate, withIntermediateDirectories: true, attributes: nil)
            try? fileManager.createDirectory(at: defaultTemplate.appendingPathComponent("1 - Rushs"), withIntermediateDirectories: true, attributes: nil)
            try? fileManager.createDirectory(at: defaultTemplate.appendingPathComponent("2 - Médias"), withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func getTemplates() -> [Template] {
        var templates: [Template] = []
        let directory = defaultTemplatesDirectory
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            for url in contents {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    let template = Template(name: url.lastPathComponent, sourceURL: url)
                    templates.append(template)
                }
            }
        } catch {
            print("Error reading templates: \(error)")
        }
        return templates
    }
    
    public func getTree(for url: URL) -> [FileNode]? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { return nil }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
            var children: [FileNode] = []
            
            for childURL in contents {
                var childIsDir: ObjCBool = false
                fileManager.fileExists(atPath: childURL.path, isDirectory: &childIsDir)
                
                if childIsDir.boolValue {
                    let grandChildren = getTree(for: childURL)
                    children.append(FileNode(url: childURL, isDirectory: true, children: grandChildren))
                } else {
                    children.append(FileNode(url: childURL, isDirectory: false, children: nil))
                }
            }
            // Sort: directories first, then alphabetical
            return children.sorted {
                if $0.isDirectory == $1.isDirectory {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.isDirectory && !$1.isDirectory
            }
        } catch {
            return nil
        }
    }
    
    public func openInFinder(url: URL) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    
    public func createTemplate(name: String) -> URL? {
        var newURL = defaultTemplatesDirectory.appendingPathComponent(name)
        var counter = 1
        
        while fileManager.fileExists(atPath: newURL.path) {
            newURL = defaultTemplatesDirectory.appendingPathComponent("\(name) \(counter)")
            counter += 1
        }
        
        do {
            try fileManager.createDirectory(at: newURL, withIntermediateDirectories: true, attributes: nil)
            return newURL
        } catch {
            print("Error creating template: \(error)")
            return nil
        }
    }
    
    public func createFolder(at parentURL: URL, name: String = "Nouveau Dossier", undoManager: UndoManager? = nil) -> URL? {
        var newURL = parentURL.appendingPathComponent(name)
        var counter = 1
        while fileManager.fileExists(atPath: newURL.path) {
            newURL = parentURL.appendingPathComponent("\(name) \(counter)")
            counter += 1
        }
        
        do {
            try fileManager.createDirectory(at: newURL, withIntermediateDirectories: true, attributes: nil)
            
            // Undo: supprimer le dossier qu'on vient de créer
            if let undo = undoManager {
                undo.registerUndo(withTarget: self) { target in
                    target.deleteItem(at: newURL, undoManager: undo)
                }
                undo.setActionName("Créer Dossier")
            }
            
            return newURL
        } catch {
            return nil
        }
    }
    
    public func createFile(at parentURL: URL, name: String, extension ext: String, undoManager: UndoManager? = nil) -> URL? {
        var baseName = name
        if baseName.isEmpty { baseName = "Nouveau Fichier" }
        
        var newURL = parentURL.appendingPathComponent("\(baseName).\(ext)")
        var counter = 1
        while fileManager.fileExists(atPath: newURL.path) {
            newURL = parentURL.appendingPathComponent("\(baseName) \(counter).\(ext)")
            counter += 1
        }
        
        if fileManager.createFile(atPath: newURL.path, contents: Data(), attributes: nil) {
            // Undo: supprimer le fichier qu'on vient de créer
            if let undo = undoManager {
                undo.registerUndo(withTarget: self) { target in
                    target.deleteItem(at: newURL, undoManager: undo)
                }
                undo.setActionName("Créer Fichier")
            }
            return newURL
        }
        return nil
    }
    
    public func deleteItem(at url: URL, undoManager: UndoManager? = nil) {
        do {
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
            
            // Undo: remettre l'élément de la corbeille à sa place
            if let trashedURL = resultingURL as URL?, let undo = undoManager {
                undo.registerUndo(withTarget: self) { target in
                    try? target.fileManager.moveItem(at: trashedURL, to: url)
                    
                    // Remettre en place permet de refaire Undo (Redo = Delete)
                    undo.registerUndo(withTarget: target) { target2 in
                        target2.deleteItem(at: url, undoManager: undo)
                    }
                }
                undo.setActionName("Supprimer")
            }
        } catch {
            print("Erreur suppression: \(error)")
        }
    }
    
    public func renameItem(at url: URL, newName: String, undoManager: UndoManager? = nil) -> URL? {
        let parentURL = url.deletingLastPathComponent()
        let oldName = url.lastPathComponent
        
        var finalName = newName
        var newURL = parentURL.appendingPathComponent(finalName)
        var counter = 1
        
        while fileManager.fileExists(atPath: newURL.path) && finalName != oldName {
            finalName = "\(newName) \(counter)"
            newURL = parentURL.appendingPathComponent(finalName)
            counter += 1
        }
        
        if finalName == oldName {
            return url
        }
        
        do {
            try fileManager.moveItem(at: url, to: newURL)
            
            // Undo: renommer avec l'ancien nom
            if let undo = undoManager {
                undo.registerUndo(withTarget: self) { target in
                    _ = target.renameItem(at: newURL, newName: oldName, undoManager: undo)
                }
                undo.setActionName("Renommer")
            }
            return newURL
        } catch {
            return nil
        }
    }
}
