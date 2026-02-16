import XCTest
@testable import Cardano

extension AddressTests {
    /// Tests Pointer addresses, which are a specialized Shelley address type.
    /// Unlike Base addresses that contain a stake credential, Pointer addresses reference 
    /// a stake registration certificate already on the blockchain via (slot, txIndex, certIndex).
    /// This reduces address length while still enabling staking.
    func testPointerAddress() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let cred = try keychain.publicKey().toRawKey().hash().toCredential()
        
        let address = try Address.pointer(networkId: 0, paymentCredential: cred, slot: 100, txIndex: 1, certIndex: 0)
        XCTAssertNotNil(address)
        XCTAssertEqual(try address.networkId(), 0)
    }
}
