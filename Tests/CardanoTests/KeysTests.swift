import XCTest
import Cardano

final class KeysTests: XCTestCase {
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

    func testSimpleKeys() throws {
        let bytes = Data(repeating: 1, count: 32)
        // PrivateKey from normal bytes (32 bytes)
        // Wait, from_extended_bytes might expect 64 bytes. Let's use 64 bytes for test.
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
