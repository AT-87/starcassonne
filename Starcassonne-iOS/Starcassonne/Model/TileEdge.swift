//
//  TileEdge.swift
//  Starcassonne
//

/// The type of feature on a single edge of a tile (N/E/S/W)
enum TileEdge: String, Codable, CaseIterable {
    case sector       // City equivalent — enclosed star system
    case warpCorridor // Road equivalent — hyperspace lane
    case openSpace    // Field/Meadow equivalent — unclaimed void
}
