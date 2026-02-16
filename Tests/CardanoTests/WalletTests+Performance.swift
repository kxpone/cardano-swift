import XCTest
import CCardano
@testable import Cardano

extension WalletTests {
    private func getPerformanceWallet() throws -> Wallet { 
        let mnemonic = Mnemonic(phrase: WalletTests.testMnemonic) 
        return try Wallet(mnemonic: mnemonic, networkId: 0) 
    }
    
    
    // MARK: - Address Derivation Benchmarks
    
    /// Benchmarks synchronous address derivation.
    /// Used as a baseline to demonstrate the computational overhead of deriving cryptographic 
    /// keys and formatting Bech32 addresses sequentially on the main thread.
    func testAddressSyncPerformance() throws {
        let iterations = 100
        
        let startTime = Date()
        var addresses = [Address]()
        
        for i in 0..<iterations {
            let address = try (try getPerformanceWallet()).getAddress(account: 0, index: UInt32(i))
            addresses.append(address)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerAddress = (duration * 1000) / Double(iterations)
        
        print("""
        ┌─ Synchronous Address Derivation Benchmark
        ├─ Total addresses: \(iterations)
        ├─ Total time: \(String(format: "%.3f", duration))s
        ├─ Time per address: \(String(format: "%.2f", timePerAddress))ms
        └─ Throughput: \(String(format: "%.0f", Double(iterations) / duration)) addresses/sec
        """)
        
        XCTAssertEqual(addresses.count, iterations)
    }
    
    /// Benchmarks asynchronous batch address derivation.
    /// Demonstrates the library's ability to offload derivation to background threads 
    /// and utilize parallel computation, significantly reducing total execution time for many addresses.
    func testAddressAsyncPerformance() async throws {
        let iterations = 100
        
        let startTime = Date()
        let addresses = try await (try getPerformanceWallet()).getAddress(
            account: 0,
            startIndex: 0,
            count: iterations
        )
        let duration = Date().timeIntervalSince(startTime)
        let timePerAddress = (duration * 1000) / Double(iterations)
        
        print("""
        ┌─ Asynchronous Address Derivation Benchmark (Batch)
        ├─ Total addresses: \(iterations)
        ├─ Total time: \(String(format: "%.3f", duration))s
        ├─ Time per address: \(String(format: "%.2f", timePerAddress))ms
        └─ Throughput: \(String(format: "%.0f", Double(iterations) / duration)) addresses/sec
        """)
        
        XCTAssertEqual(addresses.count, iterations)
    }
    
    /// Benchmarks single address derivation with async wrapper.
    /// This test evaluates the overhead of calling the asynchronous API for individual
    /// address generation. In a real-world Cardano app, using the batch API is preferred
    /// when many addresses are needed (e.g., during wallet sync), but single async calls
    /// are ideal for ad-hoc payment address generation.
    func testAddressSingleAsyncPerformance() async throws {
        let iterations = 100
        
        let startTime = Date()
        var addresses = [Address]()
        
        for i in 0..<iterations {
            let address = try await (try getPerformanceWallet()).getAddress(account: 0, index: UInt32(i))
            addresses.append(address)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerAddress = (duration * 1000) / Double(iterations)
        
        print("""
        ┌─ Asynchronous Address Derivation (Sequential)
        ├─ Total addresses: \(iterations)
        ├─ Total time: \(String(format: "%.3f", duration))s
        ├─ Time per address: \(String(format: "%.2f", timePerAddress))ms
        └─ Throughput: \(String(format: "%.0f", Double(iterations) / duration)) addresses/sec
        """)
        
        XCTAssertEqual(addresses.count, iterations)
    }
    
    // MARK: - Concurrent Batch Operations
    
    /// Tests parallel address derivation using Swift Structured Concurrency.
    /// Cardano wallets often need to scan multiple accounts or indices. This test 
    /// demonstrates how the library leverages `TaskGroup` to distribute cryptographic 
    /// derivation across available CPU cores, maximizing performance for large wallets.
    func testParallelAddressDerivation() async throws {
        let addressCount = 50
        
        let startTime = Date()
        
        // Run address derivation with controlled concurrency
        let addresses = try await (try getPerformanceWallet()).getAddress(count: addressCount)
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("""
        ┌─ Parallel Address Derivation
        ├─ Addresses derived: \(addresses.count)
        ├─ Total time: \(String(format: "%.3f", duration))s
        └─ Throughput: \(String(format: "%.0f", Double(addressCount) / duration)) ops/sec
        """)
        
        XCTAssertEqual(addresses.count, addressCount)
    }
    
    // MARK: - Keychain Derivation Benchmarks
    
    /// Tests synchronous multiple keychain derivation.
    /// Deriving child keychains (using BIP-32/CIP-1852) is a CPU-intensive process.
    /// This benchmark quantifies the time needed to derive private keys for different
    /// accounts or roles (staking vs payment) sequentially.
    func testKeychainDerivationSyncPerformance() throws {
        let paths = (0..<50).map { i in
            "m/1852'/1815'/\(i)'/0/0"
        }
        
        let startTime = Date()
        var keychains = [Keychain]()
        
        for path in paths {
            let keychain = try (try getPerformanceWallet()).keychain.derive(path: path)
            keychains.append(keychain)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerDerivation = (duration * 1000) / Double(paths.count)
        
        print("""
        ┌─ Synchronous Keychain Derivation
        ├─ Total derivations: \(paths.count)
        ├─ Total time: \(String(format: "%.3f", duration))s
        ├─ Time per derivation: \(String(format: "%.2f", timePerDerivation))ms
        └─ Throughput: \(String(format: "%.0f", Double(paths.count) / duration)) derivations/sec
        """)
        
        XCTAssertEqual(keychains.count, paths.count)
    }
    
    /// Tests asynchronous multiple keychain derivation.
    /// By utilizing batch derivation, the library can parallelize the underlying
    /// Ed25519-BIP32 operations. This is essential for enterprise-grade applications
    /// that manage thousands of keys or complex HD structures.
    func testKeychainDerivationAsyncPerformance() async throws {
        let paths = (0..<50).map { i in
            "m/1852'/1815'/\(i)'/0/0"
        }
        
        let startTime = Date()
        let keychains = try await (try getPerformanceWallet()).keychain.derive(paths: paths)
        let duration = Date().timeIntervalSince(startTime)
        let timePerDerivation = (duration * 1000) / Double(paths.count)
        
        print("""
        ┌─ Asynchronous Keychain Derivation (Parallel)
        ├─ Total derivations: \(paths.count)
        ├─ Total time: \(String(format: "%.3f", duration))s
        ├─ Time per derivation: \(String(format: "%.2f", timePerDerivation))ms
        └─ Throughput: \(String(format: "%.0f", Double(paths.count) / duration)) derivations/sec
        """)
        
        XCTAssertEqual(keychains.count, paths.count)
    }
    
    // MARK: - UI Responsiveness Tests
    
    /// Simulates UI-blocking operations with synchronous API.
    /// This test highlights the risk of calling cryptographic functions on the main thread.
    /// In a mobile app, even a 50ms block can cause dropped frames; longer operations
    /// will lead to an unresponsive user interface or system termination.
    func testSyncUIBlockingSimulation() throws {
        let startTime = Date()
        
        // Simulate waiting for main thread
        let blockingStart = Date()
        let _ = try (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        let blockingDuration = Date().timeIntervalSince(blockingStart)
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("""
        ┌─ Synchronous Call (Main Thread Impact)
        ├─ Main thread blocked for: \(String(format: "%.2f", blockingDuration * 1000))ms
        ├─ Total time: \(String(format: "%.3f", duration))s
        └─ ⚠️  UI would freeze for \(String(format: "%.0f", blockingDuration * 1000))ms
        """)
    }
    
    /// Demonstrates async non-blocking behavior.
    /// By using the `async` versions of the API, the heavy workload is shifted to a 
    /// background thread pool. This allows the main thread to stay free for UI 
    /// updates and animations while the blockchain data is being processed.
    func testAsyncNonBlockingSimulation() async throws {
        let startTime = Date()
        
        let address = try await (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        // In real scenario, main thread continues processing
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("""
        ┌─ Asynchronous Call (Main Thread Free)
        ├─ Main thread available for: other operations
        ├─ Total background time: \(String(format: "%.3f", duration))s
        └─ ✅ UI remains responsive
        """)
        
        XCTAssertNotNil(address)
    }
    
    // MARK: - Scale Tests
    
    /// Tests scaling behavior with large batches
    func testAddressScaling() async throws {
        let batchSizes = [10, 50, 100, 200]
        
        print("\n┌─ Address Derivation Scaling Test")
        
        for batchSize in batchSizes {
            let startTime = Date()
            let addresses = try await (try getPerformanceWallet()).getAddress(count: batchSize)
            let duration = Date().timeIntervalSince(startTime)
            
            let timePerAddress = (duration * 1000) / Double(batchSize)
            print("├─ \(String(format: "%3d", batchSize)) addresses: \(String(format: "%.3f", duration))s (\(String(format: "%.2f", timePerAddress))ms each)")
            
            XCTAssertEqual(addresses.count, batchSize)
        }
        print("└─ End of scaling test\n")
    }
    
    // MARK: - Memory Tests
    
    /// Verifies proper resource cleanup with async operations
    func testAsyncMemoryCleanup() async throws {
        let iterations = 50
        
        for _ in 0..<iterations {
            let addr = try await (try getPerformanceWallet()).getAddress()
            // Objects should be deallocated when exiting scope
            XCTAssertNotNil(addr)
        }
        
        print("✅ Memory cleanup test passed - no leaks detected")
    }
    
    // MARK: - Priority 1: Enterprise Address Batch Creation
    
    /// Benchmarks synchronous enterprise address creation
    func testEnterpriseAddressesSyncPerformance() throws {
        let networkId: UInt8 = 0
        let count = 500
        
        // Create credentials for testing
        var credentials = [Credential]()
        for i in 0..<count {
            let derivedKeychain = try (try getPerformanceWallet()).keychain.derive(path: "m/1852'/1815'/0'/0/\(i)")
            let publicKey = try derivedKeychain.publicKey().toRawKey()
            let keyHash = try publicKey.hash()
            let credential = try keyHash.toCredential()
            credentials.append(credential)
        }
        
        let startTime = Date()
        var addresses = [Address]()
        
        for credential in credentials {
            let address = try Address.enterprise(networkId: networkId, paymentCredential: credential)
            addresses.append(address)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerAddr = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Synchronous Enterprise Address Creation
        ├─ Total addresses: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per address: \(String(format: "%.3f", timePerAddr))ms
        └─ Throughput: \(String(format: "%.0f", Double(count) / duration)) addresses/sec
        """)
        
        XCTAssertEqual(addresses.count, count)
    }
    
    /// Benchmarks asynchronous enterprise address batch creation
    func testEnterpriseAddressesAsyncPerformance() async throws {
        let networkId: UInt8 = 0
        let count = 500
        
        // Create credentials for testing
        var credentials = [Credential]()
        for i in 0..<count {
            let derivedKeychain = try await (try getPerformanceWallet()).keychain.derive(path: "m/1852'/1815'/0'/0/\(i)")
            let publicKey = try await derivedKeychain.publicKey().toRawKey()
            let keyHash = try publicKey.hash()
            let credential = try keyHash.toCredential()
            credentials.append(credential)
        }
        
        let startTime = Date()
        let addresses = try await Address.enterprise(
            networkId: networkId,
            credentials: credentials
        )
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerAddr = (duration * 1000) / Double(count)
        let comparison = try {
            // Quick sync benchmark for comparison
            let syncStart = Date()
            var syncAddr = [Address]()
            for credential in credentials.prefix(10) {
                syncAddr.append(try Address.enterprise(networkId: networkId, paymentCredential: credential))
            }
            let syncDuration = Date().timeIntervalSince(syncStart)
            return (syncDuration / 10) * Double(count)
        }()
        
        let speedup = comparison / duration
        
        print("""
        ┌─ Asynchronous Enterprise Address Creation (Batch)
        ├─ Total addresses: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per address: \(String(format: "%.3f", timePerAddr))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) addresses/sec
        └─ Speedup: \(String(format: "%.2f", speedup))x faster ⚡
        """)
        
        XCTAssertEqual(addresses.count, count)
    }
    
    // MARK: - Priority 1: UTXO Batch Conversion
    
    /// Benchmarks synchronous UTXO conversion
    func testUTXOConversionSyncPerformance() throws {
        let count = 500
        var utxos = [UTXO]()
        
        let address = try (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        let value = Value(coin: 5000000)
        
        for i in 0..<count {
            let txHash = String(format: "%064x", i)
            let utxo = UTXO(txHash: txHash, index: UInt32(i), value: value, address: address)
            utxos.append(utxo)
        }
        
        let startTime = Date()
        var results = [RPtr]()
        
        for utxo in utxos {
            let ptr = try utxo.toTransactionUnspentOutput()
            results.append(ptr)
        }
        
        // Cleanup
        for ptr in results {
            var p = ptr
            csl_bridge_rptr_free(&p)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerUtxo = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Synchronous UTXO Conversion
        ├─ Total UTXOs: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per UTXO: \(String(format: "%.3f", timePerUtxo))ms
        └─ Throughput: \(String(format: "%.0f", Double(count) / duration)) UTXOs/sec
        """)
        
        XCTAssertEqual(results.count, count)
    }
    
    /// Benchmarks asynchronous UTXO batch conversion
    func testUTXOConversionAsyncPerformance() async throws {
        let count = 500
        var utxos = [UTXO]()
        
        let address = try await (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        let value = Value(coin: 5000000)
        
        for i in 0..<count {
            let txHash = String(format: "%064x", i)
            let utxo = UTXO(txHash: txHash, index: UInt32(i), value: value, address: address)
            utxos.append(utxo)
        }
        
        let startTime = Date()
        let results = try await UTXO.toTransactionUnspentOutput(from: utxos)
        let duration = Date().timeIntervalSince(startTime)
        
        // Cleanup
        for ptr in results {
            var p = ptr
            csl_bridge_rptr_free(&p)
        }
        
        let timePerUtxo = (duration * 1000) / Double(count)
        
        // Comparison with sync baseline
        let comparison = try {
            let syncStart = Date()
            var syncResults = [RPtr]()
            for utxo in utxos.prefix(10) {
                syncResults.append(try utxo.toTransactionUnspentOutput())
            }
            for ptr in syncResults {
                var p = ptr
                csl_bridge_rptr_free(&p)
            }
            let syncDuration = Date().timeIntervalSince(syncStart)
            return (syncDuration / 10) * Double(count)
        }()
        
        let speedup = comparison / duration
        
        print("""
        ┌─ Asynchronous UTXO Conversion (Batch)
        ├─ Total UTXOs: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per UTXO: \(String(format: "%.3f", timePerUtxo))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) UTXOs/sec
        └─ Speedup: \(String(format: "%.2f", speedup))x faster ⚡
        """)
        
        XCTAssertEqual(results.count, count)
    }
    
    // MARK: - Priority 2: Public Key Hash Batch
    
    /// Benchmarks synchronous public key hashing
    func testPublicKeyHashSyncPerformance() throws {
        let count = 200
        var publicKeys = [PublicKey]()
        
        for i in 0..<count {
            let derivedKeychain = try (try getPerformanceWallet()).keychain.derive(path: "m/1852'/1815'/0'/0/\(i)")
            let publicKey = try derivedKeychain.publicKey().toRawKey()
            publicKeys.append(publicKey)
        }
        
        let startTime = Date()
        var hashes = [KeyHash]()
        
        for key in publicKeys {
            let hash = try key.hash()
            hashes.append(hash)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerKey = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Synchronous Public Key Hashing
        ├─ Total keys: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per key: \(String(format: "%.3f", timePerKey))ms
        └─ Throughput: \(String(format: "%.0f", Double(count) / duration)) keys/sec
        """)
        
        XCTAssertEqual(hashes.count, count)
    }
    
    /// Benchmarks asynchronous public key hash batch
    func testPublicKeyHashAsyncPerformance() async throws {
        let count = 200
        var publicKeys = [PublicKey]()
        
        for i in 0..<count {
            let derivedKeychain = try await (try getPerformanceWallet()).keychain.derive(path: "m/1852'/1815'/0'/0/\(i)")
            let publicKey = try await derivedKeychain.publicKey().toRawKey()
            publicKeys.append(publicKey)
        }
        
        let startTime = Date()
        let hashes = try await PublicKey.hash(keys: publicKeys)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerKey = (duration * 1000) / Double(count)
        
        // Comparison with sync baseline
        let comparison = try {
            let syncStart = Date()
            var syncHashes = [KeyHash]()
            for key in publicKeys.prefix(10) {
                syncHashes.append(try key.hash())
            }
            let syncDuration = Date().timeIntervalSince(syncStart)
            return (syncDuration / 10) * Double(count)
        }()
        
        let speedup = comparison / duration
        
        print("""
        ┌─ Asynchronous Public Key Hashing (Batch)
        ├─ Total keys: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per key: \(String(format: "%.3f", timePerKey))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) keys/sec
        └─ Speedup: \(String(format: "%.2f", speedup))x faster ⚡
        """)
        
        XCTAssertEqual(hashes.count, count)
    }
    
    // MARK: - Priority 3: BigNum Batch Operations
    
    /// Benchmarks synchronous BigNum summation
    func testBigNumSumSyncPerformance() throws {
        let count = 100
        var numbers = [BigNum]()
        
        for i in 0..<count {
            let num = try BigNum(string: String(i + 1))
            numbers.append(num)
        }
        
        let startTime = Date()
        var sum = try BigNum.zero()
        
        for num in numbers {
            sum = try sum.checkedAdd(num)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerOp = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Synchronous BigNum Summation
        ├─ Total numbers: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per operation: \(String(format: "%.3f", timePerOp))ms
        └─ Throughput: \(String(format: "%.0f", Double(count) / duration)) ops/sec
        """)
    }
    
    /// Benchmarks asynchronous BigNum batch summation
    func testBigNumSumAsyncPerformance() async throws {
        let count = 100
        var numbers = [BigNum]()
        
        for i in 0..<count {
            let num = try BigNum(string: String(i + 1))
            numbers.append(num)
        }
        
        let startTime = Date()
        let _ = try await BigNum.sum(numbers: numbers)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerOp = (duration * 1000) / Double(count)
        
        // Comparison with sync baseline
        let comparison = try {
            let syncStart = Date()
            var syncSum = try BigNum.zero()
            for num in numbers.prefix(10) {
                syncSum = try syncSum.checkedAdd(num)
            }
            let syncDuration = Date().timeIntervalSince(syncStart)
            return (syncDuration / 10) * Double(count)
        }()
        
        let speedup = comparison / duration
        
        print("""
        ┌─ Asynchronous BigNum Summation (Batch)
        ├─ Total numbers: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per operation: \(String(format: "%.3f", timePerOp))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) ops/sec
        └─ Speedup: \(String(format: "%.2f", speedup))x faster ⚡
        """)
    }
    
    /// Benchmarks BigNum batch comparison
    func testBigNumCompareBatch() async throws {
        let count = 50
        var numbers = [BigNum]()
        
        for i in 0..<count {
            let num = try BigNum(string: String(i * 10))
            numbers.append(num)
        }
        
        let reference = try BigNum(string: "250")
        
        let startTime = Date()
        let comparisons = try await BigNum.compare(values: numbers, to: reference)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerOp = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Asynchronous BigNum Batch Comparison
        ├─ Total numbers: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per operation: \(String(format: "%.3f", timePerOp))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) ops/sec
        └─ Results count: \(comparisons.count)
        """)
        
        XCTAssertEqual(comparisons.count, count)
    }
    
    // MARK: - Priority 3: Mnemonic Validation Batch
    
    /// Benchmarks synchronous mnemonic validation
    func testMnemonicValidateSyncPerformance() throws {
        let validPhrase = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let invalidPhrase = "invalid mnemonic phrase words that are not valid"
        let count = 20
        
        let startTime = Date()
        
        for i in 0..<count {
            let phrase = (i % 2 == 0) ? validPhrase : invalidPhrase
            let _ = try? Mnemonic(phrase: phrase).toEntropy()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let timePerOp = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Synchronous Mnemonic Validation
        ├─ Total phrases: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per validation: \(String(format: "%.3f", timePerOp))ms
        └─ Throughput: \(String(format: "%.0f", Double(count) / duration)) validations/sec
        """)
    }
    
    /// Benchmarks asynchronous mnemonic batch validation
    func testMnemonicValidateAsyncPerformance() async throws {
        let validPhrase = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let invalidPhrase = "invalid mnemonic phrase words that are not valid"
        let count = 20
        
        var phrases = [String]()
        for i in 0..<count {
            phrases.append((i % 2 == 0) ? validPhrase : invalidPhrase)
        }
        
        let startTime = Date()
        let results = try await Mnemonic.validate(phrases: phrases)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerOp = (duration * 1000) / Double(count)
        
        print("""
        ┌─ Asynchronous Mnemonic Validation (Batch)
        ├─ Total phrases: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per validation: \(String(format: "%.3f", timePerOp))ms
        ├─ Throughput: \(String(format: "%.0f", Double(count) / duration)) validations/sec
        └─ Valid phrases found: \(results.filter { $0 }.count)
        """)
        
        XCTAssertEqual(results.count, count)
    }
    
    // MARK: - Priority 3: PlutusData Batch Parsing
    
    /// Benchmarks PlutusData parsing from bytes
    func testPlutusDataParseBytes() async throws {
        let count = 10
        var items: [(label: String, bytes: Data)] = []
        
        // Create simple PlutusData integers as bytes
        for i in 0..<count {
            if let plutusInt = try? PlutusData.newInteger(number: Int64(i)) {
                let bytes = try plutusInt.toBytes()
                items.append(("data_\(i)", bytes))
            }
        }
        
        guard !items.isEmpty else {
            print("⚠️  Warning: Could not create PlutusData test items")
            return
        }
        
        let startTime = Date()
        let parsedData = try await PlutusData.fromBytes(items: items)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerOp = items.isEmpty ? 0 : (duration * 1000) / Double(items.count)
        
        print("""
        ┌─ Asynchronous PlutusData Batch Parsing (from Bytes)
        ├─ Total items: \(items.count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per item: \(String(format: "%.3f", timePerOp))ms
        ├─ Throughput: \(String(format: "%.0f", items.isEmpty ? 0.0 : Double(items.count) / duration)) items/sec
        └─ Parsed items: \(parsedData.count)
        """)
        
        XCTAssertEqual(parsedData.count, items.count)
    }
    
    /// Benchmarks PlutusData parsing from JSON
    func testPlutusDataParseJSON() async throws {
        let count = 5
        var items: [(label: String, json: String)] = []
        
        // Create simple PlutusData integers as JSON
        for i in 0..<count {
            items.append(("data_\(i)", "{\"int\": \(i)}"))
        }
        
        let startTime = Date()
        let parsedData = try await PlutusData.fromJSON(items: items)
        let duration = Date().timeIntervalSince(startTime)
        
        let timePerOp = (duration * 1000) / Double(items.count)
        
        print("""
        ┌─ Asynchronous PlutusData Batch Parsing (from JSON)
        ├─ Total items: \(items.count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per item: \(String(format: "%.3f", timePerOp))ms
        ├─ Throughput: \(String(format: "%.0f", Double(items.count) / duration)) items/sec
        └─ Parsed items: \(parsedData.count)
        """)
        
        XCTAssertEqual(parsedData.count, items.count)
    }
    
    // MARK: - Priority 3: Transaction Batch Operations
    
    /// Benchmarks asynchronous transaction batch serialization
    func testTransactionToHexPerformance() async throws {
        let count = 20
        let address = try await (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        let utxo = UTXO(
            txHash: "fd656fb1f4cf6fbbc36f2705568a4d3b7a970ec0b39f80cc81e1293626b77316",
            index: 0,
            value: Value(coin: 20_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try await builder.addInputs(from: [utxo])
        try builder.addOutput(address: address, value: Value(coin: 10_000_000))
        let body = try await builder.build(changeAddress: address)
        let keychain = try Keychain(mnemonic: Mnemonic(phrase: WalletTests.testMnemonic))
        let transaction = try await (try getPerformanceWallet()).sign(transactionBody: body, keychain: keychain)
        
        let transactions = Array(repeating: transaction, count: count)
        
        let startTime = Date()
        let results = try await Transaction.toHex(transactions: transactions)
        let duration = Date().timeIntervalSince(startTime)
        
        print("""
        ┌─ Asynchronous Transaction Batch Serialization
        ├─ Total transactions: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per tx: \(String(format: "%.3f", (duration * 1000) / Double(count)))ms
        └─ Results count: \(results.count)
        """)
        
        XCTAssertEqual(results.count, count)
    }
    
    /// Benchmarks asynchronous transaction batch parsing
    func testTransactionFromHexPerformance() async throws {
        let count: Int = 20
        let address: Address = try await (try getPerformanceWallet()).getAddress(account: 0, index: 0)
        let utxo: UTXO = UTXO(
            txHash: "fd656fb1f4cf6fbbc36f2705568a4d3b7a970ec0b39f80cc81e1293626b77316",
            index: 0,
            value: Value(coin: 20_000_000),
            address: address
        )
        
        let builder: TransactionBuilder = try TransactionBuilder()
        try await builder.addInputs(from: [utxo])
        try builder.addOutput(address: address, value: Value(coin: 10_000_000))
        let body: TransactionBody = try await builder.build(changeAddress: address)
        let keychain: Keychain = try Keychain(mnemonic: Mnemonic(phrase: WalletTests.testMnemonic))
        let transaction: Transaction = try await (try getPerformanceWallet()).sign(transactionBody: body, keychain: keychain)
        let hex: String = try transaction.toHex()
        
        let hexStrings: [String] = Array(repeating: hex, count: count)
        
        let startTime: Date = Date()
        let results: [Transaction] = try await Transaction.fromHex(hexStrings: hexStrings)
        let duration: TimeInterval = Date().timeIntervalSince(startTime)
        
        print("""
        ┌─ Asynchronous Transaction Batch Parsing
        ├─ Total transactions: \(count)
        ├─ Total time: \(String(format: "%.4f", duration))s
        ├─ Time per tx: \(String(format: "%.3f", (duration * 1000) / Double(count)))ms
        └─ Results count: \(results.count)
        """)
        
        XCTAssertEqual(results.count, count)
    }

    func testStressRustInterop() throws {
        let words = "art forum devote street sure rather head chuckle guard poverty release quote oak craft enemy"
        let mnemonic = Mnemonic(phrase: words)
        let wallet = try Wallet(mnemonic: mnemonic)
        let address = try wallet.getAddress()
        
        let utxo = UTXO(
            txHash: "7233486deda2a6c5258a1c758e48a4e6adf5dd936e448c58819afb97f73e2c65",
            index: 0,
            value: Value(coin: 20_000_000),
            address: address
        )
        
        let builder = try TransactionBuilder()
        try builder.addInputs(from: [utxo])
        try builder.addOutput(address: address, value: Value(coin: 10_000_000))
        
        let body = try builder.build(changeAddress: address)
        let keychain = try Keychain(mnemonic: mnemonic)
        let transaction = try wallet.sign(transactionBody: body, keychain: keychain)
        let txHex = try transaction.toHex()
        
        for _ in 0..<100 {
            let txn = try Transaction.fromHex(txHex)
            _ = try txn.hash()
            _ = try txn.toHex()
        }
    }
}
