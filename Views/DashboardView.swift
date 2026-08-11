import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel = CreateVideoViewModel()
    
    public init() {}
    
    public var body: some View {
        ExecutionZoneView(viewModel: viewModel)
            .frame(minWidth: 800, minHeight: 600)
    }
}
