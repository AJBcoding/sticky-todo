//
//  ContentView.swift
//  StickyToDo
//
//  Created on 2025-11-17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar - will contain list/board navigation
            List {
                Section("Lists") {
                    NavigationLink("Inbox") {
                        Text("Inbox View")
                    }
                    NavigationLink("Next Actions") {
                        Text("Next Actions View")
                    }
                }

                Section("Boards") {
                    NavigationLink("Brainstorm") {
                        Text("Brainstorm Board")
                    }
                }
            }
            .navigationTitle("StickyToDo")
            .frame(minWidth: 200)
        } detail: {
            // Main content area
            VStack {
                Image(systemName: "checkmark.circle")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                Text("Welcome to StickyToDo")
                    .font(.title)
                    .padding()
                Text("Select a list or board from the sidebar to get started")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
