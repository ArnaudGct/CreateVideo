import Foundation

public struct FileNode: Identifiable, Hashable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileNode]?
    
    public init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }
}
