//
//  Mnemonic.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import Bip39

/// Represents a BIP39 mnemonic recovery phrase.
/// This structure provides utilities for generating new mnemonics and converting them to binary entropy.
public struct Mnemonic {
    /// The actual mnemonic phrase as a space-separated string.
    public let phrase: String
    
    /// Initializes a mnemonic from an existing recovery phrase.
    /// - Parameter phrase: The space-separated recovery phrase.
    public init(phrase: String) {
        self.phrase = phrase
    }
    
    /// Generates a new random mnemonic phrase with the specified strength.
    /// - Parameter strength: The entropy strength (e.g., bits128 results in 12 words).
    /// - Throws: Bip39Error if mnemonic generation fails.
    public init(strength: MnemonicStrength = .bits160) throws {
        let mnemonic = try Bip39.Mnemonic(strength: strength.bits)
        self.phrase = mnemonic.mnemonic().joined(separator: " ")
    }
    
    /// Converts the mnemonic phrase back to its original binary entropy.
    /// - Returns: An array of bytes representing the entropy.
    /// - Throws: Bip39Error if conversion fails (invalid phrase).
    public func toEntropy() throws -> [UInt8] {
        let words = phrase.components(separatedBy: " ")
        return try Bip39.Mnemonic.toEntropy(words)
    }
    
    // MARK: - Priority 3: Async Batch Validation
    
    /// Asynchronously validates multiple mnemonic phrases in parallel.
    /// - Parameter phrases: Array of mnemonic phrase strings to validate.
    /// - Returns: Array of validation results (true = valid, false = invalid) maintaining input order.
    public static func validate(phrases: [String]) async throws -> [Bool] {
        return await withTaskGroup(
            of: (Int, Bool).self,
            returning: [Bool].self
        ) { group in
            for (index, phrase) in phrases.enumerated() {
                group.addTask {
                    let words = phrase.components(separatedBy: " ")
                    let isValid: Bool
                    do {
                        _ = try Bip39.Mnemonic.toEntropy(words)
                        isValid = true
                    } catch {
                        isValid = false
                    }
                    return (index, isValid)
                }
            }
            
            var results = Array(repeating: false, count: phrases.count)
            for await (index, isValid) in group {
                results[index] = isValid
            }
            return results
        }
    }
}

/// Defines the complexity and resulting word count of a mnemonic.
public enum MnemonicStrength {
    /// 128 bits of entropy (12 words).
    case bits128
    /// 160 bits of entropy (15 words) - Preferred for many Cardano wallets.
    case bits160
    /// 192 bits of entropy (18 words).
    case bits192
    /// 224 bits of entropy (21 words).
    case bits224
    /// 256 bits of entropy (24 words).
    case bits256
    
    /// Returns the number of words associated with the strength.
    var wordCount: Int {
        switch self {
        case .bits128: return 12
        case .bits160: return 15
        case .bits192: return 18
        case .bits224: return 21
        case .bits256: return 24
        }
    }
    
    /// Returns the bit count associated with the strength.
    var bits: Int {
        switch self {
        case .bits128: return 128
        case .bits160: return 160
        case .bits192: return 192
        case .bits224: return 224
        case .bits256: return 256
        }
    }
}
