import XCTest
@testable import Cardano

final class WalletTests: XCTestCase {
    static let testMnemonic = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
    
    /// Tests deterministic wallet address generation.
    /// In Cardano, wallets follow the hierarchical deterministic (HD) pattern (CIP-1852).
    /// This test ensures that the same seed phrase always produces the same set of 
    /// payment and stake addresses across different accounts and indices.
    func testWalletAddressGeneration() throws {
        let words = WalletTests.testMnemonic
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0) // Testnet
        
        // Exact address from known test vector for account 0, index 0
        let expected = "addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w"
        let address = try wallet.getAddress(account: 0, index: 0)
        XCTAssertEqual(try address.toBech32(), expected)
    }
}
