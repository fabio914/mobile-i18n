import Foundation
import Yaml

public enum YamlParserError: Error {
    case invalidYamlFile
    case invalidFileName
    case unableToOpenInputFile
}

public struct YamlParser: Parser {
    
    enum YamlParserInternalError: Error {
        case invalidType
        case invalidKeyType
        case invalidKey(key: String)
    }
    
    public let representation: InputRepresentation
    
    private static func buildInputString(yaml: Yaml) throws -> InputString {
        
        guard let string = yaml.string else {
            throw YamlParserInternalError.invalidType
        }
        
        let parameters: [String] = (try? string.matches(for: InputString.parameterRegularExpression).map({ String(string[$0]) })) ?? []
        let parametersSet = Set(parameters.map({
            $0.replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .trimmingCharacters(in: CharacterSet.whitespaces)
        }))
        
        return .init(parameters: parametersSet, string: string)
    }
    
    private static func buildInputNamespace(yaml: Yaml) throws -> InputNamespace {
        guard let dictionary = yaml.dictionary else {
            throw YamlParserInternalError.invalidType
        }
        
        var children = [String: InputNode]()
        
        for (key, value) in dictionary {
            guard let key = key.string else {
                throw YamlParserInternalError.invalidKeyType
            }
            
            if let namespace = try? buildInputNamespace(yaml: value) {
                children[key] = namespace
            }
            
            else if let string = try? buildInputString(yaml: value) {
                children[key] = string
            }
            
            else {
                throw YamlParserInternalError.invalidKey(key: key)
            }
        }
        
        return .init(children: children)
    }
    
    internal static func buildInputRepresentation(language: String, yamlString inputString: String, path: URL) throws -> InputRepresentation {
        guard let yaml = (try? Yaml.load(inputString))?.dictionary,
            let main = yaml[Yaml.string(language)],
            let root = try? buildInputNamespace(yaml: main)
        else {
            throw  YamlParserError.invalidYamlFile
        }
        
        return .init(root: root, language: language, path: path)
    }
    
    private static func languageIdentifier(for path: URL) -> String? {
        let fileName = path.lastPathComponent
        let components = fileName.split(separator: ".")
        guard let first = components.first, components.count == 2,
            components.last?.lowercased() == "lyaml"
            else { return nil }
        return String(first).lowercased()
    }
    
    public init(path: URL) throws {
        guard let language = YamlParser.languageIdentifier(for: path) else {
            throw YamlParserError.invalidFileName
        }
        
        guard let inputString = try? String(contentsOf: path, encoding: .utf8) else {
            throw YamlParserError.unableToOpenInputFile
        }
        
        self.representation = try YamlParser.buildInputRepresentation(language: language, yamlString: inputString, path: path)
    }
}
