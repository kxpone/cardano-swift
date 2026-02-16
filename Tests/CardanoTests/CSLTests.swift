import XCTest
@testable import Cardano
import CCardano

final class CSLTests: XCTestCase {
    /// Verifies that low-level errors from the Rust bridge are correctly converted to CardanoError.
    /// This ensures that library users receive actionable error messages for common 
    /// failures like invalid Bech32 strings or malformed transaction binary data.
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
    
    /// Tests descriptive strings and equality for internal SDK errors.
    /// Correct error reporting is vital for debugging complex on-chain interactions 
    /// and providing clear feedback to end-users when a transaction fails.
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
