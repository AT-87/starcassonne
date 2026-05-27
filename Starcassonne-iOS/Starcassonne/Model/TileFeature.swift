//
//  TileFeature.swift
//  Starcassonne
//

/// Special features a tile can contain beyond its edges
enum TileFeature: String, Codable, CaseIterable {
    case colony            // Monastery — isolated inhabited world, scores by surrounding tiles
    case dilithiumAsteroid // Garden — rare resource field, only claimable by Mining Ship
    case starbase          // Pennant — built within a Sector, increases its scoring value
    case nebula            // River — shapes the initial board layout only (setup tiles)
}
