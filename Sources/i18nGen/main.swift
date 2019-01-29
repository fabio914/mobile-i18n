import Foundation

import i18nGenCore

let version = "1.0.0"

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

enum OutputLanguage {
    case swift
    case kotlin(_ packageName: String)
    
    var outputFile: String {
        switch self {
        case .swift:
            return "Localization.swift"
        case .kotlin:
            return "Localization.kt"
        }
    }
    
    func generate(output: OutputRepresentation) throws {
        switch self {
        case .swift:
            try SwiftGenerator(
                representation: output,
                version: version
            ).write(to: outputFile)
        case .kotlin(let packageName):
            try KotlinGenerator(
                representation: output,
                packageName: packageName,
                version: version
            ).write(to: outputFile)
        }
    }
}

var outputLanguage = OutputLanguage.swift
var err = FileHandle.standardError

if CommandLine.argc < 2 {
    print("Version: \(version)\nUsage: \(CommandLine.arguments.first ?? "i18nGen") <main language YAML file> [additional language YAML files ...] [-kotlin <kotlin package name>]", to: &err)
    exit(1)
}

let mainInputPath = URL(fileURLWithPath: CommandLine.arguments[1])
var otherInputPaths = [URL]()

if CommandLine.argc > 2 {
    var i = 2
    
    repeat {
        let arg = CommandLine.arguments[i]
        
        if arg == "-kotlin" {
            i = i + 1
            
            guard i < CommandLine.argc else {
                print("error: a kotlin package name is required", to: &err)
                exit(1)
            }
            
            if case .kotlin(_) = outputLanguage {
                print("error: more than one kotlin package detected", to: &err)
                exit(1)
            }
            
            outputLanguage = .kotlin(CommandLine.arguments[i])
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
                print("\(inputPath.path):1:1: warning: Ignoring input file because of error: \(error.localizedDescription)", to: &err)
                return nil
            }
        })
        .filter({ $0.language != mainInput.language })
    
    otherInputs.forEach({
        if !$0.matches(representation: mainInput) {
            print("\($0.path.path):1:1: warning: \"\($0.language)\" does not completely match the \"\(mainInput.language)\" version", to: &err)
        }
    })
    
    let output = OutputRepresentation(defaultRepresentation: mainInput, otherRepresentations: otherInputs)
    try outputLanguage.generate(output: output)
}

catch {
    print("\(mainInputPath.path):1:1: error: \(error.localizedDescription)", to: &err)
    exit(1)
}
