import XCTest
@testable import Cardano
import CCardano

final class CSLTests: XCTestCase {
    func testCSLError() {
        XCTAssertThrowsError(try Address(bech32: "invalid_bech32")) { error in
            XCTAssertTrue(error is CardanoError)
            if case CardanoError.cslError(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected cslError")
            }
        }
    }
    
    func testCardanoErrorDescription() {
        XCTAssertEqual(CardanoError.invalidPath.errorDescription, "Invalid derivation path")
        XCTAssertEqual(CardanoError.derivationFailed.errorDescription, "Key derivation failed")
        XCTAssertEqual(CardanoError.addressCreationFailed.errorDescription, "Failed to create address")
        XCTAssertEqual(CardanoError.cslError("test").errorDescription, "test")
        
        // Equatable
        XCTAssertEqual(CardanoError.cslError("a"), CardanoError.cslError("a"))
        XCTAssertNotEqual(CardanoError.cslError("a"), CardanoError.cslError("b"))
        XCTAssertNotEqual(CardanoError.cslError("a"), CardanoError.invalidPath)
    }
}
