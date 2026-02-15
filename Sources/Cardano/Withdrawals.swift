//
//  Withdrawals.swift
//  Cardano
//
//  Created by hellc.
//  Copyright © 2020-2026 KXP. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import CCardano

/// Managed collection of reward withdrawals for a transaction.
public class Withdrawals {
    internal let pointer: RPtr
    
    internal init(pointer: RPtr) {
        self.pointer = pointer
    }
    
    public init() throws {
        self.pointer = try CSL.callRPtr { csl_bridge_withdrawals_new($0, $1) }
    }
    
    deinit {
        var p = pointer
        csl_bridge_rptr_free(&p)
    }
    
    public func insert(rewardAddress: Address, amount: BigNum) throws {
        // We need to convert the Address to RewardAddress first if the bridge requires it
        // csl_bridge_reward_address_from_address(address_rptr, &result, &error)
        let rewardAddrPtr = try CSL.callRPtr { csl_bridge_reward_address_from_address(rewardAddress.pointer, $0, $1) }
        _ = try CSL.callRPtr { csl_bridge_withdrawals_insert(pointer, rewardAddrPtr, amount.pointer, $0, $1) }
    }
    
    public func count() throws -> Int64 {
        return try CSL.call { csl_bridge_withdrawals_len(pointer, $0, $1) }
    }
}

extension TransactionBuilder {
    /// Sets withdrawals for the transaction.
    public func setWithdrawals(withdrawals: Withdrawals) throws {
        try CSL.voidCall { csl_bridge_transaction_builder_set_withdrawals(builder, withdrawals.pointer, $0) }
    }
}
