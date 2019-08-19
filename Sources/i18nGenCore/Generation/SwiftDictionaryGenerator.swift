import Foundation

public struct SwiftDictionaryGenerator: Generator {

    public let code: String

    public init(representation: OutputRepresentation, version: String) {
        // This mode doesn't support strings with parameters
        self.code = {
            guard let filteredRepresentation = representation.filter({ !$0.hasParameters }) else {
                return ""
            }

            return SwiftDictionaryGenerator.root(filteredRepresentation, version: version)
        }()
    }

    private static func root(_ representation: OutputRepresentation, version: String) -> String {
        let otherLanguages = representation.languages.filter({ $0 != representation.defaultLanguage }).sorted()

        return """
        \(SwiftSnippets.header(version: version))

        \(SwiftSnippets.supportedLanguages(representation.languages, defaultLanguage: representation.defaultLanguage))

        \(namespace(representation.root, key: "LocalizedStrings", otherLanguages: otherLanguages))
        """
    }

    private static func namespace(_ outputNamespace: OutputNamespace, key: String, otherLanguages: [String]) -> String {
        let childNamespaces = outputNamespace.children.compactMapValues({ $0 as? OutputNamespace })

        return """
        struct \(key.CamelCased.sanitized) {

        \(childNamespaces.map({ (key, child) in
            namespace(child, key: key, otherLanguages: otherLanguages)
        }).joined(separator: "\n").indenting(spaces: 4))

            static var dictionary: [String: String] {
        \(dictionarySwitch(outputNamespace, otherLanguages: otherLanguages).indenting(spaces: 8))
            }
        }

        """ + "\n "
    }

    private static func dictionarySwitch(_ outputNamespace: OutputNamespace, otherLanguages: [String]) -> String {
        let childStrings = outputNamespace.children.compactMapValues({ $0 as? OutputString })

        guard !childStrings.isEmpty else {
            return "return [:]"
        }

        return """
        switch currentLanguage {
        \(otherLanguages.map({ language in
        """
        case .\(language.camelCased.sanitized):
        \(dictionary(childStrings.compactMapValues({ $0.stringForOtherLanguage[language] })).indenting(spaces: 4))
        """
        }).joined(separator: "\n"))
        default:
        \(dictionary(childStrings.mapValues({ $0.defaultString })).indenting(spaces: 4))
        }
        """
    }

    private static func dictionary(_ pairs: [String: String]) -> String {
        guard !pairs.isEmpty else { return "return [:]" }

        return """
        return [
        \(pairs.map({ key, string in
            "\"\(key)\": \"\"\"\n\(string.doubleQuoteEscaped)\n\"\"\""
        }).joined(separator: ",\n").indenting(spaces: 4))
        ]
        """
    }
}
