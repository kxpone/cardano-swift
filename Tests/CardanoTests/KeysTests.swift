import XCTest
import Cardano

final class KeysTests: XCTestCase {
    /// Tests BIP32 key derivation and serialization.
    /// BIP32 hierarchical deterministic keys are the foundation of Cardano wallets. 
    /// This test ensures that private keys derived from entropy can produce valid child keys 
    /// and that public keys can be correctly serialized/deserialized for sharing or address computation.
    func testBip32Keys() throws {
        let entropy = Data(repeating: 0, count: 32)
        let rootKey = try Bip32PrivateKey.fromEntropy(entropy: entropy)
        XCTAssertNotNil(rootKey)
        
        let child = try rootKey.derive(index: 0)
        XCTAssertNotNil(child)
        
        let pubKey = try child.toPublic()
        XCTAssertNotNil(pubKey)
        
        let pubBytes = try pubKey.asBytes()
        XCTAssertFalse(pubBytes.isEmpty)
        
        let pubFromBytes = try Bip32PublicKey.fromBytes(bytes: pubBytes)
        XCTAssertEqual(try pubFromBytes.asBytes(), pubBytes)
    }

    /// Verifies standard Ed25519 key operations.
    /// Non-extended keys are used for individual signatures (e.g., transaction witnesses). 
    /// Transitioning between private and public keys and validating their byte representations 
    /// is required for transaction signing and witness verification.
    func testSimpleKeys() throws {
        let bytes64 = Data(repeating: 1, count: 64)
        let priv = try PrivateKey.fromBytes(bytes: bytes64)
        XCTAssertNotNil(priv)
        XCTAssertFalse(try priv.toBytes().isEmpty)
        
        let pub = try priv.toPublic()
        XCTAssertNotNil(pub)
        let pubBytes = try pub.toBytes()
        XCTAssertFalse(pubBytes.isEmpty)
        
        let pub2 = try PublicKey.fromBytes(bytes: pubBytes)
        XCTAssertEqual(try pub2.toBytes(), pubBytes)
    }
}
