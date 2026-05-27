//
//  BoardView.swift
//  Starcassonne
//

import SwiftUI

struct BoardView: View {
    var vm: GameViewModel

    let tileSize: CGFloat = 90
    let gap: CGFloat      = 2

    // Item 1: animated faction glow pulse
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Subtle starscape background across the whole board
            StarscapeView()

            ScrollView([.horizontal, .vertical]) {
                let bounds = vm.boardBounds
                let cols   = bounds.minCol...bounds.maxCol
                let rows   = bounds.minRow...bounds.maxRow
                let stride = tileSize + gap

                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(
                            width:  CGFloat(cols.count) * stride,
                            height: CGFloat(rows.count) * stride
                        )

                    ForEach(rows, id: \.self) { row in
                        ForEach(cols, id: \.self) { col in
                            let pos     = GridPosition(col: col, row: row)
                            let x       = CGFloat(col - bounds.minCol) * stride
                            let y       = CGFloat(row - bounds.minRow) * stride
                            let isValid = vm.validPlacements.contains(pos)

                            if let tile = vm.gameState.placedTiles[pos] {
                                ZStack {
                                    TileView(tile: tile, size: tileSize)

                                    // Ship overlay positioned on its feature region
                                    if let ship = tile.placedShip {
                                        ShipOverlay(
                                            ship: ship,
                                            tile: tile,
                                            size: tileSize
                                        )
                                    }
                                }
                                .position(x: x + tileSize/2, y: y + tileSize/2)

                            } else if isValid && !vm.awaitingShip {
                                // Valid slot — tap immediately places the tile
                                Button {
                                    LCARSAudio.shared.placement()
                                    vm.selectPosition(pos)
                                } label: {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(
                                            vm.phase == .nebula
                                                ? Color.purple.opacity(0.7)
                                                : Color.cyan.opacity(0.7),
                                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                                        )
                                        .background(Color.clear)
                                        .frame(width: tileSize, height: tileSize)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .foregroundStyle(
                                                    vm.phase == .nebula
                                                        ? .purple.opacity(0.6)
                                                        : .cyan.opacity(0.6)
                                                )
                                                .font(.title2)
                                        }
                                }
                                .position(x: x + tileSize/2, y: y + tileSize/2)
                            }
                        }
                    }
                }
                .frame(
                    width:  CGFloat(cols.count) * stride,
                    height: CGFloat(rows.count) * stride
                )
            }

            // Item 1: Faction glow border — pulses with current player's faction color
            Rectangle()
                .strokeBorder(
                    vm.gameState.currentPlayer.faction.color
                        .opacity(glowPulse ? 0.75 : 0.45),
                    lineWidth: 3
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .onChange(of: vm.gameState.currentPlayerIndex) { _, _ in
            // Reset pulse so color snaps to new faction then restarts smoothly
            glowPulse = false
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .onChange(of: vm.awaitingShip) { _, awaiting in
            // Clear stale preview when ship placement begins
            if awaiting { previewPos = nil }
        }
    }
}

// MARK: - Ship Overlay

/// Positions a small ship symbol on the correct feature region of a tile
struct ShipOverlay: View {
    let ship: (faction: Faction, feature: PlacedFeature, edgeDir: Direction?)
    let tile: Tile
    let size: CGFloat

    var body: some View {
        // Use a ZStack framed to tile size so position() coords are local
        ZStack {
            Color.clear
            Text(ship.faction.shipSymbol)
                .font(.system(size: size * 0.19))
                .foregroundStyle(ship.faction.color)
                .shadow(color: ship.faction.color, radius: 3)
                .shadow(color: .black, radius: 1)
                .position(shipPosition(s: size))
        }
        .frame(width: size, height: size)
        .clipped()
    }

    private func shipPosition(s: CGFloat) -> CGPoint {
        let mid      = s / 2
        // Sector band: 30% deep, so center of band = 15% from edge
        let bandMid  = s * 0.15

        switch ship.feature {
        case .sector:
            // Item 6: use ship.edgeDir as authoritative sector direction
            // (fixes H/I tiles where two independent sectors exist)
            let dir: Direction
            if let d = ship.edgeDir {
                dir = d
            } else {
                // Fallback: scan edges in priority order (shouldn't happen in practice)
                let e = tile.rotatedEdges
                if      e.north == .sector { dir = .north }
                else if e.east  == .sector { dir = .east  }
                else if e.south == .sector { dir = .south }
                else if e.west  == .sector { dir = .west  }
                else { return CGPoint(x: mid, y: mid) }
            }
            switch dir {
            case .north: return CGPoint(x: mid,       y: bandMid)
            case .east:  return CGPoint(x: s-bandMid, y: mid)
            case .south: return CGPoint(x: mid,       y: s-bandMid)
            case .west:  return CGPoint(x: bandMid,   y: mid)
            }

        case .warpCorridor:
            // Sit at center of the corridor track
            return CGPoint(x: mid, y: mid)

        case .colony, .miningShip, .dilithium:
            // These symbols are drawn at center — offset ship slightly so it's visible
            return CGPoint(x: mid, y: mid - s * 0.08)

        case .openSpace:
            // Field ship: bottom-right open area, away from any features
            return CGPoint(x: s * 0.76, y: s * 0.76)
        }
    }
}

// MARK: - Starscape Background

struct StarscapeView: View {
    var body: some View {
        Canvas { ctx, size in
            // Seeded stars so they don't shimmer on re-render
            var rng = SeededRandom(seed: 42)
            let count = Int(size.width * size.height / 1800)
            for _ in 0..<count {
                let x  = CGFloat(rng.next()) * size.width
                let y  = CGFloat(rng.next()) * size.height
                let r  = CGFloat(rng.next()) * 1.4 + 0.3
                let op = CGFloat(rng.next()) * 0.28 + 0.05
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                    with: .color(.white.opacity(op))
                )
            }
            // Occasional slightly brighter star
            for _ in 0..<(count / 6) {
                let x  = CGFloat(rng.next()) * size.width
                let y  = CGFloat(rng.next()) * size.height
                let r  = CGFloat(rng.next()) * 0.8 + 0.8
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                    with: .color(.white.opacity(0.45))
                )
            }
        }
        .background(Color(red: 0.02, green: 0.02, blue: 0.06))
        .ignoresSafeArea()
    }
}

// MARK: - Seeded random (shared with TileView)

struct SeededRandom {
    var state: Int
    init(seed: Int) { state = seed &* 6364136223846793005 &+ 1 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0x7fffffff) / Double(0x7fffffff)
    }
}
