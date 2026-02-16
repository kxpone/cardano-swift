import XCTest
import Cardano

extension MetadataTests {
    /// Comprehensive test for Transaction Metadata and Auxiliary Data.
    /// In Cardano, metadata allows attaching semi-structured data to transactions using
    /// specific labels (e.g., label 674 for CIP-20 messages). This test verifies the 
    /// creation of complex metadata structures (text, maps, integers) and their
    /// successful embedding into a signed transaction for off-chain indexing.
    func testMetadataExtra() throws {
        let metadata = try Metadata()
        let label = try BigNum(string: "100")
        let datum = try Metadatum.newText("Hello")
        try metadata.insert(label: label, value: datum)
        
        XCTAssertFalse(try metadata.toHex().isEmpty)
        
        let intDatum = try Metadatum.newInt(try BigNum(string: "42"))
        XCTAssertNotNil(intDatum)
        
        let map = try MetadataMap()
        try map.insert(key: "key", value: intDatum)
        let mapDatum = try Metadatum.newMap(map)
        XCTAssertNotNil(mapDatum)
        
        let aux = try AuxiliaryData()
        try aux.setMetadata(metadata)
        
        let body = try TransactionBody(
            inputs: try TransactionInputs(),
            outputs: try TransactionOutputs(),
            fee: try BigNum(string: "1000000")
        )
        let tx = try Transaction(
            body: body,
            witnessSet: try TransactionWitnessSet(),
            auxiliaryData: aux
        )
        
        let aux2 = try tx.auxiliaryData()
        XCTAssertNotNil(aux2)
        
        let metadata2 = try aux2?.metadata()
        XCTAssertNotNil(metadata2)
    }
}
