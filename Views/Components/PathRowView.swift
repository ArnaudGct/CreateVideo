import SwiftUI

public struct PathRowView: View {
    let title: String
    let description: String?
    let pathURL: URL?
    let action: () -> Void
    
    public init(title: String, description: String? = nil, pathURL: URL?, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.pathURL = pathURL
        self.action = action
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let url = pathURL {
                    Text(url.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Aucun dossier sélectionné")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            Button(action: action) {
                Text("Parcourir...")
            }
        }
        .padding(16)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
}
