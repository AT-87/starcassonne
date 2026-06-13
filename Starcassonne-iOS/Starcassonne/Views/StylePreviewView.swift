//
//  StylePreviewView.swift
//  Starcassonne
//
//  ⚠️  TEMPORARY — Art direction exploration only. Delete before shipping.
//
//  Shows 5 representative tiles rendered in three competing visual styles
//  so we can pick a direction before committing to full artwork.
//
//  Styles:
//    1. Current    — the existing schematic renderer (baseline)
//    2. Tactical   — LCARS-grade gradients, glows, amber/blue palette
//    3. Holographic — green scan-display with grid overlay and scanlines
//

import SwiftUI

// MARK: - Style enum

enum TileStyle: String, CaseIterable, Identifiable {
    case current     = "Current"
    case tactical    = "Tactical"
    case holographic = "Holographic"
    var id: String { rawValue }
}

// MARK: - Preview tiles

private let previewTiles: [(label: String, tile: Tile)] = [
    ("SINGLE\nSECTOR",
     Tile(type: .E,
          edges: TileEdges(north: .sector, east: .openSpace, south: .openSpace, west: .openSpace),
          features: [], sectorGroups: [[.north]])),

    ("CONNECTED\nSECTORS",
     Tile(type: .N,
          edges: TileEdges(north: .sector, east: .sector, south: .openSpace, west: .openSpace),
          features: [.starbase], sectorGroups: [[.north, .east]])),

    ("STRAIGHT\nCORRIDOR",
     Tile(type: .U,
          edges: TileEdges(north: .warpCorridor, east: .openSpace, south: .warpCorridor, west: .openSpace),
          features: [], sectorGroups: [])),

    ("CURVED\nCORRIDOR",
     Tile(type: .V,
          edges: TileEdges(north: .openSpace, east: .openSpace, south: .warpCorridor, west: .warpCorridor),
          features: [], sectorGroups: [])),

    ("COLONY",
     Tile(type: .A,
          edges: TileEdges(north: .openSpace, east: .openSpace, south: .openSpace, west: .openSpace),
          features: [.colony], sectorGroups: [])),

    ("SECTOR +\nCORRIDOR",
     Tile(type: .J,
          edges: TileEdges(north: .sector, east: .warpCorridor, south: .warpCorridor, west: .openSpace),
          features: [], sectorGroups: [[.north]])),
]

// MARK: - Top-level view

struct StylePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: TileStyle = .current
    @State private var tileSize: CGFloat = 130

    var body: some View {
        ZStack {
            Color(white: 0.05).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Label("BACK", systemImage: "chevron.left")
                            .font(LCARSFont.label(11))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .frame(height: 30)
                            .background(Color.lcarsRed)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("✦ STYLE LAB")
                        .font(LCARSFont.display(20))
                        .foregroundStyle(.black)
                        .tracking(4)

                    Spacer()

                    // Size slider
                    HStack(spacing: 6) {
                        Image(systemName: "square.resize")
                            .font(.caption)
                            .foregroundStyle(.black.opacity(0.6))
                        Slider(value: $tileSize, in: 80...200)
                            .frame(width: 100)
                            .tint(.black.opacity(0.5))
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 52)
                .background(Color.lcarsOrange)

                // ── Style picker ──────────────────────────────────────────────
                HStack(spacing: 0) {
                    ForEach(TileStyle.allCases) { style in
                        let selected = style == selectedStyle
                        Button { selectedStyle = style } label: {
                            VStack(spacing: 2) {
                                Text(style.rawValue.uppercased())
                                    .font(LCARSFont.label(11))
                                    .tracking(3)
                                    .foregroundStyle(selected ? .black : Color(white: 0.5))
                                Rectangle()
                                    .fill(selected ? Color.lcarsOrange : Color.clear)
                                    .frame(height: 2)
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 38)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Text("⚠ PROTOTYPE — DELETE BEFORE SHIP")
                        .font(LCARSFont.caption(8))
                        .foregroundStyle(Color.lcarsRed.opacity(0.6))
                        .tracking(2)
                        .padding(.trailing, 16)
                }
                .background(Color(white: 0.10))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(white: 0.2)).frame(height: 1)
                }

                // ── Style description ─────────────────────────────────────────
                Text(styleDescription(selectedStyle))
                    .font(LCARSFont.caption(9))
                    .foregroundStyle(Color.lcarsPeach.opacity(0.7))
                    .tracking(1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.08))

                // ── Tile grid ─────────────────────────────────────────────────
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: tileSize + 40), spacing: 20)
                        ],
                        spacing: 24
                    ) {
                        ForEach(previewTiles, id: \.label) { entry in
                            VStack(spacing: 8) {
                                ZStack {
                                    // Board surface hint
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(white: 0.09))
                                        .frame(width: tileSize + 16, height: tileSize + 16)

                                    StyledTileView(tile: entry.tile,
                                                   style: selectedStyle,
                                                   size: tileSize)
                                }
                                .shadow(color: shadowColor(selectedStyle).opacity(0.4), radius: 8)

                                Text(entry.label)
                                    .font(LCARSFont.caption(8))
                                    .foregroundStyle(Color(white: 0.5))
                                    .tracking(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(24)
                }

                // ── Side-by-side comparison strip (single tile, all styles) ──
                VStack(spacing: 0) {
                    Rectangle().fill(Color(white: 0.2)).frame(height: 1)
                    Text("SAME TILE — ALL THREE STYLES")
                        .font(LCARSFont.caption(8))
                        .foregroundStyle(Color(white: 0.4))
                        .tracking(3)
                        .padding(.vertical, 6)

                    HStack(spacing: 20) {
                        ForEach(TileStyle.allCases) { style in
                            VStack(spacing: 6) {
                                StyledTileView(tile: previewTiles[1].tile,
                                               style: style,
                                               size: 90)
                                    .shadow(color: shadowColor(style).opacity(0.5), radius: 6)
                                Text(style.rawValue.uppercased())
                                    .font(LCARSFont.caption(8))
                                    .foregroundStyle(
                                        style == selectedStyle
                                            ? Color.lcarsOrange
                                            : Color(white: 0.4)
                                    )
                                    .tracking(2)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
                .background(Color(white: 0.07))
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    private func styleDescription(_ style: TileStyle) -> String {
        switch style {
        case .current:
            return "Current renderer — flat schematic with trapezoid sectors and rail corridors. Functional and clear but lacks depth and atmosphere."
        case .tactical:
            return "LCARS Tactical — gradient fills, amber city walls, glowing corridor lanes, star-scatter background. Matches the existing UI palette."
        case .holographic:
            return "Holographic — green/teal scan-display aesthetic inspired by stellar cartography. Grid overlay, scanlines, minimal fills with bright outlines."
        }
    }

    private func shadowColor(_ style: TileStyle) -> Color {
        switch style {
        case .current:     return .blue
        case .tactical:    return Color(red: 1.0, green: 0.6, blue: 0.1)
        case .holographic: return .green
        }
    }
}

// MARK: - Style router

struct StyledTileView: View {
    let tile: Tile
    let style: TileStyle
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            switch style {
            case .current:     TileStyleCurrent.draw(tile: tile, ctx: ctx, s: sz.width)
            case .tactical:    TileStyleTactical.draw(tile: tile, ctx: ctx, s: sz.width)
            case .holographic: TileStyleHolographic.draw(tile: tile, ctx: ctx, s: sz.width)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Style 1: Current (mirrors the existing TileView closely)

private enum TileStyleCurrent {
    static func draw(tile: Tile, ctx: GraphicsContext, s: CGFloat) {
        let edges  = tile.rotatedEdges
        let groups = tile.rotatedSectorGroups
        let d  = s * 0.30
        let hw = s * 0.11

        ctx.fill(Path(CGRect(x: 0, y: 0, width: s, height: s)),
                 with: .color(Color.black.opacity(0.38)))

        drawSectors(ctx: ctx, edges: edges, groups: groups, s: s, d: d)
        drawCorridors(ctx: ctx, edges: edges, s: s, hw: hw)

        ctx.stroke(Path(CGRect(x: 0, y: 0, width: s, height: s)),
                   with: .color(.white.opacity(0.12)), lineWidth: 1)

        let mid = CGPoint(x: s/2, y: s/2)
        if tile.features.contains(.colony) {
            drawColony(ctx: ctx, c: mid, r: s * 0.13)
        }
        if tile.features.contains(.starbase) {
            drawStarbase(ctx: ctx, c: CGPoint(x: s*0.78, y: s*0.22), r: s*0.11)
        }
    }

    static func drawSectors(ctx: GraphicsContext, edges: TileEdges,
                             groups: [[Direction]], s: CGFloat, d: CGFloat) {
        let dirs = Direction.allCases.filter { edges.edge(facing: $0) == .sector }
        let fill = Color(red: 0.10, green: 0.25, blue: 0.65)
        let wall = Color(red: 0.35, green: 0.60, blue: 1.00)

        for dir in dirs { ctx.fill(trapezoid(dir: dir, s: s, d: d), with: .color(fill)) }

        let corners: [(Direction, Direction)] = [
            (.north,.east),(.east,.south),(.south,.west),(.west,.north)
        ]
        for (a,b) in corners {
            guard dirs.contains(a), dirs.contains(b) else { continue }
            let connected = groups.contains { $0.contains(a) && $0.contains(b) }
            if connected {
                ctx.fill(cornerTriangle(a: a, b: b, s: s, d: d), with: .color(fill))
            }
        }
        for dir in dirs {
            ctx.stroke(innerLine(dir: dir, s: s, d: d), with: .color(wall), lineWidth: 1.5)
        }
    }

    static func drawCorridors(ctx: GraphicsContext, edges: TileEdges, s: CGFloat, hw: CGFloat) {
        let sides = Direction.allCases.filter { edges.edge(facing: $0) == .warpCorridor }
        guard !sides.isEmpty else { return }
        let fill = Color(red: 0.00, green: 0.55, blue: 0.70)
        let rail = Color(red: 0.20, green: 0.90, blue: 1.00)
        let mid = s / 2

        if sides.count >= 3 {
            for side in sides { drawTrack(ctx: ctx, a: side, b: side, s: s, hw: hw, fill: fill, rail: rail) }
            let r = s * 0.10
            let rect = CGRect(x: mid-r, y: mid-r, width: r*2, height: r*2)
            ctx.fill(Path(ellipseIn: rect), with: .color(.cyan.opacity(0.55)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)), lineWidth: 1.2)
            return
        }
        for (a,b) in corridorPairs(sides) {
            drawTrack(ctx: ctx, a: a, b: b, s: s, hw: hw, fill: fill, rail: rail)
        }
    }

    static func drawColony(ctx: GraphicsContext, c: CGPoint, r: CGFloat) {
        let rect = CGRect(x: c.x-r, y: c.y-r, width: r*2, height: r*2)
        ctx.fill(Path(ellipseIn: rect), with: .color(.green.opacity(0.25)))
        ctx.stroke(Path(ellipseIn: rect), with: .color(.green.opacity(0.95)), lineWidth: 1.5)
        let dr = r * 0.3
        ctx.fill(Path(ellipseIn: CGRect(x: c.x-dr, y: c.y-dr, width: dr*2, height: dr*2)),
                 with: .color(.green))
    }

    static func drawStarbase(ctx: GraphicsContext, c: CGPoint, r: CGFloat) {
        var p = Path()
        for i in 0..<12 {
            let angle = CGFloat(i) * .pi / 6 - .pi/2
            let rad   = i.isMultiple(of: 2) ? r : r * 0.5
            let pt    = CGPoint(x: c.x + cos(angle)*rad, y: c.y + sin(angle)*rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(.orange.opacity(0.9)))
    }

    // shared geometry helpers used by all three styles
    static func trapezoid(dir: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        switch dir {
        case .north: p.move(to:.init(x:0,y:0));   p.addLine(to:.init(x:s,y:0));   p.addLine(to:.init(x:s-d,y:d));   p.addLine(to:.init(x:d,y:d))
        case .east:  p.move(to:.init(x:s,y:0));   p.addLine(to:.init(x:s,y:s));   p.addLine(to:.init(x:s-d,y:s-d)); p.addLine(to:.init(x:s-d,y:d))
        case .south: p.move(to:.init(x:0,y:s));   p.addLine(to:.init(x:s,y:s));   p.addLine(to:.init(x:s-d,y:s-d)); p.addLine(to:.init(x:d,y:s-d))
        case .west:  p.move(to:.init(x:0,y:0));   p.addLine(to:.init(x:0,y:s));   p.addLine(to:.init(x:d,y:s-d));   p.addLine(to:.init(x:d,y:d))
        }
        p.closeSubpath(); return p
    }

    static func cornerTriangle(a: Direction, b: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        let pair = Set([a,b])
        switch pair {
        case Set([Direction.north,.east]):  p.move(to:.init(x:s,y:0));  p.addLine(to:.init(x:s-d,y:0)); p.addLine(to:.init(x:s-d,y:d)); p.addLine(to:.init(x:s,y:d))
        case Set([Direction.east,.south]):  p.move(to:.init(x:s,y:s));  p.addLine(to:.init(x:s-d,y:s)); p.addLine(to:.init(x:s-d,y:s-d)); p.addLine(to:.init(x:s,y:s-d))
        case Set([Direction.south,.west]):  p.move(to:.init(x:0,y:s));  p.addLine(to:.init(x:d,y:s));   p.addLine(to:.init(x:d,y:s-d));  p.addLine(to:.init(x:0,y:s-d))
        case Set([Direction.west,.north]):  p.move(to:.init(x:0,y:0));  p.addLine(to:.init(x:d,y:0));   p.addLine(to:.init(x:d,y:d));    p.addLine(to:.init(x:0,y:d))
        default: break
        }
        p.closeSubpath(); return p
    }

    static func innerLine(dir: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        switch dir {
        case .north: p.move(to:.init(x:d,y:d));     p.addLine(to:.init(x:s-d,y:d))
        case .east:  p.move(to:.init(x:s-d,y:d));   p.addLine(to:.init(x:s-d,y:s-d))
        case .south: p.move(to:.init(x:d,y:s-d));   p.addLine(to:.init(x:s-d,y:s-d))
        case .west:  p.move(to:.init(x:d,y:d));     p.addLine(to:.init(x:d,y:s-d))
        }
        return p
    }

    static func corridorPairs(_ sides: [Direction]) -> [(Direction,Direction)] {
        let s = sides.sorted()
        switch s {
        case [.north,.south]: return [(.north,.south)]
        case [.east,.west]:   return [(.east,.west)]
        case [.north,.east]:  return [(.north,.east)]
        case [.east,.south]:  return [(.east,.south)]
        case [.south,.west]:  return [(.south,.west)]
        case [.north,.west]:  return [(.north,.west)]
        default: if sides.count==1{return[(sides[0],sides[0])]}; return []
        }
    }

    static func drawTrack(ctx: GraphicsContext, a: Direction, b: Direction,
                           s: CGFloat, hw: CGFloat,
                           fill: Color, rail: Color) {
        let mid = s/2
        let ep: (Direction)->CGPoint = {
            switch $0 {
            case .north: return .init(x:mid,y:0)
            case .east:  return .init(x:s,y:mid)
            case .south: return .init(x:mid,y:s)
            case .west:  return .init(x:0,y:mid)
            }
        }
        let pp: (Direction)->CGPoint = {
            switch $0 {
            case .north,.south: return .init(x:hw,y:0)
            case .east,.west:   return .init(x:0,y:hw)
            }
        }
        let straight: Set<Set<Direction>> = [[.north,.south],[.east,.west]]
        let aPt=ep(a); let bPt=ep(b); let aPrp=pp(a); let bPrp=pp(b)

        if a == b {
            let c = CGPoint(x:mid,y:mid)
            var body = Path()
            body.move(to:.init(x:aPt.x+aPrp.x,y:aPt.y+aPrp.y))
            body.addLine(to:.init(x:aPt.x-aPrp.x,y:aPt.y-aPrp.y))
            body.addLine(to:.init(x:c.x-aPrp.x,y:c.y-aPrp.y))
            body.addLine(to:.init(x:c.x+aPrp.x,y:c.y+aPrp.y))
            body.closeSubpath(); ctx.fill(body,with:.color(fill))
            for sign: CGFloat in [-1,1] {
                var r=Path()
                r.move(to:.init(x:aPt.x+aPrp.x*sign,y:aPt.y+aPrp.y*sign))
                r.addLine(to:.init(x:c.x+aPrp.x*sign,y:c.y+aPrp.y*sign))
                ctx.stroke(r,with:.color(rail),lineWidth:1.5)
            }
            return
        }

        if straight.contains(Set([a,b])) {
            var body=Path()
            body.move(to:.init(x:aPt.x+aPrp.x,y:aPt.y+aPrp.y))
            body.addLine(to:.init(x:aPt.x-aPrp.x,y:aPt.y-aPrp.y))
            body.addLine(to:.init(x:bPt.x-bPrp.x,y:bPt.y-bPrp.y))
            body.addLine(to:.init(x:bPt.x+bPrp.x,y:bPt.y+bPrp.y))
            body.closeSubpath(); ctx.fill(body,with:.color(fill))
            for sign: CGFloat in [-1,1] {
                var r=Path()
                r.move(to:.init(x:aPt.x+aPrp.x*sign,y:aPt.y+aPrp.y*sign))
                r.addLine(to:.init(x:bPt.x+bPrp.x*sign,y:bPt.y+bPrp.y*sign))
                ctx.stroke(r,with:.color(rail),lineWidth:1.5)
            }
        } else {
            // bent
            let d=s*0.30
            let signs: [Set<Direction>: (CGFloat,CGFloat)] = [
                Set([Direction.north,.east]): (1,-1), Set([Direction.east,.south]): (1,1),
                Set([Direction.south,.west]): (-1,1), Set([Direction.north,.west]): (-1,-1)
            ]
            let (aSign,bSign) = signs[Set([a,b])] ?? (1,1)
            let cornerPts: [Set<Direction>: CGPoint] = [
                Set([Direction.north,.east]): .init(x:s-d,y:d),
                Set([Direction.east,.south]): .init(x:s-d,y:s-d),
                Set([Direction.south,.west]): .init(x:d,y:s-d),
                Set([Direction.north,.west]): .init(x:d,y:d)
            ]
            let ic = cornerPts[Set([a,b])] ?? .init(x:mid,y:mid)
            let aIn=CGPoint(x:aPt.x+aPrp.x*aSign,y:aPt.y+aPrp.y*aSign)
            let aOut=CGPoint(x:aPt.x-aPrp.x*aSign,y:aPt.y-aPrp.y*aSign)
            let bIn=CGPoint(x:bPt.x+bPrp.x*bSign,y:bPt.y+bPrp.y*bSign)
            let bOut=CGPoint(x:bPt.x-bPrp.x*bSign,y:bPt.y-bPrp.y*bSign)
            var body=Path()
            body.move(to:aIn); body.addQuadCurve(to:bIn,control:ic)
            body.addLine(to:bOut); body.addQuadCurve(to:aOut,control:ic)
            body.closeSubpath(); ctx.fill(body,with:.color(fill))
            for (p1,p2) in [(aIn,bIn),(aOut,bOut)] {
                var r=Path(); r.move(to:p1); r.addQuadCurve(to:p2,control:ic)
                ctx.stroke(r,with:.color(rail),lineWidth:1.5)
            }
        }
    }
}

// MARK: - Style 2: LCARS Tactical

private enum TileStyleTactical {
    static func draw(tile: Tile, ctx: GraphicsContext, s: CGFloat) {
        let edges  = tile.rotatedEdges
        let groups = tile.rotatedSectorGroups
        let d  = s * 0.30
        let hw = s * 0.11
        let mid = s / 2

        // Deep space background with gradient
        let bgGrad = Gradient(colors: [
            Color(red: 0.02, green: 0.04, blue: 0.12),
            Color(red: 0.01, green: 0.02, blue: 0.08)
        ])
        ctx.fill(Path(CGRect(x:0,y:0,width:s,height:s)),
                 with: .linearGradient(bgGrad,
                                       startPoint: .init(x:0,y:0),
                                       endPoint: .init(x:s,y:s)))

        // Subtle star scatter
        var rng = SeededRNG(seed: tile.type.rawValue.hashValue)
        for _ in 0..<18 {
            let x = rng.next() * s
            let y = rng.next() * s
            let r = rng.next() * 1.2 + 0.3
            let brightness = rng.next() * 0.5 + 0.3
            ctx.fill(Path(ellipseIn: CGRect(x:x-r,y:y-r,width:r*2,height:r*2)),
                     with: .color(Color.white.opacity(brightness)))
        }

        let sectorDirs = Direction.allCases.filter { edges.edge(facing: $0) == .sector }

        // Sector: gradient trapezoid — deep blue to amber at the wall
        for dir in sectorDirs {
            let trap = TileStyleCurrent.trapezoid(dir: dir, s: s, d: d)
            let sectorGrad = Gradient(stops: [
                .init(color: Color(red:0.05,green:0.12,blue:0.40), location: 0),
                .init(color: Color(red:0.12,green:0.28,blue:0.65), location: 0.55),
                .init(color: Color(red:0.55,green:0.38,blue:0.08), location: 1.0),
            ])
            let (startPt, endPt) = gradientAxis(dir: dir, s: s)
            ctx.fill(trap, with: .linearGradient(sectorGrad,
                                                  startPoint: startPt,
                                                  endPoint: endPt))
        }

        // Corner fills
        let corners: [(Direction,Direction)] = [(.north,.east),(.east,.south),(.south,.west),(.west,.north)]
        for (a,b) in corners {
            guard sectorDirs.contains(a), sectorDirs.contains(b) else { continue }
            let connected = groups.contains { $0.contains(a) && $0.contains(b) }
            if connected {
                ctx.fill(TileStyleCurrent.cornerTriangle(a:a,b:b,s:s,d:d),
                         with: .color(Color(red:0.08,green:0.18,blue:0.50)))
            }
        }

        // Amber city wall with outer glow
        for dir in sectorDirs {
            let wall = TileStyleCurrent.innerLine(dir: dir, s: s, d: d)
            ctx.stroke(wall, with: .color(Color(red:1.0,green:0.75,blue:0.2).opacity(0.35)), lineWidth: 4)
            ctx.stroke(wall, with: .color(Color(red:1.0,green:0.80,blue:0.3)), lineWidth: 1.5)
        }

        // Corridors: glowing cyan lanes with dashed center
        let corrDirs = Direction.allCases.filter { edges.edge(facing: $0) == .warpCorridor }
        if !corrDirs.isEmpty {
            let fill  = Color(red:0.00,green:0.45,blue:0.65)
            let rail  = Color(red:0.10,green:0.90,blue:1.00)
            let glow  = Color(red:0.10,green:0.90,blue:1.00)

            if corrDirs.count >= 3 {
                for side in corrDirs {
                    TileStyleCurrent.drawTrack(ctx:ctx,a:side,b:side,s:s,hw:hw,fill:fill,rail:rail)
                }
                let r = s*0.10
                let rect = CGRect(x:mid-r,y:mid-r,width:r*2,height:r*2)
                ctx.fill(Path(ellipseIn:rect), with:.color(glow.opacity(0.3)))
                ctx.stroke(Path(ellipseIn:rect), with:.color(glow), lineWidth:1.5)
            } else {
                for (a,b) in TileStyleCurrent.corridorPairs(corrDirs) {
                    // Glow pass
                    TileStyleCurrent.drawTrack(ctx:ctx,a:a,b:b,s:s,hw:hw*1.6,
                                               fill:glow.opacity(0.12),rail:.clear)
                    // Body
                    TileStyleCurrent.drawTrack(ctx:ctx,a:a,b:b,s:s,hw:hw,fill:fill,rail:rail)
                }
                // Dashed center line
                drawDashedCenter(ctx: ctx, dirs: corrDirs, s: s, color: glow.opacity(0.7))
            }
        }

        // Tile border — thin amber line
        ctx.stroke(Path(RoundedRect(in: CGRect(x:1,y:1,width:s-2,height:s-2),
                                    cornerSize: .init(width:3,height:3))),
                   with: .color(Color(red:1.0,green:0.65,blue:0.1).opacity(0.55)), lineWidth: 1.5)

        // Colony
        if tile.features.contains(.colony) {
            let c = CGPoint(x:mid,y:mid)
            let r = s*0.14
            let grd = Gradient(colors:[Color(red:0.0,green:0.6,blue:0.3).opacity(0.15),
                                        Color(red:0.0,green:0.8,blue:0.4).opacity(0.45)])
            ctx.fill(Path(ellipseIn:CGRect(x:c.x-r,y:c.y-r,width:r*2,height:r*2)),
                     with:.radialGradient(grd,center:.init(x:mid,y:mid),
                                         startRadius:0,endRadius:r))
            ctx.stroke(Path(ellipseIn:CGRect(x:c.x-r,y:c.y-r,width:r*2,height:r*2)),
                       with:.color(Color(red:0.2,green:1.0,blue:0.5)),lineWidth:1.5)
            // Glow ring
            ctx.stroke(Path(ellipseIn:CGRect(x:c.x-r*1.4,y:c.y-r*1.4,width:r*2.8,height:r*2.8)),
                       with:.color(Color(red:0.2,green:1.0,blue:0.5).opacity(0.2)),lineWidth:2)
            let dr=r*0.28
            ctx.fill(Path(ellipseIn:CGRect(x:c.x-dr,y:c.y-dr,width:dr*2,height:dr*2)),
                     with:.color(Color(red:0.3,green:1.0,blue:0.6)))
        }

        // Starbase — amber star badge
        if tile.features.contains(.starbase) {
            let center = starbaseCenter(groups: groups, s: s)
            let r = s*0.11
            var p=Path()
            for i in 0..<12 {
                let angle=CGFloat(i)*.pi/6 - .pi/2
                let rad = i.isMultiple(of:2) ? r : r*0.5
                let pt=CGPoint(x:center.x+cos(angle)*rad,y:center.y+sin(angle)*rad)
                if i==0{p.move(to:pt)}else{p.addLine(to:pt)}
            }
            p.closeSubpath()
            ctx.fill(p,with:.color(Color(red:1.0,green:0.7,blue:0.1).opacity(0.9)))
            ctx.stroke(p,with:.color(.white.opacity(0.6)),lineWidth:0.8)
        }
    }

    private static func gradientAxis(dir: Direction, s: CGFloat) -> (CGPoint, CGPoint) {
        switch dir {
        case .north: return (.init(x:s/2,y:0), .init(x:s/2,y:s*0.30))
        case .south: return (.init(x:s/2,y:s), .init(x:s/2,y:s*0.70))
        case .east:  return (.init(x:s,y:s/2), .init(x:s*0.70,y:s/2))
        case .west:  return (.init(x:0,y:s/2), .init(x:s*0.30,y:s/2))
        }
    }

    private static func drawDashedCenter(ctx: GraphicsContext,
                                          dirs: [Direction], s: CGFloat,
                                          color: Color) {
        let mid = s/2
        let pairs = TileStyleCurrent.corridorPairs(dirs)
        for (a,b) in pairs {
            let ep: (Direction)->CGPoint = {
                switch $0 {
                case .north: return .init(x:mid,y:0)
                case .east:  return .init(x:s,y:mid)
                case .south: return .init(x:mid,y:s)
                case .west:  return .init(x:0,y:mid)
                }
            }
            var path = Path()
            path.move(to: ep(a))
            if a != b {
                path.addLine(to: ep(b))
            } else {
                path.addLine(to: CGPoint(x:mid,y:mid))
            }
            ctx.stroke(path,
                       with: .color(color),
                       style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }
    }

    private static func starbaseCenter(groups: [[Direction]], s: CGFloat) -> CGPoint {
        let bandMid = s * 0.15
        let mid = s / 2
        guard let primary = groups.first, !primary.isEmpty else {
            return CGPoint(x: s*0.78, y: s*0.22)
        }
        var x: CGFloat = 0; var y: CGFloat = 0
        for dir in primary {
            switch dir {
            case .north: x += mid;         y += bandMid
            case .east:  x += s-bandMid;   y += mid
            case .south: x += mid;         y += s-bandMid
            case .west:  x += bandMid;     y += mid
            }
        }
        let n = CGFloat(primary.count)
        return CGPoint(x: x/n, y: y/n)
    }
}

// MARK: - Style 3: Holographic

private enum TileStyleHolographic {
    static let gridColor   = Color(red: 0.0, green: 0.7, blue: 0.4)
    static let sectorColor = Color(red: 0.0, green: 1.0, blue: 0.6)
    static let corrColor   = Color(red: 0.2, green: 0.9, blue: 1.0)
    static let bgColor     = Color(red: 0.00, green: 0.05, blue: 0.08)

    static func draw(tile: Tile, ctx: GraphicsContext, s: CGFloat) {
        let edges  = tile.rotatedEdges
        let groups = tile.rotatedSectorGroups
        let d  = s * 0.30
        let hw = s * 0.11
        let mid = s / 2

        // Background
        ctx.fill(Path(CGRect(x:0,y:0,width:s,height:s)), with: .color(bgColor))

        // Fine grid
        let gridStep: CGFloat = s / 10
        var gridPath = Path()
        var gx: CGFloat = 0
        while gx <= s { gridPath.move(to:.init(x:gx,y:0)); gridPath.addLine(to:.init(x:gx,y:s)); gx += gridStep }
        var gy: CGFloat = 0
        while gy <= s { gridPath.move(to:.init(x:0,y:gy)); gridPath.addLine(to:.init(x:s,y:gy)); gy += gridStep }
        ctx.stroke(gridPath, with: .color(gridColor.opacity(0.12)), lineWidth: 0.5)

        // Scanlines (every 3 pixels, very subtle)
        let scanStep: CGFloat = 3
        var scanPath = Path()
        var sy: CGFloat = 0
        while sy < s { scanPath.move(to:.init(x:0,y:sy)); scanPath.addLine(to:.init(x:s,y:sy)); sy += scanStep }
        ctx.stroke(scanPath, with: .color(Color.black.opacity(0.18)), lineWidth: 1)

        let sectorDirs = Direction.allCases.filter { edges.edge(facing: $0) == .sector }

        // Sectors: very subtle fill + bright outline + inner hatching
        for dir in sectorDirs {
            let trap = TileStyleCurrent.trapezoid(dir: dir, s: s, d: d)
            ctx.fill(trap, with: .color(sectorColor.opacity(0.07)))
            ctx.stroke(trap, with: .color(sectorColor.opacity(0.15)), lineWidth: 0.5)
        }

        // Corner fills for connected sectors
        let corners: [(Direction,Direction)] = [(.north,.east),(.east,.south),(.south,.west),(.west,.north)]
        for (a,b) in corners {
            guard sectorDirs.contains(a), sectorDirs.contains(b) else { continue }
            let connected = groups.contains { $0.contains(a) && $0.contains(b) }
            if connected {
                ctx.fill(TileStyleCurrent.cornerTriangle(a:a,b:b,s:s,d:d),
                         with: .color(sectorColor.opacity(0.07)))
            }
        }

        // City wall — bright green line with glow
        for dir in sectorDirs {
            let wall = TileStyleCurrent.innerLine(dir: dir, s: s, d: d)
            ctx.stroke(wall, with: .color(sectorColor.opacity(0.3)), lineWidth: 5)   // glow
            ctx.stroke(wall, with: .color(sectorColor),              lineWidth: 1.2) // sharp
        }

        // Sector hatching (diagonal lines inside the trapezoid)
        for dir in sectorDirs {
            drawHatching(ctx: ctx, trap: TileStyleCurrent.trapezoid(dir:dir,s:s,d:d),
                         s: s, color: sectorColor.opacity(0.12))
        }

        // Corridors: dashed lines with glow
        let corrDirs = Direction.allCases.filter { edges.edge(facing: $0) == .warpCorridor }
        if !corrDirs.isEmpty {
            // Glow fill
            for (a,b) in TileStyleCurrent.corridorPairs(corrDirs) {
                TileStyleCurrent.drawTrack(ctx:ctx,a:a,b:b,s:s,hw:hw,
                                           fill:corrColor.opacity(0.08),rail:.clear)
            }
            // Outer rail — solid thin
            for (a,b) in TileStyleCurrent.corridorPairs(corrDirs) {
                TileStyleCurrent.drawTrack(ctx:ctx,a:a,b:b,s:s,hw:hw,fill:.clear,rail:corrColor.opacity(0.5))
            }
            // Center — dashed bright
            drawCenterDash(ctx: ctx, dirs: corrDirs, s: s, color: corrColor)

            // Junction dot
            if corrDirs.count >= 3 {
                let r = s*0.07
                ctx.fill(Path(ellipseIn:CGRect(x:mid-r,y:mid-r,width:r*2,height:r*2)),
                         with:.color(corrColor))
                ctx.stroke(Path(ellipseIn:CGRect(x:mid-r*1.8,y:mid-r*1.8,width:r*3.6,height:r*3.6)),
                           with:.color(corrColor.opacity(0.3)),lineWidth:1)
            }
        }

        // Tile border — bright green frame
        ctx.stroke(Path(CGRect(x:0.5,y:0.5,width:s-1,height:s-1)),
                   with: .color(gridColor.opacity(0.6)), lineWidth: 1)

        // Colony — concentric rings
        if tile.features.contains(.colony) {
            let c = CGPoint(x:mid,y:mid)
            for i in 1...3 {
                let r = s * CGFloat(i) * 0.055
                ctx.stroke(Path(ellipseIn:CGRect(x:c.x-r,y:c.y-r,width:r*2,height:r*2)),
                           with:.color(sectorColor.opacity(0.8/CGFloat(i))), lineWidth: 0.8)
            }
            let dr = s*0.04
            ctx.fill(Path(ellipseIn:CGRect(x:c.x-dr,y:c.y-dr,width:dr*2,height:dr*2)),
                     with:.color(sectorColor))
            ctx.draw(
                Text("COLONY")
                    .font(.system(size: s*0.075, weight: .medium, design: .monospaced))
                    .foregroundStyle(sectorColor.opacity(0.7)),
                at: CGPoint(x: mid, y: mid + s*0.18)
            )
        }

        // Starbase — crosshair / targeting reticle
        if tile.features.contains(.starbase) {
            let center = starbaseCenter(groups: groups, s: s)
            let r = s*0.09
            var reticle = Path()
            reticle.addEllipse(in: CGRect(x:center.x-r,y:center.y-r,width:r*2,height:r*2))
            let gap: CGFloat = r*0.35
            reticle.move(to:.init(x:center.x-r*1.6,y:center.y)); reticle.addLine(to:.init(x:center.x-gap,y:center.y))
            reticle.move(to:.init(x:center.x+gap,y:center.y));   reticle.addLine(to:.init(x:center.x+r*1.6,y:center.y))
            reticle.move(to:.init(x:center.x,y:center.y-r*1.6)); reticle.addLine(to:.init(x:center.x,y:center.y-gap))
            reticle.move(to:.init(x:center.x,y:center.y+gap));   reticle.addLine(to:.init(x:center.x,y:center.y+r*1.6))
            ctx.stroke(reticle, with: .color(Color(red:1.0,green:0.85,blue:0.2)), lineWidth: 1)
            ctx.stroke(Path(ellipseIn:CGRect(x:center.x-r*1.4,y:center.y-r*1.4,width:r*2.8,height:r*2.8)),
                       with:.color(Color(red:1.0,green:0.85,blue:0.2).opacity(0.2)),lineWidth:3)
        }
    }

    private static func drawHatching(ctx: GraphicsContext, trap: Path, s: CGFloat, color: Color) {
        ctx.clip(to: trap)
        var hatch = Path()
        let step: CGFloat = s * 0.08
        var h: CGFloat = -s
        while h < s * 2 {
            hatch.move(to: .init(x: h, y: 0))
            hatch.addLine(to: .init(x: h + s, y: s))
            h += step
        }
        ctx.stroke(hatch, with: .color(color), lineWidth: 0.7)
        // Reset clip by drawing nothing — SwiftUI Canvas restores clip after saveGState
        var restore = ctx
        restore.clip(to: Path(CGRect(x:0,y:0,width:s,height:s)))
    }

    private static func drawCenterDash(ctx: GraphicsContext, dirs: [Direction],
                                        s: CGFloat, color: Color) {
        let mid = s/2
        let pairs = TileStyleCurrent.corridorPairs(dirs)
        let ep: (Direction)->CGPoint = {
            switch $0 {
            case .north: return .init(x:mid,y:0)
            case .east:  return .init(x:s,y:mid)
            case .south: return .init(x:mid,y:s)
            case .west:  return .init(x:0,y:mid)
            }
        }
        for (a,b) in pairs {
            var p=Path()
            p.move(to:ep(a))
            p.addLine(to: a==b ? CGPoint(x:mid,y:mid) : ep(b))
            ctx.stroke(p, with:.color(color), style:StrokeStyle(lineWidth:1.2,dash:[5,3]))
        }
    }

    private static func starbaseCenter(groups: [[Direction]], s: CGFloat) -> CGPoint {
        let bandMid = s * 0.15; let mid = s / 2
        guard let primary = groups.first, !primary.isEmpty else {
            return CGPoint(x: s*0.78, y: s*0.22)
        }
        var x: CGFloat = 0; var y: CGFloat = 0
        for dir in primary {
            switch dir {
            case .north: x+=mid;       y+=bandMid
            case .east:  x+=s-bandMid; y+=mid
            case .south: x+=mid;       y+=s-bandMid
            case .west:  x+=bandMid;   y+=mid
            }
        }
        let n=CGFloat(primary.count)
        return CGPoint(x:x/n,y:y/n)
    }
}

// MARK: - Seeded RNG (deterministic star scatter per tile type)

private struct SeededRNG {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed &* 6364136223846793005 &+ 1442695040888963407)) }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(state >> 33) / CGFloat(1 << 31)
    }
}
