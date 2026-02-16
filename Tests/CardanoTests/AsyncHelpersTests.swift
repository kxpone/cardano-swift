import XCTest
@testable import Cardano

final class AsyncHelpersTests: XCTestCase {
    
    func testRunOnBackgroundThread() async throws {
        let result = try await AsyncHelpers.runOnBackgroundThread {
            return "success"
        }
        XCTAssertEqual(result, "success")
        
        // Test throwing
        do {
            _ = try await AsyncHelpers.runOnBackgroundThread {
                throw CardanoError.invalidPath
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(error as? CardanoError, .invalidPath)
        }
    }
    
    func testProcessInParallel() async throws {
        let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let results = try await AsyncHelpers.processInParallel(items: items, maxConcurrency: 3) { item in
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return item * 2
        }
        
        XCTAssertEqual(results, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    }
    
    func testProcessInParallelEmpty() async throws {
        let items: [Int] = []
        let results = try await AsyncHelpers.processInParallel(items: items) { item in
            return item
        }
        XCTAssertEqual(results, [])
    }
    
    func testRetryWithBackoffSuccess() async throws {
        var attempts = 0
        let result = try await AsyncHelpers.retryWithBackoff(maxAttempts: 3, initialDelay: 10) {
            attempts += 1
            if attempts < 2 {
                throw CardanoError.derivationFailed
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 2)
    }
    
    func testRetryWithBackoffFailure() async throws {
        var attempts = 0
        do {
            _ = try await AsyncHelpers.retryWithBackoff(maxAttempts: 3, initialDelay: 10) {
                attempts += 1
                throw CardanoError.derivationFailed
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(error as? CardanoError, .derivationFailed)
            XCTAssertEqual(attempts, 3)
        }
    }
    
    func testRetryWithBackoffZeroAttempts() async throws {
        do {
            _ = try await AsyncHelpers.retryWithBackoff(maxAttempts: 0) {
                return "fail"
            }
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(error as? CardanoError, .invalidPath)
        }
    }
}
