import XCTest
@testable import Cardano

final class TransactionTests: XCTestCase {
    func testBuildAndSignTransaction() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let keychain = try Keychain(mnemonic: mnemonic)
        
        let address = try wallet.getAddress(account: 0, index: 0)
        let destination = try wallet.getAddress(account: 1, index: 0)
        
        let utxo = UTXO(
            txHash: "fd656fb1f4cf6fbbc36f2705568a4d3b7a970ec0b39f80cc81e1293626b77316",
            index: 0,
            value: Value(coin: 20_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        try builder.addOutput(address: destination, value: Value(coin: 10_000_000))
        try builder.setTTL(ttl: 1000)
        
        let body = try builder.build(changeAddress: address)
        let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
        
        XCTAssertFalse(try transaction.toHex().isEmpty)
    }
    
    func testTransactionParsing() throws {
        // Handled in MemoryTests
    }
}
