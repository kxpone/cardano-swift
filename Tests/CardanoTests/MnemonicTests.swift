import XCTest
@testable import Cardano

final class MnemonicTests: XCTestCase {
    /// Verifies mnemonic phrase generation for different entropy strengths.
    /// Cardano uses BIP-39 mnemonics. Standard strengths (128 to 256 bits) result in 12 to 24 words. 
    /// Correct word counts are essential for compatibility with other Cardano wallets like Yoroi or Daedalus.
    func testMnemonicStrengths() throws {
        let s128 = try Mnemonic(strength: .bits128)
        XCTAssertEqual(s128.phrase.components(separatedBy: " ").count, 12)
        
        let s192 = try Mnemonic(strength: .bits192)
        XCTAssertEqual(s192.phrase.components(separatedBy: " ").count, 18)
        
        let s224 = try Mnemonic(strength: .bits224)
        XCTAssertEqual(s224.phrase.components(separatedBy: " ").count, 21)
        
        let s256 = try Mnemonic(strength: .bits256)
        XCTAssertEqual(s256.phrase.components(separatedBy: " ").count, 24)
    }
    
    /// Verifies asynchronous validation of multiple recovery phrases.
    /// Batch validation is useful for wallet recovery UIs where users might import multiple accounts. 
    /// This ensures the library correctly identifies valid and invalid BIP-39 phrases in parallel.
    func testMnemonicValidateAsync() async throws {
        let valid = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let invalid = "invalid mnemonic phrase that is not valid"
        
        let results = try await Mnemonic.validate(phrases: [valid, invalid])
        XCTAssertEqual(results, [true, false])
    }
    
    /// Tests initialization of Mnemonic objects from existing phrases.
    /// This confirms that a mnemonic stored by an application can be correctly 
    /// reloaded and its phrase integrity maintained for future key derivations.
    func testMnemonicInitExceptions() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let m = Mnemonic(phrase: words)
        XCTAssertEqual(m.phrase, words)
    }

    /// Validates the mapping between bits of entropy and resulting word counts.
    /// Standardizing this mapping ensures the SDK follows the BIP-39 specification precisely, 
    /// maintaining deterministic behavior across different Cardano wallet implementations.
    func testEntropyWordCounts() {
        XCTAssertEqual(MnemonicStrength.bits128.wordCount, 12)
        XCTAssertEqual(MnemonicStrength.bits160.wordCount, 15)
        XCTAssertEqual(MnemonicStrength.bits192.wordCount, 18)
        XCTAssertEqual(MnemonicStrength.bits224.wordCount, 21)
        XCTAssertEqual(MnemonicStrength.bits256.wordCount, 24)
    }
}
