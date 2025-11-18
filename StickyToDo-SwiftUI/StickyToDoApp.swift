//
//  StickyToDoApp.swift
//  StickyToDo
//
//  Created on 2025-11-17.
//

import SwiftUI

@main
struct StickyToDoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Quick Capture") {
                    // TODO: Implement quick capture
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
