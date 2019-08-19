import Foundation

public struct IssuesMatcher {

    public enum Issues: Equatable {
        case stringExpected(String)
        case namespaceExpected(String)
        case unusedNamespace(String)
        case unusedString(String)
        case missingNamespace(String)
        case missingString(String)
        case mismatchingStringParameters(String)
    }

    private static func match(fullKey: String, primaryString: InputString, otherNode: InputNode) -> [Issues] {
        guard let otherString = otherNode as? InputString else {
            return [.stringExpected(fullKey)]
        }

        guard primaryString.parameters == otherString.parameters else {
            return [.mismatchingStringParameters(fullKey)]
        }

        return []
    }

    private static func match(fullKey: String, primaryNamespace: InputNamespace, otherNode: InputNode) -> [Issues] {
        guard let otherNamespace = otherNode as? InputNamespace else {
            return [.namespaceExpected(fullKey)]
        }

        var result: [Issues] = []

        for (key, child) in primaryNamespace.children {
            let childKey = "\(fullKey).\(key.camelCased.sanitized)"

            if let otherChild = otherNamespace.children[key] {
                result += match(fullKey: childKey, primaryNode: child, otherNode: otherChild)
            } else {
                if child is InputNamespace {
                    result.append(.missingNamespace(childKey))
                } else if let childString = child as? InputString, !childString.string.isEmpty { // Ignores issue if string is empty
                    result.append(.missingString(childKey))
                }
            }
        }

        for (key, child) in otherNamespace.children {
            if let _ = primaryNamespace.children[key] { continue }
            let childKey = "\(fullKey).\(key.camelCased.sanitized)"

            if child is InputNamespace {
                result.append(.unusedNamespace(childKey))
            } else if child is InputString {
                result.append(.unusedString(childKey))
            }
        }

        return result
    }

    private static func match(fullKey: String, primaryNode: InputNode, otherNode: InputNode) -> [Issues] {
        if let primaryNamespace = primaryNode as? InputNamespace {
            return match(fullKey: fullKey, primaryNamespace: primaryNamespace, otherNode: otherNode)
        } else if let primaryString = primaryNode as? InputString {
            return match(fullKey: fullKey, primaryString: primaryString, otherNode: otherNode)
        } else {
            return []
        }
    }

    public static func match(_ primary: InputRepresentation, other: InputRepresentation) -> [Issues] {
        return match(fullKey: "", primaryNode: primary.root, otherNode: other.root)
    }
}
