import XCTest
@testable import Cardano

final class AsyncHelpersTests: XCTestCase {
    
    /// Verifies offloading tasks to background threads.
    /// Many Cardano operations (like heavy cryptographic signing or large CBOR serialization) 
    /// are CPU-intensive. Offloading them ensures the main thread stays free for UI animations and interactions.
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
    
    /// Tests the parallel processing utility with concurrency limits.
    /// When dealing with large batches (e.g., deriving 1,000 addresses or signing 100 UTXOs), 
    /// parallelization maximizes multi-core utilization while limits prevent memory exhaustion 
    /// from creating too many simultaneous tasks.
    func testProcessInParallel() async throws {
        let items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let results = try await AsyncHelpers.processInParallel(items: items, maxConcurrency: 3) { item in
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return item * 2
        }
        
        XCTAssertEqual(results, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    }
    
    /// Verifies parallel processing behavior with empty input sets.
    /// This edge case ensures that batch operations (like empty wallet synchronizations) 
    /// return gracefully without triggering errors or hangs in the task group.
    func testProcessInParallelEmpty() async throws {
        let items: [Int] = []
        let results = try await AsyncHelpers.processInParallel(items: items) { item in
            return item
        }
        XCTAssertEqual(results, [])
    }
    
    /// Tests the retry logic with exponential backoff on successful recovery.
    /// Network-dependent operations or temporary resource locks in the Rust bridge 
    /// might fail transiently. Automatically retrying with a delay improves the 
    /// robustness of blockchain interactions.
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
    
    /// Verifies that the retry logic correctly propagates the final error after all attempts fail.
    /// This ensures that persistent issues (like invalid credentials) are correctly 
    /// reported to the user after the maximum number of retries is reached.
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
    
    /// Tests behavior when maxAttempts is set to zero or invalid values.
    /// This prevents misconfiguration of the retry utility from causing infinite 
    /// loops or silent failures in high-level blockchain methods.
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
