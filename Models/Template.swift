import Foundation

public struct Template: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var sourceURL: URL
    
    public init(id: UUID = UUID(), name: String, sourceURL: URL) {
        self.id = id
        self.name = name
        self.sourceURL = sourceURL
    }
}
