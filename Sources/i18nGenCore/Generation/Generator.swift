import Foundation

public protocol Generator {
    var code: String { get }
}

public extension Generator {

    func write(to path: String) throws {
        try code.data(using: .utf8)?.write(to: URL(fileURLWithPath: path))
    }
}
