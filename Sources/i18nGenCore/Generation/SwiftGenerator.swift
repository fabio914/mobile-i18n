import Foundation

public struct SwiftGenerator: Generator {

    public let code: String

    public init(representation: OutputRepresentation, version: String) {
        self.code = SwiftGenerator.root(representation, version: version)
    }

    private static func root(_ representation: OutputRepresentation, version: String) -> String {
        return """
        \(SwiftSnippets.header(version: version))

        \(SwiftSnippets.supportedLanguages(representation.languages, defaultLanguage: representation.defaultLanguage))

        \(namespace(representation.root, key: "LocalizedStrings"))
        """
    }

    private static func namespace(_ outputNamespace: OutputNamespace, key: String) -> String {
        return """
        struct \(key.CamelCased.sanitized) {

        \(outputNamespace.children.compactMap({ child -> String? in
            if let childNamespace = child.value as? OutputNamespace {
                return namespace(childNamespace, key: child.key).indenting(spaces: 4)
            }

            else if let childString = child.value as? OutputString {
                return string(childString, key: child.key).indenting(spaces: 4)
            }

            else {
                return nil
            }
        }).joined(separator: "\n"))
        }

        let \(key.camelCased.sanitized) = \(key.CamelCased.sanitized)()
        """ + "\n "
    }

    private static func string(_ outputString: OutputString, key: String) -> String {

        func processParams(_ input: String) -> String {
            guard outputString.hasParameters else {
                return input
            }

            var mutableInput = input

            while let paramRange = (try? mutableInput.matches(for: InputString.parameterRegularExpression))?.first {
                let paramString = String(mutableInput[paramRange])
                    .replacingOccurrences(of: "{", with: "")
                    .replacingOccurrences(of: "}", with: "")
                    .trimmingCharacters(in: CharacterSet.whitespaces)
                    .camelCased
                    .sanitized

                mutableInput.replaceSubrange(paramRange, with: "\\(\(paramString))")
            }

            return mutableInput
        }

        func result() -> String {
            guard outputString.stringForOtherLanguage.count > 0 else {
                return "return \"\"\"\n\(processParams(outputString.defaultString).doubleQuoteEscaped)\n\"\"\""
            }

            return """
            switch currentLanguage {
            \(outputString.stringForOtherLanguage.map({ language, value in
                "case .\(language.camelCased.sanitized): return \"\"\"\n\(processParams(value).doubleQuoteEscaped)\n\"\"\""
            }).joined(separator: "\n"))
            default: return \"\"\"\n\(processParams(outputString.defaultString).doubleQuoteEscaped)\n\"\"\"
            }
            """
        }

        guard outputString.hasParameters else {
            return """
            var \(key.camelCased.sanitized): String {
            \(result().indenting(spaces: 4))
            }
            """ + "\n "
        }

        return """
        func \(key.camelCased.sanitized)(\(outputString.sortedParameters.map({ "\($0.camelCased.sanitized): String" }).joined(separator: ", "))) -> String {
        \(result().indenting(spaces: 4))
        }
        """ + "\n "
    }
}
