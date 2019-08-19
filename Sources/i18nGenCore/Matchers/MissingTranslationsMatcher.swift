import Foundation

public struct MissingTranslationsMatcher {

    public struct Result {
        public let countOfMissingTranslations: Int
        public let totalTranslations: Int

        static var zero = Result(0, of: 0)

        static func +(_ lhs: Result, _ rhs: Result) -> Result {
            return .init(
                lhs.countOfMissingTranslations + rhs.countOfMissingTranslations,
                of: lhs.totalTranslations + rhs.totalTranslations
            )
        }

        static func +=(_ lhs: inout Result, _ rhs: Result) {
            return lhs = lhs + rhs
        }

        public var percentageOfMissingTranslations: Int {
            guard totalTranslations > 0 else { return 100 }
            return Int(ceil(Double(countOfMissingTranslations) * (100.0/Double(totalTranslations))))
        }

        public var hasMissingTranslations: Bool {
            return countOfMissingTranslations > 0 && totalTranslations > 0
        }

        init(_ countOfMissingTranslations: Int, of totalTranslations: Int) {
            self.countOfMissingTranslations = countOfMissingTranslations
            self.totalTranslations = totalTranslations
        }

        init(_ total: Int) {
            self.countOfMissingTranslations = total
            self.totalTranslations = total
        }
    }

    private static func match(primaryString: InputString, otherNode: InputNode) -> Result {
        // This isn't checking if the parameters match

        guard otherNode is InputString else {
            return .init(primaryString.count)
        }

        return .init(0, of: primaryString.count)
    }

    private static func match(primaryNamespace: InputNamespace, otherNode: InputNode) -> Result {
        // This only checks for missing translations in the `other` representation (not in the primary)

        guard let otherNamespace = otherNode as? InputNamespace else {
            return .init(primaryNamespace.count)
        }

        var result: Result = .zero

        for (key, child) in primaryNamespace.children {
            if let otherChild = otherNamespace.children[key] {
                result += match(primaryNode: child, otherNode: otherChild)
            } else {
                if let childString = child as? InputString, childString.string.isEmpty { // Ignores issue if string is empty
                    result += .init(0, of: childString.count)
                } else {
                    result += .init(child.count)
                }
            }
        }

        return result
    }

    private static func match(primaryNode: InputNode, otherNode: InputNode) -> Result {
        if let primaryNamespace = primaryNode as? InputNamespace {
            return match(primaryNamespace: primaryNamespace, otherNode: otherNode)
        } else if let primaryString = primaryNode as? InputString {
            return match(primaryString: primaryString, otherNode: otherNode)
        } else {
            return .zero
        }
    }

    public static func match(_ primary: InputRepresentation, other: InputRepresentation) -> Result {
        return match(primaryNode: primary.root, otherNode: other.root)
    }
}
