import XCTest
import Cardano

extension WithdrawalsTests {
    /// Verifies initialization and basic state management for the Withdrawals collection.
    /// To move ADA from a staking account, a withdrawal must be explicitly added to a 
    /// transaction. This test ensures the collection is correctly initialized empty.
    func testWithdrawalsExtra() throws {
        let withdrawals = try Withdrawals()
        XCTAssertEqual(try withdrawals.len(), 0)
    }
}
