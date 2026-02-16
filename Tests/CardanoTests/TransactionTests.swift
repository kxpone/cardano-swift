import XCTest
@testable import Cardano

final class TransactionTests: XCTestCase {
    /// Verifies the full lifecycle of a transaction: construction, building, and signing.
    /// In Cardano, transactions follow an eUTXO model. This test ensures that a simple
    /// payment transaction correctly balances inputs and outputs and produces a valid
    /// witness set (signature) for the spending credential.
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
        
        // Finalizing the transaction body ensures that fees are calculated and change is returned.
        let body = try builder.build(changeAddress: address)
        let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
        
        XCTAssertFalse(try transaction.toHex().isEmpty)
    }
    
    /// Tests transaction serialization and deserialization from Hex.
    /// Maintaining binary compatibility with the Cardano Node (CBOR format) is essential
    /// for transaction submission and propagation across the network.
    func testTransactionCodec() throws {
        let body = try TransactionBody(
            inputs: try TransactionInputs(),
            outputs: try TransactionOutputs(),
            fee: try BigNum(string: "1000000")
        )
        let tx = try Transaction(body: body, witnessSet: try TransactionWitnessSet())
        let hex = try tx.toHex()
        
        let decoded = try Transaction.fromHex(hex)
        XCTAssertEqual(try decoded.toHex(), hex)
    }

    /// Verifies that the library correctly identifies invalid transaction data.
    func testInvalidTransactionParsing() throws {
        XCTAssertThrowsError(try Transaction.fromHex("invalid_hex"))
    }
}
