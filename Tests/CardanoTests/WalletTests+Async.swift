import XCTest
@testable import Cardano

extension WalletTests {
    /// Tests asynchronous data signing using the Wallet API.
    /// In modern iOS/macOS apps, signing operations (which involve heavy Rust-to-Swift bridge 
    /// calls) should be performed asynchronously to keep the UI responsive.
    func testWalletAsyncSignData() async throws {
        let mnemonic = Mnemonic(phrase: WalletTests.testMnemonic)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let address = try await wallet.getAddress()
        let bech32 = try address.toBech32()
        
        let data = Data(repeating: 0, count: 32)
        let signature = try await wallet.signData(data: data, withAddress: bech32)
        XCTAssertNotNil(signature)
    }
    
    /// Verifies batch data signing capabilities.
    /// This is useful for multi-asset transactions or signing multiple authentication 
    /// challenges in a single user action.
    func testWalletAsyncSignDataList() async throws {
        let mnemonic = Mnemonic(phrase: WalletTests.testMnemonic)
        let wallet = try Wallet(mnemonic: mnemonic, networkId: 0)
        let address = try await wallet.getAddress()
        let bech32 = try address.toBech32()
        
        let data1 = Data(repeating: 1, count: 32)
        let data2 = Data(repeating: 2, count: 32)
        
        let signatures = try await wallet.signData(dataList: [
            (data: data1, address: bech32),
            (data: data2, address: bech32)
        ])
        
        XCTAssertEqual(signatures.count, 2)
    }
}
