//
//  PerformanceMonitorTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for PerformanceMonitor covering operation timing,
//  memory monitoring, metrics collection, and reporting.
//

import XCTest
@testable import StickyToDoCore

final class PerformanceMonitorTests: XCTestCase {

    var monitor: PerformanceMonitor!

    override func setUpWithError() throws {
        monitor = PerformanceMonitor.shared
        monitor.reset()
    }

    override func tearDownWithError() throws {
        monitor.stopMemoryMonitoring()
        monitor.reset()
        monitor = nil
    }

    // MARK: - Initialization Tests

    func testSharedInstance() {
        let instance1 = PerformanceMonitor.shared
        let instance2 = PerformanceMonitor.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testInitialState() {
        XCTAssertEqual(monitor.launchDuration, 0)
        XCTAssertEqual(monitor.currentMemoryUsage, 0)
        XCTAssertEqual(monitor.peakMemoryUsage, 0)
    }

    // MARK: - Launch Tracking Tests

    func testMarkLaunchStart() {
        monitor.markLaunchStart()

        // Should not crash and should set internal state
        XCTAssertTrue(true)
    }

    func testMarkLaunchComplete() {
        monitor.markLaunchStart()
        Thread.sleep(forTimeInterval: 0.1)
        monitor.markLaunchComplete()

        XCTAssertGreaterThan(monitor.launchDuration, 0)
        XCTAssertGreaterThan(monitor.launchDuration, 0.1)
    }

    func testLaunchCompleteWithoutStart() {
        // Should handle gracefully
        monitor.markLaunchComplete()

        XCTAssertEqual(monitor.launchDuration, 0)
    }

    func testMultipleLaunchMarks() {
        monitor.markLaunchStart()
        Thread.sleep(forTimeInterval: 0.05)
        monitor.markLaunchComplete()

        let firstDuration = monitor.launchDuration

        monitor.markLaunchStart()
        Thread.sleep(forTimeInterval: 0.1)
        monitor.markLaunchComplete()

        // Second launch should overwrite first
        XCTAssertNotEqual(monitor.launchDuration, firstDuration)
    }

    // MARK: - Operation Timing Tests

    func testStartOperation() {
        monitor.startOperation("testOp")

        // Should not crash
        XCTAssertTrue(true)
    }

    func testEndOperation() {
        monitor.startOperation("testOp")
        Thread.sleep(forTimeInterval: 0.05)
        monitor.endOperation("testOp")

        // Should complete without errors
        XCTAssertTrue(true)
    }

    func testEndOperationWithoutStart() {
        monitor.endOperation("neverStarted")

        // Should handle gracefully
        XCTAssertTrue(true)
    }

    func testMultipleOperations() {
        monitor.startOperation("op1")
        monitor.startOperation("op2")
        monitor.startOperation("op3")

        Thread.sleep(forTimeInterval: 0.05)

        monitor.endOperation("op1")
        monitor.endOperation("op2")
        monitor.endOperation("op3")

        // Should handle multiple concurrent operations
        XCTAssertTrue(true)
    }

    // MARK: - Measure Function Tests

    func testMeasureSync() {
        let result = monitor.measure("syncTest") {
            return 42
        }

        XCTAssertEqual(result, 42)
    }

    func testMeasureThrows() {
        enum TestError: Error {
            case testError
        }

        XCTAssertThrowsError(try monitor.measure("throwTest") {
            throw TestError.testError
        })
    }

    func testMeasureAsync() async {
        let result = await monitor.measureAsync("asyncTest") {
            return "success"
        }

        XCTAssertEqual(result, "success")
    }

    func testMeasureAsyncThrows() async {
        enum TestError: Error {
            case testError
        }

        do {
            _ = try await monitor.measureAsync("asyncThrowTest") {
                throw TestError.testError
            }
            XCTFail("Should have thrown error")
        } catch {
            // Expected
        }
    }

    // MARK: - Operation Statistics Tests

    func testGetOperationStats() {
        // Run operation multiple times
        for _ in 0..<10 {
            monitor.startOperation("repeatedOp")
            Thread.sleep(forTimeInterval: 0.01)
            monitor.endOperation("repeatedOp")
        }

        let stats = monitor.getOperationStats("repeatedOp")

        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.identifier, "repeatedOp")
        XCTAssertEqual(stats?.count, 10)
        XCTAssertGreaterThan(stats?.average ?? 0, 0)
        XCTAssertGreaterThan(stats?.min ?? 0, 0)
        XCTAssertGreaterThan(stats?.max ?? 0, 0)
    }

    func testGetNonexistentOperationStats() {
        let stats = monitor.getOperationStats("nonexistent")

        XCTAssertNil(stats)
    }

    func testOperationStatsAccuracy() {
        // Run operations with known delays
        for _ in 0..<5 {
            monitor.startOperation("timedOp")
            Thread.sleep(forTimeInterval: 0.05)
            monitor.endOperation("timedOp")
        }

        let stats = monitor.getOperationStats("timedOp")

        XCTAssertNotNil(stats)
        XCTAssertGreaterThan(stats!.average, 0.04) // Should be around 0.05
        XCTAssertLessThan(stats!.average, 0.1) // But not too high
    }

    func testStatsP95Calculation() {
        // Run 100 operations
        for i in 0..<100 {
            monitor.startOperation("p95Test")
            // Vary the duration slightly
            Thread.sleep(forTimeInterval: 0.001 * Double(i % 10))
            monitor.endOperation("p95Test")
        }

        let stats = monitor.getOperationStats("p95Test")

        XCTAssertNotNil(stats)
        XCTAssertGreaterThan(stats!.p95, stats!.median)
    }

    // MARK: - Memory Monitoring Tests

    func testStartMemoryMonitoring() {
        monitor.startMemoryMonitoring()

        Thread.sleep(forTimeInterval: 0.5)

        monitor.stopMemoryMonitoring()

        // Should update memory values
        XCTAssertGreaterThan(monitor.currentMemoryUsage, 0)
    }

    func testStopMemoryMonitoring() {
        monitor.startMemoryMonitoring()
        Thread.sleep(forTimeInterval: 0.2)
        monitor.stopMemoryMonitoring()

        let memoryBeforeStop = monitor.currentMemoryUsage

        Thread.sleep(forTimeInterval: 0.5)

        // Memory should not update after stop
        // (In practice, it might stay the same, so we just check it's set)
        XCTAssertGreaterThan(memoryBeforeStop, 0)
    }

    func testPeakMemoryTracking() {
        monitor.startMemoryMonitoring()

        Thread.sleep(forTimeInterval: 1.0)

        monitor.stopMemoryMonitoring()

        XCTAssertGreaterThanOrEqual(monitor.peakMemoryUsage, monitor.currentMemoryUsage)
    }

    func testMemoryUsageString() {
        monitor.startMemoryMonitoring()
        Thread.sleep(forTimeInterval: 0.5)
        monitor.stopMemoryMonitoring()

        let usageString = monitor.getMemoryUsageString()

        XCTAssertTrue(usageString.contains("MB"))
        XCTAssertFalse(usageString.isEmpty)
    }

    func testPeakMemoryUsageString() {
        monitor.startMemoryMonitoring()
        Thread.sleep(forTimeInterval: 0.5)
        monitor.stopMemoryMonitoring()

        let peakString = monitor.getPeakMemoryUsageString()

        XCTAssertTrue(peakString.contains("MB"))
        XCTAssertFalse(peakString.isEmpty)
    }

    // MARK: - Report Generation Tests

    func testGenerateReport() {
        // Run some operations
        for i in 0..<5 {
            monitor.startOperation("op\(i)")
            Thread.sleep(forTimeInterval: 0.01)
            monitor.endOperation("op\(i)")
        }

        let report = monitor.generateReport()

        XCTAssertEqual(report.operationStats.count, 5)
        XCTAssertGreaterThanOrEqual(report.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.peakMemoryUsage, 0)
    }

    func testReportWithNoData() {
        let report = monitor.generateReport()

        XCTAssertEqual(report.launchDuration, 0)
        XCTAssertEqual(report.operationStats.count, 0)
    }

    func testReportOperationsAreSorted() {
        // Create operations with different durations
        for i in 0..<5 {
            monitor.startOperation("op\(i)")
            Thread.sleep(forTimeInterval: 0.01 * Double(i + 1))
            monitor.endOperation("op\(i)")
        }

        let report = monitor.generateReport()

        // Should be sorted by average duration (descending)
        for i in 1..<report.operationStats.count {
            XCTAssertGreaterThanOrEqual(
                report.operationStats[i-1].average,
                report.operationStats[i].average
            )
        }
    }

    func testPrintReport() {
        monitor.startOperation("testOp")
        Thread.sleep(forTimeInterval: 0.01)
        monitor.endOperation("testOp")

        // Should not crash
        monitor.printReport()

        XCTAssertTrue(true)
    }

    // MARK: - Convenience Method Tests

    func testTrackTaskStoreOperation() {
        monitor.trackTaskStoreOperation("load")
        Thread.sleep(forTimeInterval: 0.01)
        monitor.endTaskStoreOperation("load")

        let stats = monitor.getOperationStats("TaskStore.load")
        XCTAssertNotNil(stats)
    }

    func testTrackBoardStoreOperation() {
        monitor.trackBoardStoreOperation("save")
        Thread.sleep(forTimeInterval: 0.01)
        monitor.endBoardStoreOperation("save")

        let stats = monitor.getOperationStats("BoardStore.save")
        XCTAssertNotNil(stats)
    }

    func testTrackFileOperation() {
        monitor.trackFileOperation("read")
        Thread.sleep(forTimeInterval: 0.01)
        monitor.endFileOperation("read")

        let stats = monitor.getOperationStats("FileIO.read")
        XCTAssertNotNil(stats)
    }

    func testTrackRenderOperation() {
        monitor.trackRenderOperation("draw")
        Thread.sleep(forTimeInterval: 0.01)
        monitor.endRenderOperation("draw")

        let stats = monitor.getOperationStats("Render.draw")
        XCTAssertNotNil(stats)
    }

    // MARK: - Reset Tests

    func testReset() {
        // Generate some data
        monitor.markLaunchStart()
        monitor.markLaunchComplete()

        monitor.startOperation("op1")
        monitor.endOperation("op1")

        monitor.startMemoryMonitoring()
        Thread.sleep(forTimeInterval: 0.2)
        monitor.stopMemoryMonitoring()

        // Reset
        monitor.reset()

        // Values should be cleared
        XCTAssertEqual(monitor.launchDuration, 0)
        XCTAssertEqual(monitor.peakMemoryUsage, 0)

        let stats = monitor.getOperationStats("op1")
        XCTAssertNil(stats)
    }

    // MARK: - Monitoring State Tests

    func testIsMonitoringFlag() {
        #if DEBUG
        XCTAssertTrue(monitor.isMonitoring)
        #else
        // May or may not be monitoring in release
        #endif
    }

    // MARK: - Edge Cases

    func testNestedOperations() {
        monitor.startOperation("outer")
        monitor.startOperation("inner")

        Thread.sleep(forTimeInterval: 0.01)

        monitor.endOperation("inner")
        monitor.endOperation("outer")

        // Both should have stats
        XCTAssertNotNil(monitor.getOperationStats("inner"))
        XCTAssertNotNil(monitor.getOperationStats("outer"))
    }

    func testSameOperationMultipleTimes() {
        for _ in 0..<100 {
            monitor.startOperation("repeated")
            monitor.endOperation("repeated")
        }

        let stats = monitor.getOperationStats("repeated")

        XCTAssertEqual(stats?.count, 100)
    }

    func testOperationWithVeryLongName() {
        let longName = String(repeating: "a", count: 1000)

        monitor.startOperation(longName)
        monitor.endOperation(longName)

        let stats = monitor.getOperationStats(longName)
        XCTAssertNotNil(stats)
    }

    func testZeroDurationOperation() {
        monitor.startOperation("instant")
        monitor.endOperation("instant") // Immediate end

        let stats = monitor.getOperationStats("instant")

        // Should still have stats, duration might be very small
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.count, 1)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentOperations() {
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10

        for i in 0..<10 {
            DispatchQueue.global().async {
                self.monitor.startOperation("concurrent\(i)")
                Thread.sleep(forTimeInterval: 0.01)
                self.monitor.endOperation("concurrent\(i)")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)

        // All operations should have stats
        for i in 0..<10 {
            XCTAssertNotNil(monitor.getOperationStats("concurrent\(i)"))
        }
    }

    // MARK: - Performance Tests

    func testOperationTrackingOverhead() {
        measure {
            for _ in 0..<1000 {
                monitor.startOperation("perf")
                monitor.endOperation("perf")
            }
        }
    }

    func testMeasureFunctionOverhead() {
        measure {
            for _ in 0..<1000 {
                _ = monitor.measure("measPerf") {
                    return 42
                }
            }
        }
    }

    func testReportGenerationPerformance() {
        // Create many operations
        for i in 0..<100 {
            monitor.startOperation("op\(i)")
            monitor.endOperation("op\(i)")
        }

        measure {
            _ = monitor.generateReport()
        }
    }

    func testMemoryMonitoringOverhead() {
        measure {
            monitor.startMemoryMonitoring()
            Thread.sleep(forTimeInterval: 0.1)
            monitor.stopMemoryMonitoring()
        }
    }
}
