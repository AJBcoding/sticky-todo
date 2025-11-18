//
//  AnimationHelpers.swift
//  StickyToDo-AppKit
//
//  Production-quality CATransaction-based animations for AppKit
//

import Cocoa
import QuartzCore

/// Collection of animation helpers for AppKit views using Core Animation
enum AnimationHelpers {

    // MARK: - Animation Durations

    enum Duration {
        static let instant: TimeInterval = 0.0
        static let quick: TimeInterval = 0.15
        static let standard: TimeInterval = 0.25
        static let gentle: TimeInterval = 0.35
        static let slow: TimeInterval = 0.5
    }

    // MARK: - Timing Functions

    enum TimingFunction {
        static let easeIn = CAMediaTimingFunction(name: .easeIn)
        static let easeOut = CAMediaTimingFunction(name: .easeOut)
        static let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
        static let linear = CAMediaTimingFunction(name: .linear)

        // Custom timing functions
        static let smooth = CAMediaTimingFunction(controlPoints: 0.42, 0, 0.58, 1)
        static let spring = CAMediaTimingFunction(controlPoints: 0.5, 1.5, 0.5, 1)
        static let materialStandard = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1)
    }

    // MARK: - Basic Animation Helpers

    /// Execute animation block with CATransaction
    static func animate(
        duration: TimeInterval = Duration.standard,
        timingFunction: CAMediaTimingFunction = TimingFunction.easeInOut,
        animations: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(timingFunction)

        if let completion = completion {
            CATransaction.setCompletionBlock(completion)
        }

        animations()
        CATransaction.commit()
    }

    /// Execute animation without implicit animations
    static func performWithoutAnimation(_ block: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
        CATransaction.commit()
    }

    /// Execute spring animation
    static func springAnimate(
        duration: TimeInterval = Duration.standard,
        damping: CGFloat = 0.7,
        velocity: CGFloat = 0.5,
        animations: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(TimingFunction.spring)

        if let completion = completion {
            CATransaction.setCompletionBlock(completion)
        }

        animations()
        CATransaction.commit()
    }
}

// MARK: - Task Completion Animations

extension AnimationHelpers {

    /// Animate task completion with fade and scale
    static func animateTaskCompletion(
        view: NSView,
        completed: Bool,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.standard,
            timingFunction: TimingFunction.easeOut,
            animations: {
                if completed {
                    view.alphaValue = 0.6
                } else {
                    view.alphaValue = 1.0
                }
            },
            completion: completion
        )
    }

    /// Animate strike-through effect
    static func animateStrikeThrough(
        layer: CALayer,
        from startPoint: CGPoint,
        to endPoint: CGPoint
    ) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = Duration.standard
        animation.timingFunction = TimingFunction.easeOut

        layer.add(animation, forKey: "strikethrough")
    }

    /// Animate checkbox toggle
    static func animateCheckbox(
        view: NSView,
        checked: Bool,
        completion: (() -> Void)? = nil
    ) {
        springAnimate(
            duration: 0.3,
            damping: 0.65,
            animations: {
                view.layer?.transform = CATransform3DMakeScale(1.1, 1.1, 1.0)
            },
            completion: {
                animate(
                    duration: 0.15,
                    animations: {
                        view.layer?.transform = CATransform3DIdentity
                    },
                    completion: completion
                )
            }
        )
    }
}

// MARK: - Inspector Panel Animations

extension AnimationHelpers {

    /// Slide inspector panel in from right
    static func slideInspectorIn(
        view: NSView,
        width: CGFloat,
        completion: (() -> Void)? = nil
    ) {
        // Start off-screen
        performWithoutAnimation {
            view.frame.origin.x = view.superview?.bounds.width ?? 0
        }

        // Animate in
        springAnimate(
            duration: 0.35,
            damping: 0.75,
            animations: {
                view.animator().frame.origin.x = (view.superview?.bounds.width ?? 0) - width
            },
            completion: completion
        )
    }

    /// Slide inspector panel out to right
    static func slideInspectorOut(
        view: NSView,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.standard,
            timingFunction: TimingFunction.easeIn,
            animations: {
                view.animator().frame.origin.x = view.superview?.bounds.width ?? 0
            },
            completion: completion
        )
    }

    /// Fade inspector content
    static func fadeInspectorContent(
        view: NSView,
        visible: Bool,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.quick,
            animations: {
                view.animator().alphaValue = visible ? 1.0 : 0.0
            },
            completion: completion
        )
    }
}

// MARK: - Table View Animations

extension AnimationHelpers {

    /// Animate row insertion
    static func animateRowInsertion(
        tableView: NSTableView,
        row: Int,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        tableView.insertRows(at: IndexSet(integer: row), withAnimation: .slideDown)

        CATransaction.commit()
    }

    /// Animate row deletion
    static func animateRowDeletion(
        tableView: NSTableView,
        row: Int,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideUp)

        CATransaction.commit()
    }

    /// Animate row reordering
    static func animateRowMove(
        tableView: NSTableView,
        from sourceRow: Int,
        to targetRow: Int,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Duration.standard)
        CATransaction.setCompletionBlock(completion)

        tableView.moveRow(at: sourceRow, to: targetRow)

        CATransaction.commit()
    }

    /// Highlight row temporarily
    static func highlightRow(view: NSView, duration: TimeInterval = 0.6) {
        let originalBackgroundColor = view.layer?.backgroundColor

        animate(
            duration: duration / 2,
            animations: {
                view.layer?.backgroundColor = NSColor.selectedContentBackgroundColor.cgColor
            },
            completion: {
                animate(
                    duration: duration / 2,
                    animations: {
                        view.layer?.backgroundColor = originalBackgroundColor
                    }
                )
            }
        )
    }
}

// MARK: - Board Canvas Animations

extension AnimationHelpers {

    /// Animate smooth zoom
    static func animateBoardZoom(
        scrollView: NSScrollView,
        scale: CGFloat,
        centerPoint: CGPoint,
        completion: (() -> Void)? = nil
    ) {
        guard let clipView = scrollView.contentView as? NSClipView else { return }

        animate(
            duration: Duration.standard,
            timingFunction: TimingFunction.easeInOut,
            animations: {
                clipView.animator().magnification = scale
            },
            completion: completion
        )
    }

    /// Animate board card movement
    static func animateBoardCardMove(
        view: NSView,
        to point: CGPoint,
        completion: (() -> Void)? = nil
    ) {
        springAnimate(
            duration: 0.35,
            damping: 0.75,
            animations: {
                view.animator().frame.origin = point
            },
            completion: completion
        )
    }

    /// Animate board card scaling
    static func animateBoardCardScale(
        view: NSView,
        scale: CGFloat,
        completion: (() -> Void)? = nil
    ) {
        springAnimate(
            duration: 0.3,
            animations: {
                view.layer?.transform = CATransform3DMakeScale(scale, scale, 1.0)
            },
            completion: completion
        )
    }

    /// Smooth pan animation
    static func animateBoardPan(
        scrollView: NSScrollView,
        to point: CGPoint,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.quick,
            timingFunction: TimingFunction.easeOut,
            animations: {
                scrollView.contentView.animator().setBoundsOrigin(point)
            },
            completion: completion
        )
    }
}

// MARK: - Quick Capture Window Animations

extension AnimationHelpers {

    /// Animate quick capture window appearance with spring
    static func animateQuickCaptureAppear(
        window: NSWindow,
        completion: (() -> Void)? = nil
    ) {
        // Start slightly smaller and transparent
        window.alphaValue = 0.0
        let originalFrame = window.frame
        let startFrame = NSRect(
            x: originalFrame.midX - originalFrame.width * 0.45,
            y: originalFrame.midY - originalFrame.height * 0.45,
            width: originalFrame.width * 0.9,
            height: originalFrame.height * 0.9
        )
        window.setFrame(startFrame, display: true)

        // Animate to full size with spring
        springAnimate(
            duration: 0.4,
            damping: 0.7,
            animations: {
                window.animator().setFrame(originalFrame, display: true)
                window.animator().alphaValue = 1.0
            },
            completion: completion
        )
    }

    /// Animate quick capture window dismissal
    static func animateQuickCaptureDismiss(
        window: NSWindow,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.quick,
            timingFunction: TimingFunction.easeIn,
            animations: {
                window.animator().alphaValue = 0.0
            },
            completion: {
                window.orderOut(nil)
                completion?()
            }
        )
    }

    /// Animate field focus
    static func animateFieldFocus(
        field: NSTextField,
        focused: Bool
    ) {
        animate(
            duration: Duration.quick,
            animations: {
                if focused {
                    field.layer?.borderWidth = 2.0
                    field.layer?.borderColor = NSColor.controlAccentColor.cgColor
                } else {
                    field.layer?.borderWidth = 1.0
                    field.layer?.borderColor = NSColor.separatorColor.cgColor
                }
            }
        )
    }
}

// MARK: - Toolbar & UI Element Animations

extension AnimationHelpers {

    /// Animate toolbar item state change
    static func animateToolbarItem(
        button: NSButton,
        selected: Bool,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.quick,
            animations: {
                button.animator().contentTintColor = selected ?
                    NSColor.controlAccentColor : NSColor.labelColor
            },
            completion: completion
        )
    }

    /// Pulse animation for attention
    static func pulseView(
        view: NSView,
        repeatCount: Int = 2
    ) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.05
        animation.duration = 0.3
        animation.autoreverses = true
        animation.repeatCount = Float(repeatCount)

        view.layer?.add(animation, forKey: "pulse")
    }

    /// Shake animation for errors
    static func shakeView(view: NSView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -10, 10, -5, 5, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1.0]
        animation.duration = 0.4
        animation.timingFunction = TimingFunction.linear

        view.layer?.add(animation, forKey: "shake")
    }
}

// MARK: - Badge & Counter Animations

extension AnimationHelpers {

    /// Animate badge count update
    static func animateBadgeUpdate(
        view: NSView,
        completion: (() -> Void)? = nil
    ) {
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 1.0
        scaleUp.toValue = 1.2
        scaleUp.duration = 0.15

        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1.2
        scaleDown.toValue = 1.0
        scaleDown.duration = 0.15
        scaleDown.beginTime = 0.15

        let group = CAAnimationGroup()
        group.animations = [scaleUp, scaleDown]
        group.duration = 0.3

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        view.layer?.add(group, forKey: "badgeUpdate")
        CATransaction.commit()
    }

    /// Animate badge appearance
    static func animateBadgeAppear(
        view: NSView,
        completion: (() -> Void)? = nil
    ) {
        view.alphaValue = 0.0
        view.layer?.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)

        springAnimate(
            duration: 0.35,
            damping: 0.65,
            animations: {
                view.animator().alphaValue = 1.0
                view.layer?.transform = CATransform3DIdentity
            },
            completion: completion
        )
    }

    /// Animate badge disappearance
    static func animateBadgeDisappear(
        view: NSView,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: Duration.quick,
            animations: {
                view.animator().alphaValue = 0.0
                view.layer?.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
            },
            completion: completion
        )
    }
}

// MARK: - Fade Utilities

extension AnimationHelpers {

    /// Fade in view
    static func fadeIn(
        view: NSView,
        duration: TimeInterval = Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: duration,
            timingFunction: TimingFunction.easeIn,
            animations: {
                view.animator().alphaValue = 1.0
            },
            completion: completion
        )
    }

    /// Fade out view
    static func fadeOut(
        view: NSView,
        duration: TimeInterval = Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        animate(
            duration: duration,
            timingFunction: TimingFunction.easeOut,
            animations: {
                view.animator().alphaValue = 0.0
            },
            completion: completion
        )
    }

    /// Cross-fade between two views
    static func crossFade(
        from oldView: NSView,
        to newView: NSView,
        duration: TimeInterval = Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        newView.alphaValue = 0.0

        animate(
            duration: duration,
            animations: {
                oldView.animator().alphaValue = 0.0
                newView.animator().alphaValue = 1.0
            },
            completion: completion
        )
    }
}

// MARK: - NSView Animation Extensions

extension NSView {

    /// Animate frame change
    func animateFrame(
        to newFrame: NSRect,
        duration: TimeInterval = AnimationHelpers.Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        AnimationHelpers.animate(
            duration: duration,
            animations: {
                self.animator().frame = newFrame
            },
            completion: completion
        )
    }

    /// Animate alpha change
    func animateAlpha(
        to newAlpha: CGFloat,
        duration: TimeInterval = AnimationHelpers.Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        AnimationHelpers.animate(
            duration: duration,
            animations: {
                self.animator().alphaValue = newAlpha
            },
            completion: completion
        )
    }

    /// Animate background color change
    func animateBackgroundColor(
        to color: NSColor,
        duration: TimeInterval = AnimationHelpers.Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        AnimationHelpers.animate(
            duration: duration,
            animations: {
                self.layer?.backgroundColor = color.cgColor
            },
            completion: completion
        )
    }
}

// MARK: - NSWindow Animation Extensions

extension NSWindow {

    /// Animate window frame
    func animateFrame(
        to newFrame: NSRect,
        duration: TimeInterval = AnimationHelpers.Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        AnimationHelpers.animate(
            duration: duration,
            animations: {
                self.animator().setFrame(newFrame, display: true)
            },
            completion: completion
        )
    }

    /// Animate window alpha
    func animateAlpha(
        to newAlpha: CGFloat,
        duration: TimeInterval = AnimationHelpers.Duration.standard,
        completion: (() -> Void)? = nil
    ) {
        AnimationHelpers.animate(
            duration: duration,
            animations: {
                self.animator().alphaValue = newAlpha
            },
            completion: completion
        )
    }
}
