//
//  BoardStoreTests.swift
//  StickyToDoTests
//
//  Comprehensive tests for BoardStore operations.
//

import XCTest
import Combine
@testable import StickyToDo

final class BoardStoreTests: XCTestCase {

    var tempDirectory: URL!
    var fileIO: MarkdownFileIO!
    var boardStore: BoardStore!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoardStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        fileIO = MarkdownFileIO(rootDirectory: tempDirectory)
        try fileIO.ensureDirectoryStructure()

        boardStore = BoardStore(fileIO: fileIO)
        cancellables = []
    }

    override func tearDown() async throws {
        boardStore.cancelAllPendingSaves()
        cancellables = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(boardStore.boards.count, 0)
        XCTAssertEqual(boardStore.visibleBoards.count, 0)
    }

    func testLoadAllBoards() throws {
        // Write test boards
        let boards = [
            Board(id: "test-1", type: .custom),
            Board(id: "test-2", type: .project),
            Board(id: "test-3", type: .context)
        ]

        for board in boards {
            try fileIO.writeBoard(board)
        }

        try boardStore.loadAll()

        let expectation = XCTestExpectation(description: "Boards loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have loaded custom boards plus built-in boards
        XCTAssertGreaterThanOrEqual(boardStore.boardCount, boards.count)
    }

    func testBuiltInBoardsCreation() throws {
        // Load with no existing boards
        try boardStore.loadAll()

        let expectation = XCTestExpectation(description: "Built-in boards created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // All built-in boards should be created
        XCTAssertEqual(boardStore.boardCount, Board.builtInBoards.count)

        XCTAssertNotNil(boardStore.board(withID: "inbox"))
        XCTAssertNotNil(boardStore.board(withID: "next-actions"))
        XCTAssertNotNil(boardStore.board(withID: "flagged"))
    }

    // MARK: - CRUD Tests

    func testAddBoard() {
        let board = Board(id: "new-board", type: .custom)
        boardStore.add(board)

        let expectation = XCTestExpectation(description: "Board added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(boardStore.boardCount, 1)
        XCTAssertNotNil(boardStore.board(withID: "new-board"))
    }

    func testUpdateBoard() {
        var board = Board(id: "update-test", type: .custom, title: "Original")
        boardStore.add(board)

        let expectation1 = XCTestExpectation(description: "Board added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        board.title = "Updated"
        boardStore.update(board)

        let expectation2 = XCTestExpectation(description: "Board updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        let updated = boardStore.board(withID: "update-test")
        XCTAssertEqual(updated?.title, "Updated")
    }

    func testDeleteBoard() {
        let board = Board(id: "delete-me", type: .custom)
        boardStore.add(board)

        let expectation1 = XCTestExpectation(description: "Board added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        boardStore.delete(board)

        let expectation2 = XCTestExpectation(description: "Board deleted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        XCTAssertNil(boardStore.board(withID: "delete-me"))
    }

    func testCannotDeleteBuiltInBoard() {
        let inbox = Board.inbox
        boardStore.add(inbox)

        let expectation1 = XCTestExpectation(description: "Board added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        let initialCount = boardStore.boardCount

        boardStore.delete(inbox)

        let expectation2 = XCTestExpectation(description: "Delete attempted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        // Built-in board should still exist
        XCTAssertEqual(boardStore.boardCount, initialCount)
        XCTAssertNotNil(boardStore.board(withID: "inbox"))
    }

    // MARK: - Board Lookup Tests

    func testBoardsOfType() {
        let boards = [
            Board(id: "project-1", type: .project),
            Board(id: "project-2", type: .project),
            Board(id: "context-1", type: .context),
            Board(id: "custom-1", type: .custom)
        ]

        for board in boards {
            boardStore.add(board)
        }

        let expectation = XCTestExpectation(description: "Boards added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let projectBoards = boardStore.boards(ofType: .project)
        XCTAssertEqual(projectBoards.count, 2)

        let contextBoards = boardStore.boards(ofType: .context)
        XCTAssertEqual(contextBoards.count, 1)

        let customBoards = boardStore.boards(ofType: .custom)
        XCTAssertEqual(customBoards.count, 1)
    }

    func testBoardsWithLayout() {
        let boards = [
            Board(id: "freeform-1", type: .custom, layout: .freeform),
            Board(id: "kanban-1", type: .status, layout: .kanban),
            Board(id: "kanban-2", type: .project, layout: .kanban),
            Board(id: "grid-1", type: .custom, layout: .grid)
        ]

        for board in boards {
            boardStore.add(board)
        }

        let expectation = XCTestExpectation(description: "Boards added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(boardStore.freeformBoards.count, 1)
        XCTAssertEqual(boardStore.kanbanBoards.count, 2)
        XCTAssertEqual(boardStore.gridBoards.count, 1)
    }

    func testBoardsMatchingSearch() {
        let boards = [
            Board(id: "project-website", type: .project, title: "Website Redesign"),
            Board(id: "project-mobile", type: .project, title: "Mobile App"),
            Board(id: "context-office", type: .context, title: "Office Tasks")
        ]

        for board in boards {
            boardStore.add(board)
        }

        let expectation = XCTestExpectation(description: "Boards added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let websiteBoards = boardStore.boards(matchingSearch: "website")
        XCTAssertEqual(websiteBoards.count, 1)

        let projectBoards = boardStore.boards(matchingSearch: "project")
        XCTAssertEqual(projectBoards.count, 2)

        let officeBoards = boardStore.boards(matchingSearch: "office")
        XCTAssertEqual(officeBoards.count, 1)
    }

    // MARK: - Dynamic Board Creation Tests

    func testGetOrCreateContextBoard() {
        let context = Context(name: "@phone", icon: "📱", color: "blue")

        let board1 = boardStore.getOrCreateContextBoard(for: context)

        let expectation = XCTestExpectation(description: "Board created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(board1.id, "@phone")
        XCTAssertEqual(board1.type, .context)

        // Getting again should return same board, not create new one
        let initialCount = boardStore.boardCount
        let board2 = boardStore.getOrCreateContextBoard(for: context)

        XCTAssertEqual(board1.id, board2.id)
        XCTAssertEqual(boardStore.boardCount, initialCount)
    }

    func testGetOrCreateProjectBoard() {
        let board1 = boardStore.getOrCreateProjectBoard(for: "Website Redesign")

        let expectation = XCTestExpectation(description: "Board created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(board1.type, .project)
        XCTAssertTrue(board1.autoHide)

        // Getting again should return same board
        let initialCount = boardStore.boardCount
        let board2 = boardStore.getOrCreateProjectBoard(for: "Website Redesign")

        XCTAssertEqual(board1.id, board2.id)
        XCTAssertEqual(boardStore.boardCount, initialCount)
    }

    // MARK: - Board Visibility Tests

    func testHideAndShowBoard() {
        var board = Board(id: "visibility-test", type: .custom, isVisible: true)
        boardStore.add(board)

        let expectation1 = XCTestExpectation(description: "Board added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        XCTAssertEqual(boardStore.visibleBoardCount, 1)

        boardStore.hide(board)

        let expectation2 = XCTestExpectation(description: "Board hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        XCTAssertEqual(boardStore.visibleBoardCount, 0)

        boardStore.show(board)

        let expectation3 = XCTestExpectation(description: "Board shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 2.0)

        XCTAssertEqual(boardStore.visibleBoardCount, 1)
    }

    // MARK: - Board Reordering Tests

    func testReorderBoards() {
        let boards = [
            Board(id: "board-1", type: .custom, order: 0),
            Board(id: "board-2", type: .custom, order: 1),
            Board(id: "board-3", type: .custom, order: 2)
        ]

        for board in boards {
            boardStore.add(board)
        }

        let expectation1 = XCTestExpectation(description: "Boards added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)

        // Reorder: 3, 1, 2
        boardStore.reorder(["board-3", "board-1", "board-2"])

        let expectation2 = XCTestExpectation(description: "Boards reordered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)

        let board1 = boardStore.board(withID: "board-1")
        let board2 = boardStore.board(withID: "board-2")
        let board3 = boardStore.board(withID: "board-3")

        XCTAssertEqual(board3?.order, 0)
        XCTAssertEqual(board1?.order, 1)
        XCTAssertEqual(board2?.order, 2)
    }

    // MARK: - Statistics Tests

    func testBoardCounts() {
        let boards = [
            Board(id: "visible-1", type: .custom, isVisible: true),
            Board(id: "visible-2", type: .custom, isVisible: true),
            Board(id: "hidden-1", type: .custom, isVisible: false)
        ]

        for board in boards {
            boardStore.add(board)
        }

        let expectation = XCTestExpectation(description: "Boards added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(boardStore.boardCount, 3)
        XCTAssertEqual(boardStore.visibleBoardCount, 2)
        XCTAssertEqual(boardStore.hiddenBoardCount, 1)
    }

    // MARK: - Observation Tests

    func testBoardsPublisher() {
        let expectation = XCTestExpectation(description: "Publisher fired")
        var receivedCount = 0

        boardStore.$boards.sink { boards in
            receivedCount = boards.count
            if receivedCount > 0 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        let board = Board(id: "publisher-test", type: .custom)
        boardStore.add(board)

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(receivedCount, 1)
    }

    func testVisibleBoardsPublisher() {
        let expectation = XCTestExpectation(description: "Visible boards updated")
        var receivedCount = 0

        boardStore.$visibleBoards.sink { visibleBoards in
            receivedCount = visibleBoards.count
            if receivedCount > 0 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        let board = Board(id: "visible-test", type: .custom, isVisible: true)
        boardStore.add(board)

        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(receivedCount, 1)
    }
}
