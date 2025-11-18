//
//  SampleDataGenerator.swift
//  StickyToDo
//
//  Generates realistic sample data for testing, demos, and first-run experience.
//

import Foundation

/// Generates sample tasks, boards, and positions for testing and demonstration purposes
///
/// This generator creates a comprehensive set of realistic data that demonstrates
/// GTD workflows, different contexts, projects, and board configurations.
struct SampleDataGenerator {

    // MARK: - Main Generation Methods

    /// Generates a complete set of sample tasks with realistic GTD metadata
    /// - Parameter count: Number of tasks to generate (default: 40)
    /// - Returns: Array of sample tasks
    static func generateSampleTasks(count: Int = 40) -> [Task] {
        var tasks: [Task] = []
        let now = Date()

        // MARK: Inbox Items (8 unprocessed tasks)
        // These represent tasks that haven't been categorized yet
        tasks.append(Task(
            type: .task,
            title: "Review quarterly budget report",
            notes: "Finance sent the Q4 numbers - need to review and approve before Friday meeting.",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 12),
            modified: now.addingTimeInterval(-3600 * 12)
        ))

        tasks.append(Task(
            type: .note,
            title: "Ideas for team building event",
            notes: "- Escape room?\n- Bowling tournament\n- Cooking class\n- Outdoor adventure day",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 8),
            modified: now.addingTimeInterval(-3600 * 8)
        ))

        tasks.append(Task(
            type: .task,
            title: "Schedule dentist appointment",
            notes: "Been putting this off. Need cleaning and checkup.",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 24),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        tasks.append(Task(
            type: .task,
            title: "Research cloud backup solutions",
            notes: "Current system is getting expensive. Look into alternatives like Backblaze, iDrive.",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 6),
            modified: now.addingTimeInterval(-3600 * 6)
        ))

        tasks.append(Task(
            type: .note,
            title: "Blog post ideas",
            notes: "- Getting started with GTD\n- Why context matters\n- Digital vs paper planning\n- My morning routine",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        tasks.append(Task(
            type: .task,
            title: "Fix squeaky door in bedroom",
            notes: "WD-40 should do the trick. Check hinges.",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 16),
            modified: now.addingTimeInterval(-3600 * 16)
        ))

        tasks.append(Task(
            type: .task,
            title: "Update emergency contact list",
            notes: "Several numbers are outdated. Update and share with family.",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 4),
            modified: now.addingTimeInterval(-3600 * 4)
        ))

        tasks.append(Task(
            type: .note,
            title: "Gift ideas for mom's birthday",
            notes: "- New gardening tools\n- Cookbook she mentioned\n- Weekend spa getaway\n- Photo album of grandkids",
            status: .inbox,
            created: now.addingTimeInterval(-3600 * 72),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        // MARK: Next Actions - @computer context (6 tasks)
        // Actionable tasks that require a computer
        tasks.append(Task(
            type: .task,
            title: "Update project dependencies to latest versions",
            notes: "Several packages have security updates available. Run npm audit and update.",
            status: .nextAction,
            project: "Website Redesign",
            context: "@computer",
            due: now.addingTimeInterval(3600 * 24 * 3), // 3 days from now
            priority: .high,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        tasks.append(Task(
            type: .task,
            title: "Write unit tests for authentication module",
            notes: "Need to cover:\n- Login flow\n- Password reset\n- Token refresh\n- Permission checks\n\nTarget: 80% coverage",
            status: .nextAction,
            project: "Website Redesign",
            context: "@computer",
            due: now.addingTimeInterval(3600 * 24 * 5), // 5 days from now
            flagged: true,
            priority: .high,
            effort: 120,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        tasks.append(Task(
            type: .task,
            title: "Research Swift concurrency patterns",
            notes: "Want to learn more about async/await and actors for the iOS app. Watch WWDC videos.",
            status: .nextAction,
            project: "Learning Swift",
            context: "@computer",
            priority: .medium,
            effort: 60,
            created: now.addingTimeInterval(-3600 * 120),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Set up CI/CD pipeline for new repository",
            notes: "Configure GitHub Actions:\n- Run tests on PR\n- Deploy to staging on merge to main\n- Production deploy on tagged release",
            status: .nextAction,
            project: "Website Redesign",
            context: "@computer",
            due: now.addingTimeInterval(3600 * 24 * 7), // 1 week from now
            priority: .medium,
            effort: 90,
            created: now.addingTimeInterval(-3600 * 72),
            modified: now.addingTimeInterval(-3600 * 36)
        ))

        tasks.append(Task(
            type: .task,
            title: "Respond to client emails from yesterday",
            notes: "3 emails need responses about project timeline and deliverables.",
            status: .nextAction,
            context: "@computer",
            due: now.addingTimeInterval(3600 * 12), // Today
            flagged: true,
            priority: .high,
            effort: 15,
            created: now.addingTimeInterval(-3600 * 18),
            modified: now.addingTimeInterval(-3600 * 12)
        ))

        tasks.append(Task(
            type: .task,
            title: "Draft Q4 planning presentation",
            notes: "Outline:\n1. Q3 recap\n2. Goals for Q4\n3. Resource allocation\n4. Risk assessment\n5. Success metrics",
            status: .nextAction,
            project: "Q4 Planning",
            context: "@computer",
            due: now.addingTimeInterval(3600 * 24 * 4), // 4 days from now
            priority: .high,
            effort: 120,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        // MARK: Next Actions - @phone context (4 tasks)
        // Tasks that require phone calls
        tasks.append(Task(
            type: .task,
            title: "Call insurance about claim status",
            notes: "Claim #12345 from last month. Ask about processing timeline.",
            status: .nextAction,
            context: "@phone",
            due: now.addingTimeInterval(3600 * 24 * 2), // 2 days from now
            priority: .medium,
            effort: 15,
            created: now.addingTimeInterval(-3600 * 120),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Schedule meeting with design team",
            notes: "Need to discuss new brand guidelines and timeline for implementation.",
            status: .nextAction,
            project: "Website Redesign",
            context: "@phone",
            priority: .high,
            effort: 10,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        tasks.append(Task(
            type: .task,
            title: "Call plumber about bathroom renovation quote",
            notes: "Got voicemail last week. Follow up on estimate for master bathroom work.",
            status: .nextAction,
            project: "Home Renovation",
            context: "@phone",
            priority: .medium,
            effort: 10,
            created: now.addingTimeInterval(-3600 * 168),
            modified: now.addingTimeInterval(-3600 * 96)
        ))

        tasks.append(Task(
            type: .task,
            title: "Confirm dinner reservation for Friday",
            notes: "Restaurant: The Blue Door, 7:30 PM, party of 4",
            status: .nextAction,
            context: "@phone",
            due: now.addingTimeInterval(3600 * 24 * 1), // Tomorrow
            priority: .low,
            effort: 5,
            created: now.addingTimeInterval(-3600 * 36),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        // MARK: Next Actions - @home context (4 tasks)
        // Tasks to do at home
        tasks.append(Task(
            type: .task,
            title: "Organize garage storage",
            notes: "Install new shelving units and sort through boxes. Donate items we don't need.",
            status: .nextAction,
            project: "Home Renovation",
            context: "@home",
            priority: .low,
            effort: 180,
            created: now.addingTimeInterval(-3600 * 240),
            modified: now.addingTimeInterval(-3600 * 168)
        ))

        tasks.append(Task(
            type: .task,
            title: "Winterize outdoor faucets",
            notes: "Disconnect hoses, drain pipes, install insulation covers.",
            status: .nextAction,
            context: "@home",
            due: now.addingTimeInterval(3600 * 24 * 10), // 10 days from now
            priority: .medium,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 72),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        tasks.append(Task(
            type: .task,
            title: "Replace air filter in HVAC system",
            notes: "Size: 16x25x1. Buy 3-pack from hardware store.",
            status: .nextAction,
            context: "@home",
            due: now.addingTimeInterval(3600 * 24 * 5), // 5 days from now
            priority: .medium,
            effort: 15,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Sort through mail pile on desk",
            notes: "File important documents, shred junk mail, respond to anything urgent.",
            status: .nextAction,
            context: "@home",
            flagged: true,
            priority: .medium,
            effort: 20,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        // MARK: Next Actions - @office context (3 tasks)
        // Tasks to do at the office
        tasks.append(Task(
            type: .task,
            title: "Print and sign contract documents",
            notes: "New vendor agreement needs signature. Print 2 copies, keep one for files.",
            status: .nextAction,
            context: "@office",
            due: now.addingTimeInterval(3600 * 24 * 2), // 2 days from now
            priority: .high,
            effort: 10,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 36)
        ))

        tasks.append(Task(
            type: .task,
            title: "Meet with HR about benefits enrollment",
            notes: "Open enrollment period ends next week. Review health insurance options.",
            status: .nextAction,
            context: "@office",
            due: now.addingTimeInterval(3600 * 24 * 6), // 6 days from now
            priority: .high,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Update team calendar with Q4 milestones",
            notes: "Add key dates:\n- Sprint planning sessions\n- Release dates\n- Team retrospectives\n- Company holidays",
            status: .nextAction,
            project: "Q4 Planning",
            context: "@office",
            priority: .medium,
            effort: 20,
            created: now.addingTimeInterval(-3600 * 72),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        // MARK: Next Actions - @errands context (3 tasks)
        // Tasks that require going out
        tasks.append(Task(
            type: .task,
            title: "Pick up prescription at pharmacy",
            notes: "Should be ready after 2 PM. Bring insurance card.",
            status: .nextAction,
            context: "@errands",
            due: now.addingTimeInterval(3600 * 24 * 1), // Tomorrow
            flagged: true,
            priority: .high,
            effort: 15,
            created: now.addingTimeInterval(-3600 * 36),
            modified: now.addingTimeInterval(-3600 * 24)
        ))

        tasks.append(Task(
            type: .task,
            title: "Buy paint samples for bedroom",
            notes: "Colors to try:\n- Soft Sage\n- Coastal Blue\n- Warm Taupe\n\nGet small sample sizes first.",
            status: .nextAction,
            project: "Home Renovation",
            context: "@errands",
            priority: .low,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 120),
            modified: now.addingTimeInterval(-3600 * 96)
        ))

        tasks.append(Task(
            type: .task,
            title: "Return Amazon package",
            notes: "Wrong item shipped. Print return label and drop off at UPS.",
            status: .nextAction,
            context: "@errands",
            due: now.addingTimeInterval(3600 * 24 * 8), // 8 days from now
            priority: .medium,
            effort: 20,
            created: now.addingTimeInterval(-3600 * 72),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        // MARK: Waiting For (5 tasks)
        // Tasks blocked on others
        tasks.append(Task(
            type: .task,
            title: "Waiting for design mockups from Sarah",
            notes: "Requested last Monday. Needed before we can proceed with implementation. Follow up if not received by Friday.",
            status: .waiting,
            project: "Website Redesign",
            priority: .high,
            created: now.addingTimeInterval(-3600 * 144),
            modified: now.addingTimeInterval(-3600 * 96)
        ))

        tasks.append(Task(
            type: .task,
            title: "Waiting for budget approval from finance",
            notes: "Submitted Q4 budget request on Oct 15. Expected response in 1-2 weeks.",
            status: .waiting,
            project: "Q4 Planning",
            priority: .high,
            created: now.addingTimeInterval(-3600 * 168),
            modified: now.addingTimeInterval(-3600 * 120)
        ))

        tasks.append(Task(
            type: .task,
            title: "Waiting for contractor estimate",
            notes: "Bathroom renovation quote. Should have it by end of week.",
            status: .waiting,
            project: "Home Renovation",
            priority: .medium,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Waiting for laptop repair from IT",
            notes: "Submitted ticket #7890. Battery replacement needed. Estimated 3-5 business days.",
            status: .waiting,
            priority: .medium,
            created: now.addingTimeInterval(-3600 * 48),
            modified: now.addingTimeInterval(-3600 * 36)
        ))

        tasks.append(Task(
            type: .task,
            title: "Waiting for code review approval",
            notes: "PR #234 submitted yesterday. Needs review from @john and @emily.",
            status: .waiting,
            project: "Website Redesign",
            priority: .medium,
            created: now.addingTimeInterval(-3600 * 24),
            modified: now.addingTimeInterval(-3600 * 18)
        ))

        // MARK: Someday/Maybe (8 tasks)
        // Future ideas and possibilities
        tasks.append(Task(
            type: .note,
            title: "Learn photography basics",
            notes: "Would be nice to take better photos. Maybe take an online course or workshop.",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 720),
            modified: now.addingTimeInterval(-3600 * 720)
        ))

        tasks.append(Task(
            type: .note,
            title: "Plan European vacation",
            notes: "Ideas:\n- Visit Italy (Rome, Florence, Venice)\n- France (Paris, Lyon)\n- Spain (Barcelona, Madrid)\n\nMaybe summer 2025?",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 480),
            modified: now.addingTimeInterval(-3600 * 480)
        ))

        tasks.append(Task(
            type: .task,
            title: "Build a home automation system",
            notes: "Research smart home platforms. Would be fun to automate lights, thermostat, security.",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 336),
            modified: now.addingTimeInterval(-3600 * 336)
        ))

        tasks.append(Task(
            type: .note,
            title: "Start a podcast",
            notes: "Topic: productivity and work-life balance. Interview successful remote workers.",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 600),
            modified: now.addingTimeInterval(-3600 * 600)
        ))

        tasks.append(Task(
            type: .task,
            title: "Write a technical book",
            notes: "Share lessons learned from 10 years of software development. Focus on practical advice.",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 840),
            modified: now.addingTimeInterval(-3600 * 840)
        ))

        tasks.append(Task(
            type: .task,
            title: "Learn to play guitar",
            notes: "Always wanted to learn. Maybe take lessons once schedule settles down.",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 1200),
            modified: now.addingTimeInterval(-3600 * 1200)
        ))

        tasks.append(Task(
            type: .note,
            title: "Organize digital photo library",
            notes: "Thousands of photos need sorting, tagging, and backing up. Big project for winter break?",
            status: .someday,
            priority: .low,
            created: now.addingTimeInterval(-3600 * 240),
            modified: now.addingTimeInterval(-3600 * 240)
        ))

        tasks.append(Task(
            type: .task,
            title: "Contribute to open source project",
            notes: "Find a project I'm passionate about and start contributing. Good for resume and learning.",
            status: .someday,
            project: "Learning Swift",
            priority: .low,
            created: now.addingTimeInterval(-3600 * 504),
            modified: now.addingTimeInterval(-3600 * 504)
        ))

        // MARK: Completed Tasks (10 tasks)
        // Recently completed tasks for reference
        tasks.append(Task(
            type: .task,
            title: "Submit expense report for October",
            notes: "Submitted all receipts and expense claims. Total: $347.82",
            status: .completed,
            context: "@computer",
            priority: .medium,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 240),
            modified: now.addingTimeInterval(-3600 * 48)
        ))

        tasks.append(Task(
            type: .task,
            title: "Complete Swift fundamentals course",
            notes: "Finished all 12 modules on Udemy. Got certificate!",
            status: .completed,
            project: "Learning Swift",
            context: "@computer",
            priority: .medium,
            effort: 720,
            created: now.addingTimeInterval(-3600 * 720),
            modified: now.addingTimeInterval(-3600 * 72)
        ))

        tasks.append(Task(
            type: .task,
            title: "Set up new development environment",
            notes: "Installed Xcode, configured Git, set up SSH keys, installed dependencies.",
            status: .completed,
            project: "Website Redesign",
            context: "@computer",
            priority: .high,
            effort: 60,
            created: now.addingTimeInterval(-3600 * 192),
            modified: now.addingTimeInterval(-3600 * 168)
        ))

        tasks.append(Task(
            type: .task,
            title: "Get car oil changed",
            notes: "Done at Quick Lube. Next change due in 3 months or 3000 miles.",
            status: .completed,
            context: "@errands",
            priority: .medium,
            effort: 45,
            created: now.addingTimeInterval(-3600 * 168),
            modified: now.addingTimeInterval(-3600 * 144)
        ))

        tasks.append(Task(
            type: .task,
            title: "Finalize team budget for Q4",
            notes: "Submitted final numbers. Approved by management.",
            status: .completed,
            project: "Q4 Planning",
            context: "@office",
            priority: .high,
            effort: 120,
            created: now.addingTimeInterval(-3600 * 240),
            modified: now.addingTimeInterval(-3600 * 96)
        ))

        tasks.append(Task(
            type: .task,
            title: "Send birthday card to mom",
            notes: "Card mailed on Monday. Should arrive by her birthday on Friday.",
            status: .completed,
            priority: .high,
            effort: 15,
            created: now.addingTimeInterval(-3600 * 144),
            modified: now.addingTimeInterval(-3600 * 120)
        ))

        tasks.append(Task(
            type: .task,
            title: "Clean out refrigerator",
            notes: "Threw out expired items, wiped down shelves, organized remaining food.",
            status: .completed,
            context: "@home",
            priority: .low,
            effort: 30,
            created: now.addingTimeInterval(-3600 * 96),
            modified: now.addingTimeInterval(-3600 * 84)
        ))

        tasks.append(Task(
            type: .task,
            title: "Review and merge feature branch",
            notes: "New authentication system tested and merged to main. Deployed to staging.",
            status: .completed,
            project: "Website Redesign",
            context: "@computer",
            flagged: true,
            priority: .high,
            effort: 45,
            created: now.addingTimeInterval(-3600 * 120),
            modified: now.addingTimeInterval(-3600 * 96)
        ))

        tasks.append(Task(
            type: .task,
            title: "Renew driver's license",
            notes: "Renewed online. New license should arrive in 7-10 days.",
            status: .completed,
            context: "@computer",
            priority: .high,
            effort: 20,
            created: now.addingTimeInterval(-3600 * 192),
            modified: now.addingTimeInterval(-3600 * 168)
        ))

        tasks.append(Task(
            type: .task,
            title: "Install new smoke detectors",
            notes: "Replaced all 4 detectors. Tested - working properly.",
            status: .completed,
            project: "Home Renovation",
            context: "@home",
            priority: .high,
            effort: 45,
            created: now.addingTimeInterval(-3600 * 216),
            modified: now.addingTimeInterval(-3600 * 192)
        ))

        return Array(tasks.prefix(count))
    }

    /// Generates a complete set of sample boards including built-in and custom boards
    /// - Returns: Array of sample boards
    static func generateSampleBoards() -> [Board] {
        var boards: [Board] = []

        // MARK: Built-in Smart Boards
        // These are the standard GTD boards that come with the app
        boards.append(contentsOf: Board.builtInBoards)

        // MARK: Context Boards
        // Create a board for each default context
        for context in Context.defaults {
            boards.append(Board.contextBoard(for: context))
        }

        // MARK: Project Boards
        // Create boards for the sample projects
        boards.append(Board.projectBoard(
            name: "Website Redesign",
            projectName: "Website Redesign"
        ))

        boards.append(Board.projectBoard(
            name: "Q4 Planning",
            projectName: "Q4 Planning"
        ))

        boards.append(Board.projectBoard(
            name: "Home Renovation",
            projectName: "Home Renovation"
        ))

        boards.append(Board.projectBoard(
            name: "Learning Swift",
            projectName: "Learning Swift"
        ))

        // MARK: Custom Board
        // High Priority Actions board - shows all high priority next actions
        boards.append(Board(
            id: "high-priority",
            type: .custom,
            layout: .grid,
            filter: Filter(status: .nextAction, priority: .high),
            title: "High Priority Actions",
            notes: "All high priority tasks that need attention",
            icon: "🔥",
            color: "red",
            isBuiltIn: false,
            isVisible: true,
            order: 100
        ))

        return boards
    }

    /// Generates a complete data set with tasks, boards, and positions
    /// - Returns: Tuple containing tasks and boards
    static func generateCompleteDataSet() -> (tasks: [Task], boards: [Board]) {
        var tasks = generateSampleTasks()
        let boards = generateSampleBoards()

        // Add positions for tasks on freeform/grid boards
        tasks = addSamplePositions(to: tasks, for: boards)

        return (tasks: tasks, boards: boards)
    }

    // MARK: - Testing Utilities

    /// Generates a large dataset for stress testing and performance evaluation
    /// - Parameter taskCount: Number of tasks to generate
    /// - Returns: Array of tasks
    static func generateStressTestData(taskCount: Int) -> [Task] {
        var tasks: [Task] = []
        let now = Date()

        let statuses: [Status] = [.inbox, .nextAction, .waiting, .someday, .completed]
        let contexts = Context.defaults.map { $0.name }
        let projects = ["Project A", "Project B", "Project C", "Project D", "Project E"]
        let priorities: [Priority] = [.high, .medium, .low]

        for i in 0..<taskCount {
            let randomStatus = statuses.randomElement()!
            let randomContext = contexts.randomElement()
            let randomProject = projects.randomElement()
            let randomPriority = priorities.randomElement()!

            // Randomly assign due dates
            let hasDue = Bool.random()
            let dueDate = hasDue ? now.addingTimeInterval(Double.random(in: -7...14) * 86400) : nil

            // Randomly flag 10% of tasks
            let isFlagged = Double.random(in: 0...1) < 0.1

            // Random effort estimates
            let efforts = [15, 30, 60, 90, 120]
            let effort = efforts.randomElement()

            tasks.append(Task(
                type: .task,
                title: "Stress test task \(i + 1)",
                notes: "This is a generated task for performance testing.",
                status: randomStatus,
                project: randomProject,
                context: randomContext,
                due: dueDate,
                flagged: isFlagged,
                priority: randomPriority,
                effort: effort,
                created: now.addingTimeInterval(Double(-i) * 3600),
                modified: now.addingTimeInterval(Double(-i) * 3600)
            ))
        }

        return tasks
    }

    /// Generates an empty workspace with just built-in boards and no tasks
    /// - Returns: Tuple with empty tasks array and built-in boards
    static func generateEmptyWorkspace() -> (tasks: [Task], boards: [Board]) {
        return (tasks: [], boards: Board.builtInBoards)
    }

    /// Generates minimal data set for quick testing (5 tasks)
    /// - Returns: Tuple containing minimal tasks and boards
    static func generateMinimalData() -> (tasks: [Task], boards: [Board]) {
        let now = Date()

        let tasks = [
            Task(
                type: .task,
                title: "First task in inbox",
                notes: "This is a test task",
                status: .inbox
            ),
            Task(
                type: .task,
                title: "High priority action",
                status: .nextAction,
                context: "@computer",
                due: now.addingTimeInterval(86400),
                flagged: true,
                priority: .high,
                effort: 30
            ),
            Task(
                type: .task,
                title: "Waiting for response",
                status: .waiting,
                priority: .medium
            ),
            Task(
                type: .note,
                title: "Random idea",
                status: .someday
            ),
            Task(
                type: .task,
                title: "Completed task",
                status: .completed,
                context: "@home"
            )
        ]

        let boards = Board.builtInBoards

        return (tasks: tasks, boards: boards)
    }

    // MARK: - Private Helpers

    /// Adds realistic positions to tasks for freeform and grid boards
    /// - Parameters:
    ///   - tasks: Tasks to position
    ///   - boards: Boards to position tasks on
    /// - Returns: Tasks with positions added
    private static func addSamplePositions(to tasks: [Task], for boards: [Board]) -> [Task] {
        var modifiedTasks = tasks

        // Find freeform boards that might need positions
        let freeformBoards = boards.filter { $0.layout == .freeform || $0.layout == .grid }

        // For demonstration, add positions to flagged board (grid layout)
        if let flaggedBoard = boards.first(where: { $0.id == "flagged" }) {
            let flaggedTasks = modifiedTasks.enumerated().filter { $0.element.flagged }

            // Create a grid layout: 3 columns, space items evenly
            let columnWidth: Double = 300
            let rowHeight: Double = 200
            let startX: Double = 50
            let startY: Double = 50

            for (index, (taskIndex, _)) in flaggedTasks.enumerated() {
                let column = index % 3
                let row = index / 3

                let position = Position(
                    x: startX + Double(column) * columnWidth,
                    y: startY + Double(row) * rowHeight
                )

                modifiedTasks[taskIndex].setPosition(position, for: flaggedBoard.id)
            }
        }

        // For someday board (freeform), create scattered positions for brainstorming feel
        if let somedayBoard = boards.first(where: { $0.id == "someday-maybe" }) {
            let somedayTasks = modifiedTasks.enumerated().filter { $0.element.status == .someday }

            // Create more organic, scattered positioning
            for (index, (taskIndex, _)) in somedayTasks.enumerated() {
                // Random but controlled scatter
                let baseX = Double(index % 4) * 250 + 50
                let baseY = Double(index / 4) * 200 + 50

                // Add some randomness for natural feel
                let randomOffsetX = Double.random(in: -30...30)
                let randomOffsetY = Double.random(in: -30...30)

                let position = Position(
                    x: baseX + randomOffsetX,
                    y: baseY + randomOffsetY
                )

                modifiedTasks[taskIndex].setPosition(position, for: somedayBoard.id)
            }
        }

        return modifiedTasks
    }
}

// MARK: - Convenience Extensions

extension SampleDataGenerator {
    /// Quick access to a single sample task for testing
    static var singleTask: Task {
        Task(
            type: .task,
            title: "Sample task",
            notes: "This is a sample task for testing",
            status: .nextAction,
            context: "@computer",
            priority: .medium
        )
    }

    /// Quick access to a single sample board for testing
    static var singleBoard: Board {
        Board.inbox
    }
}
