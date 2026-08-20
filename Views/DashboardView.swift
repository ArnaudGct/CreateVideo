import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel = CreateVideoViewModel()
    @StateObject private var updateManager = UpdateManager(repoName: "ArnaudGct/CreateVideo")
    
    public init() {}
    
    public var body: some View {
        ExecutionZoneView(viewModel: viewModel)
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
                updateManager.checkForUpdates()
            }
            .sheet(isPresented: $updateManager.showUpdateSheet) {
                UpdateSheetView(updateManager: updateManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CheckForUpdates"))) { _ in
                updateManager.checkForUpdates(isManualCheck: true)
            }
    }
}
