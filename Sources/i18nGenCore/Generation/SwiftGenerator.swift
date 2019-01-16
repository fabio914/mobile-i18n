import Foundation

public struct SwiftGenerator: Generator {
    
    public let code: String
    
    public init(representation: OutputRepresentation, version: String) {
        self.code = SwiftGenerator.root(representation, version: version)
    }
    
    private static func root(_ representation: OutputRepresentation, version: String) -> String {
        return """
        // Localized Strings
        // i18nGen \(version)
        // AUTOMATICALLY GENERATED CODE. DO NOT EDIT!
        
        import Foundation
        
        enum SupportedLanguages: String, CaseIterable {
        \(representation.languages.map({ language in
            "case \(language.camelCased.sanitized) = \"\(language.doubleQuoteEscaped)\"".indenting(spaces: 4)
        }).joined(separator: "\n"))
        
            static func current() -> SupportedLanguages {
                guard let preferred = Locale.preferredLanguages.first?.lowercased() else {
                    return SupportedLanguages.\(representation.defaultLanguage.camelCased.sanitized)
                }

                return SupportedLanguages.allCases.first(where: { preferred.hasPrefix($0.rawValue) }) ?? SupportedLanguages.\(representation.defaultLanguage.camelCased.sanitized)
            }
        }
        
        let currentLanguage = SupportedLanguages.current()
        
        \(SwiftGenerator.namespace(representation.root, key: "LocalizedStrings"))
        
        """
    }
    
    private static func namespace(_ namespace: OutputNamespace, key: String) -> String {
        return """
        struct \(key.CamelCased.sanitized) {
         
        \(namespace.children.map({ child -> String in
            if let childNamespace = child.value as? OutputNamespace {
                return SwiftGenerator.namespace(childNamespace, key: child.key).indenting(spaces: 4)
            }
            
            else if let childString = child.value as? OutputString {
                return SwiftGenerator.string(childString, key: child.key).indenting(spaces: 4)
            }
            
            else {
                return ""
            }
        }).joined(separator: "\n"))
        }
            
        let \(key.camelCased.sanitized) = \(key.CamelCased.sanitized)()
        """ + "\n "
    }
    
    private static func string(_ string: OutputString, key: String) -> String {

        func processParams(_ input: String) -> String {
            guard string.hasParameters else {
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
            guard string.stringForOtherLanguage.count > 0 else {
                return "return \"\"\"\n\(processParams(string.defaultString).doubleQuoteEscaped)\n\"\"\""
            }
            
            return """
            switch currentLanguage {
            \(string.stringForOtherLanguage.map({ language, value in
                "case .\(language.camelCased.sanitized): return \"\"\"\n\(processParams(value).doubleQuoteEscaped)\n\"\"\""
            }).joined(separator: "\n"))
            default: return \"\"\"\n\(processParams(string.defaultString).doubleQuoteEscaped)\n\"\"\"
            }
            """
        }
        
        guard string.hasParameters else {
            return """
            var \(key.camelCased.sanitized): String {
            \(result().indenting(spaces: 4))
            }
            """ + "\n "
        }
        
        return """
        func \(key.camelCased.sanitized)(\(string.sortedParameters.map({ "\($0.camelCased.sanitized): String" }).joined(separator: ", "))) -> String {
        \(result().indenting(spaces: 4))
        }
        """ + "\n "
    }
}
