//
//  Player.swift
//  Starcassonne
//

import SwiftUI

enum Faction: String, CaseIterable, Codable, Identifiable {
    case federation
    case cardassian
    case klingon
    case borg
    case romulan
    case bajoran

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .federation: return "Federation"
        case .cardassian: return "Cardassian"
        case .klingon:    return "Klingon"
        case .borg:       return "Borg"
        case .romulan:    return "Romulan"
        case .bajoran:    return "Bajoran"
        }
    }

    var color: Color {
        switch self {
        case .federation: return .blue
        case .cardassian: return .yellow
        case .klingon:    return .red
        case .borg:       return .white
        case .romulan:    return .green
        case .bajoran:    return Color(red: 0.6, green: 0.2, blue: 0.8)
        }
    }

    /// Unicode symbol representing this faction's ship on the board
    var shipSymbol: String {
        switch self {
        case .federation: return "✦"   // UFP starburst chevron
        case .cardassian: return "◆"   // Galor-class — angular diamond
        case .klingon:    return "⚔"   // Warrior culture — crossed swords
        case .borg:       return "⬛"   // Borg Cube
        case .romulan:    return "⚕"   // Bird of Prey — mirrored wings
        case .bajoran:    return "✡"   // Bajoran spiritual sun symbol
        }
    }

    /// SF Symbol name for use in picker / UI icons
    var sfSymbol: String {
        switch self {
        case .federation: return "shield.lefthalf.filled"
        case .cardassian: return "hexagon.fill"
        case .klingon:    return "bolt.fill"
        case .borg:       return "cube.fill"
        case .romulan:    return "bird.fill"
        case .bajoran:    return "sun.max.fill"
        }
    }
}

struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var faction: Faction
    var score: Int = 0
    var shipsRemaining: Int = 7  // Standard meeple count

    init(name: String, faction: Faction) {
        self.id      = UUID()
        self.name    = name
        self.faction = faction
    }
}
