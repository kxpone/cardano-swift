import XCTest
@testable import Cardano

extension AddressTests {
    /// Tests Shelley-era address types: Enterprise and Reward addresses.
    /// In Cardano, Enterprise addresses are for payments only (no staking), 
    /// while Reward addresses (Stake addresses) are used to collect staking rewards.
    /// This test ensures that credentials derived from keys correctly form these address types
    /// for specific network IDs (0 for Testnet, 1 for Mainnet).
    func testEnterpriseAndRewardAddresses() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        
        // Derive payment credential according to CIP-1852
        let paymentCred = try keychain.derive(path: "m/1852'/1815'/0'/0/0")
            .publicKey()
            .toRawKey()
            .hash()
            .toCredential()
        
        // Enterprise addresses do not have a stake component
        let enterpriseAddr = try Address.enterprise(networkId: 0, paymentCredential: paymentCred)
        XCTAssertEqual(try enterpriseAddr.networkId(), 0)
        XCTAssertTrue(try enterpriseAddr.toBech32().contains("addr_test"))
        
        // Reward addresses are used for stake account registration and delegation
        let rewardAddr = try Address.reward(networkId: 0, stakeCredential: paymentCred)
        XCTAssertEqual(try rewardAddr.networkId(), 0)
        XCTAssertTrue(try rewardAddr.toBech32().contains("stake_test"))
    }
    
    /// Verifies asynchronous generation of Reward addresses for batch processing.
    /// Useful for applications that need to generate multiple stake addresses simultaneously
    /// without blocking the main execution thread.
    func testRewardAddressAsync() async throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let cred = try await keychain.publicKey().toRawKey().hash().toCredential()
        
        let addresses = try await Address.reward(networkId: 1, credentials: [cred])
        XCTAssertEqual(addresses.count, 1)
    }
}
