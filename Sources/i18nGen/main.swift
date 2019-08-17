import Foundation
import i18nGenCore

let version = "2.0.0"
let console = ConsoleOutput()

var outputLanguage: OutputLanguage? {
    willSet {
        if let _ = outputLanguage {
            console.fatalError("error: more than one output option detected")
        }
    }
}

if CommandLine.argc < 2 {
    let brightWhite = "\u{001B}[1;97m"
    let disable = "\u{001B}[0;0m"

    console.fatalError(
        """
        Version: \(version)

        \(brightWhite)\(CommandLine.arguments.first ?? "i18nGen")\(disable) <main language YAML file> [additional language YAML files ...] [output option] [warning options]

        \(brightWhite)OPTIONS\(disable)
          \(brightWhite)Output options \u{001B}[0;0m
              \(brightWhite)-swift\(disable)
                  Swift (default option)

              \(brightWhite)-swift-dictionary\(disable)
                  Swift dictionary (ignores strings with parameters)

              \(brightWhite)-kotlin <kotlin package name>\(disable)
                  Kotlin

              \(brightWhite)-kotlin-filtered <kotlin package name>\(disable)
                  Kotlin filtered (ignores strings without parameters)

          \(brightWhite)Warning options\(disable)
              \(brightWhite)-w\(disable)
                  Disable all warnings

              \(brightWhite)-Wall\(disable)
                  Enable all warnings
        """
    )
}

let mainInputPath = URL(fileURLWithPath: CommandLine.arguments[1])
var otherInputPaths = [URL]()

if CommandLine.argc > 2 {
    var i = 2

    repeat {
        let arg = CommandLine.arguments[i]

        if arg == "-kotlin" || arg == "-kotlin-filtered" {
            i = i + 1

            guard i < CommandLine.argc else {
                console.fatalError("error: a kotlin package name is required")
                exit(1)
            }

            outputLanguage = .kotlin(CommandLine.arguments[i], arg == "-kotlin-filtered")
        }

        else if arg == "-swift" {
            outputLanguage = .swift
        }

        else if arg == "-swift-dictionary" {
            outputLanguage = .swiftDictionary
        }

        else if arg == "-w" {
            console.warningLevel = .disabled
        }

        else if arg == "-Wall" {
            console.warningLevel = .all
        }

        else {
            otherInputPaths.append(URL(fileURLWithPath: arg))
        }

        i = i + 1
    } while(i < CommandLine.argc)
}

do {
    let mainInput = (try YamlParser(path: mainInputPath)).representation
    let otherInputs = otherInputPaths
        .compactMap({ inputPath -> InputRepresentation? in
            do {
                return (try YamlParser(path: inputPath)).representation
            }

            catch {
                console.warning("\(inputPath.path):1:1: warning: Ignoring input file because of error: \(error.localizedDescription)")
                return nil
            }
        })
        .filter({ $0.language != mainInput.language })

    if console.warningLevel != .disabled {

        for input in otherInputs {
            let result = MissingTranslationsMatcher.match(mainInput, other: input)

            if result.hasMissingTranslations {
                console.warning(
                    """
                    \(input.path.path):1:1: warning: \"\(input.language)\" is missing \(result.percentageOfMissingTranslations)% of the translations for \"\(mainInput.language)\" (\(result.countOfMissingTranslations)/\(result.totalTranslations))
                    """
                )
            }
        }

        if console.warningLevel == .all {

            for input in otherInputs {
                for issue in IssuesMatcher.match(mainInput, other: input) {
                    switch issue {
                    case .mismatchingStringParameters(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Parameter mismatch: \"\(input.language)\(key)\" and \"\(mainInput.language)\(key)\" have different parameters")
                    case .missingNamespace(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Missing item: \"\(input.language)\" is missing the namespace for \"\(mainInput.language)\(key)\"")
                    case .missingString(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Missing item: \"\(input.language)\" is missing the string for \"\(mainInput.language)\(key)\"")
                    case .namespaceExpected(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Type mismatch: \"\(mainInput.language)\(key)\" is a namespace but \"\(input.language)\(key)\" isn't")
                    case .stringExpected(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Type mismatch: \"\(mainInput.language)\(key)\" is a string but \"\(input.language)\(key)\" isn't")
                    case .unusedNamespace(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Unused item: the namespace at \"\(input.language)\(key)\" does not exist in \"\(mainInput.language)\" and can possibily be removed")
                    case .unusedString(let key):
                        console.extraWarning("\(input.path.path):1:1: warning: Unused item: the string at \"\(input.language)\(key)\" does not exist in \"\(mainInput.language)\" and can possibily be removed")
                    }
                }
            }
        }
    }

    let output = OutputRepresentation(defaultRepresentation: mainInput, otherRepresentations: otherInputs)

    let outputLanguageToUse = outputLanguage ?? .swift
    try outputLanguageToUse.generate(output: output)
}

catch {
    console.fatalError("\(mainInputPath.path):1:1: error: \(error.localizedDescription)")
}
