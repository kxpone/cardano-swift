import XCTest
import CCardano
@testable import Cardano

final class AddressTests: XCTestCase {
    func testAddressFromBech32() throws {
        let bech32 = "addr1qydqycuh5r253yp70572k2u80yy7hajyy5r9vd6nl9kcxndftu32t8ma5rrlus948vc8wcm0wj5nq6yz5p532lth67xq4hd8ee"
        let address = try Address(bech32: bech32)
        XCTAssertEqual(try address.toBech32(), bech32)
    }
    
    func testAddressFromHex() throws {
        let hex = "011a026397a0d548903e7d3cab2b877909ebf6442506563753f96d834da95f22a59f7da0c7fe40b53b3077636f74a9306882a069157d77d78c"
        let address = try Address(hex: hex)
        XCTAssertEqual(try address.toHex(), hex)
    }

    func testByronAddress() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let pubKey = try keychain.derive(path: "m/44'/1815'/0'/0/0").publicKey()
        
        let address = try Address.byron(key: pubKey, protocolMagic: 764824073)
        XCTAssertFalse(try address.toHex().isEmpty)
    }
    
    func testEnterpriseAndRewardAddresses() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        
        // Use Swift-native key derivation API
        let paymentCred = try keychain.derive(path: "m/1852'/1815'/0'/0/0")
            .publicKey()
            .toRawKey()
            .hash()
            .toCredential()
        
        let enterpriseAddr = try Address.enterprise(networkId: 0, paymentCredential: paymentCred)
        XCTAssertEqual(try enterpriseAddr.networkId(), 0)
        XCTAssertTrue(try enterpriseAddr.toBech32().contains("addr_test"))
        
        let rewardAddr = try Address.reward(networkId: 0, stakeCredential: paymentCred)
        XCTAssertEqual(try rewardAddr.networkId(), 0)
        XCTAssertTrue(try rewardAddr.toBech32().contains("stake_test"))
    }
}
