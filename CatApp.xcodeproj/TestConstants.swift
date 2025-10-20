import Foundation

enum TestConstants {
    // Expectation timeouts
    static let defaultExpectationTimeout: TimeInterval = 2.0

    // RunLoop delays used to allow Combine pipelines or async tasks to complete in tests
    static let shortDelay: TimeInterval = 0.05
    static let mediumDelay: TimeInterval = 0.1
    static let longDelay: TimeInterval = 0.2
}
