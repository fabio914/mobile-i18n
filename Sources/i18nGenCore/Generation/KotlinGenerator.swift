import Foundation

public struct KotlinGenerator: Generator {
    
    public let code: String
    
    public init(representation: OutputRepresentation, packageName: String, version: String) {
        self.code = KotlinGenerator.root(representation, packageName: packageName, version: version)
    }
    
    private static func root(_ representation: OutputRepresentation, packageName: String, version: String) -> String {
        return """
        // Localized Strings
        // i18nGen \(version)
        // AUTOMATICALLY GENERATED CODE. DO NOT EDIT!
        
        package \(packageName)
        import java.util.Locale
        
        internal object LocalizedStrings {
        
          private val currentLanguage = getCurrentLang()
        
          private enum class SupportedLanguage(val identifier: String) {
          \(representation.languages.map({ language in
          "  \(language.uppercased().sanitized)(\"\(language.replacingOccurrences(of: "-", with: "_").doubleQuoteEscaped)\")"
          }).joined(separator: ",\n  "))
          }
        
          private fun getCurrentLang(): SupportedLanguage {
            val locale = Locale.getDefault().toString().toLowerCase()
            return SupportedLanguage.values().firstOrNull { locale.startsWith(it.identifier) } ?: SupportedLanguage.\(representation.defaultLanguage.uppercased().sanitized)
          }
        
        \(KotlinGenerator.namespace(representation.root))
        }
        """
    }
    
    private static func namespace(_ namespace: OutputNamespace) -> String {
        return """
        \(namespace.children.map({ child -> String in
            if let childNamespace = child.value as? OutputNamespace {
                return KotlinGenerator.objectNamespace(childNamespace, key: child.key).indenting(spaces: 2)
            }
            
            else if let childString = child.value as? OutputString {
                return KotlinGenerator.string(childString, key: child.key).indenting(spaces: 2)
            }
            
            else {
                return ""
            }
        }).joined(separator: "\n"))
        """ + "\n "
    }
    
    private static func objectNamespace(_ namespace: OutputNamespace, key: String) -> String {
        return """
        val \(key.camelCased.sanitized) = \(key.CamelCased.sanitized)
        
        object \(key.CamelCased.sanitized) {
         
        \(KotlinGenerator.namespace(namespace))
        }

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
                
                mutableInput.replaceSubrange(paramRange, with: "${\(paramString)}")
            }
            
            return mutableInput
        }
        
        func result() -> String {
            guard string.stringForOtherLanguage.count > 0 else {
                return "return \"\"\"\n\(processParams(string.defaultString).doubleQuoteEscaped)\n\"\"\".trimIndent()"
            }
            
            return """
            return when (LocalizedStrings.currentLanguage) {
            \(string.stringForOtherLanguage.map({ language, value in
            "SupportedLanguage.\(language.uppercased().sanitized) -> \"\"\"\n\(processParams(value).doubleQuoteEscaped)\n\"\"\"".indenting(spaces: 2)
            }).joined(separator: "\n"))
            \("else -> \"\"\"\n\(processParams(string.defaultString).doubleQuoteEscaped)\n\"\"\"".indenting(spaces: 2))
            }.trimIndent()
            """
        }
        
        guard string.hasParameters else {
            return """
            val \(key.camelCased.sanitized): String
            get() {
            \(result().indenting(spaces: 2))
            }
            """ + "\n "
        }
        
        return """
        fun \(key.camelCased.sanitized)(\(string.sortedParameters.map({ "\($0.camelCased.sanitized): String" }).joined(separator: ", "))): String {
        \(result().indenting(spaces: 2))
        }
        """ + "\n "
    }
}
