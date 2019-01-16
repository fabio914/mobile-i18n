import Foundation
import Yaml

protocol InputNode {
    var children: [String: InputNode] { get }
    func matches(node: InputNode) -> Bool
}

struct InputString: InputNode, CustomDebugStringConvertible {
    
    enum InputStringError: Error {
        case invalidType
    }
    
    static let parameterRegularExpression = "\\{\\{.*?\\}\\}"
    
    let children: [String: InputNode] = [:]
    let parameters: Set<String>
    let string: String
    
    init(yaml: Yaml) throws {
        guard let string = yaml.string else {
            throw InputStringError.invalidType
        }
        
        self.string = string
        
        let parameters: [String] = (try? string.matches(for: InputString.parameterRegularExpression).map({ String(string[$0]) })) ?? []
        self.parameters = Set(parameters.map({
            $0.replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .trimmingCharacters(in: CharacterSet.whitespaces)
        }))
    }
    
    func matches(node: InputNode) -> Bool {
        guard let node = node as? InputString else { return false }
        return node.parameters == self.parameters
    }
    
    var debugDescription: String {
        return "InputString(\(string))"
    }
}

struct InputNamespace: InputNode, CustomDebugStringConvertible {
    
    enum InputNamespaceError: Error {
        case invalidType
        case invalidKeyType
        case invalidKey(key: String)
    }
    
    let children: [String: InputNode]
    
    init(yaml: Yaml) throws {
        guard let dictionary = yaml.dictionary else {
            throw InputNamespaceError.invalidType
        }
        
        var children = [String: InputNode]()
        
        for (key, value) in dictionary {
            guard let key = key.string else {
                throw InputNamespaceError.invalidKeyType
            }
            
            if let namespace = try? InputNamespace(yaml: value) {
                children[key] = namespace
            }
            
            else if let string = try? InputString(yaml: value) {
                children[key] = string
            }
            
            else {
                throw InputNamespaceError.invalidKey(key: key)
            }
        }
        
        self.children = children
    }
    
    func matches(node: InputNode) -> Bool {
        guard let node = node as? InputNamespace else { return false }
        for (key, value) in children {
            guard let other = node.children[key], other.matches(node: value) else {
                return false
            }
        }
        return true
    }
    
    var debugDescription: String {
        return "InputNamespace(\(children))"
    }
}

public struct InputRepresentation {
    
    public enum InputRepresentationError: Error {
        case invalidFileName
        case unableToOpenInputFile
        case invalidYamlFile
    }
    
    static func languageIdentifier(for path: URL) -> String? {
        let fileName = path.lastPathComponent
        let components = fileName.split(separator: ".")
        guard let first = components.first, components.count == 2,
            components.last?.lowercased() == "lyaml"
        else { return nil }
        return String(first).lowercased()
    }
    
    let root: InputNamespace
    
    public let language: String
    public let path: URL
    
    public init(path: URL) throws {
        
        guard let language = InputRepresentation.languageIdentifier(for: path) else {
            throw InputRepresentationError.invalidFileName
        }
        
        guard let inputString = try? String(contentsOf: path, encoding: .utf8) else {
            throw InputRepresentationError.unableToOpenInputFile
        }

        try self.init(language: language, yamlString: inputString, path: path)
    }
    
    init(language: String, yamlString inputString: String, path: URL) throws {
        guard let yaml = (try? Yaml.load(inputString))?.dictionary,
            let main = yaml[Yaml.string(language)],
            let root = try? InputNamespace(yaml: main)
        else {
            throw InputRepresentationError.invalidYamlFile
        }
        
        self.language = language
        self.root = root
        self.path = path
    }
    
    public func matches(representation other: InputRepresentation) -> Bool {
        return root.matches(node: other.root)
    }
}
