import Foundation

protocol InputNode {
    var children: [String: InputNode] { get }
    func matches(node: InputNode) -> Bool
}

struct InputString: InputNode, CustomDebugStringConvertible {
    
    static let parameterRegularExpression = "\\{\\{.*?\\}\\}"
    
    let children: [String: InputNode] = [:]
    let parameters: Set<String>
    let string: String
    
    func matches(node: InputNode) -> Bool {
        guard let node = node as? InputString else { return false }
        return node.parameters == self.parameters
    }
    
    var debugDescription: String {
        return "InputString(\(string))"
    }
}

struct InputNamespace: InputNode, CustomDebugStringConvertible {
    
    let children: [String: InputNode]
    
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
    
    let root: InputNamespace
    
    public let language: String
    public let path: URL
    
    public func matches(representation other: InputRepresentation) -> Bool {
        return root.matches(node: other.root)
    }
}
