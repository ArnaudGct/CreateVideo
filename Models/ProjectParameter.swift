import Foundation

public enum ParameterType: String, Codable, CaseIterable, Identifiable {
    case text = "Texte"
    case date = "Date"
    
    public var id: String { self.rawValue }
}

public struct ProjectParameter: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var defaultValue: String
    public var isRequired: Bool
    public var type: ParameterType
    
    public init(id: UUID = UUID(), name: String, defaultValue: String = "", isRequired: Bool = false, type: ParameterType = .text) {
        self.id = id
        self.name = name
        self.defaultValue = defaultValue
        self.isRequired = isRequired
        self.type = type
    }
}
