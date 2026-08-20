import SwiftUI
import AppKit

@main
struct CreateVideoApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                // Configuration de la fenêtre principale
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.title = "CreateVideo"
                        window.center()
                    }
                }
        }
        .commands {
            // Commandes clavier globales
            CommandGroup(replacing: .newItem) {
                Button("Nouveau Projet") {
                    // Action
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandGroup(after: .appInfo) {
                Button("Rechercher des mises à jour...") {
                    NotificationCenter.default.post(name: NSNotification.Name("CheckForUpdates"), object: nil)
                }
            }
        }
    }
}
