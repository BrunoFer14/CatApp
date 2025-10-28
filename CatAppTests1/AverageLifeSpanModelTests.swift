import XCTest
@testable import CatApp

final class AverageLifeSpanModelTests: XCTestCase {
    func testAverageLifeSpanWithRangeWithSpaces() throws {
        let breed = CatBreed(
            id: "a",
            name: "A",
            origin: nil,
            description: nil,
            temperament: nil,
            lifeSpan: "10 - 12",
            image: nil,
            referenceImageId: nil
        )
        let value = try XCTUnwrap(breed.averageLifeSpan)
        XCTAssertEqual(value, 11.0)
    }

    func testAverageLifeSpanWithRangeNoSpaces() throws {
        let breed = CatBreed(
            id: "b",
            name: "B",
            origin: nil,
            description: nil,
            temperament: nil,
            lifeSpan: "8-14",
            image: nil,
            referenceImageId: nil
        )
        let value = try XCTUnwrap(breed.averageLifeSpan)
        XCTAssertEqual(value, 11.0)
    }

    func testAverageLifeSpanWithSingleValue() throws {
        let breed = CatBreed(
            id: "c",
            name: "C",
            origin: nil,
            description: nil,
            temperament: nil,
            lifeSpan: "15",
            image: nil,
            referenceImageId: nil
        )
        let value = try XCTUnwrap(breed.averageLifeSpan)
        XCTAssertEqual(value, 15.0)
    }

    func testAverageLifeSpanInvalidStringReturnsNil() {
        let invalids: [String?] = [nil, "", "abc", "10 - x", " - ", "10 - "]
        for life in invalids {
            let breed = CatBreed(
                id: UUID().uuidString,
                name: "X",
                origin: nil,
                description: nil,
                temperament: nil,
                lifeSpan: life,
                image: nil,
                referenceImageId: nil
            )
            XCTAssertNil(breed.averageLifeSpan, "Expected nil for life_span: \(life ?? "nil")")
        }
    }
}
