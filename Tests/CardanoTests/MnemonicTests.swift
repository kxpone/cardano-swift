import XCTest
@testable import Cardano

final class MnemonicTests: XCTestCase {
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
    
    func testMnemonicValidateAsync() async throws {
        let valid = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let invalid = "invalid mnemonic phrase that is not valid"
        
        let results = try await Mnemonic.validate(phrases: [valid, invalid])
        XCTAssertEqual(results, [true, false])
    }
    
    func testMnemonicInitExceptions() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let m = Mnemonic(phrase: words)
        XCTAssertEqual(m.phrase, words)
    }

    func testEntropyWordCounts() {
        XCTAssertEqual(MnemonicStrength.bits128.wordCount, 12)
        XCTAssertEqual(MnemonicStrength.bits160.wordCount, 15)
        XCTAssertEqual(MnemonicStrength.bits192.wordCount, 18)
        XCTAssertEqual(MnemonicStrength.bits224.wordCount, 21)
        XCTAssertEqual(MnemonicStrength.bits256.wordCount, 24)
    }
}
