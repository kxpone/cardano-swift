//
//  WalletRecoveryTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class WalletRecoveryTests: XCTestCase {
    func testCreateFromWordsAddressToBech32() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        
        // Exact expected result
        XCTAssertEqual(try wallet.getAddress(index: 0).toBech32(), "addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w")
    }
    
    func testSigningSomeData() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        
        let messageData = Data(Array(0..<32).map { UInt8($0) })
        let signature = try wallet.signData(data: messageData, withAddress: try wallet.getAddress(index: 15).toBech32())
        
        XCTAssertFalse(signature.signature.isEmpty)
        XCTAssertFalse(signature.key.isEmpty)
    }
}
