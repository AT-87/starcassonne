//
//  GridPosition.swift
//  Starcassonne
//

import Foundation

struct GridPosition: Hashable, Codable, Equatable {
    let col: Int
    let row: Int

    var neighbors: [GridPosition] {
        [
            GridPosition(col: col,     row: row - 1), // north
            GridPosition(col: col + 1, row: row),     // east
            GridPosition(col: col,     row: row + 1), // south
            GridPosition(col: col - 1, row: row),     // west
        ]
    }

    func direction(to neighbor: GridPosition) -> Direction? {
        switch (neighbor.col - col, neighbor.row - row) {
        case (0, -1): return .north
        case (1,  0): return .east
        case (0,  1): return .south
        case (-1, 0): return .west
        default:      return nil
        }
    }
}

enum Direction: String, CaseIterable, Codable, Comparable {
    case north, east, south, west

    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east:  return .west
        case .west:  return .east
        }
    }

    /// Rotate 90° clockwise
    var rotatedCW: Direction {
        switch self {
        case .north: return .east
        case .east:  return .south
        case .south: return .west
        case .west:  return .north
        }
    }

    public static func < (lhs: Direction, rhs: Direction) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The rotational turn from `self` (incoming direction) to `next` (outgoing direction)
    func turnRotation(to next: Direction) -> TurnRotation? {
        // Clockwise order: N → E → S → W → N
        let order: [Direction] = [.north, .east, .south, .west]
        guard let fromIdx = order.firstIndex(of: self),
              let toIdx   = order.firstIndex(of: next) else { return nil }
        let delta = (toIdx - fromIdx + 4) % 4
        switch delta {
        case 0: return nil          // straight ahead
        case 1: return .clockwise
        case 3: return .counterClockwise
        default: return nil         // 180° = U-turn, handled separately
        }
    }
}

enum TurnRotation: Equatable {
    case clockwise
    case counterClockwise
}

extension GridPosition {
    /// Returns the neighboring position one step in `dir`.
    func neighbor(in dir: Direction) -> GridPosition {
        switch dir {
        case .north: return GridPosition(col: col,     row: row - 1)
        case .south: return GridPosition(col: col,     row: row + 1)
        case .east:  return GridPosition(col: col + 1, row: row)
        case .west:  return GridPosition(col: col - 1, row: row)
        }
    }
}
