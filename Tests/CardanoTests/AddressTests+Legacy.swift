import XCTest
@testable import Cardano

extension AddressTests {
    /// Tests the generation of legacy Byron-era addresses.
    /// Byron addresses use a different structure and serialization (Base58) compared to Shelley's Bech32.
    /// Correct support is vital for wallet recovery of older accounts and supporting legacy 
    /// UTXOs still present on the Mainnet.
    func testByronAddress() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let pubKey = try keychain.derive(path: "m/44'/1815'/0'/0/0").publicKey()
        
        let address = try Address.byron(key: pubKey, protocolMagic: 764824073)
        XCTAssertFalse(try address.toHex().isEmpty)
    }
    
    /// Additional validation for Byron address properties such as the network identifier (protocol magic).
    func testByronAddressExtra() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let pubKey = try keychain.publicKey()
        
        // Protocol magic 764824073 corresponds to Mainnet
        let address = try Address.byron(key: pubKey, protocolMagic: 764824073)
        XCTAssertNotNil(address)
        XCTAssertEqual(try address.networkId(), 1)
    }
}
