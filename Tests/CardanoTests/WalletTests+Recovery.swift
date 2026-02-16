//
//  WalletRecoveryTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

extension WalletTests {
    /// Tests wallet recovery from a 15-word mnemonic phrase.
    /// This ensures that the recovery process accurately restores the same state (addresses)
    /// as the original wallet. Compatibility with other Cardano wallets (like Eternl or Lace)
    /// depends on this exact derivation logic.
    func testCreateFromWordsAddressToBech32Recovery() throws {
        let words = WalletTests.testMnemonic
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        
        // Exact expected result for the primary address
        XCTAssertEqual(try wallet.getAddress(index: 0).toBech32(), "addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w")
    }
    
    /// Verifies that a recovered wallet can produce valid signatures for its derived addresses.
    /// This test mimics the "Sign Message" functionality often used for DApp authentication.
    func testSigningSomeDataRecovery() throws {
        let words = WalletTests.testMnemonic
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        
        let messageData = Data(Array(0..<32).map { UInt8($0) })
        let signature = try wallet.signData(data: messageData, withAddress: try wallet.getAddress(index: 15).toBech32())
        
        XCTAssertFalse(signature.signature.isEmpty)
        XCTAssertFalse(signature.key.isEmpty)
    }
}
