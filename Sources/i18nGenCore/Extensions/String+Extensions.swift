import Foundation

extension String {

    var capitalized: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var undoCamelCase: String {
        return unicodeScalars.reduce("", {
            if CharacterSet.uppercaseLetters.contains($1) {
                if $0.count > 0 {
                    return $0 + " " + String($1)
                }
            }

            return $0 + String($1)
        })
    }

    var camelCased: String {
        let parts = undoCamelCase.components(separatedBy: CharacterSet(charactersIn: " _"))
        return "\(parts.first?.lowercased() ?? "")\(parts.dropFirst().map({ $0.lowercased().capitalized }).joined())"
    }

    var CamelCased: String {
        return undoCamelCase
            .components(separatedBy: CharacterSet(charactersIn: " _"))
            .map({ $0.lowercased().capitalized })
            .joined()
    }

    var sanitized: String {
        let transformed = components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted).joined()
        if let first = transformed.first, "0123456789".contains(first) {
            return "_\(transformed)"
        }
        return transformed
    }

    var doubleQuoteEscaped: String {
        return replacingOccurrences(of: "\"", with: "\\\"")
    }

    init(spaces: Int) {
        if spaces <= 0 {
            self = ""
        }

        var result = ""
        for _ in 0 ..< spaces {
            result += " "
        }
        self = result
    }

    func indenting(spaces: Int) -> String {
        let lines = self.split(separator: "\n")
        return lines.map({ String(spaces: spaces) + $0 }).joined(separator: "\n")
    }
}
