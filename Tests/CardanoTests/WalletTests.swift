import XCTest
@testable import Cardano

final class WalletTests: XCTestCase {
    func testWalletAddressGeneration() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0) // Testnet
        
        // Exact address from known test vector
        let expected = "addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w"
        let address = try wallet.getAddress(account: 0, index: 0)
        XCTAssertEqual(try address.toBech32(), expected)
    }
}
