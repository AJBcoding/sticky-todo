//
//  TaskDragDropModifier.swift
//  StickyToDo-SwiftUI
//
//  Drag and drop support for tasks between list and canvas views.
//

import SwiftUI
import UniformTypeIdentifiers

/// Drag and drop type identifier for tasks
extension UTType {
    static let task = UTType(exportedAs: "com.stickytodo.task")
}

/// View modifier for making tasks draggable
struct TaskDraggableModifier: ViewModifier {
    let task: Task

    func body(content: Content) -> some View {
        content
            .onDrag {
                // Create item provider with task data
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(task) {
                    return NSItemProvider(item: data as NSData, typeIdentifier: UTType.task.identifier)
                }
                return NSItemProvider()
            }
    }
}

/// View modifier for making views accept dropped tasks
struct TaskDroppableModifier: ViewModifier {
    let onDrop: (Task, CGPoint) -> Bool

    func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.task], delegate: TaskDropDelegate(onDrop: onDrop))
    }
}

/// Drop delegate for handling task drops
struct TaskDropDelegate: DropDelegate {
    let onDrop: (Task, CGPoint) -> Bool

    func performDrop(info: DropInfo) -> Bool {
        // Extract task from drop info
        guard let itemProvider = info.itemProviders(for: [UTType.task]).first else {
            return false
        }

        itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.task.identifier) { data, error in
            guard let data = data,
                  let task = try? JSONDecoder().decode(Task.self, from: data) else {
                return
            }

            DispatchQueue.main.async {
                _ = onDrop(task, info.location)
            }
        }

        return true
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [UTType.task])
    }
}

// MARK: - View Extensions

extension View {
    /// Makes this view draggable as a task
    func taskDraggable(_ task: Task) -> some View {
        modifier(TaskDraggableModifier(task: task))
    }

    /// Makes this view accept dropped tasks
    func taskDroppable(onDrop: @escaping (Task, CGPoint) -> Bool) -> some View {
        modifier(TaskDroppableModifier(onDrop: onDrop))
    }
}
