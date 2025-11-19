//
//  Position.swift
//  StickyToDo
//
//  Represents x,y coordinates for task position on boards.
//

import Foundation

/// Represents a 2D position on a board canvas
///
/// Used to store task positions on freeform boards. Each task can have
/// different positions on different boards, stored in the Task's positions dictionary.
public struct Position: Codable, Equatable, Hashable {
    /// Horizontal coordinate
    var x: Double

    /// Vertical coordinate
    var y: Double

    /// Creates a position with the given coordinates
    /// - Parameters:
    ///   - x: Horizontal coordinate
    ///   - y: Vertical coordinate
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension Position {
    /// Origin position (0, 0)
    static let zero = Position(x: 0, y: 0)

    /// Returns the distance between this position and another
    /// - Parameter other: The other position
    /// - Returns: Euclidean distance between the two positions
    func distance(to other: Position) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Returns a new position offset by the given deltas
    /// - Parameters:
    ///   - dx: Horizontal offset
    ///   - dy: Vertical offset
    /// - Returns: New position offset from this one
    func offset(by dx: Double, dy: Double) -> Position {
        return Position(x: x + dx, y: y + dy)
    }

    /// Returns a new position offset by another position
    /// - Parameter offset: The offset to apply
    /// - Returns: New position offset from this one
    func offset(by offset: Position) -> Position {
        return Position(x: x + offset.x, y: y + offset.y)
    }
}

// MARK: - Custom String Convertible
extension Position: CustomStringConvertible {
    var description: String {
        return "(\(x), \(y))"
    }
}
