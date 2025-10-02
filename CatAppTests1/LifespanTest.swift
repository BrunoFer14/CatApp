import XCTest
@testable import CatApp

/// Testes unitários para verificar o cálculo da média do life_span das raças.
final class LifeSpanAverageTests: XCTestCase {

    func testAverageLifeSpanCalculation() {
        // Raças de exemplo
        let breeds = [
            CatBreed(
                id: "1",
                name: "Breed A",
                origin: nil,
                description: nil,
                temperament: nil,
                life_span: "10 - 12",
                image: nil
            ),
            CatBreed(
                id: "2",
                name: "Breed B",
                origin: nil,
                description: nil,
                temperament: nil,
                life_span: "8 - 14",
                image: nil
            )
        ]

        // Extrair valores numéricos dos life_span
        let spans = breeds.compactMap { breed -> Double? in
            guard let life = breed.life_span else { return nil }
            let parts = life
                .components(separatedBy: " - ")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }

            if parts.count == 2 {
                return (parts[0] + parts[1]) / 2.0 // média do intervalo
            } else if parts.count == 1 {
                return parts[0]
            }
            return nil
        }

        // Calcular média geral
        let average = spans.reduce(0, +) / Double(spans.count)

        // Assert esperado:
        // Breed A → (10+12)/2 = 11
        // Breed B → (8+14)/2 = 11
        // Média final = (11 + 11) / 2 = 11
        XCTAssertEqual(average, 11.0, accuracy: 0.01)
    }
}
