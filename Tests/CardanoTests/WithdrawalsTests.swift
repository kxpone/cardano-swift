import XCTest
@testable import Cardano

final class WithdrawalsTests: XCTestCase {
    func testWithdrawalsCollection() throws {
        let withdrawals = try Withdrawals()
        XCTAssertEqual(try withdrawals.count(), 0)
        
        // Setup a reward address
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let keychain = try Keychain(mnemonic: mnemonic)
        let stakeCred = try keychain.publicKey().toRawKey().hash().toCredential()
        let rewardAddr = try Address.reward(networkId: 0, stakeCredential: stakeCred)
        
        try withdrawals.insert(rewardAddress: rewardAddr, amount: try BigNum(string: "1000000"))
        XCTAssertEqual(try withdrawals.count(), 1)
    }
}
