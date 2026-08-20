import Foundation
import SwiftUI
import AppKit

class UpdateManager: ObservableObject {
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var updateUrl: URL? = nil
    @Published var showUpdateSheet: Bool = false
    
    private let repoUrl: String
    
    init(repoName: String) {
        self.repoUrl = "https://api.github.com/repos/\(repoName)/releases/latest"
    }
    
    func checkForUpdates(isManualCheck: Bool = false) {
        guard let url = URL(string: repoUrl) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("UpdateChecker/1.0", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                if isManualCheck {
                    DispatchQueue.main.async { self?.showErrorAlert(message: "Impossible de contacter GitHub. Vérifiez votre connexion ou la visibilité du dépôt (qui doit être public).") }
                }
                return
            }
            
            do {
                let release = try JSONDecoder().decode(GithubRelease.self, from: data)
                
                let latestVersionString = release.tagName.replacingOccurrences(of: "v", with: "")
                
                guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
                
                if latestVersionString.compare(currentVersion, options: .numeric) == .orderedDescending {
                    DispatchQueue.main.async {
                        self?.latestVersion = latestVersionString
                        self?.releaseNotes = release.body ?? "Nouvelle mise à jour disponible."
                        self?.updateUrl = URL(string: release.htmlUrl)
                        self?.isUpdateAvailable = true
                        self?.showUpdateSheet = true
                    }
                } else {
                    if isManualCheck {
                        DispatchQueue.main.async { self?.showErrorAlert(message: "Votre application est déjà à jour (v\(currentVersion)).") }
                    }
                }
                
            } catch {
                if isManualCheck {
                    DispatchQueue.main.async { self?.showErrorAlert(message: "Aucune mise à jour trouvée. Assurez-vous que le dépôt GitHub est bien public et qu'une release existe.") }
                }
                print("Erreur de décodage de la release: \(error)")
            }
        }
        task.resume()
    }
    
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Mise à jour"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func openUpdatePage() {
        if let url = updateUrl {
            NSWorkspace.shared.open(url)
            self.showUpdateSheet = false
        }
    }
}
