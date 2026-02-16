import XCTest
@testable import Cardano

extension TransactionTests {
    /// Tests Transaction Input (UTXO reference) logic.
    /// Each input refers to a previous Transaction ID and an output index.
    func testTransactionInputs() throws {
        let hash = Data(repeating: 0, count: 32)
        let input = try TransactionInput(hash: hash, index: 1)
        XCTAssertNotNil(input)
        XCTAssertEqual(try input.index(), 1)
        XCTAssertEqual(try input.transactionId(), hash)
    }
    
    /// Verifies Transaction Body fields accessors.
    /// The body contains the "intent" of the transaction (who gets what, and the fee paid).
    func testTransactionBodyFields() throws {
        let builder = try TransactionBuilder()
        let address = try Address(bech32: "addr1qydqycuh5r253yp70572k2u80yy7hajyy5r9vd6nl9kcxndftu32t8ma5rrlus948vc8wcm0wj5nq6yz5p532lth67xq4hd8ee")
        let value = Value(coin: 20000000)
        let utxo = UTXO(txHash: "fd656fb1f4cf6fbbc36f2705568a4d3b7a970ec0b39f80cc81e1293626b77316", index: 0, value: value, address: address)
        try builder.addInputs(from: [utxo])
        
        // Add an output so the builder has something to pay for
        try builder.addOutput(address: address, value: Value(coin: 10000000))
        
        let body = try builder.build(changeAddress: address)
        XCTAssertGreaterThan(try body.inputs().len(), 0)
        XCTAssertGreaterThan(try body.outputs().len(), 0)
        XCTAssertNotEqual(try body.fee().toString(), "0")
    }
    
    /// Tests complex value composition in transaction outputs.
    /// Cardano supports Multi-Asset transactions where an output can contain ADA plus 
    /// any number of native tokens (NFTs, utility tokens).
    func testValueComposition() throws {
        let multiasset = try MultiAsset()
        let policyId = "00000000000000000000000000000000000000000000000000000000"
        let assets = try Assets()
        try assets.add(assetName: "TEST", amount: 100)
        try multiasset.insert(policyId: policyId, assets: assets)
        
        let value = Value(coin: 1000000, multiAsset: multiasset)
        XCTAssertNotNil(value.multiAsset)
    }
}
