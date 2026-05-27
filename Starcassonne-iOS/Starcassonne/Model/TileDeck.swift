//
//  TileDeck.swift
//  Starcassonne
//
//  All 24 tile types. Edges described N/E/S/W.
//  sectorGroups: which edges form the SAME connected sector.
//

import Foundation

struct TileDef {
    let type: TileType
    let edges: TileEdges
    let features: Set<TileFeature>
    let sectorGroups: [[Direction]]   // each sub-array = one connected sector's edges
    let count: Int
}

struct TileDeck {

    static let definitions: [TileDef] = [

        // ── Colonies (Monasteries) ───────────────────────────────────────────

        // A: Colony only, all-field
        TileDef(type: .A,
                edges: TileEdges(north: .openSpace, east: .openSpace, south: .openSpace, west: .openSpace),
                features: [.colony], sectorGroups: [], count: 4),

        // B: Colony + warp corridor south
        TileDef(type: .B,
                edges: TileEdges(north: .openSpace, east: .openSpace, south: .warpCorridor, west: .openSpace),
                features: [.colony], sectorGroups: [], count: 2),

        // ── Full / 3-sided Sectors ────────────────────────────────────────────

        // C: All four sides sector, connected, with starbase
        TileDef(type: .C,
                edges: TileEdges(north: .sector, east: .sector, south: .sector, west: .sector),
                features: [.starbase], sectorGroups: [[.north,.east,.south,.west]], count: 1),

        // Q: Three-sided sector N+E+W connected, field S, with starbase
        TileDef(type: .Q,
                edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .sector),
                features: [.starbase], sectorGroups: [[.north,.east,.west]], count: 1),

        // R: Three-sided sector N+E+W connected, field S
        TileDef(type: .R,
                edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .sector),
                features: [], sectorGroups: [[.north,.east,.west]], count: 3),

        // S: Three-sided sector N+E+W + warp corridor S, with starbase
        TileDef(type: .S,
                edges: TileEdges(north: .sector, east: .sector, south: .warpCorridor, west: .sector),
                features: [.starbase], sectorGroups: [[.north,.east,.west]], count: 2),

        // T: Three-sided sector N+E+W + warp corridor S
        TileDef(type: .T,
                edges: TileEdges(north: .sector, east: .sector, south: .warpCorridor, west: .sector),
                features: [], sectorGroups: [[.north,.east,.west]], count: 1),

        // ── Two opposite Sectors (connected through) ──────────────────────────

        // F: E+W connected sector, field N+S, with starbase
        TileDef(type: .F,
                edges: TileEdges(north: .openSpace, east: .sector, south: .openSpace, west: .sector),
                features: [.starbase], sectorGroups: [[.east,.west]], count: 2),

        // G: E+W connected sector, field N+S
        TileDef(type: .G,
                edges: TileEdges(north: .openSpace, east: .sector, south: .openSpace, west: .sector),
                features: [], sectorGroups: [[.east,.west]], count: 1),

        // ── Two adjacent Sectors (connected) ──────────────────────────────────

        // M: N+E connected, field S+W, with starbase
        TileDef(type: .M,
                edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .openSpace),
                features: [.starbase], sectorGroups: [[.north,.east]], count: 2),

        // N: N+E connected, field S+W
        TileDef(type: .N,
                edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .openSpace),
                features: [], sectorGroups: [[.north,.east]], count: 3),

        // O: N+E connected + corridor S, field W, with starbase
        TileDef(type: .O,
                edges: TileEdges(north: .sector, east: .sector, south: .warpCorridor, west: .openSpace),
                features: [.starbase], sectorGroups: [[.north,.east]], count: 2),

        // P: N+E connected + corridor S, field W
        TileDef(type: .P,
                edges: TileEdges(north: .sector, east: .sector, south: .warpCorridor, west: .openSpace),
                features: [], sectorGroups: [[.north,.east]], count: 3),

        // ── Two SEPARATE (disconnected) Sectors ───────────────────────────────

        // H: N sector + S sector, separate. Field E+W.
        TileDef(type: .H,
                edges: TileEdges(north: .sector, east: .openSpace, south: .sector, west: .openSpace),
                features: [], sectorGroups: [[.north],[.south]], count: 3),

        // I: N sector + E sector, separate. Field S+W.
        TileDef(type: .I,
                edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .openSpace),
                features: [], sectorGroups: [[.north],[.east]], count: 2),

        // ── Single Sector ─────────────────────────────────────────────────────

        // E: North sector only, field E+S+W
        TileDef(type: .E,
                edges: TileEdges(north: .sector, east: .openSpace, south: .openSpace, west: .openSpace),
                features: [], sectorGroups: [[.north]], count: 5),

        // D: North sector + straight corridor E–W, field S
        //    (the standard starting tile)
        TileDef(type: .D,
                edges: TileEdges(north: .sector, east: .warpCorridor, south: .openSpace, west: .warpCorridor),
                features: [], sectorGroups: [[.north]], count: 4),

        // J: North sector + corridor bend E→S, field W
        TileDef(type: .J,
                edges: TileEdges(north: .sector, east: .warpCorridor, south: .warpCorridor, west: .openSpace),
                features: [], sectorGroups: [[.north]], count: 3),

        // K: North sector + corridor bend S→W, field E
        TileDef(type: .K,
                edges: TileEdges(north: .sector, east: .openSpace, south: .warpCorridor, west: .warpCorridor),
                features: [], sectorGroups: [[.north]], count: 3),

        // L: North sector + 3-way corridor junction E/S/W
        TileDef(type: .L,
                edges: TileEdges(north: .sector, east: .warpCorridor, south: .warpCorridor, west: .warpCorridor),
                features: [], sectorGroups: [[.north]], count: 3),

        // ── Warp Corridor only ────────────────────────────────────────────────

        // U: Straight corridor N–S, field E+W
        TileDef(type: .U,
                edges: TileEdges(north: .warpCorridor, east: .openSpace, south: .warpCorridor, west: .openSpace),
                features: [], sectorGroups: [], count: 8),

        // V: Corridor bend W→S, field N+E
        TileDef(type: .V,
                edges: TileEdges(north: .openSpace, east: .openSpace, south: .warpCorridor, west: .warpCorridor),
                features: [], sectorGroups: [], count: 9),

        // W: Three-way junction E/S/W, field N
        TileDef(type: .W,
                edges: TileEdges(north: .openSpace, east: .warpCorridor, south: .warpCorridor, west: .warpCorridor),
                features: [], sectorGroups: [], count: 4),

        // X: Four-way junction N/E/S/W
        TileDef(type: .X,
                edges: TileEdges(north: .warpCorridor, east: .warpCorridor, south: .warpCorridor, west: .warpCorridor),
                features: [], sectorGroups: [], count: 1),
    ]

    // MARK: - Deck builder

    static func makeDeck() -> [Tile] {
        var deck: [Tile] = []
        for def in definitions {
            for _ in 0..<def.count {
                deck.append(Tile(type: def.type,
                                 edges: def.edges,
                                 features: def.features,
                                 sectorGroups: def.sectorGroups))
            }
        }
        return deck.shuffled()
    }

    static var totalCount: Int { definitions.reduce(0) { $0 + $1.count } }
}
