//
//  TransactionBuilderTests.swift
//  Cardano
//

import XCTest
import CCardano
@testable import Cardano

final class TransactionBuilderTests: XCTestCase {
    func testComplexTransactionBuilding() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let changeAddress = try wallet.getAddress()
        let receiveAddress = try wallet.getAddress(index: 2)
        
        let utxo = UTXO(
            txHash: "7233486deda2a6c5258a1c758e48a4e6adf5dd936e448c58819afb97f73e2c65",
            index: 0,
            value: Value(coin: 20_000_000),
            address: changeAddress
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        try builder.addOutput(address: receiveAddress, value: Value(coin: 10_000_000))
        
        // Simulating the transaction building logic
        let body = try builder.build(changeAddress: changeAddress)
        XCTAssertNotNil(body)
    }
    
    func testTransactionWithWithdrawals() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let address = try wallet.getAddress()
        
        let keychain = try Keychain(mnemonic: mnemonic)
        let stakeCred = try keychain.derive(path: "m/1852'/1815'/0'/2/0")
            .publicKey()
            .toRawKey()
            .hash()
            .toCredential()
            
        let rewardAddr = try Address.reward(networkId: 0, stakeCredential: stakeCred)
        
        let utxo = UTXO(
            txHash: "7233486deda2a6c5258a1c758e48a4e6adf5dd936e448c58819afb97f73e2c65",
            index: 0,
            value: Value(coin: 30_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        
        // Add a withdrawal
        let withdrawals = try Withdrawals()
        try withdrawals.insert(rewardAddress: rewardAddr, amount: try BigNum(string: "1000000"))
        try builder.setWithdrawals(withdrawals: withdrawals)
        
        let body = try builder.build(changeAddress: address)
        XCTAssertNotNil(body)
    }
    
    func testTransactionWithMetadata() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let address = try wallet.getAddress()
        
        let utxo = UTXO(
            txHash: "7233486deda2a6c5258a1c758e48a4e6adf5dd936e448c58819afb97f73e2c65",
            index: 0,
            value: Value(coin: 30_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        
        let metadata = try Metadata()
        try metadata.insert(label: try BigNum(string: "123"), value: try Metadatum.newText("KXP Transaction"))
        
        let auxData = try AuxiliaryData()
        try auxData.setMetadata(metadata)
        try builder.setAuxiliaryData(auxiliaryData: auxData)
        
        let body = try builder.build(changeAddress: address)
        XCTAssertNotNil(body)
    }
}
