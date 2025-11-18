//
//  OnboardingFlow.swift
//  StickyToDo-SwiftUI
//
//  Manages the onboarding flow and coordination with app state.
//  Handles first-run detection and sample data generation.
//

import SwiftUI
import Combine

/// Coordinator for the onboarding flow
@MainActor
class OnboardingCoordinator: ObservableObject {

    // MARK: - Published Properties

    @Published var showOnboarding = false
    @Published var isComplete = false

    // MARK: - Properties

    private let configManager: ConfigurationManager
    private let dataManager: DataManager

    // MARK: - Initialization

    init(configManager: ConfigurationManager = .shared,
         dataManager: DataManager = .shared) {
        self.configManager = configManager
        self.dataManager = dataManager
    }

    // MARK: - Methods

    /// Checks if onboarding should be shown
    func checkForFirstRun() {
        showOnboarding = configManager.isFirstRun
    }

    /// Completes the onboarding flow with user configuration
    func completeOnboarding(with config: WelcomeConfiguration) {
        // Update data directory if changed
        if config.dataDirectory != configManager.dataDirectory {
            configManager.changeDataDirectory(to: config.dataDirectory)
        }

        // Create sample data if requested
        if config.createSampleData {
            createSampleData()
        }

        // Mark first run as complete
        configManager.isFirstRun = false
        configManager.save()

        isComplete = true
        showOnboarding = false
    }

    /// Creates sample data for the user to explore
    private func createSampleData() {
        print("Creating sample data...")

        // Sample tasks for Inbox
        let sampleTasks: [(String, Context?, String?)] = [
            ("Review project proposal", .work, "Q1 Planning"),
            ("Buy groceries", .errands, nil),
            ("Call dentist to schedule appointment", .errands, nil),
            ("Read 'Getting Things Done' book", .personal, "Learning"),
            ("Plan weekend trip", .personal, "Travel"),
            ("Update team on progress", .work, "Team Sync"),
            ("Fix leaky faucet", .home, nil),
            ("Meditate for 10 minutes", .personal, nil)
        ]

        for (title, context, project) in sampleTasks {
            let task = Task(title: title)
            task.context = context
            task.project = project
            task.status = .inbox
            dataManager.taskStore.add(task)
        }

        // Sample tasks with due dates
        let todayTask = Task(title: "Complete onboarding tutorial")
        todayTask.dueDate = Date()
        todayTask.status = .active
        todayTask.context = .work
        dataManager.taskStore.add(todayTask)

        let upcomingTask = Task(title: "Prepare presentation for Monday")
        upcomingTask.dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        upcomingTask.status = .active
        upcomingTask.context = .work
        upcomingTask.project = "Q1 Planning"
        dataManager.taskStore.add(upcomingTask)

        // Create sample boards
        createSampleBoards()

        print("Sample data created successfully")
    }

    private func createSampleBoards() {
        // Weekly Planning board
        let weeklyBoard = Board(name: "Weekly Planning")
        weeklyBoard.boardDescription = "Plan and track your weekly goals"

        let mondayNote = StickyNote(content: "Monday\n- Team standup\n- Review emails")
        mondayNote.position = CGPoint(x: 50, y: 50)
        mondayNote.color = .blue

        let tuesdayNote = StickyNote(content: "Tuesday\n- Client meeting\n- Project review")
        tuesdayNote.position = CGPoint(x: 250, y: 50)
        tuesdayNote.color = .green

        let ideasNote = StickyNote(content: "Ideas\n- Improve workflow\n- Automate reports")
        ideasNote.position = CGPoint(x: 450, y: 50)
        ideasNote.color = .yellow

        weeklyBoard.notes = [mondayNote, tuesdayNote, ideasNote]
        dataManager.boardStore.add(weeklyBoard)

        // Project Planning board
        let projectBoard = Board(name: "Q1 Planning")
        projectBoard.boardDescription = "Quarterly planning and objectives"

        let goalsNote = StickyNote(content: "Q1 Goals\n✓ Launch new feature\n✓ Improve performance\n- Expand team")
        goalsNote.position = CGPoint(x: 50, y: 50)
        goalsNote.color = .purple

        let milestonesNote = StickyNote(content: "Milestones\nJan: Planning\nFeb: Development\nMar: Launch")
        milestonesNote.position = CGPoint(x: 50, y: 250)
        milestonesNote.color = .orange

        projectBoard.notes = [goalsNote, milestonesNote]
        dataManager.boardStore.add(projectBoard)

        // Create context boards
        for context in Context.defaults {
            let board = dataManager.boardStore.getOrCreateContextBoard(for: context)

            // Add a welcome note to the work context board
            if context == .work {
                let welcomeNote = StickyNote(content: "Welcome to StickyToDo!\n\nUse this board to organize your work tasks visually.")
                welcomeNote.position = CGPoint(x: 100, y: 100)
                welcomeNote.color = .blue
                board.notes.append(welcomeNote)
                dataManager.boardStore.update(board)
            }
        }
    }
}

// MARK: - Onboarding Container View

/// Container view that manages onboarding presentation
struct OnboardingContainer: View {

    @StateObject private var coordinator: OnboardingCoordinator

    init(configManager: ConfigurationManager = .shared,
         dataManager: DataManager = .shared) {
        _coordinator = StateObject(wrappedValue: OnboardingCoordinator(
            configManager: configManager,
            dataManager: dataManager
        ))
    }

    var body: some View {
        Color.clear
            .sheet(isPresented: $coordinator.showOnboarding) {
                WelcomeView { config in
                    coordinator.completeOnboarding(with: config)
                }
            }
            .onAppear {
                coordinator.checkForFirstRun()
            }
    }
}

// MARK: - View Extension

extension View {
    /// Presents onboarding flow if needed
    func withOnboarding(configManager: ConfigurationManager = .shared,
                       dataManager: DataManager = .shared) -> some View {
        self.overlay(
            OnboardingContainer(configManager: configManager, dataManager: dataManager)
        )
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    Color.gray
        .withOnboarding()
}
