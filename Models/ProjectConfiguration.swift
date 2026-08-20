import Foundation

public struct ProjectConfiguration: Codable {
    public var destinationURL: URL?
    
    // Dictionnaire reliant l'id d'un paramètre à la valeur saisie par l'utilisateur
    public var dynamicValues: [UUID: String]
    // Le caractère de séparation pour le nom de dossier généré
    public var separator: String
    
    public init(destinationURL: URL? = nil, dynamicValues: [UUID: String] = [:], separator: String = "_") {
        self.destinationURL = destinationURL
        self.dynamicValues = dynamicValues
        self.separator = separator
    }
    
    public func finalProjectName(using parameters: [ProjectParameter]) -> String {
        var parts: [String] = []
        
        for param in parameters {
            if let value = dynamicValues[param.id], !value.isEmpty {
                parts.append(value)
            } else if !param.name.isEmpty {
                // Si aucune valeur n'est saisie, on met le nom du champ par défaut dans le nom
                parts.append(param.name)
            }
        }
        
        var name = parts.joined(separator: separator)
        if name.isEmpty { name = "Nouveau_Projet" }
        
        // Sanitize (Retirer les caractères interdits dans un nom de dossier macOS : : et /)
        let invalidCharacters = CharacterSet(charactersIn: ":/")
        name = name.components(separatedBy: invalidCharacters).joined(separator: "-")
        
        return name
    }
}
