//
//  GameState.swift
//  Starcassonne
//

import Foundation

// MARK: - Game Phase

enum GamePhase: String, Codable {
    case nebula      // Placing the 12 Nebula tiles (River equivalent)
    case exploration // Main game — drawing & placing sector tiles
    case ended       // Deck exhausted
}

// MARK: - Nebula Tile Definitions
//
// The Nebula (River) has 12 tiles placed before main play begins.
// Rules (from official River expansion):
//   - Source tile is placed first (fixed, no player choice)
//   - Lake tile ends the phase (placed last)
//   - River cannot U-turn — can't place back in the direction you came from
//   - Ships CANNOT be placed on the nebula stream itself
//   - Ships CAN be placed on fields/sectors/corridors on nebula tiles
//   - Terrain edge matching is only checked against non-nebula adjacent tiles
//     (in practice all nebula tiles are placed in open space so this rarely matters)

struct NebulaDeck {
    /// Builds the 12-tile Nebula deck matching Carcassonne River I exactly:
    ///
    /// Rules encoded here:
    ///   - Stream occupies EXACTLY 2 edges per tile (entry + exit). Those edges are openSpace
    ///     for terrain-matching purposes but rendered as the nebula stream.
    ///   - The other 2 edges carry real terrain (sector, warpCorridor, or openSpace).
    ///   - Tiles can be rotated. nebulaEntry/nebulaExit are base-orientation directions;
    ///     the Tile model rotates them with the tile.
    ///   - Source: stream exits .south only (fixed, no entry). Placed automatically at (0,0).
    ///   - Lake: stream enters .west only (no exit). Has Colony. Always placed last.
    ///   - 10 middle tiles are shuffled.
    ///
    /// Tile-by-tile (Carcassonne River I reference name → Starcassonne):
    ///   Source  : SPRING  — stream out S only. All field edges.
    ///   CICI    : Two Sectors straight (W→E stream, N=sector, S=sector, two separate sectors)
    ///   CIRI    : Sector + Warp Corridor straight (W→E stream, N=sector, S=warpCorridor)
    ///   LIRI    : Warp Corridor + Open Space straight (W→E stream, N=openSpace, S=warpCorridor)
    ///   RIrI    : Two Warp Corridors crossing stream (N→S stream, E=warpCorridor, W=warpCorridor)
    ///   IFI ×2  : Plain straight (W→E stream, all other edges openSpace)
    ///   CcII    : Corner Sector (S→E stream, N=sector, W=sector, connected)
    ///   RrII    : Two Warp Corridors corner (W→S stream, N=warpCorridor, E=warpCorridor)
    ///   II ×2   : Plain curved (W→S stream, all other edges openSpace)
    ///   Lake    : LAKE — stream in from W only. Colony feature. All field edges.
    static func make() -> [Tile] {
        // Source: stream exits south. All terrain edges are openSpace.
        let source = make(.U,
                          n: .openSpace, e: .openSpace, s: .openSpace, w: .openSpace,
                          entry: nil, exit: .south)

        var middle: [Tile] = [
            // CICI — two separate sectors N and S, stream W→E
            make(.N,
                 n: .sector,      e: .openSpace, s: .sector,      w: .openSpace,
                 entry: .west, exit: .east,
                 sg: [[.north], [.south]]),

            // CIRI — sector N, warp corridor S, stream W→E
            make(.J,
                 n: .sector,      e: .openSpace, s: .warpCorridor, w: .openSpace,
                 entry: .west, exit: .east,
                 sg: [[.north]]),

            // LIRI — warp corridor S, stream W→E (no colony — only lake has colony)
            make(.V,
                 n: .openSpace,   e: .openSpace, s: .warpCorridor, w: .openSpace,
                 entry: .west, exit: .east),

            // RIrI — two warp corridors (E+W), stream N→S
            make(.U,
                 n: .openSpace,   e: .warpCorridor, s: .openSpace, w: .warpCorridor,
                 entry: .north, exit: .south),

            // IFI — plain straight ×2, stream W→E
            make(.U,
                 n: .openSpace,   e: .openSpace, s: .openSpace,    w: .openSpace,
                 entry: .west, exit: .east),
            make(.U,
                 n: .openSpace,   e: .openSpace, s: .openSpace,    w: .openSpace,
                 entry: .west, exit: .east),

            // CcII — corner sector (N+W connected), curved stream S→E
            make(.N,
                 n: .sector,      e: .openSpace, s: .openSpace,    w: .sector,
                 entry: .south, exit: .east,
                 sg: [[.north, .west]]),

            // RrII — two warp corridors (N+E), curved stream W→S
            make(.V,
                 n: .warpCorridor, e: .warpCorridor, s: .openSpace, w: .openSpace,
                 entry: .west, exit: .south),

            // II — plain curved ×2, stream W→S
            make(.U,
                 n: .openSpace,   e: .openSpace, s: .openSpace,    w: .openSpace,
                 entry: .west, exit: .south),
            make(.U,
                 n: .openSpace,   e: .openSpace, s: .openSpace,    w: .openSpace,
                 entry: .west, exit: .south),
        ]
        middle = NebulaDeck.shuffleNoAdjacentCurved(middle)

        // Lake: stream enters from west (player rotates to fit). Has Colony.
        let lake = make(.A,
                        n: .openSpace, e: .openSpace, s: .openSpace, w: .openSpace,
                        entry: .west, exit: nil,
                        f: [.colony])

        return [source] + middle + [lake]
    }

    /// Returns true if both stream edges exist and are perpendicular (i.e. the tile curves).
    /// Straight tiles have entry/exit on opposite edges; curved tiles have them on adjacent edges.
    private static func isCurved(_ tile: Tile) -> Bool {
        guard let entry = tile.nebulaEntry, let exit = tile.nebulaExit else { return false }
        return entry != exit.opposite
    }

    /// Shuffles the 10 middle nebula tiles so no two curved tiles are ever adjacent.
    ///
    /// Strategy: split into curved and straight groups, shuffle each independently,
    /// then distribute the curved tiles into distinct gaps between straight tiles.
    /// With 6 straight tiles there are 7 gaps (positions 0…6) and only 4 curved tiles,
    /// so a valid arrangement always exists.
    private static func shuffleNoAdjacentCurved(_ tiles: [Tile]) -> [Tile] {
        var curved   = tiles.filter {  isCurved($0) }.shuffled()
        var straight = tiles.filter { !isCurved($0) }.shuffled()

        // Pick `curved.count` distinct insertion gaps from the (straight.count + 1) available.
        // Gaps are indexed 0 … straight.count (before, between, and after straight tiles).
        var gaps = Array(0...straight.count).shuffled().prefix(curved.count).sorted()

        // Build the result by walking through straight tiles, inserting curved tiles
        // at the chosen gap indices.
        var result: [Tile] = []
        var curvedIdx = 0
        for i in 0...straight.count {
            if curvedIdx < gaps.count && gaps[curvedIdx] == i {
                result.append(curved[curvedIdx])
                curvedIdx += 1
            }
            if i < straight.count {
                result.append(straight[i])
            }
        }
        return result
    }

    private static func make(_ type: TileType,
                              n: TileEdge, e: TileEdge, s: TileEdge, w: TileEdge,
                              entry: Direction?, exit: Direction?,
                              f: Set<TileFeature> = [],
                              sg: [[Direction]] = []) -> Tile {
        Tile(type: type,
             edges: TileEdges(north: n, east: e, south: s, west: w),
             features: f, sectorGroups: sg, isNebula: true,
             nebulaEntry: entry, nebulaExit: exit)
    }
}

// MARK: - GameState

struct GameState {
    var placedTiles:   [GridPosition: Tile] = [:]
    var deck:          [Tile] = []
    var nebulaDeck:    [Tile] = []
    var currentTile:   Tile?
    var phase:         GamePhase = .nebula
    var currentPlayerIndex: Int = 0
    var players:       [Player]
    var awaitingShipPlacement: Bool = false
    var lastPlacedPos: GridPosition?

    // Nebula tracking
    var lastNebulaPos:     GridPosition = GridPosition(col: 0, row: 0)
    var prevNebulaPos:     GridPosition? = nil
    var prevNebulaMoveDir: Direction?   = nil
    let nebulaCount:       Int = 12
    var nebulaPlaced:      Int = 0

    var endGameScored:     Bool = false

    var isGameOver: Bool { phase == .ended }

    init(players: [Player]) {
        self.players    = players
        self.nebulaDeck = NebulaDeck.make()
        self.deck       = TileDeck.makeDeck()
        placeNebulaSource()
    }

    // MARK: - Setup

    mutating func placeNebulaSource() {
        let source = nebulaDeck.removeFirst()
        let origin = GridPosition(col: 0, row: 0)
        placedTiles[origin] = source
        nebulaPlaced  = 1
        lastNebulaPos = origin
        prevNebulaPos = nil
        drawNextTile()
    }

    // MARK: - Drawing

    mutating func drawNextTile() {
        if phase == .nebula {
            if nebulaDeck.isEmpty {
                // All nebula tiles placed — switch to exploration
                phase = .exploration
                drawFromMainDeck()
            } else {
                currentTile = nebulaDeck.removeFirst()
            }
        } else {
            drawFromMainDeck()
        }
    }

    private mutating func drawFromMainDeck() {
        guard !deck.isEmpty else {
            currentTile = nil
            phase = .ended
            applyEndGameScoring()
            return
        }
        currentTile = deck.removeFirst()
    }

    // MARK: - Placement validation

    func validPlacements(for tile: Tile) -> [GridPosition] {
        switch phase {
        case .nebula:
            return nebulaValidPlacements(for: tile)
        case .exploration:
            return explorationValidPlacements(for: tile)
        case .ended:
            return []
        }
    }

    /// Nebula placement: the valid cell is ALWAYS the single cell the last placed tile's
    /// stream exits into. The player rotates the new tile until its entry faces back.
    ///
    /// Flow:
    ///  1. Look up the last placed tile's `rotatedNebulaExit` — that direction IS the
    ///     only valid placement direction.
    ///  2. The candidate cell = lastNebulaPos.neighbor(in: exitDir).
    ///  3. Reject if occupied, or if double-same-turn rule fires (curved tiles only).
    ///  4. Reject if the new tile's current rotation doesn't align its entry back toward
    ///     lastNebulaPos — player must rotate first.
    ///
    /// U-turn is geometrically impossible with valid tile definitions (no tile exits the
    /// same edge it entered). Double-turn is checked against move-direction history.
    private func nebulaValidPlacements(for tile: Tile) -> [GridPosition] {
        guard let lastTile = placedTiles[lastNebulaPos] else { return [] }

        // Determine the effective exit direction of the last placed tile.
        // Because middle tiles can be placed in either orientation (either stream edge
        // may face back toward the previous tile), we cannot simply read rotatedNebulaExit —
        // that may point backward if the tile was placed "reversed."
        // Instead: the exit is whichever stream edge does NOT face back toward prevNebulaPos.
        // For the source tile there is no previous tile, so rotatedNebulaExit is authoritative.
        let exitDir: Direction
        if let incomingDir = prevNebulaMoveDir {
            // The edge that faces our incoming travel direction's opposite is the "back" edge.
            let backDir = incomingDir.opposite
            let streamEdges = [lastTile.rotatedNebulaEntry, lastTile.rotatedNebulaExit].compactMap { $0 }
            guard let forward = streamEdges.first(where: { $0 != backDir }) else {
                // Lake tile: only one stream edge and it faces back → stream ends here.
                return []
            }
            exitDir = forward
        } else {
            // Source tile: no incoming direction, use its fixed exit directly.
            guard let exit = lastTile.rotatedNebulaExit else { return [] }
            exitDir = exit
        }

        // The one and only candidate cell
        let candidatePos = lastNebulaPos.neighbor(in: exitDir)
        guard placedTiles[candidatePos] == nil else { return [] }

        // The new tile is valid if EITHER of its stream edges faces back toward lastNebulaPos.
        // In real Carcassonne the river is directionless — a tile is validly placed as long as
        // one of its stream edges connects to the incoming flow. Requiring only nebulaEntry was
        // too strict: tiles placed "reversed" (exit facing back) were incorrectly rejected.
        // U-turns are impossible because that would require both stream edges to point the same
        // direction, which no valid tile has.
        let newTileStreamEdges = [tile.rotatedNebulaEntry, tile.rotatedNebulaExit].compactMap { $0 }
        guard newTileStreamEdges.contains(exitDir.opposite) else { return [] }

        return [candidatePos]
    }

    /// Exploration: any empty cell adjacent to any placed tile, with edge matching
    private func explorationValidPlacements(for tile: Tile) -> [GridPosition] {
        var candidates = Set<GridPosition>()
        for pos in placedTiles.keys {
            for n in pos.neighbors where placedTiles[n] == nil {
                candidates.insert(n)
            }
        }
        return candidates.filter { canPlace(tile: tile, at: $0) }
    }

    func canPlace(tile: Tile, at pos: GridPosition) -> Bool {
        let edges = tile.rotatedEdges
        var hasNeighbor = false
        for neighbor in pos.neighbors {
            guard let neighborTile = placedTiles[neighbor],
                  let dir = pos.direction(to: neighbor) else { continue }
            hasNeighbor = true
            if edges.edge(facing: dir) != neighborTile.rotatedEdges.edge(facing: dir.opposite) {
                return false
            }
        }
        return hasNeighbor
    }

    // MARK: - Place tile

    mutating func place(tile: Tile, at pos: GridPosition) {
        let t = tile
        lastPlacedPos = pos

        if phase == .nebula {
            // Track the move direction so nebulaValidPlacements can identify which
            // stream edge of the last tile faces "back" when computing its effective exit.
            let moveDir = lastNebulaPos.direction(to: pos)
            prevNebulaMoveDir = moveDir
            prevNebulaPos     = lastNebulaPos
            lastNebulaPos     = pos
            nebulaPlaced     += 1
            if nebulaDeck.isEmpty { phase = .exploration }
        }

        placedTiles[pos] = t
        awaitingShipPlacement = true
    }

    // MARK: - Ship placement

    @discardableResult
    mutating func placeShip(at pos: GridPosition, feature: PlacedFeature?, edgeDir: Direction?) -> [ScoreEvent] {
        let idx = currentPlayerIndex

        if let feature {
            // Only deploy if the player has ships left
            if players[idx].shipsRemaining > 0 {
                if var tile = placedTiles[pos] {
                    tile.placedShip = (faction: currentPlayer.faction, feature: feature, edgeDir: edgeDir)
                    placedTiles[pos] = tile
                    players[idx].shipsRemaining -= 1
                }
            }
        }

        awaitingShipPlacement = false
        lastPlacedPos = nil

        // Score any features that are now complete (returns ships, awards points)
        let events = applyCompletedFeatures(at: pos)

        advanceTurn()
        return events
    }

    /// Apply all ScoreEvents from features completed by placing/shipping at `pos`.
    /// Returns the events so callers can emit score toasts.
    @discardableResult
    mutating func applyCompletedFeatures(at pos: GridPosition) -> [ScoreEvent] {
        let events = ScoringEngine.findCompletedFeatures(at: pos, in: self)
        for event in events {
            // Award points to winning factions
            for faction in event.factions {
                if let i = players.firstIndex(where: { $0.faction == faction }) {
                    players[i].score += event.points
                }
            }
            // Return ALL ships from the completed feature (winner and loser both get theirs back)
            for tilePos in event.clearTiles {
                if var tile = placedTiles[tilePos],
                   let ship = tile.placedShip,
                   ship.feature == event.feature {
                    if let i = players.firstIndex(where: { $0.faction == ship.faction }) {
                        players[i].shipsRemaining += 1
                    }
                    tile.placedShip = nil
                    placedTiles[tilePos] = tile
                }
            }
        }
        return events
    }

    /// Run end-of-game scoring: incomplete features + Trader (field) scoring.
    mutating func applyEndGameScoring() {
        guard !endGameScored else { return }
        endGameScored = true

        let events = ScoringEngine.scoreEndGame(in: self)
        for event in events {
            for faction in event.factions {
                if let i = players.firstIndex(where: { $0.faction == faction }) {
                    players[i].score += event.points
                }
            }
            // Return ships (for display purposes we leave them on the board)
            for tilePos in event.clearTiles {
                if let tile = placedTiles[tilePos],
                   let ship = tile.placedShip,
                   ship.feature == event.feature {
                    if let i = players.firstIndex(where: { $0.faction == ship.faction }) {
                        players[i].shipsRemaining += 1
                    }
                }
            }
        }
    }

    private mutating func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        drawNextTileSkippingUnplaceable()
    }

    /// Draws tiles, discarding any that can't be placed.
    ///
    /// For nebula tiles:
    ///   - The valid cell is always the one the last tile's stream exits into.
    ///   - Either stream edge (entry or exit) may face back toward the previous tile,
    ///     so every middle tile always has at least one valid rotation. In practice
    ///     all 10 middle tiles are always placed — no discards occur.
    ///   - The tile is presented to the player at rotation=0; they rotate to align it.
    ///
    /// For exploration tiles: standard edge-matching check across all rotations.
    private mutating func drawNextTileSkippingUnplaceable() {
        var attempts = 0
        let maxAttempts = 72   // safety cap — well above the 11 nebula + 72 exploration tiles
        repeat {
            drawNextTile()
            attempts += 1
            guard let tile = currentTile else { break }   // deck exhausted → phase = .ended

            // A tile is keepable if ANY of its 4 rotations produces a valid placement.
            //
            // Nebula: the double-turn rule may reject all rotations geometrically;
            //         otherwise exactly one rotation aligns the entry correctly.
            // Exploration: standard edge-matching — any rotation that matches at least
            //         one empty cell is sufficient (player rotates to the right one).
            var anyValid = false
            for rot in 0..<4 {
                var t = tile; t.rotation = rot
                if !validPlacements(for: t).isEmpty { anyValid = true; break }
            }
            if anyValid { break }

            // No valid orientation at any rotation — silently discard and draw again
            currentTile = nil
        } while attempts < maxAttempts
    }

    // MARK: - Abbot / Mining Ship recall

    /// GridPositions where the current player has a colony or dilithium ship (recallable).
    var recallableTiles: [GridPosition] {
        guard phase == .exploration else { return [] }
        return placedTiles.compactMap { (pos, tile) -> GridPosition? in
            guard let ship = tile.placedShip,
                  ship.faction == currentPlayer.faction,
                  ship.feature == .colony || ship.feature == .dilithium else { return nil }
            return pos
        }
    }

    /// Recall a colony/dilithium ship: score it at its current value, return it to supply,
    /// and clear it from the board. Does NOT advance the turn.
    /// Returns the points awarded so the caller can emit a toast.
    @discardableResult
    mutating func recallShip(at pos: GridPosition) -> Int {
        guard var tile = placedTiles[pos],
              let ship = tile.placedShip,
              ship.faction == currentPlayer.faction,
              ship.feature == .colony || ship.feature == .dilithium else { return 0 }

        // Score at current board state (ship still present for monastery calculation)
        var scored = 0
        if let info = ScoringEngine.findMonastery(at: pos, in: self), !info.ships.isEmpty {
            scored = info.score()
            for faction in info.scoringFactions {
                if let i = players.firstIndex(where: { $0.faction == faction }) {
                    players[i].score += scored
                }
            }
        }

        // Return ship to supply
        if let i = players.firstIndex(where: { $0.faction == ship.faction }) {
            players[i].shipsRemaining += 1
        }
        tile.placedShip = nil
        placedTiles[pos] = tile
        return scored
    }

    // MARK: - Helpers

    var currentPlayer: Player { players[currentPlayerIndex] }
    var tilesRemaining: Int   { phase == .nebula ? nebulaDeck.count : deck.count }
}

// MARK: - GameState Codable

extension GameState: Codable {
    enum CodingKeys: String, CodingKey {
        case placedTiles, deck, nebulaDeck, currentTile, phase, currentPlayerIndex,
             players, awaitingShipPlacement, lastPlacedPos, lastNebulaPos,
             prevNebulaPos, prevNebulaMoveDir, nebulaPlaced, endGameScored
        // nebulaCount is a constant (12) — not encoded
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        // Encode [GridPosition: Tile] as [String: Tile] with keys "col_row"
        let tileDict = Dictionary(uniqueKeysWithValues:
            placedTiles.map { ("\($0.key.col)_\($0.key.row)", $0.value) })
        try c.encode(tileDict,                forKey: .placedTiles)
        try c.encode(deck,                    forKey: .deck)
        try c.encode(nebulaDeck,              forKey: .nebulaDeck)
        try c.encodeIfPresent(currentTile,    forKey: .currentTile)
        try c.encode(phase,                   forKey: .phase)
        try c.encode(currentPlayerIndex,      forKey: .currentPlayerIndex)
        try c.encode(players,                 forKey: .players)
        try c.encode(awaitingShipPlacement,   forKey: .awaitingShipPlacement)
        try c.encodeIfPresent(lastPlacedPos,  forKey: .lastPlacedPos)
        try c.encode(lastNebulaPos,           forKey: .lastNebulaPos)
        try c.encodeIfPresent(prevNebulaPos,  forKey: .prevNebulaPos)
        try c.encodeIfPresent(prevNebulaMoveDir, forKey: .prevNebulaMoveDir)
        try c.encode(nebulaPlaced,            forKey: .nebulaPlaced)
        try c.encode(endGameScored,           forKey: .endGameScored)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Decode [String: Tile] → [GridPosition: Tile] by splitting "col_row" key
        let tileDict = try c.decode([String: Tile].self, forKey: .placedTiles)
        placedTiles = Dictionary(uniqueKeysWithValues: tileDict.map { key, value in
            let parts = key.split(separator: "_", maxSplits: 1)
            let col   = Int(parts[0])!
            let row   = Int(parts[1])!
            return (GridPosition(col: col, row: row), value)
        })
        deck                  = try c.decode([Tile].self,            forKey: .deck)
        nebulaDeck            = try c.decode([Tile].self,            forKey: .nebulaDeck)
        currentTile           = try c.decodeIfPresent(Tile.self,     forKey: .currentTile)
        phase                 = try c.decode(GamePhase.self,         forKey: .phase)
        currentPlayerIndex    = try c.decode(Int.self,               forKey: .currentPlayerIndex)
        players               = try c.decode([Player].self,          forKey: .players)
        awaitingShipPlacement = try c.decode(Bool.self,              forKey: .awaitingShipPlacement)
        lastPlacedPos         = try c.decodeIfPresent(GridPosition.self, forKey: .lastPlacedPos)
        lastNebulaPos         = try c.decode(GridPosition.self,      forKey: .lastNebulaPos)
        prevNebulaPos         = try c.decodeIfPresent(GridPosition.self, forKey: .prevNebulaPos)
        prevNebulaMoveDir     = try c.decodeIfPresent(Direction.self, forKey: .prevNebulaMoveDir)
        nebulaPlaced          = try c.decode(Int.self,               forKey: .nebulaPlaced)
        endGameScored         = try c.decode(Bool.self,              forKey: .endGameScored)
        // nebulaCount is a `let` with default value 12 — initialized at declaration, not here
    }
}
