import Foundation
import i18nGenCore

enum OutputLanguage {
    case swift
    case swiftDictionary
    case kotlin(_ packageName: String, _ filteringOutStaticStrings: Bool)

    var outputFile: String {
        switch self {
        case .swift, .swiftDictionary:
            return "Localization.swift"
        case .kotlin:
            return "Localization.kt"
        }
    }

    func generate(output: OutputRepresentation) throws {
        switch self {
        case .swift:
            try SwiftGenerator(representation: output, version: version).write(to: outputFile)
        case .swiftDictionary:
            try SwiftDictionaryGenerator(representation: output, version: version).write(to: outputFile)
        case .kotlin(let packageName, let filtering):
            try KotlinGenerator(
                representation: output,
                packageName: packageName,
                filteringOutStaticStrings: filtering,
                version: version
            ).write(to: outputFile)
        }
    }
}
