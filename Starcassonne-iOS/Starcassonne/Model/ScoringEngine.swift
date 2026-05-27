//
//  ScoringEngine.swift
//  Starcassonne
//
//  Stateless scoring logic. All methods take a GameState and return results;
//  GameState applies them (mutating).
//

import Foundation

// MARK: - Result types

struct SectorInfo {
    let tiles:     Set<GridPosition>
    let halfEdges: Set<HalfEdge>     // every (pos,dir) pair in this sector region
    let isComplete: Bool
    let ships:     [Faction: Int]    // faction → ship count in this sector
    let starbases: Int

    func score(complete: Bool) -> Int {
        let mul = complete ? 2 : 1
        return tiles.count * mul + starbases * mul
    }

    var scoringFactions: [Faction] {
        guard !ships.isEmpty else { return [] }
        let max = ships.values.max()!
        return ships.filter { $0.value == max }.map(\.key)
    }
}

struct CorridorInfo {
    let tiles:      Set<GridPosition>
    let isComplete: Bool
    let ships:      [Faction: Int]

    func score() -> Int { tiles.count }   // 1 pt/tile complete OR incomplete

    var scoringFactions: [Faction] {
        guard !ships.isEmpty else { return [] }
        let max = ships.values.max()!
        return ships.filter { $0.value == max }.map(\.key)
    }
}

struct MonasteryInfo {
    let tilePos:        GridPosition
    let isComplete:     Bool
    let surroundCount:  Int           // 0–8 occupied neighbor cells
    let ships:          [Faction: Int]

    func score() -> Int { 1 + surroundCount }

    var scoringFactions: [Faction] {
        guard !ships.isEmpty else { return [] }
        let max = ships.values.max()!
        return ships.filter { $0.value == max }.map(\.key)
    }
}

/// A single (tile position, edge direction) pair used for sector graph traversal.
struct HalfEdge: Hashable {
    let pos: GridPosition
    let dir: Direction
}

struct ScoreEvent {
    let feature:    PlacedFeature
    let points:     Int
    let factions:   [Faction]
    let clearTiles: Set<GridPosition>   // tiles whose ships should be returned
}

// MARK: - Engine

enum ScoringEngine {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Sector (City) graph traversal
    // ─────────────────────────────────────────────────────────────────────────

    static func findSector(at pos: GridPosition,
                            edgeDir: Direction,
                            in state: GameState) -> SectorInfo? {
        guard let tile = state.placedTiles[pos],
              tile.rotatedEdges.edge(facing: edgeDir) == .sector else { return nil }

        var visitedHE = Set<HalfEdge>()
        var queue     = [HalfEdge(pos: pos, dir: edgeDir)]
        var tiles     = Set<GridPosition>()
        var ships     = [Faction: Int]()
        var starbases = 0
        var isComplete = true

        while let current = queue.popLast() {
            guard !visitedHE.contains(current) else { continue }
            visitedHE.insert(current)

            guard let cur = state.placedTiles[current.pos] else {
                isComplete = false; continue
            }

            if tiles.insert(current.pos).inserted {
                if let ship = cur.placedShip, ship.feature == .sector {
                    // On a tile with multiple separate sectors, only count the ship if its
                    // stored edgeDir belongs to the same sector group as the edge we arrived on.
                    let grps = cur.rotatedSectorGroups
                    let shipBelongsHere: Bool
                    if let shipDir = ship.edgeDir, !grps.isEmpty {
                        let shipGrp = grps.first(where: { $0.contains(shipDir) })
                        let curGrp  = grps.first(where: { $0.contains(current.dir) })
                        // Count if both groups can be determined and they match.
                        // If either is nil (data inconsistency), count the ship as a safe
                        // fallback — better to over-count than silently drop a meeple.
                        shipBelongsHere = shipGrp == nil || curGrp == nil || shipGrp == curGrp
                    } else {
                        // No edgeDir stored (single-sector tile or legacy data) — always count.
                        shipBelongsHere = true
                    }
                    if shipBelongsHere { ships[ship.faction, default: 0] += 1 }
                }
                if cur.features.contains(.starbase) { starbases += 1 }
            }

            // Find all edges in the same sectorGroup as current.dir
            let grps  = cur.rotatedSectorGroups
            let myGrp = grps.first { $0.contains(current.dir) } ?? [current.dir]

            for edDir in myGrp {
                // Expand within same tile (other edges in same group)
                let he = HalfEdge(pos: current.pos, dir: edDir)
                if !visitedHE.contains(he) { queue.append(he) }

                // Expand outward to the neighbouring tile
                let nPos = current.pos.neighbor(in: edDir)
                let nHE  = HalfEdge(pos: nPos, dir: edDir.opposite)
                if !visitedHE.contains(nHE) {
                    if let nTile = state.placedTiles[nPos],
                       nTile.rotatedEdges.edge(facing: edDir.opposite) == .sector {
                        queue.append(nHE)
                    } else if state.placedTiles[nPos] == nil {
                        isComplete = false
                        visitedHE.insert(nHE)   // don't revisit this open edge
                    }
                }
            }
        }

        return SectorInfo(tiles: tiles, halfEdges: visitedHE,
                          isComplete: isComplete, ships: ships, starbases: starbases)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Corridor (Road) traversal
    // ─────────────────────────────────────────────────────────────────────────

    static func findCorridor(at pos: GridPosition,
                              edgeDir: Direction,
                              in state: GameState) -> CorridorInfo? {
        guard let tile = state.placedTiles[pos],
              tile.rotatedEdges.edge(facing: edgeDir) == .warpCorridor else { return nil }

        var visited = Set<GridPosition>([pos])
        var tiles   = Set<GridPosition>([pos])
        var ships   = [Faction: Int]()
        var isComplete = true

        if let ship = tile.placedShip, ship.feature == .warpCorridor {
            ships[ship.faction, default: 0] += 1
        }

        // Follow outward (in edgeDir)
        let r1 = followCorridor(from: pos, exitDir: edgeDir, visited: &visited, in: state)
        tiles.formUnion(r1.tiles); r1.ships.forEach { ships[$0, default: 0] += $1 }
        if !r1.terminates { isComplete = false }

        // Follow in the opposite direction (through the tile's other corridor exit)
        if let otherExit = tile.corridorExit(entering: edgeDir) {
            let r2 = followCorridor(from: pos, exitDir: otherExit, visited: &visited, in: state)
            tiles.formUnion(r2.tiles); r2.ships.forEach { ships[$0, default: 0] += $1 }
            if !r2.terminates { isComplete = false }
        }
        // corridorExit == nil → dead-end or crossroads here → terminates

        return CorridorInfo(tiles: tiles, isComplete: isComplete, ships: ships)
    }

    private static func followCorridor(from startPos: GridPosition,
                                        exitDir: Direction,
                                        visited: inout Set<GridPosition>,
                                        in state: GameState)
        -> (tiles: Set<GridPosition>, ships: [Faction: Int], terminates: Bool)
    {
        let nPos = startPos.neighbor(in: exitDir)
        if visited.contains(nPos) { return ([], [:], true) }   // cycle → terminates

        guard let nTile = state.placedTiles[nPos] else { return ([], [:], false) }  // open end
        let enterDir = exitDir.opposite
        guard nTile.rotatedEdges.edge(facing: enterDir) == .warpCorridor else {
            return ([], [:], true)   // hit a non-corridor (city edge etc.) → terminates
        }

        visited.insert(nPos)
        var tiles = Set<GridPosition>([nPos])
        var ships = [Faction: Int]()
        if let ship = nTile.placedShip, ship.feature == .warpCorridor {
            ships[ship.faction, default: 0] += 1
        }

        if let nextExit = nTile.corridorExit(entering: enterDir) {
            let r = followCorridor(from: nPos, exitDir: nextExit, visited: &visited, in: state)
            tiles.formUnion(r.tiles); r.ships.forEach { ships[$0, default: 0] += $1 }
            return (tiles, ships, r.terminates)
        } else {
            return (tiles, ships, true)   // dead-end or crossroads
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Monastery / Colony / Dilithium
    // ─────────────────────────────────────────────────────────────────────────

    static func findMonastery(at pos: GridPosition, in state: GameState) -> MonasteryInfo? {
        guard let tile = state.placedTiles[pos],
              tile.features.contains(.colony) || tile.features.contains(.dilithiumAsteroid)
        else { return nil }

        let ring: [GridPosition] = [
            GridPosition(col: pos.col-1, row: pos.row-1),
            GridPosition(col: pos.col,   row: pos.row-1),
            GridPosition(col: pos.col+1, row: pos.row-1),
            GridPosition(col: pos.col-1, row: pos.row),
            GridPosition(col: pos.col+1, row: pos.row),
            GridPosition(col: pos.col-1, row: pos.row+1),
            GridPosition(col: pos.col,   row: pos.row+1),
            GridPosition(col: pos.col+1, row: pos.row+1),
        ]
        let surroundCount = ring.filter { state.placedTiles[$0] != nil }.count

        var ships = [Faction: Int]()
        let feat: PlacedFeature = tile.features.contains(.colony) ? .colony : .dilithium
        if let ship = tile.placedShip, ship.feature == feat {
            ships[ship.faction, default: 0] += 1
        }

        return MonasteryInfo(tilePos: pos,
                             isComplete: surroundCount == 8,
                             surroundCount: surroundCount,
                             ships: ships)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Feature occupation check (for ship placement gating)
    // ─────────────────────────────────────────────────────────────────────────

    /// Returns true if any ship already occupies the connected feature region at (pos, edgeDir).
    static func isOccupied(at pos: GridPosition,
                            edgeDir: Direction,
                            feature: PlacedFeature,
                            in state: GameState) -> Bool {
        switch feature {
        case .sector:
            return findSector(at: pos, edgeDir: edgeDir, in: state)?.ships.isEmpty == false
        case .warpCorridor:
            return findCorridor(at: pos, edgeDir: edgeDir, in: state)?.ships.isEmpty == false
        case .colony:
            return state.placedTiles[pos]?.placedShip?.feature == .colony
        case .dilithium:
            return state.placedTiles[pos]?.placedShip?.feature == .dilithium
        case .openSpace:
            return false   // Traders (farmers) compete; multiple are allowed in a field
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Post-placement completion check
    // ─────────────────────────────────────────────────────────────────────────

    /// After a tile is placed at `pos`, finds all features that are NOW complete.
    /// Returns ScoreEvents ready to be applied (points + ship-return tile sets).
    static func findCompletedFeatures(at pos: GridPosition,
                                       in state: GameState) -> [ScoreEvent] {
        var results = [ScoreEvent]()
        // Check pos plus all immediate neighbours — placing at pos may close gaps
        // on adjacent tiles' features too.
        let posToCheck = [pos] + pos.neighbors

        // ── Sectors ──────────────────────────────────────────────────────────
        var processedSectorHEs = Set<HalfEdge>()
        for checkPos in posToCheck {
            guard let ct = state.placedTiles[checkPos] else { continue }
            let cEdges  = ct.rotatedEdges
            let cStream = ct.streamEdges
            for dir in Direction.allCases
                where cEdges.edge(facing: dir) == .sector && !cStream.contains(dir) {
                let he = HalfEdge(pos: checkPos, dir: dir)
                guard !processedSectorHEs.contains(he) else { continue }
                if let info = findSector(at: checkPos, edgeDir: dir, in: state) {
                    processedSectorHEs.formUnion(info.halfEdges)
                    if info.isComplete && !info.ships.isEmpty {
                        results.append(ScoreEvent(
                            feature:    .sector,
                            points:     info.score(complete: true),
                            factions:   info.scoringFactions,
                            clearTiles: info.tiles
                        ))
                    }
                }
            }
        }

        // ── Corridors ────────────────────────────────────────────────────────
        // Bug-fix: we must mark ALL corridor half-edges across ALL tiles in the
        // discovered corridor, not just the 1–2 edges on the tile we started from.
        // Without this a 4-tile road discovered from 2 adjacent tiles in posToCheck
        // would be scored twice, awarding double points.
        var processedCorridorHEs = Set<HalfEdge>()
        for checkPos in posToCheck {
            guard let ct = state.placedTiles[checkPos] else { continue }
            let cEdges  = ct.rotatedEdges
            let cStream = ct.streamEdges
            for dir in Direction.allCases
                where cEdges.edge(facing: dir) == .warpCorridor && !cStream.contains(dir) {
                let he = HalfEdge(pos: checkPos, dir: dir)
                guard !processedCorridorHEs.contains(he) else { continue }
                if let info = findCorridor(at: checkPos, edgeDir: dir, in: state) {
                    // Mark every corridor half-edge in every tile of this corridor.
                    for tilePos in info.tiles {
                        if let t = state.placedTiles[tilePos] {
                            let tStream = t.streamEdges
                            for d in Direction.allCases
                                where t.rotatedEdges.edge(facing: d) == .warpCorridor
                                   && !tStream.contains(d) {
                                processedCorridorHEs.insert(HalfEdge(pos: tilePos, dir: d))
                            }
                        }
                    }
                    if info.isComplete && !info.ships.isEmpty {
                        results.append(ScoreEvent(
                            feature:    .warpCorridor,
                            points:     info.score(),
                            factions:   info.scoringFactions,
                            clearTiles: info.tiles
                        ))
                    }
                }
            }
        }

        // ── Monasteries ──────────────────────────────────────────────────────
        // The placed tile plus its 8 ring neighbours could newly complete a monastery.
        let monasteryPositions: [GridPosition] = [pos,
            GridPosition(col: pos.col-1, row: pos.row-1),
            GridPosition(col: pos.col,   row: pos.row-1),
            GridPosition(col: pos.col+1, row: pos.row-1),
            GridPosition(col: pos.col-1, row: pos.row),
            GridPosition(col: pos.col+1, row: pos.row),
            GridPosition(col: pos.col-1, row: pos.row+1),
            GridPosition(col: pos.col,   row: pos.row+1),
            GridPosition(col: pos.col+1, row: pos.row+1),
        ]
        for mPos in monasteryPositions {
            guard let mTile = state.placedTiles[mPos],
                  mTile.features.contains(.colony) || mTile.features.contains(.dilithiumAsteroid),
                  let info = findMonastery(at: mPos, in: state),
                  info.isComplete, !info.ships.isEmpty else { continue }
            let feat: PlacedFeature = mTile.features.contains(.colony) ? .colony : .dilithium
            results.append(ScoreEvent(
                feature:    feat,
                points:     info.score(),
                factions:   info.scoringFactions,
                clearTiles: [mPos]
            ))
        }

        return results
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: End-game scoring
    // ─────────────────────────────────────────────────────────────────────────

    /// Score all remaining incomplete features at end-of-game rates.
    /// Also scores Traders (field ships). Returns events to apply.
    static func scoreEndGame(in state: GameState) -> [ScoreEvent] {
        var results = [ScoreEvent]()
        var processedSectorHEs  = Set<HalfEdge>()
        var processedCorridorHEs = Set<HalfEdge>()
        var processedMonasteries = Set<GridPosition>()

        for (pos, tile) in state.placedTiles {
            let edges  = tile.rotatedEdges
            let stream = tile.streamEdges

            // Incomplete sectors (1pt/tile + 1pt/starbase)
            for dir in Direction.allCases where edges.edge(facing: dir) == .sector && !stream.contains(dir) {
                let he = HalfEdge(pos: pos, dir: dir)
                guard !processedSectorHEs.contains(he) else { continue }
                if let info = findSector(at: pos, edgeDir: dir, in: state) {
                    processedSectorHEs.formUnion(info.halfEdges)
                    if !info.ships.isEmpty {
                        results.append(ScoreEvent(
                            feature:    .sector,
                            points:     info.score(complete: false),
                            factions:   info.scoringFactions,
                            clearTiles: info.tiles
                        ))
                    }
                }
            }

            // Incomplete corridors (1pt/tile — same as complete)
            for dir in Direction.allCases where edges.edge(facing: dir) == .warpCorridor && !stream.contains(dir) {
                let he = HalfEdge(pos: pos, dir: dir)
                guard !processedCorridorHEs.contains(he) else { continue }
                if let info = findCorridor(at: pos, edgeDir: dir, in: state) {
                    // Mark ALL corridor edges across ALL tiles so each corridor is scored once.
                    for tilePos in info.tiles {
                        if let t = state.placedTiles[tilePos] {
                            let tStream = t.streamEdges
                            for d in Direction.allCases
                                where t.rotatedEdges.edge(facing: d) == .warpCorridor
                                   && !tStream.contains(d) {
                                processedCorridorHEs.insert(HalfEdge(pos: tilePos, dir: d))
                            }
                        }
                    }
                    if !info.ships.isEmpty {
                        results.append(ScoreEvent(
                            feature:    .warpCorridor,
                            points:     info.score(),
                            factions:   info.scoringFactions,
                            clearTiles: info.tiles
                        ))
                    }
                }
            }

            // Incomplete monasteries (1pt per placed tile in 3×3)
            if (tile.features.contains(.colony) || tile.features.contains(.dilithiumAsteroid)),
               !processedMonasteries.contains(pos) {
                processedMonasteries.insert(pos)
                if let info = findMonastery(at: pos, in: state), !info.ships.isEmpty {
                    let feat: PlacedFeature = tile.features.contains(.colony) ? .colony : .dilithium
                    results.append(ScoreEvent(
                        feature:    feat,
                        points:     info.score(),
                        factions:   info.scoringFactions,
                        clearTiles: [pos]
                    ))
                }
            }
        }

        // Trader (field) scoring
        results.append(contentsOf: scoreTraders(in: state))

        return results
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Trader (Farmer / Field) scoring
    // ─────────────────────────────────────────────────────────────────────────

    private static func scoreTraders(in state: GameState) -> [ScoreEvent] {
        // 1. Find all COMPLETED sector tile sets
        var completedSectorGroups: [Set<GridPosition>] = []
        var processedHEs = Set<HalfEdge>()
        for (pos, tile) in state.placedTiles {
            for dir in Direction.allCases where tile.rotatedEdges.edge(facing: dir) == .sector {
                let he = HalfEdge(pos: pos, dir: dir)
                guard !processedHEs.contains(he) else { continue }
                if let info = findSector(at: pos, edgeDir: dir, in: state), info.isComplete {
                    processedHEs.formUnion(info.halfEdges)
                    completedSectorGroups.append(info.tiles)
                }
            }
        }

        // 2. BFS to group tiles into field regions (connected through openSpace edges)
        var visited = Set<GridPosition>()
        var fieldRegions: [(tiles: Set<GridPosition>, traders: [Faction: Int])] = []

        for startPos in state.placedTiles.keys {
            guard !visited.contains(startPos) else { continue }

            var regionTiles = Set<GridPosition>()
            var traders     = [Faction: Int]()
            var queue       = [startPos]
            var bfsSeen     = Set<GridPosition>()

            while !queue.isEmpty {
                let cur = queue.removeFirst()
                guard !bfsSeen.contains(cur), state.placedTiles[cur] != nil else { continue }
                bfsSeen.insert(cur)
                regionTiles.insert(cur)

                if let ship = state.placedTiles[cur]?.placedShip, ship.feature == .openSpace {
                    traders[ship.faction, default: 0] += 1
                }

                // Expand only through openSpace edges (roads & rivers break fields apart)
                for dir in Direction.allCases {
                    guard let ct = state.placedTiles[cur],
                          ct.rotatedEdges.edge(facing: dir) == .openSpace,
                          !ct.streamEdges.contains(dir) else { continue }
                    let nPos = cur.neighbor(in: dir)
                    if let nt = state.placedTiles[nPos],
                       nt.rotatedEdges.edge(facing: dir.opposite) == .openSpace,
                       !bfsSeen.contains(nPos) {
                        queue.append(nPos)
                    }
                }
            }

            visited.formUnion(regionTiles)
            guard !traders.isEmpty else { continue }
            fieldRegions.append((tiles: regionTiles, traders: traders))
        }

        // 3. For each field region, count distinct adjacent completed sectors → 3pts each
        var results = [ScoreEvent]()
        for region in fieldRegions {
            // Find which completed sector groups border this region
            var adjacentSectorGroups = Set<Int>()   // index into completedSectorGroups
            for rPos in region.tiles {
                for dir in Direction.allCases {
                    let nPos = rPos.neighbor(in: dir)
                    for (idx, sectorTiles) in completedSectorGroups.enumerated() {
                        if sectorTiles.contains(nPos) { adjacentSectorGroups.insert(idx) }
                    }
                }
            }

            let pts = adjacentSectorGroups.count * 3
            guard pts > 0 else { continue }

            let maxTraders = region.traders.values.max()!
            let winners    = region.traders.filter { $0.value == maxTraders }.map(\.key)
            results.append(ScoreEvent(
                feature:    .openSpace,
                points:     pts,
                factions:   winners,
                clearTiles: []    // Traders don't return mid-game; kept for display
            ))
        }

        return results
    }
}
