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
                    // Si on veut reset l'UI via le ViewModel
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
