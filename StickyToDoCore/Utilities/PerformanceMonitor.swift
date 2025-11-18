//
//  PerformanceMonitor.swift
//  StickyToDoCore
//
//  Created on 2025-11-18.
//  Copyright © 2025 Sticky ToDo. All rights reserved.
//

import Foundation
import Combine

#if canImport(AppKit)
import AppKit
#endif

/// Monitors app performance metrics including launch time, memory usage, and operation timing
public class PerformanceMonitor: ObservableObject {
    public static let shared = PerformanceMonitor()

    // MARK: - Published Properties
    @Published public var isMonitoring: Bool = false
    @Published public var currentMemoryUsage: UInt64 = 0
    @Published public var peakMemoryUsage: UInt64 = 0
    @Published public var launchDuration: TimeInterval = 0

    // MARK: - Private Properties
    private var launchStartTime: Date?
    private var operationTimers: [String: Date] = [:]
    private var operationDurations: [String: [TimeInterval]] = [:]
    private var memoryUpdateTimer: Timer?
    private let queue = DispatchQueue(label: "com.stickytodo.performance", qos: .utility)

    // MARK: - Constants
    private enum Thresholds {
        static let slowOperationWarning: TimeInterval = 0.1 // 100ms
        static let criticalMemoryMB: UInt64 = 500
        static let warningMemoryMB: UInt64 = 250
    }

    // MARK: - Initialization
    private init() {
        #if DEBUG
        isMonitoring = true
        #endif
    }

    // MARK: - Launch Tracking

    /// Mark the start of app launch
    public func markLaunchStart() {
        launchStartTime = Date()
        log("🚀 App launch started")
    }

    /// Mark the completion of app launch
    public func markLaunchComplete() {
        guard let startTime = launchStartTime else { return }
        launchDuration = Date().timeIntervalSince(startTime)

        log("✅ App launch completed in \(String(format: "%.3f", launchDuration))s")

        if launchDuration > 2.0 {
            log("⚠️ Slow launch detected: \(String(format: "%.3f", launchDuration))s", level: .warning)
        }

        launchStartTime = nil
    }

    // MARK: - Operation Timing

    /// Start timing an operation
    public func startOperation(_ identifier: String) {
        guard isMonitoring else { return }
        queue.async { [weak self] in
            self?.operationTimers[identifier] = Date()
        }
    }

    /// End timing an operation and log if slow
    public func endOperation(_ identifier: String) {
        guard isMonitoring else { return }
        queue.async { [weak self] in
            guard let self = self,
                  let startTime = self.operationTimers[identifier] else { return }

            let duration = Date().timeIntervalSince(startTime)
            self.operationTimers.removeValue(forKey: identifier)

            // Store duration
            var durations = self.operationDurations[identifier] ?? []
            durations.append(duration)
            // Keep only last 100 measurements
            if durations.count > 100 {
                durations.removeFirst(durations.count - 100)
            }
            self.operationDurations[identifier] = durations

            // Log if slow
            if duration > Thresholds.slowOperationWarning {
                self.log("⏱️ Slow operation '\(identifier)': \(String(format: "%.3f", duration))s", level: .warning)
            }
        }
    }

    /// Measure the execution time of a closure
    @discardableResult
    public func measure<T>(_ identifier: String, operation: () throws -> T) rethrows -> T {
        startOperation(identifier)
        defer { endOperation(identifier) }
        return try operation()
    }

    /// Measure the execution time of an async closure
    @discardableResult
    public func measureAsync<T>(_ identifier: String, operation: () async throws -> T) async rethrows -> T {
        startOperation(identifier)
        defer { endOperation(identifier) }
        return try await operation()
    }

    /// Get statistics for an operation
    public func getOperationStats(_ identifier: String) -> OperationStats? {
        guard let durations = operationDurations[identifier], !durations.isEmpty else {
            return nil
        }

        let sorted = durations.sorted()
        let count = durations.count
        let average = durations.reduce(0, +) / TimeInterval(count)
        let median = sorted[count / 2]
        let min = sorted.first ?? 0
        let max = sorted.last ?? 0
        let p95Index = Int(Double(count) * 0.95)
        let p95 = sorted[min(p95Index, count - 1)]

        return OperationStats(
            identifier: identifier,
            count: count,
            average: average,
            median: median,
            min: min,
            max: max,
            p95: p95
        )
    }

    // MARK: - Memory Monitoring

    /// Start monitoring memory usage
    public func startMemoryMonitoring() {
        guard isMonitoring else { return }

        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }

    /// Stop monitoring memory usage
    public func stopMemoryMonitoring() {
        memoryUpdateTimer?.invalidate()
        memoryUpdateTimer = nil
    }

    /// Update current memory usage
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentMemoryUsage = usage

            if usage > self.peakMemoryUsage {
                self.peakMemoryUsage = usage
            }

            let usageMB = usage / 1024 / 1024
            if usageMB > Thresholds.criticalMemoryMB {
                self.log("🔴 Critical memory usage: \(usageMB)MB", level: .error)
            } else if usageMB > Thresholds.warningMemoryMB {
                self.log("⚠️ High memory usage: \(usageMB)MB", level: .warning)
            }
        }
    }

    /// Get current memory usage in bytes
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    /// Get formatted memory usage string
    public func getMemoryUsageString() -> String {
        let mb = Double(currentMemoryUsage) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }

    /// Get formatted peak memory usage string
    public func getPeakMemoryUsageString() -> String {
        let mb = Double(peakMemoryUsage) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }

    // MARK: - Reporting

    /// Generate performance report
    public func generateReport() -> PerformanceReport {
        var operationStats: [OperationStats] = []

        for identifier in operationDurations.keys {
            if let stats = getOperationStats(identifier) {
                operationStats.append(stats)
            }
        }

        return PerformanceReport(
            launchDuration: launchDuration,
            currentMemoryUsage: currentMemoryUsage,
            peakMemoryUsage: peakMemoryUsage,
            operationStats: operationStats.sorted { $0.average > $1.average }
        )
    }

    /// Print performance report to console
    public func printReport() {
        let report = generateReport()

        log("📊 Performance Report")
        log("-------------------")
        log("Launch Time: \(String(format: "%.3f", report.launchDuration))s")
        log("Current Memory: \(formatBytes(report.currentMemoryUsage))")
        log("Peak Memory: \(formatBytes(report.peakMemoryUsage))")
        log("")
        log("Operation Statistics:")

        for stats in report.operationStats {
            log("  \(stats.identifier):")
            log("    Calls: \(stats.count)")
            log("    Average: \(String(format: "%.3f", stats.average))s")
            log("    Median: \(String(format: "%.3f", stats.median))s")
            log("    Min: \(String(format: "%.3f", stats.min))s")
            log("    Max: \(String(format: "%.3f", stats.max))s")
            log("    P95: \(String(format: "%.3f", stats.p95))s")
        }
    }

    // MARK: - Utilities

    private func formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1024.0)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    private func log(_ message: String, level: LogLevel = .info) {
        guard isMonitoring else { return }

        let prefix: String
        switch level {
        case .info:
            prefix = "[PERF]"
        case .warning:
            prefix = "[PERF WARNING]"
        case .error:
            prefix = "[PERF ERROR]"
        }

        print("\(prefix) \(message)")
    }

    /// Reset all performance data
    public func reset() {
        queue.async { [weak self] in
            self?.operationTimers.removeAll()
            self?.operationDurations.removeAll()
        }

        DispatchQueue.main.async { [weak self] in
            self?.peakMemoryUsage = 0
            self?.launchDuration = 0
        }
    }
}

// MARK: - Supporting Types

public struct OperationStats {
    public let identifier: String
    public let count: Int
    public let average: TimeInterval
    public let median: TimeInterval
    public let min: TimeInterval
    public let max: TimeInterval
    public let p95: TimeInterval
}

public struct PerformanceReport {
    public let launchDuration: TimeInterval
    public let currentMemoryUsage: UInt64
    public let peakMemoryUsage: UInt64
    public let operationStats: [OperationStats]
}

private enum LogLevel {
    case info
    case warning
    case error
}

// MARK: - Convenience Extensions

public extension PerformanceMonitor {
    /// Track task store operations
    func trackTaskStoreOperation(_ operation: String) {
        startOperation("TaskStore.\(operation)")
    }

    /// End task store operation tracking
    func endTaskStoreOperation(_ operation: String) {
        endOperation("TaskStore.\(operation)")
    }

    /// Track board store operations
    func trackBoardStoreOperation(_ operation: String) {
        startOperation("BoardStore.\(operation)")
    }

    /// End board store operation tracking
    func endBoardStoreOperation(_ operation: String) {
        endOperation("BoardStore.\(operation)")
    }

    /// Track file operations
    func trackFileOperation(_ operation: String) {
        startOperation("FileIO.\(operation)")
    }

    /// End file operation tracking
    func endFileOperation(_ operation: String) {
        endOperation("FileIO.\(operation)")
    }

    /// Track rendering operations
    func trackRenderOperation(_ operation: String) {
        startOperation("Render.\(operation)")
    }

    /// End rendering operation tracking
    func endRenderOperation(_ operation: String) {
        endOperation("Render.\(operation)")
    }
}
