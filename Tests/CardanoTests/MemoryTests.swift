//
//  MemoryTests.swift
//  Cardano
//

import XCTest
@testable import Cardano

final class MemoryTests: XCTestCase {
    func testStressRustInterop() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic)
        let address = try wallet.getAddress()
        
        let utxo = UTXO(
            txHash: "7233486deda2a6c5258a1c758e48a4e6adf5dd936e448c58819afb97f73e2c65",
            index: 0,
            value: Value(coin: 20_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        try builder.addOutput(address: address, value: Value(coin: 10_000_000))
        
        let body = try builder.build(changeAddress: address)
        let keychain = try Keychain(mnemonic: mnemonic)
        let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
        let txHex = try transaction.toHex()
        
        for _ in 0..<100 {
            let txn = try Transaction.fromHex(txHex)
            _ = try txn.hash()
            _ = try txn.toHex()
        }
    }
}
