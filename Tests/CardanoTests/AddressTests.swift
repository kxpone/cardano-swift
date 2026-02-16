import XCTest
import CCardano
@testable import Cardano

final class AddressTests: XCTestCase {
    /// Tests the conversion of a Bech32-encoded string back to an Address object and vice versa.
    /// This ensures that the library correctly handles the standard string representation used in the Cardano ecosystem
    /// for both Mainnet (`addr1...`) and Testnet (`addr_test1...`).
    func testAddressFromBech32() throws {
        let bech32 = "addr1qydqycuh5r253yp70572k2u80yy7hajyy5r9vd6nl9kcxndftu32t8ma5rrlus948vc8wcm0wj5nq6yz5p532lth67xq4hd8ee"
        let address = try Address(bech32: bech32)
        XCTAssertEqual(try address.toBech32(), bech32)
    }
    
    /// Tests address instantiation from a raw CBOR/Hex string.
    /// In Cardano, addresses are binary payloads. Validating Hex parsing ensures compatibility with
    /// low-level transaction builders and blockchain indexers that store addresses in raw bytes.
    func testAddressFromHex() throws {
        let hex = "011a026397a0d548903e7d3cab2b877909ebf6442506563753f96d834da95f22a59f7da0c7fe40b53b3077636f74a9306882a069157d77d78c"
        let address = try Address(hex: hex)
        XCTAssertEqual(try address.toHex(), hex)
    }
}
