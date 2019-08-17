import Foundation

protocol OutputNode {
    var children: [String: OutputNode] { get }
}

struct OutputString: OutputNode {

    let children: [String: OutputNode] = [:]
    let sortedParameters: [String]
    let defaultString: String
    let stringForOtherLanguage: [String: String]

    var hasParameters: Bool {
        return sortedParameters.count > 0
    }

    init(defaultNode: InputString, otherNodes: [String: InputString]) {

        var otherStrings = [String: String]()

        for (language, stringNode) in otherNodes {
            if stringNode.matches(node: defaultNode) {
                otherStrings[language] = stringNode.string
            }
        }

        defaultString = defaultNode.string
        sortedParameters = defaultNode.parameters.sorted()
        stringForOtherLanguage = otherStrings
    }
}

struct OutputNamespace: OutputNode {

    let children: [String: OutputNode]

    init(defaultNode: InputNamespace, otherNodes: [String: InputNamespace]) {

        var children = [String: OutputNode]()

        for (key, currentNode) in defaultNode.children {

            if let currentNode = currentNode as? InputString {

                var childOtherNodes = [String: InputString]()

                for (language, namespace) in otherNodes {
                    guard let otherNode = namespace.children[key] as? InputString else {
                        continue
                    }

                    childOtherNodes[language] = otherNode
                }

                children[key] = OutputString(defaultNode: currentNode, otherNodes: childOtherNodes)
            }

            else if let currentNode = currentNode as? InputNamespace {

                var childOtherNodes = [String: InputNamespace]()

                for (language, namespace) in otherNodes {
                    guard let otherNode = namespace.children[key] as? InputNamespace else {
                        continue
                    }

                    childOtherNodes[language] = otherNode
                }

                children[key] = OutputNamespace(defaultNode: currentNode, otherNodes: childOtherNodes)
            }
        }

        self.children = children
    }

    private init?(children: [String: OutputNode]) {
        guard !children.isEmpty else { return nil }
        self.children = children
    }

    func filter(_ shouldInclude: (OutputString) -> Bool) -> OutputNamespace? {
        var filtered = [String: OutputNode]()

        for (key, node) in children {
            if let string = node as? OutputString, shouldInclude(string) {
                filtered[key] = string
            }

            else if let namespace = (node as? OutputNamespace)?.filter(shouldInclude) {
                filtered[key] = namespace
            }
        }

        return OutputNamespace(children: filtered)
    }
}

public struct OutputRepresentation {

    let root: OutputNamespace
    let languages: Set<String>
    let defaultLanguage: String

    public init(defaultRepresentation: InputRepresentation, otherRepresentations: [InputRepresentation]) {

        var languages = Set<String>()
        var otherNamespaces = [String: InputNamespace]()

        for representation in otherRepresentations {
            otherNamespaces[representation.language] = representation.root
            languages.insert(representation.language)
        }

        defaultLanguage = defaultRepresentation.language
        languages.insert(defaultLanguage)

        root = OutputNamespace(defaultNode: defaultRepresentation.root, otherNodes: otherNamespaces)
        self.languages = languages
    }

    private init?(root: OutputNamespace?, languages: Set<String>, defaultLanguage: String) {
        guard let root = root else { return nil }
        self.root = root
        self.languages = languages
        self.defaultLanguage = defaultLanguage
    }

    func filter(_ shouldInclude: (OutputString) -> Bool) -> OutputRepresentation? {
        return OutputRepresentation(root: root.filter(shouldInclude), languages: languages, defaultLanguage: defaultLanguage)
    }
}
