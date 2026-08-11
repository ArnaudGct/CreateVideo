import SwiftUI

public struct FinderClickableRow: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    public init(title: String, iconName: String = "folder.fill", isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 16)
                
                Text(title)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
