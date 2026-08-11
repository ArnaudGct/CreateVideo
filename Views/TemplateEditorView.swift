import SwiftUI
import AppKit

public struct TemplateEditorView: View {
    let template: Template
    @State private var nodes: [FileNode] = []
    @State private var selectedNodeId: URL?
    @State private var renamingNodeId: URL?
    @State private var newName: String = ""
    @Environment(\.undoManager) var undoManager
    
    // Pour gérer l'ouverture automatique des dossiers
    @State private var expandedNodes: Set<URL> = []
    
    public init(template: Template) {
        self.template = template
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Contenu de : \(template.name)")
                    .font(.headline)
                
                Spacer()
                
                Button("Ouvrir dans le Finder") {
                    FileManagerService.shared.openInFinder(url: template.sourceURL)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding()
            
            Divider()
            
            if nodes.isEmpty {
                VStack {
                    Spacer()
                    Text("Ce template est vide.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(selection: $selectedNodeId) {
                    ForEach(nodes) { node in
                        NodeRow(
                            node: node,
                            selectedNodeId: $selectedNodeId,
                            renamingNodeId: $renamingNodeId,
                            newName: $newName,
                            expandedNodes: $expandedNodes,
                            commitRenameAction: commitRename,
                            createItemAction: createItem,
                            deleteItemAction: deleteItem
                        )
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .onDeleteCommand {
                    if let url = selectedNodeId {
                        deleteItem(at: url)
                    }
                }
                // Add support for the Return key to rename
                .background(
                    Button("") {
                        if let id = selectedNodeId {
                            let node = findNode(id: id, in: nodes)
                            if let node = node {
                                renamingNodeId = node.url
                                newName = node.name
                            }
                        }
                    }
                    .keyboardShortcut(.defaultAction) // this maps to Return key
                    .opacity(0)
                )
            }
            
            Divider()
            
            // Bottom Toolbar
            HStack(spacing: 16) {
                Menu {
                    FileCreationMenuContent { type in
                        createItem(type: type, in: selectedNodeUrl)
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .menuIndicator(.hidden) // Supprime la flèche moche
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Button(action: {
                    if let url = selectedNodeId {
                        deleteItem(at: url)
                    }
                }) {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(selectedNodeId == nil)
                
                Spacer()
            }
            .padding(8)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            refreshTree()
        }
        .onChange(of: template) { _ in
            selectedNodeId = nil
            renamingNodeId = nil
            expandedNodes.removeAll()
            refreshTree()
        }
        .onChange(of: selectedNodeId) { newSelected in
            // Si on change de sélection alors qu'on renomme, on annule le mode édition
            if renamingNodeId != nil && renamingNodeId != newSelected {
                renamingNodeId = nil
            }
        }
    }
    
    // MARK: - Logic
    
    private var selectedNodeUrl: URL? {
        guard let id = selectedNodeId else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: id.path, isDirectory: &isDir), isDir.boolValue {
            return id
        } else {
            return id.deletingLastPathComponent()
        }
    }
    
    internal enum CreateType {
        case folder
        case file(String)
    }
    
    private func createItem(type: CreateType, in parent: URL?) {
        let destination = parent ?? template.sourceURL
        var createdURL: URL?
        
        switch type {
        case .folder:
            createdURL = FileManagerService.shared.createFolder(at: destination, undoManager: undoManager)
        case .file(let ext):
            createdURL = FileManagerService.shared.createFile(at: destination, name: "[template]", extension: ext, undoManager: undoManager)
        }
        
        // Auto-expand the parent folder so the user sees the new item
        expandedNodes.insert(destination)
        
        refreshTree()
        
        // Select the newly created item
        if let newURL = createdURL {
            selectedNodeId = newURL
        }
    }
    
    private func deleteItem(at url: URL) {
        FileManagerService.shared.deleteItem(at: url, undoManager: undoManager)
        if selectedNodeId == url {
            selectedNodeId = nil
        }
        refreshTree()
    }
    
    private func refreshTree() {
        if let tree = FileManagerService.shared.getTree(for: template.sourceURL) {
            self.nodes = tree
        } else {
            self.nodes = []
        }
    }
    
    private func findNode(id: URL, in nodes: [FileNode]) -> FileNode? {
        for node in nodes {
            if node.id == id { return node }
            if let children = node.children, let found = findNode(id: id, in: children) {
                return found
            }
        }
        return nil
    }
    
    private func commitRename(for node: FileNode) {
        var finalName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalName.isEmpty {
            finalName = node.isDirectory ? "Nouveau Dossier" : "Nouveau Fichier"
        }
        
        if finalName != node.name {
            if let newURL = FileManagerService.shared.renameItem(at: node.url, newName: finalName, undoManager: undoManager) {
                if selectedNodeId == node.id {
                    selectedNodeId = newURL
                }
            }
        }
        renamingNodeId = nil
        refreshTree()
    }
}

// Vue récursive personnalisée pour gérer l'ouverture manuelle (DisclosureGroup)
private struct NodeRow: View {
    let node: FileNode
    @Binding var selectedNodeId: URL?
    @Binding var renamingNodeId: URL?
    @Binding var newName: String
    @Binding var expandedNodes: Set<URL>
    
    @FocusState private var isFocused: Bool
    
    let commitRenameAction: (FileNode) -> Void
    let createItemAction: (TemplateEditorView.CreateType, URL?) -> Void
    let deleteItemAction: (URL) -> Void
    
    var body: some View {
        if let children = node.children, !children.isEmpty {
            DisclosureGroup(isExpanded: Binding(
                get: { expandedNodes.contains(node.url) },
                set: { isExpanded in
                    if isExpanded { expandedNodes.insert(node.url) }
                    else { expandedNodes.remove(node.url) }
                }
            )) {
                ForEach(children) { child in
                    NodeRow(
                        node: child,
                        selectedNodeId: $selectedNodeId,
                        renamingNodeId: $renamingNodeId,
                        newName: $newName,
                        expandedNodes: $expandedNodes,
                        commitRenameAction: commitRenameAction,
                        createItemAction: createItemAction,
                        deleteItemAction: deleteItemAction
                    )
                }
            } label: {
                nodeContent
            }
        } else {
            nodeContent
        }
    }
    
    @ViewBuilder
    var nodeContent: some View {
        HStack {
            if node.isDirectory {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFileType: node.url.pathExtension).resizedForMenu())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            
            if renamingNodeId == node.id {
                TextField("Nom", text: $newName)
                .textFieldStyle(.plain)
                .padding(2)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .focused($isFocused)
                .onAppear {
                    newName = node.name
                    DispatchQueue.main.async {
                        isFocused = true
                    }
                }
                .onChange(of: isFocused) { focused in
                    if !focused && renamingNodeId == node.id {
                        commitRenameAction(node)
                    }
                }
                .onSubmit {
                    commitRenameAction(node)
                }
                .onTapGesture {
                    // Empêche la sélection de liste de voler le focus au champ de texte
                }
            } else {
                Text(node.name)
            }
            Spacer()
        }
        .tag(node.url)
        .contextMenu {
            if node.isDirectory {
                FileCreationMenuContent { type in
                    createItemAction(type, node.url)
                }
            }
            Divider()
            Button("Renommer") {
                selectedNodeId = node.url
                renamingNodeId = node.url
                newName = node.name
            }
            Button("Supprimer", role: .destructive) {
                deleteItemAction(node.url)
            }
        }
    }
}

private struct FileCreationMenuContent: View {
    let createAction: (TemplateEditorView.CreateType) -> Void
    
    var body: some View {
        Button(action: { createAction(.folder) }) {
            Label("Nouveau Dossier", systemImage: "folder.fill")
        }
        Divider()
        fileButton("Fichier Premiere Pro (.prproj)", ext: "prproj")
        fileButton("Fichier After Effects (.aep)", ext: "aep")
        fileButton("Fichier Illustrator (.ai)", ext: "ai")
        fileButton("Fichier Photoshop (.psd)", ext: "psd")
        fileButton("Fichier Cinema 4D (.c4d)", ext: "c4d")
        fileButton("Fichier Blender (.blend)", ext: "blend")
        fileButton("Fichier Texte (.txt)", ext: "txt")
    }
    
    @ViewBuilder
    private func fileButton(_ title: String, ext: String) -> some View {
        Button(action: { createAction(.file(ext)) }) {
            Label {
                Text(title)
            } icon: {
                Image(nsImage: NSWorkspace.shared.icon(forFileType: ext).resizedForMenu())
            }
        }
    }
}

fileprivate extension NSImage {
    func resizedForMenu() -> NSImage {
        let copy = self.copy() as! NSImage
        copy.size = NSSize(width: 20, height: 20)
        return copy
    }
}
