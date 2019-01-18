import XCTest

extension InputRepresentationTests {
    static let __allTests = [
        ("testAnotherMismatch", testAnotherMismatch),
        ("testLanguageMatch", testLanguageMatch),
        ("testMatch", testMatch),
        ("testMismatch", testMismatch),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(InputRepresentationTests.__allTests),
    ]
}
#endif

