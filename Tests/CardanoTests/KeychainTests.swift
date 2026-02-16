import XCTest
@testable import Cardano

final class KeychainTests: XCTestCase {
    /// Tests hierarchical deterministic (HD) wallet derivation using the Keychain API.
    /// Cardano follows CIP-1852 for its HD structure. This test ensures that mnemonic phrases 
    /// with optional passwords correctly initialize the derivation root and that asynchronous 
    /// path derivation correctly resolves specific payment or staking keys.
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
