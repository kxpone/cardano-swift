import XCTest
import Cardano

extension WithdrawalsTests {
    func testWithdrawalsExtra() throws {
        let withdrawals = try Withdrawals()
        XCTAssertEqual(try withdrawals.len(), 0)
    }
}
