import Foundation
import XCTest
@testable import i18nGenCore

func makeInput(language: String, string: String) throws -> InputRepresentation {
    return try YamlParser.buildInputRepresentation(
        language: language,
        yamlString: string,
        path: URL(string: "/")!
    )
}

class InputRepresentationTests: XCTestCase {
    
    func testLanguageMatch() {
        let string = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
        """
        
        XCTAssertNoThrow(try makeInput(language: "en", string: string))
        XCTAssertThrowsError(try makeInput(language: "es", string: string))
    }
    
    func testMatch() throws {
        let first = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
        """
        
        let second = """
        pt-br:
          first: "Primeiro"
          second:
            third: "Terceiro {{ param }}"
        """
        
        let firstInput = try makeInput(language: "en", string: first)
        let secondInput = try makeInput(language: "pt-br", string: second)

        XCTAssertFalse(MissingTranslationsMatcher.match(firstInput, other: secondInput).hasMissingTranslations)
        XCTAssertTrue(IssuesMatcher.match(firstInput, other: secondInput).isEmpty)
    }
    
    func testMismatch() throws {
        let first = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
        """
        
        let second = """
        pt-br:
          first: "Primeiro"
          second:
            third: "Terceiro"
        """
        
        let firstInput = try makeInput(language: "en", string: first)
        let secondInput = try makeInput(language: "pt-br", string: second)

        let issues = IssuesMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues.contains(.mismatchingStringParameters(".second.third")))
    }
    
    func testAnotherMismatch() throws {
        let first = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
            fourth: "Fourth"
        """
        
        let second = """
        pt-br:
          first: "Primeiro"
          second:
            third: "Terceiro"
        """
        
        let firstInput = try makeInput(language: "en", string: first)
        let secondInput = try makeInput(language: "pt-br", string: second)

        let issues = IssuesMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(issues.count, 2)
        XCTAssertTrue(issues.contains(.mismatchingStringParameters(".second.third")))
        XCTAssertTrue(issues.contains(.missingString(".second.fourth")))

        let missingTranslationsResult = MissingTranslationsMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(missingTranslationsResult.countOfMissingTranslations, 1)
        XCTAssertEqual(missingTranslationsResult.totalTranslations, 3)
    }
    
    func testRootMismatch() throws {
        let first = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
        """
        
        let second = """
        pt-br:
          first: "Primeiro"
        """
        
        let firstInput = try makeInput(language: "en", string: first)
        let secondInput = try makeInput(language: "pt-br", string: second)

        let issues = IssuesMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues.contains(.missingNamespace(".second")))

        let missingTranslationsResult = MissingTranslationsMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(missingTranslationsResult.countOfMissingTranslations, 1)
        XCTAssertEqual(missingTranslationsResult.totalTranslations, 2)
    }

    func testUnused() throws {
        let first = """
        en:
          first: "First"
          second:
            third: "Third {{ param }}"
        """

        let second = """
        pt-br:
          first: "Primeiro"
          unusedString: "Não utilizada"
          second:
            third: "Terceiro {{ param }}"
            unusedNamespace:
              someString: "Alguma string"
        """

        let firstInput = try makeInput(language: "en", string: first)
        let secondInput = try makeInput(language: "pt-br", string: second)

        XCTAssertFalse(MissingTranslationsMatcher.match(firstInput, other: secondInput).hasMissingTranslations)
        let issues = IssuesMatcher.match(firstInput, other: secondInput)
        XCTAssertEqual(issues.count, 2)
        XCTAssertTrue(issues.contains(.unusedString(".unusedString")))
        XCTAssertTrue(issues.contains(.unusedNamespace(".second.unusedNamespace")))
    }

    // TODO: Add more and better tests...
}

class OutputRepresentationTests: XCTestCase {
    
    // TODO: Write tests
}

class SwiftGenerationTests: XCTestCase {
    
    // TODO: Write tests
}

class SwiftDictionaryGenerationTests: XCTestCase {

    // TODO: Write tests
}

class KotlinGenerationTests: XCTestCase {
    
    // TODO: Write tests
}
