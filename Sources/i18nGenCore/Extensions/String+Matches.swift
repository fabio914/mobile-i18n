import Foundation

extension String {

    func matches(for regex: String) throws -> [Range<String.Index>] {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        return results.compactMap({ Range<String.Index>($0.range, in: self) })
    }
}
