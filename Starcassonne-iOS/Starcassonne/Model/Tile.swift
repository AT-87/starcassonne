//
//  Tile.swift
//  Starcassonne
//

import Foundation

struct TileEdges: Codable {
    var north: TileEdge
    var east:  TileEdge
    var south: TileEdge
    var west:  TileEdge

    func rotated(steps: Int) -> TileEdges {
        var e = self
        for _ in 0..<(steps % 4) {
            e = TileEdges(north: e.west, east: e.north, south: e.east, west: e.south)
        }
        return e
    }

    func edge(facing dir: Direction) -> TileEdge {
        switch dir {
        case .north: return north
        case .east:  return east
        case .south: return south
        case .west:  return west
        }
    }
}

enum TileType: String, Codable, CaseIterable {
    case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X
}

struct Tile: Identifiable, Codable {
    let id: UUID
    let type: TileType
    var edges: TileEdges
    var features: Set<TileFeature>

    /// Which edge groups form a single connected sector.
    /// e.g. [[.north, .east]] means N and E are the same city.
    /// [[.north], [.south]] means N and S are separate cities.
    var sectorGroups: [[Direction]]

    var rotation: Int       // 0–3 clockwise 90° steps
    var isNebula: Bool

    /// The direction the nebula stream ENTERS this tile in its base (0°) orientation.
    /// nil for the Source tile (stream starts here, no entry).
    /// Rotate with the tile using rotatedNebulaEntry.
    var nebulaEntry: Direction? = nil
    /// The direction the nebula stream EXITS this tile in its base (0°) orientation.
    /// nil for the Lake tile (stream ends here, no exit).
    /// Rotate with the tile using rotatedNebulaExit.
    var nebulaExit: Direction? = nil

    /// Ship placed on this tile: faction, feature type, and the specific edge direction
    /// the ship was placed on (used to disambiguate which sector/corridor on multi-feature tiles).
    /// `edgeDir` is nil for colony, dilithium, and open-space placements.
    var placedShip: (faction: Faction, feature: PlacedFeature, edgeDir: Direction?)?

    init(type: TileType,
         edges: TileEdges,
         features: Set<TileFeature> = [],
         sectorGroups: [[Direction]] = [],
         isNebula: Bool = false,
         nebulaEntry: Direction? = nil,
         nebulaExit: Direction? = nil)
    {
        self.id           = UUID()
        self.type         = type
        self.edges        = edges
        self.features     = features
        self.sectorGroups = sectorGroups
        self.rotation     = 0
        self.isNebula     = isNebula
        self.nebulaEntry  = nebulaEntry
        self.nebulaExit   = nebulaExit
        self.placedShip   = nil
    }

    var rotatedEdges: TileEdges { edges.rotated(steps: rotation) }

    /// Stream entry direction adjusted for current tile rotation.
    var rotatedNebulaEntry: Direction? {
        nebulaEntry.map { rotateDir($0, steps: rotation) }
    }

    /// Stream exit direction adjusted for current tile rotation.
    var rotatedNebulaExit: Direction? {
        nebulaExit.map { rotateDir($0, steps: rotation) }
    }

    /// The set of edges that carry the stream (0, 1, or 2 edges).
    /// Terrain features should never be drawn on these edges.
    var streamEdges: Set<Direction> {
        var s = Set<Direction>()
        if let e = rotatedNebulaEntry { s.insert(e) }
        if let x = rotatedNebulaExit  { s.insert(x) }
        return s
    }

    /// Sector groups adjusted for current rotation
    var rotatedSectorGroups: [[Direction]] {
        sectorGroups.map { group in
            group.map { dir in
                var d = dir
                for _ in 0..<rotation { d = d.rotatedCW }
                return d
            }
        }
    }

    mutating func rotateClockwise() {
        rotation = (rotation + 1) % 4
    }

    // Rotate a direction N steps clockwise
    private func rotateDir(_ dir: Direction, steps: Int) -> Direction {
        var d = dir
        for _ in 0..<(steps % 4) { d = d.rotatedCW }
        return d
    }

    /// Road traversal: given the Warp Corridor ENTERS this tile from `entryDir`,
    /// returns the direction it exits — or nil if this is a dead-end or Space Outpost (crossroads).
    ///
    /// Rules:
    ///  - 1 corridor edge  → dead-end cap → nil
    ///  - 2 corridor edges → exit through the OTHER edge
    ///  - 3+ corridor edges → Space Outpost / crossroads → nil (each arm terminates here)
    func corridorExit(entering entryDir: Direction) -> Direction? {
        let edges = rotatedEdges
        guard edges.edge(facing: entryDir) == .warpCorridor else { return nil }
        let corridorEdges = Direction.allCases.filter { edges.edge(facing: $0) == .warpCorridor }
        guard corridorEdges.count == 2 else { return nil }   // dead-end or crossroads
        return corridorEdges.first { $0 != entryDir }
    }
}

/// What feature a ship is occupying on a tile
enum PlacedFeature: String, Codable {
    case sector       // city
    case warpCorridor // road
    case colony       // monastery — regular ship (not recallable)
    case miningShip   // abbot on monastery OR any claim on dilithium (recallable)
    case openSpace    // field (farmer)
    case dilithium    // garden — Mining Ship only (recallable)
}

// MARK: - Codable conformance for placedShip tuple
extension Tile {
    enum CodingKeys: String, CodingKey {
        case id, type, edges, features, sectorGroups, rotation, isNebula
        case nebulaEntry, nebulaExit
        case placedShipFaction, placedShipFeature, placedShipEdgeDir
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self,            forKey: .id)
        type         = try c.decode(TileType.self,        forKey: .type)
        edges        = try c.decode(TileEdges.self,       forKey: .edges)
        features     = try c.decode(Set<TileFeature>.self,forKey: .features)
        sectorGroups = try c.decode([[Direction]].self,   forKey: .sectorGroups)
        rotation     = try c.decode(Int.self,             forKey: .rotation)
        isNebula     = try c.decode(Bool.self,            forKey: .isNebula)
        nebulaEntry  = try c.decodeIfPresent(Direction.self, forKey: .nebulaEntry)
        nebulaExit   = try c.decodeIfPresent(Direction.self, forKey: .nebulaExit)
        let faction  = try c.decodeIfPresent(Faction.self,        forKey: .placedShipFaction)
        let feature  = try c.decodeIfPresent(PlacedFeature.self,  forKey: .placedShipFeature)
        let edgeDir  = try c.decodeIfPresent(Direction.self,      forKey: .placedShipEdgeDir)
        placedShip   = (faction != nil && feature != nil) ? (faction!, feature!, edgeDir) : nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,           forKey: .id)
        try c.encode(type,         forKey: .type)
        try c.encode(edges,        forKey: .edges)
        try c.encode(features,     forKey: .features)
        try c.encode(sectorGroups, forKey: .sectorGroups)
        try c.encode(rotation,     forKey: .rotation)
        try c.encode(isNebula,     forKey: .isNebula)
        try c.encodeIfPresent(nebulaEntry, forKey: .nebulaEntry)
        try c.encodeIfPresent(nebulaExit,  forKey: .nebulaExit)
        try c.encodeIfPresent(placedShip?.faction, forKey: .placedShipFaction)
        try c.encodeIfPresent(placedShip?.feature, forKey: .placedShipFeature)
        try c.encodeIfPresent(placedShip?.edgeDir, forKey: .placedShipEdgeDir)
    }
}

extension TileFeature: Hashable {}
