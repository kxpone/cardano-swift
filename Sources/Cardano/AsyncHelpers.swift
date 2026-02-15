//
//  AsyncHelpers.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

/// Helper utilities for async/await operations in the Cardano API.
/// Provides convenient wrappers and patterns for parallel processing.
public class AsyncHelpers {
    
    /// Executes a closure on a background thread with high priority.
    /// Useful for offloading synchronous CPU-bound tasks.
    /// - Parameter block: The synchronous block to execute.
    /// - Returns: The result of the block execution.
    public static func runOnBackgroundThread<T>(_ block: @escaping () throws -> T) async throws -> T {
        return try await Task.detached(priority: .userInitiated) {
            try block()
        }.value
    }
    
    /// Processes multiple items in parallel with a maximum concurrency limit.
    /// Prevents resource exhaustion when processing large batches.
    /// - Parameters:
    ///   - items: The items to process.
    ///   - maxConcurrency: The maximum number of concurrent operations (default: 4).
    ///   - block: The async operation to perform on each item.
    /// - Returns: An array of results in the same order as input items.
    public static func processInParallel<T, U>(
        items: [T],
        maxConcurrency: Int = 4,
        block: @escaping (T) async throws -> U
    ) async throws -> [U] {
        let results = try await withThrowingTaskGroup(of: (Int, U).self, returning: [U].self) { group in
            var activeCount = 0
            var itemIterator = items.enumerated().makeIterator()
            
            while activeCount < maxConcurrency, let (idx, item) = itemIterator.next() {
                group.addTask {
                    return try await (idx, block(item))
                }
                activeCount += 1
            }
            
            var resultArray = [(Int, U)]()
            for try await (idx, result) in group {
                resultArray.append((idx, result))
                
                if let (nextIdx, nextItem) = itemIterator.next() {
                    group.addTask {
                        return try await (nextIdx, block(nextItem))
                    }
                }
            }
            
            return resultArray.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        return results
    }
    
    /// Retries an async operation with exponential backoff on failure.
    /// - Parameters:
    ///   - maxAttempts: The maximum number of retry attempts.
    ///   - initialDelay: The initial delay in milliseconds between retries.
    ///   - block: The async operation to retry.
    /// - Returns: The result of successful execution.
    public static func retryWithBackoff<T>(
        maxAttempts: Int = 3,
        initialDelay: UInt64 = 100,
        block: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 0..<maxAttempts {
            do {
                return try await block()
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    try await Task.sleep(nanoseconds: delay * 1_000_000)
                    delay *= 2 // Exponential backoff
                }
            }
        }
        
        throw lastError ?? CardanoError.invalidPath
    }
}

