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

    func testCompoundInterestWithoutRate() {
        let result = SpecialtyMath.compound(
            principal: 1_000_000,
            annualRate: 0,
            years: 2,
            monthlyDeposit: 10_000
        )
        XCTAssertEqual(result.total, 1_240_000, accuracy: 0.001)
        XCTAssertEqual(result.invested, 1_240_000, accuracy: 0.001)
    }

    func testHealthAndElectricalCalculations() {
        XCTAssertEqual(SpecialtyMath.bmi(height: 170, weight: 65), 22.491, accuracy: 0.001)
        let result = SpecialtyMath.electrical(voltage: 100, current: 2, hours: 3)
        XCTAssertEqual(result.power, 200)
        XCTAssertEqual(result.resistance, 50)
        XCTAssertEqual(result.energy, 0.6, accuracy: 0.001)
    }
}
