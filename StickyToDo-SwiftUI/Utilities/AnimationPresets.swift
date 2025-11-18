//
//  AnimationPresets.swift
//  StickyToDo-SwiftUI
//
//  Production-quality animation presets for SwiftUI
//

import SwiftUI

/// Collection of reusable animation presets for consistent UI behavior
enum AnimationPresets {

    // MARK: - Basic Animations

    /// Smooth default animation for general UI updates
    static let smooth = Animation.easeInOut(duration: 0.25)

    /// Quick animation for immediate feedback
    static let quick = Animation.easeInOut(duration: 0.15)

    /// Gentle animation for subtle changes
    static let gentle = Animation.easeInOut(duration: 0.35)

    /// Snappy spring animation for interactive elements
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Bouncy spring animation for playful interactions
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    // MARK: - Task Animations

    /// Animation for task completion (checkbox toggle)
    static let taskCompletion = Animation.spring(response: 0.35, dampingFraction: 0.65)

    /// Animation for strike-through text effect
    static let strikeThrough = Animation.easeOut(duration: 0.3)

    /// Animation for task insertion into list
    static let taskInsert = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// Animation for task deletion from list
    static let taskDelete = Animation.easeOut(duration: 0.25)

    /// Animation for task reordering
    static let taskReorder = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Animation for task drag and drop
    static let taskDrag = Animation.spring(response: 0.25, dampingFraction: 0.7)

    // MARK: - Board View Animations

    /// Animation for transitioning between board views
    static let boardTransition = Animation.easeInOut(duration: 0.3)

    /// Animation for board card movement
    static let boardCardMove = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Animation for board zoom in/out
    static let boardZoom = Animation.easeInOut(duration: 0.25)

    /// Animation for board pan/scroll
    static let boardPan = Animation.interactiveSpring(response: 0.15, dampingFraction: 1.0)

    /// Animation for board column changes
    static let boardColumnChange = Animation.spring(response: 0.4, dampingFraction: 0.7)

    // MARK: - View Transitions

    /// Animation for list to board view transition
    static let viewModeTransition = Animation.easeInOut(duration: 0.35)

    /// Fade in animation
    static let fadeIn = Animation.easeIn(duration: 0.2)

    /// Fade out animation
    static let fadeOut = Animation.easeOut(duration: 0.2)

    /// Slide in from right
    static let slideInRight = Animation.easeOut(duration: 0.3)

    /// Slide out to right
    static let slideOutRight = Animation.easeIn(duration: 0.3)

    // MARK: - Inspector Panel Animations

    /// Animation for inspector panel show
    static let inspectorShow = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Animation for inspector panel hide
    static let inspectorHide = Animation.easeIn(duration: 0.25)

    /// Animation for inspector field updates
    static let inspectorFieldUpdate = Animation.easeInOut(duration: 0.2)

    // MARK: - Quick Capture Animations

    /// Animation for quick capture window appearance
    static let quickCaptureAppear = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Animation for quick capture window dismissal
    static let quickCaptureDismiss = Animation.easeIn(duration: 0.2)

    /// Animation for quick capture field focus
    static let quickCaptureFocus = Animation.easeOut(duration: 0.15)

    // MARK: - Badge and Counter Animations

    /// Animation for badge count updates
    static let badgeUpdate = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Animation for badge appearance
    static let badgeAppear = Animation.spring(response: 0.35, dampingFraction: 0.65)

    /// Animation for badge disappearance
    static let badgeDisappear = Animation.easeOut(duration: 0.2)

    // MARK: - List Animations

    /// Animation for list item insertions
    static let listInsert = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Animation for list item deletions
    static let listDelete = Animation.easeOut(duration: 0.25)

    /// Animation for list item reordering
    static let listReorder = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Animation for list expansion/collapse
    static let listExpand = Animation.spring(response: 0.35, dampingFraction: 0.75)

    // MARK: - Feedback Animations

    /// Pulse animation for attention
    static let pulse = Animation.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)

    /// Shake animation for errors
    static let shake = Animation.spring(response: 0.2, dampingFraction: 0.3).repeatCount(3, autoreverses: true)

    /// Success animation
    static let success = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Animation Modifiers

extension View {
    /// Apply smooth animation to view changes
    func animateSmooth<V: Equatable>(_ value: V) -> some View {
        animation(AnimationPresets.smooth, value: value)
    }

    /// Apply quick animation to view changes
    func animateQuick<V: Equatable>(_ value: V) -> some View {
        animation(AnimationPresets.quick, value: value)
    }

    /// Apply gentle animation to view changes
    func animateGentle<V: Equatable>(_ value: V) -> some View {
        animation(AnimationPresets.gentle, value: value)
    }

    /// Apply spring animation to view changes
    func animateSpring<V: Equatable>(_ value: V) -> some View {
        animation(AnimationPresets.snappy, value: value)
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Slide and fade transition for inspector panel
    static var inspectorSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// Slide and fade transition from bottom
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Scale and fade transition for boards
    static var boardScale: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    /// Quick capture window transition
    static var quickCapture: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// List item insertion transition
    static var listItem: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    }
}

// MARK: - Animation Timing Curves

extension Animation {
    /// Custom ease-in-out timing for smooth motion
    static let customEaseInOut = Animation.timingCurve(0.42, 0, 0.58, 1, duration: 0.3)

    /// Custom spring with precise control
    static func customSpring(stiffness: Double = 200, damping: Double = 20) -> Animation {
        .interpolatingSpring(stiffness: stiffness, damping: damping)
    }

    /// Material Design standard easing
    static let materialStandard = Animation.timingCurve(0.4, 0.0, 0.2, 1, duration: 0.3)

    /// Material Design deceleration easing
    static let materialDecelerate = Animation.timingCurve(0.0, 0.0, 0.2, 1, duration: 0.3)

    /// Material Design acceleration easing
    static let materialAccelerate = Animation.timingCurve(0.4, 0.0, 1, 1, duration: 0.3)
}

// MARK: - Animation Helpers

struct AnimationHelper {
    /// Execute animation with completion handler
    static func animate(
        _ animation: Animation = AnimationPresets.smooth,
        _ action: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        withAnimation(animation) {
            action()
        }

        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion()
            }
        }
    }

    /// Execute sequential animations
    static func animateSequence(
        animations: [(delay: Double, animation: Animation, action: () -> Void)]
    ) {
        for (index, item) in animations.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + item.delay) {
                withAnimation(item.animation) {
                    item.action()
                }
            }
        }
    }

    /// Create staggered list animations
    static func staggeredAnimation(
        count: Int,
        baseDelay: Double = 0.05,
        animation: Animation = AnimationPresets.listInsert
    ) -> [(delay: Double, animation: Animation)] {
        (0..<count).map { index in
            (delay: Double(index) * baseDelay, animation: animation)
        }
    }
}

// MARK: - Haptic Feedback Integration

#if os(macOS)
import AppKit

struct HapticFeedback {
    /// Provide haptic feedback for task completion
    static func taskCompleted() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }

    /// Provide haptic feedback for errors
    static func error() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
    }

    /// Provide haptic feedback for success
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .levelChange,
            performanceTime: .default
        )
    }
}
#endif
