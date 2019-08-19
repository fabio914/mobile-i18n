import Foundation

struct SwiftSnippets {

    static func header(version: String) -> String {
        return """
        // Localized Strings
        // i18nGen \(version)
        // AUTOMATICALLY GENERATED CODE. DO NOT EDIT!

        import Foundation
        """
    }

    static func supportedLanguages(_ languages: Set<String>, defaultLanguage: String) -> String {
        return """
        enum SupportedLanguages: String, CaseIterable {
        \(languages.sorted(by: >).map({ language in
            "case \(language.camelCased.sanitized) = \"\(language.doubleQuoteEscaped)\"".indenting(spaces: 4)
        }).joined(separator: "\n"))

            var language: String {
                return .init(rawValue.split(separator: "-")[0])
            }

            var languageAndRegion: String {
                return rawValue
            }

            static func current() -> SupportedLanguages {
                guard let preferred = Locale.preferredLanguages.first?.lowercased() else {
                    return .\(defaultLanguage.camelCased.sanitized)
                }

                return allCases.first(where: { preferred.hasPrefix($0.languageAndRegion) }) ??
                    allCases.first(where: { preferred.hasPrefix($0.language) }) ??
                    .\(defaultLanguage.camelCased.sanitized)
            }
        }

        let currentLanguage = SupportedLanguages.current()
        """
    }
}
