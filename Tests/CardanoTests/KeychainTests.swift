import XCTest
@testable import Cardano

final class KeychainTests: XCTestCase {
    func testKeychainAdditional() async throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        
        let keychain = try Keychain(mnemonic: mnemonic, password: [1, 2, 3])
        XCTAssertNotNil(keychain)
        
        // Invalid path
        do {
            _ = try await keychain.derive(path: "m/invalid/0") as Keychain
            XCTFail("Should have thrown")
        } catch {}
        
        // Async derive
        let derived = try await keychain.derive(path: "m/1852'/1815'/0'/0/0")
        XCTAssertNotNil(derived)
    }
}
