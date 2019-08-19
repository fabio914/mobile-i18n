import Foundation

protocol InputNode {
    var count: Int { get }
    var children: [String: InputNode] { get }
}

struct InputString: InputNode, CustomDebugStringConvertible {
    
    static let parameterRegularExpression = "\\{\\{.*?\\}\\}"
    
    let children: [String: InputNode] = [:]
    let count = 1
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
    var count: Int {
        return children.values.map({ $0.count }).reduce(0, +)
    }
    
    var debugDescription: String {
        return "InputNamespace(\(children))"
    }
}

public struct InputRepresentation {

    let root: InputNamespace
    
    public let language: String
    public let path: URL
}
