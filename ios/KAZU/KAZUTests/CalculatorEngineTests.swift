import XCTest
@testable import KAZU

final class CalculatorEngineTests: XCTestCase {
    func testBinaryOperations() {
        XCTAssertEqual(BinaryOperation.add.apply(12, 8), 20)
        XCTAssertEqual(BinaryOperation.multiply.apply(7, 6), 42)
        XCTAssertNil(BinaryOperation.divide.apply(4, 0))
        XCTAssertEqual(BinaryOperation.power.apply(2, 10), 1024)
    }

    func testScientificOperations() {
        XCTAssertEqual(UnaryOperation.sin.apply(30)!, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(UnaryOperation.sqrt.apply(81), 9)
        XCTAssertNil(UnaryOperation.log.apply(0))
    }
}

