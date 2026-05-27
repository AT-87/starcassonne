//
//  GameViewModel.swift
//  Starcassonne
//

import SwiftUI

// MARK: - Ship placement option

/// A single entry in the ship-placement menu: feature type, the specific edge direction
/// it's anchored to (for sector/corridor disambiguation), and a display label.
struct ShipOption: Identifiable {
    let id      = UUID()
    let feature: PlacedFeature
    let edgeDir: Direction?    // nil for colony / dilithium / open-space
    let label:   String
}

// MARK: - ViewModel

@MainActor
@Observable
class GameViewModel {
    var gameState:       GameState
    var message:         String = ""
    var lastPlacedPos:   GridPosition?   // position awaiting ship decision
    var pendingToasts:   [(points: Int, factions: [Faction])] = []

    init(players: [Player]) {
        self.gameState = GameState(players: players)
        updateMessage()
    }

    /// Load a previously saved game state (used by SetupView's CONTINUE button).
    init(state: GameState) {
        self.gameState = state
        updateMessage()
    }

    // MARK: - Derived state

    var currentTile: Tile?   { gameState.currentTile }
    var phase:       GamePhase { gameState.phase }

    var validPlacements: [GridPosition] {
        guard let tile = gameState.currentTile,
              !gameState.awaitingShipPlacement else { return [] }
        let placements = gameState.validPlacements(for: tile)
        return placements
    }


    var awaitingShip: Bool { gameState.awaitingShipPlacement }

    // MARK: - End game

    func triggerEndGameScoring() {
        gameState.applyEndGameScoring()
    }

    // MARK: - Tile actions

    func rotateTile() {
        guard !gameState.awaitingShipPlacement else { return }
        gameState.currentTile?.rotateClockwise()
    }

    func selectPosition(_ pos: GridPosition) {
        guard let tile = gameState.currentTile,
              !gameState.awaitingShipPlacement else { return }
        guard validPlacements.contains(pos) else {
            message = "⚠️ Edges don't match — try rotating"
            return
        }
        gameState.place(tile: tile, at: pos)
        lastPlacedPos = pos
        updateMessage()
    }

    // MARK: - Ship placement

    /// Called after tile is placed — player chooses an option or passes (nil).
    func placeShip(option: ShipOption?) {
        guard let pos = lastPlacedPos else { return }
        let events = gameState.placeShip(at: pos, feature: option?.feature, edgeDir: option?.edgeDir)
        lastPlacedPos = nil
        // Queue score toasts for each completed feature
        let toasts = events.filter { $0.points > 0 }.map { (points: $0.points, factions: $0.factions) }
        pendingToasts.append(contentsOf: toasts)
        // Auto-save after each move
        try? GamePersistence.save(gameState)
        updateMessage()
    }

    // MARK: - Available ship options on just-placed tile

    /// One entry per placeable feature region.  When a tile has two *separate* sectors
    /// (e.g. CICI — sectors on N and S with no connecting group) each sector appears as
    /// its own option, labelled "SECTOR (N)" / "SECTOR (S)" so the player can pick.
    var availableShipOptions: [ShipOption] {
        guard let pos  = lastPlacedPos,
              let tile = gameState.placedTiles[pos] else { return [] }

        guard gameState.currentPlayer.shipsRemaining > 0 else { return [] }

        var options: [ShipOption] = []
        let edges       = tile.rotatedEdges
        let streamEdges = tile.streamEdges
        let groups      = tile.rotatedSectorGroups   // [[Direction]]

        // ── Sectors ──────────────────────────────────────────────────────────
        // Collect one representative direction per distinct sector group.
        var seenGroupKeys = Set<Int>()          // index into `groups`, or -1 for ungrouped
        var sectorEntries: [(dir: Direction, groupKey: Int)] = []

        for dir in Direction.allCases where edges.edge(facing: dir) == .sector
                                         && !streamEdges.contains(dir) {
            let key = groups.firstIndex(where: { $0.contains(dir) }) ?? -1
            if seenGroupKeys.insert(key).inserted {
                sectorEntries.append((dir: dir, groupKey: key))
            }
        }

        let multiSector = sectorEntries.count > 1

        for entry in sectorEntries {
            guard !ScoringEngine.isOccupied(at: pos, edgeDir: entry.dir,
                                             feature: .sector, in: gameState) else { continue }
            let label = multiSector
                ? "SECTOR (\(entry.dir.rawValue.prefix(1).uppercased()))"
                : "SECTOR"
            options.append(ShipOption(feature: .sector, edgeDir: entry.dir, label: label))
        }

        // ── Warp Corridor ─────────────────────────────────────────────────────
        // Corridors always form a single connected road through a tile (or terminate at
        // a crossroads), so one representative direction is sufficient.
        for dir in Direction.allCases where edges.edge(facing: dir) == .warpCorridor
                                         && !streamEdges.contains(dir) {
            if !ScoringEngine.isOccupied(at: pos, edgeDir: dir,
                                          feature: .warpCorridor, in: gameState) {
                options.append(ShipOption(feature: .warpCorridor, edgeDir: dir,
                                          label: "WARP CORRIDOR"))
                break   // all corridor edges on this tile connect — one option is enough
            }
        }

        // ── Colony / Dilithium ────────────────────────────────────────────────
        if tile.features.contains(.colony),
           !ScoringEngine.isOccupied(at: pos, edgeDir: .north,
                                      feature: .colony, in: gameState) {
            options.append(ShipOption(feature: .colony, edgeDir: nil, label: "COLONY"))
        }
        if tile.features.contains(.dilithiumAsteroid),
           !ScoringEngine.isOccupied(at: pos, edgeDir: .north,
                                      feature: .dilithium, in: gameState) {
            options.append(ShipOption(feature: .dilithium, edgeDir: nil, label: "DILITHIUM"))
        }

        // ── Open Space / Trader ───────────────────────────────────────────────
        options.append(ShipOption(feature: .openSpace, edgeDir: nil, label: "TRADER"))

        return options
    }

    // MARK: - Abbot / Mining Ship recall

    /// Colony and dilithium tiles where the current player can recall their ship.
    var recallableTiles: [(pos: GridPosition, score: Int)] {
        gameState.recallableTiles.compactMap { pos in
            guard let info = ScoringEngine.findMonastery(at: pos, in: gameState) else { return nil }
            return (pos: pos, score: info.score())
        }
    }

    func recallShip(at pos: GridPosition) {
        LCARSAudio.shared.confirm()
        let recallingFaction = gameState.currentPlayer.faction
        let scored = gameState.recallShip(at: pos)
        if scored > 0 {
            pendingToasts.append((points: scored, factions: [recallingFaction]))
        }
        try? GamePersistence.save(gameState)
        updateMessage()
    }

    // MARK: - Save / Load

    func saveGame() {
        try? GamePersistence.save(gameState)
    }

    var hasSave: Bool { GamePersistence.hasSave }

    // MARK: - Board bounds

    var boardBounds: (minCol: Int, maxCol: Int, minRow: Int, maxRow: Int) {
        guard !gameState.placedTiles.isEmpty else {
            return (minCol: -3, maxCol: 3, minRow: -3, maxRow: 3)
        }
        let cols = gameState.placedTiles.keys.map(\.col)
        let rows = gameState.placedTiles.keys.map(\.row)
        return (
            minCol: (cols.min() ?? 0) - 2,
            maxCol: (cols.max() ?? 0) + 2,
            minRow: (rows.min() ?? 0) - 2,
            maxRow: (rows.max() ?? 0) + 2
        )
    }

    // MARK: - Messaging

    private func updateMessage() {
        switch gameState.phase {
        case .nebula:
            if gameState.awaitingShipPlacement {
                message = "Deploy a ship or pass"
            } else {
                let remaining = gameState.nebulaDeck.count
                if validPlacements.isEmpty, gameState.currentTile != nil {
                    message = "↻ Rotate to align the nebula stream"
                } else {
                    message = "\(gameState.currentPlayer.name) — Chart the Nebula (\(remaining) tiles left)"
                }
            }
        case .exploration:
            if gameState.awaitingShipPlacement {
                message = "Deploy a ship or pass"
            } else {
                message = "\(gameState.currentPlayer.name) — Place a tile (\(gameState.deck.count) left)"
            }
        case .ended:
            message = "🏁 Exploration complete — Final scoring!"
        }
    }
}
