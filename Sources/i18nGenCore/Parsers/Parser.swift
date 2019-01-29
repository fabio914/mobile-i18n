import Foundation

public protocol Parser {
    var representation: InputRepresentation { get }
    init(path: URL) throws
}
