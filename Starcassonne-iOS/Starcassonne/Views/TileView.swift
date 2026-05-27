//
//  TileView.swift
//  Starcassonne
//
//  Visual language:
//  ┌──────────────────────────────────────────────────────────────┐
//  │  SECTOR       = solid blue trapezoid from each sector edge   │
//  │                 connected corners filled; separated by line  │
//  │  CORRIDOR     = cyan filled track, dark rail lines           │
//  │  OPEN SPACE   = dark transparent background                  │
//  │  COLONY       = green circle with dot (center)               │
//  │  DILITHIUM    = yellow diamond (center)                      │
//  │  STARBASE     = orange star badge (top-right)                │
//  │  NEBULA STREAM= purple glowing band from entry→exit edge     │
//  │                 Always rendered from pre-defined directions.  │
//  │                 NEVER overlaps with sector/corridor —        │
//  │                 terrain only exists on non-stream edges.     │
//  └──────────────────────────────────────────────────────────────┘

import SwiftUI

// MARK: - Constants

private struct K {
    static let sectorDepth:    CGFloat = 0.30
    static let corridorHW:     CGFloat = 0.11   // half-width of corridor track
    static let sectorFill   = Color(red: 0.10, green: 0.25, blue: 0.65)
    static let sectorBorder = Color(red: 0.35, green: 0.60, blue: 1.00)
    static let corridorFill = Color(red: 0.00, green: 0.55, blue: 0.70)
    static let corridorRail = Color(red: 0.20, green: 0.90, blue: 1.00)
    static let nebulaCore   = Color(red: 0.55, green: 0.20, blue: 0.90)
    static let nebulaGlow   = Color(red: 0.80, green: 0.50, blue: 1.00)
    static let sepColor     = Color.white
}

// MARK: - TileView

struct TileView: View {
    let tile: Tile
    var size: CGFloat = 120

    var body: some View {
        Canvas { ctx, sz in
            draw(ctx: ctx, s: sz.width)
        }
        .frame(width: size, height: size)
        .background(Color.clear)
        .clipShape(Rectangle())
    }

    // MARK: - Draw

    private func draw(ctx: GraphicsContext, s: CGFloat) {
        let edges  = tile.rotatedEdges
        let groups = tile.rotatedSectorGroups
        let d  = s * K.sectorDepth
        let hw = s * K.corridorHW

        // Subtle dark tint so features are legible against the starscape behind
        ctx.fill(Path(CGRect(x: 0, y: 0, width: s, height: s)),
                 with: .color(Color.black.opacity(0.38)))

        // Nebula stream edges — never draw terrain here
        let streamEdges = tile.streamEdges   // Set<Direction>

        // 1. Sector fills (skip any edge that carries the stream)
        drawSectors(ctx: ctx, edges: edges, groups: groups, s: s, d: d, skip: streamEdges)

        // 2. Corridor tracks (skip any edge that carries the stream)
        drawCorridors(ctx: ctx, edges: edges, s: s, hw: hw, skip: streamEdges)

        // 3. Tile border
        ctx.stroke(Path(CGRect(x: 0, y: 0, width: s, height: s)),
                   with: .color(.white.opacity(0.12)), lineWidth: 1)

        // 4. Nebula stream (drawn on top of terrain, under feature symbols)
        if tile.isNebula {
            drawNebulaStream(ctx: ctx, s: s)
        }

        // 5. Feature symbols
        let mid = CGPoint(x: s/2, y: s/2)
        if tile.features.contains(.colony)            { drawColony(ctx: ctx, c: mid, r: s*0.13) }
        if tile.features.contains(.dilithiumAsteroid) { drawDilithium(ctx: ctx, c: mid, r: s*0.13) }
        if tile.features.contains(.starbase)          { drawStarbase(ctx: ctx, c: starbaseCenter(groups: groups, s: s), r: s*0.11) }

        // 6. Tile type label (subtle, bottom-left)
        ctx.draw(
            Text(tile.type.rawValue)
                .font(.system(size: s * 0.10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.20)),
            at: CGPoint(x: s * 0.10, y: s * 0.90)
        )
    }

    // MARK: - Sector rendering

    private func drawSectors(ctx: GraphicsContext,
                              edges: TileEdges,
                              groups: [[Direction]],
                              s: CGFloat, d: CGFloat,
                              skip: Set<Direction>)
    {
        let sectorDirs = Direction.allCases.filter {
            edges.edge(facing: $0) == .sector && !skip.contains($0)
        }

        // Fill trapezoids
        for dir in sectorDirs {
            ctx.fill(trapezoid(dir: dir, s: s, d: d), with: .color(K.sectorFill))
        }

        // Corner treatment between adjacent sector edges
        let corners: [(Direction, Direction)] = [
            (.north, .east), (.east, .south), (.south, .west), (.west, .north)
        ]
        for (a, b) in corners {
            guard sectorDirs.contains(a), sectorDirs.contains(b) else { continue }
            let connected = groups.contains { $0.contains(a) && $0.contains(b) }
            if connected {
                ctx.fill(cornerTriangle(a: a, b: b, s: s, d: d), with: .color(K.sectorFill))
            } else {
                var sep = Path()
                let (outer, inner) = cornerPoints(a: a, b: b, s: s, d: d)
                sep.move(to: outer); sep.addLine(to: inner)
                ctx.stroke(sep, with: .color(K.sepColor.opacity(0.8)), lineWidth: 2)
            }
        }

        // Inner border line ("city wall")
        for dir in sectorDirs {
            ctx.stroke(innerEdgeLine(dir: dir, s: s, d: d),
                       with: .color(K.sectorBorder), lineWidth: 1.5)
        }
    }

    private func trapezoid(dir: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        switch dir {
        case .north:
            p.move(to: .init(x: 0, y: 0)); p.addLine(to: .init(x: s, y: 0))
            p.addLine(to: .init(x: s-d, y: d)); p.addLine(to: .init(x: d, y: d))
        case .east:
            p.move(to: .init(x: s, y: 0)); p.addLine(to: .init(x: s, y: s))
            p.addLine(to: .init(x: s-d, y: s-d)); p.addLine(to: .init(x: s-d, y: d))
        case .south:
            p.move(to: .init(x: 0, y: s)); p.addLine(to: .init(x: s, y: s))
            p.addLine(to: .init(x: s-d, y: s-d)); p.addLine(to: .init(x: d, y: s-d))
        case .west:
            p.move(to: .init(x: 0, y: 0)); p.addLine(to: .init(x: 0, y: s))
            p.addLine(to: .init(x: d, y: s-d)); p.addLine(to: .init(x: d, y: d))
        }
        p.closeSubpath()
        return p
    }

    private func cornerTriangle(a: Direction, b: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        let (outer, inner) = cornerPoints(a: a, b: b, s: s, d: d)
        p.move(to: outer); p.addLine(to: inner); p.addLine(to: inner)   // degenerate — use quad
        // Build the proper corner fill
        p = Path()
        p.move(to: outer)
        switch Set([a, b]) {
        case Set([Direction.north, .east]):
            p.addLine(to: CGPoint(x: s-d, y: 0)); p.addLine(to: inner); p.addLine(to: CGPoint(x: s, y: d))
        case Set([Direction.east, .south]):
            p.addLine(to: CGPoint(x: s, y: s-d)); p.addLine(to: inner); p.addLine(to: CGPoint(x: s-d, y: s))
        case Set([Direction.south, .west]):
            p.addLine(to: CGPoint(x: d, y: s)); p.addLine(to: inner); p.addLine(to: CGPoint(x: 0, y: s-d))
        case Set([Direction.west, .north]):
            p.addLine(to: CGPoint(x: 0, y: d)); p.addLine(to: inner); p.addLine(to: CGPoint(x: d, y: 0))
        default: break
        }
        p.closeSubpath()
        return p
    }

    private func cornerPoints(a: Direction, b: Direction, s: CGFloat, d: CGFloat) -> (CGPoint, CGPoint) {
        let pair = Set([a, b])
        if pair == Set([Direction.north, .east])  { return (CGPoint(x: s, y: 0),   CGPoint(x: s-d, y: d)) }
        if pair == Set([Direction.east,  .south]) { return (CGPoint(x: s, y: s),   CGPoint(x: s-d, y: s-d)) }
        if pair == Set([Direction.south, .west])  { return (CGPoint(x: 0, y: s),   CGPoint(x: d,   y: s-d)) }
        if pair == Set([Direction.west,  .north]) { return (CGPoint(x: 0, y: 0),   CGPoint(x: d,   y: d)) }
        return (.zero, .zero)
    }

    private func innerEdgeLine(dir: Direction, s: CGFloat, d: CGFloat) -> Path {
        var p = Path()
        switch dir {
        case .north: p.move(to: .init(x: d, y: d));     p.addLine(to: .init(x: s-d, y: d))
        case .east:  p.move(to: .init(x: s-d, y: d));   p.addLine(to: .init(x: s-d, y: s-d))
        case .south: p.move(to: .init(x: d, y: s-d));   p.addLine(to: .init(x: s-d, y: s-d))
        case .west:  p.move(to: .init(x: d, y: d));     p.addLine(to: .init(x: d,   y: s-d))
        }
        return p
    }

    // MARK: - Corridor rendering

    private func drawCorridors(ctx: GraphicsContext,
                                edges: TileEdges,
                                s: CGFloat, hw: CGFloat,
                                skip: Set<Direction>)
    {
        let sides = Direction.allCases.filter {
            edges.edge(facing: $0) == .warpCorridor && !skip.contains($0)
        }
        guard !sides.isEmpty else { return }

        // Space Outpost (crossroads): 3+ corridor arms all terminate here.
        // Draw each arm as an independent dead-end stub + central outpost marker.
        if sides.count >= 3 {
            for side in sides {
                drawCorridorTrack(ctx: ctx, from: side, to: side, s: s, hw: hw)
            }
            drawSpaceOutpost(ctx: ctx, s: s)
            return
        }

        for (a, b) in corridorConnections(sides: sides) {
            drawCorridorTrack(ctx: ctx, from: a, to: b, s: s, hw: hw)
        }
    }

    /// Small circular station marker for Space Outpost (crossroads) tiles.
    private func drawSpaceOutpost(ctx: GraphicsContext, s: CGFloat) {
        let mid = s / 2
        let r   = s * 0.10
        let rect = CGRect(x: mid-r, y: mid-r, width: r*2, height: r*2)
        ctx.fill(Path(ellipseIn: rect),   with: .color(.cyan.opacity(0.55)))
        ctx.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)), lineWidth: 1.2)
        // Cross / station arms
        var cross = Path()
        cross.move(to: CGPoint(x: mid - r*0.55, y: mid))
        cross.addLine(to: CGPoint(x: mid + r*0.55, y: mid))
        cross.move(to: CGPoint(x: mid, y: mid - r*0.55))
        cross.addLine(to: CGPoint(x: mid, y: mid + r*0.55))
        ctx.stroke(cross, with: .color(.white.opacity(0.9)), lineWidth: 1.2)
        ctx.draw(
            Text("OUTPOST")
                .font(.system(size: s * 0.07, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cyan.opacity(0.75)),
            at: CGPoint(x: mid, y: mid + r + s*0.06)
        )
    }

    private func corridorConnections(sides: [Direction]) -> [(Direction, Direction)] {
        switch sides.sorted() {
        case [.north, .south]:              return [(.north, .south)]
        case [.east,  .west]:              return [(.east,  .west)]
        case [.north, .east]:              return [(.north, .east)]
        case [.east,  .south]:             return [(.east,  .south)]
        case [.south, .west]:              return [(.south, .west)]
        case [.north, .west]:              return [(.north, .west)]
        case [.north, .east,  .south]:     return [(.north, .east), (.east, .south)]
        case [.east,  .south, .west]:      return [(.east,  .south), (.south, .west)]
        case [.north, .south, .west]:      return [(.north, .south), (.south, .west)]
        case [.north, .east,  .west]:      return [(.north, .east), (.north, .west)]
        case [.north, .east,  .south, .west]: return [(.north, .south), (.east, .west)]
        default:
            if sides.count == 1 { return [(sides[0], sides[0])] }
            return []
        }
    }

    private func drawCorridorTrack(ctx: GraphicsContext,
                                    from a: Direction, to b: Direction,
                                    s: CGFloat, hw: CGFloat)
    {
        let mid = s / 2
        let edgePt: (Direction) -> CGPoint = {
            switch $0 {
            case .north: return CGPoint(x: mid, y: 0)
            case .east:  return CGPoint(x: s,   y: mid)
            case .south: return CGPoint(x: mid, y: s)
            case .west:  return CGPoint(x: 0,   y: mid)
            }
        }
        let perp: (Direction) -> CGPoint = {
            switch $0 {
            case .north, .south: return CGPoint(x: hw, y: 0)
            case .east,  .west:  return CGPoint(x: 0,  y: hw)
            }
        }

        if a == b {
            // Dead-end: track to center with cap
            let e = edgePt(a); let c = CGPoint(x: mid, y: mid); let pv = perp(a)
            drawTrackSegment(ctx: ctx, from: e, to: c,
                             perpA: pv, perpB: pv, s: s, hw: hw, drawCap: true)
            return
        }

        let aPt = edgePt(a); let bPt = edgePt(b)
        let aPrp = perp(a);  let bPrp = perp(b)

        let straight: Set<Set<Direction>> = [[.north, .south], [.east, .west]]
        if straight.contains(Set([a, b])) {
            drawTrackSegment(ctx: ctx, from: aPt, to: bPt,
                             perpA: aPrp, perpB: bPrp, s: s, hw: hw, drawCap: false)
        } else {
            drawBentTrack(ctx: ctx, a: a, b: b, s: s, hw: hw, edgePt: edgePt, perp: perp)
        }
    }

    private func drawTrackSegment(ctx: GraphicsContext,
                                   from start: CGPoint, to end: CGPoint,
                                   perpA: CGPoint, perpB: CGPoint,
                                   s: CGFloat, hw: CGFloat, drawCap: Bool)
    {
        var body = Path()
        body.move(to:    CGPoint(x: start.x + perpA.x, y: start.y + perpA.y))
        body.addLine(to: CGPoint(x: start.x - perpA.x, y: start.y - perpA.y))
        body.addLine(to: CGPoint(x: end.x   - perpB.x, y: end.y   - perpB.y))
        body.addLine(to: CGPoint(x: end.x   + perpB.x, y: end.y   + perpB.y))
        body.closeSubpath()
        ctx.fill(body, with: .color(K.corridorFill))

        for sign: CGFloat in [-1, 1] {
            var rail = Path()
            rail.move(to:    CGPoint(x: start.x + perpA.x*sign, y: start.y + perpA.y*sign))
            rail.addLine(to: CGPoint(x: end.x   + perpB.x*sign, y: end.y   + perpB.y*sign))
            ctx.stroke(rail, with: .color(K.corridorRail), lineWidth: 1.5)
        }

        if drawCap {
            var cap = Path()
            cap.move(to:    CGPoint(x: end.x + perpB.x, y: end.y + perpB.y))
            cap.addLine(to: CGPoint(x: end.x - perpB.x, y: end.y - perpB.y))
            ctx.stroke(cap, with: .color(K.corridorRail.opacity(0.6)), lineWidth: 1.5)
        }
    }

    private func drawBentTrack(ctx: GraphicsContext,
                                a: Direction, b: Direction,
                                s: CGFloat, hw: CGFloat,
                                edgePt: (Direction)->CGPoint,
                                perp: (Direction)->CGPoint)
    {
        let d  = s * K.sectorDepth
        let ic = cornerInset(a: a, b: b, s: s, d: d)
        let aPt = edgePt(a); let aPrp = perp(a)
        let bPt = edgePt(b); let bPrp = perp(b)

        // The "inner" side of each edge is the side facing the shared tile corner.
        // For N+E and S+W corners the two edges need OPPOSITE perp signs to both
        // point "inward." Using the same sign on both creates crossing arcs that
        // look broken and nearly invisible in the top-right / bottom-left rotations.
        let (aSign, bSign) = corridorInnerSigns(a: a, b: b)

        let aInner = CGPoint(x: aPt.x + aPrp.x * aSign,  y: aPt.y + aPrp.y * aSign)
        let aOuter = CGPoint(x: aPt.x - aPrp.x * aSign,  y: aPt.y - aPrp.y * aSign)
        let bInner = CGPoint(x: bPt.x + bPrp.x * bSign,  y: bPt.y + bPrp.y * bSign)
        let bOuter = CGPoint(x: bPt.x - bPrp.x * bSign,  y: bPt.y - bPrp.y * bSign)

        // Fill: region between the inner and outer arcs (never self-intersects)
        var body = Path()
        body.move(to: aInner)
        body.addQuadCurve(to: bInner, control: ic)   // inner (tight) arc
        body.addLine(to: bOuter)
        body.addQuadCurve(to: aOuter, control: ic)   // outer (wide) arc
        body.closeSubpath()
        ctx.fill(body, with: .color(K.corridorFill))

        // Rails: two parallel arcs tracing the corridor edges
        for (aEnd, bEnd) in [(aInner, bInner), (aOuter, bOuter)] {
            var rail = Path()
            rail.move(to: aEnd); rail.addQuadCurve(to: bEnd, control: ic)
            ctx.stroke(rail, with: .color(K.corridorRail), lineWidth: 1.5)
        }
    }

    /// Returns the perp-offset signs that put each edge's rail point on the side
    /// facing the shared corner (the "inner" radius of the curve).
    ///
    ///  N+E corner (0,0 top-right of tile at (s,0)):
    ///    N inner = right  (+) | E inner = top   (−)  → (+1, −1)
    ///  E+S corner (bottom-right, (s,s)):
    ///    E inner = bottom (+) | S inner = right (+)  → (+1, +1)
    ///  S+W corner (bottom-left, (0,s)):
    ///    S inner = left   (−) | W inner = bottom(+)  → (−1, +1)
    ///  W+N corner (top-left, (0,0)):
    ///    W inner = top    (−) | N inner = left  (−)  → (−1, −1)
    private func corridorInnerSigns(a: Direction, b: Direction) -> (CGFloat, CGFloat) {
        switch (a, b) {
        case (.north, .east):  return ( 1, -1)
        case (.east,  .south): return ( 1,  1)
        case (.south, .west):  return (-1,  1)
        case (.north, .west):  return (-1, -1)
        default:               return ( 1,  1)
        }
    }

    private func cornerInset(a: Direction, b: Direction, s: CGFloat, d: CGFloat) -> CGPoint {
        let pair = Set([a, b])
        if pair == Set([Direction.north, .east])  { return CGPoint(x: s-d, y: d) }
        if pair == Set([Direction.east,  .south]) { return CGPoint(x: s-d, y: s-d) }
        if pair == Set([Direction.south, .west])  { return CGPoint(x: d,   y: s-d) }
        if pair == Set([Direction.west,  .north]) { return CGPoint(x: d,   y: d) }
        return CGPoint(x: s/2, y: s/2)
    }

    // MARK: - Nebula stream

    /// Draws the nebula stream band using the tile's pre-defined stream directions.
    /// - Source tile: entry=nil, exit=some → stream from center to exit edge
    /// - Lake tile:   entry=some, exit=nil → stream from entry edge to center
    /// - Middle tiles: entry=some, exit=some → stream from entry edge to exit edge (straight or curved)
    /// This always renders correctly whether the tile is in preview or placed on the board.
    private func drawNebulaStream(ctx: GraphicsContext, s: CGFloat) {
        let mid    = s / 2
        let center = CGPoint(x: mid, y: mid)
        let entry  = tile.rotatedNebulaEntry
        let exit   = tile.rotatedNebulaExit
        let bw     = s * 0.26   // stream band width

        let edgePt: (Direction) -> CGPoint = {
            switch $0 {
            case .north: return CGPoint(x: mid, y: 0)
            case .east:  return CGPoint(x: s,   y: mid)
            case .south: return CGPoint(x: mid, y: s)
            case .west:  return CGPoint(x: 0,   y: mid)
            }
        }

        let startPt: CGPoint = entry.map { edgePt($0) } ?? center
        let endPt:   CGPoint = exit.map  { edgePt($0) } ?? center

        // Control point for the quad-curve
        let control: CGPoint
        if let en = entry, let ex = exit {
            let isOpposite = en == ex.opposite
            control = isOpposite ? center : nebulaCornerControl(a: en, b: ex, s: s)
        } else {
            control = center
        }

        // ── Glow pass (wide, soft) ─────────────────────────────────────────────
        var glowPath = Path()
        glowPath.move(to: startPt)
        glowPath.addQuadCurve(to: endPt, control: control)
        ctx.stroke(glowPath,
                   with: .color(K.nebulaGlow.opacity(0.18)),
                   lineWidth: bw * 1.8)

        // ── Body pass (filled band) ────────────────────────────────────────────
        // Build filled shape perpendicular to the curve
        let hw: CGFloat = bw / 2
        let perp = streamPerpOffset(entry: entry, exit: exit, hw: hw)

        var body = Path()
        body.move(to:    CGPoint(x: startPt.x + perp.x, y: startPt.y + perp.y))
        body.addQuadCurve(to: CGPoint(x: endPt.x + perp.x, y: endPt.y + perp.y),
                          control: control)
        body.addLine(to: CGPoint(x: endPt.x   - perp.x, y: endPt.y   - perp.y))
        body.addQuadCurve(to: CGPoint(x: startPt.x - perp.x, y: startPt.y - perp.y),
                          control: control)
        body.closeSubpath()
        ctx.fill(body, with: .color(K.nebulaCore.opacity(0.45)))

        // ── Edge lines ────────────────────────────────────────────────────────
        var outline = Path()
        outline.move(to: startPt)
        outline.addQuadCurve(to: endPt, control: control)
        ctx.stroke(outline, with: .color(K.nebulaGlow.opacity(0.85)), lineWidth: bw * 0.15)

        // ── Flow arrow (direction indicator) ─────────────────────────────────
        if exit != nil {
            let t: CGFloat = 0.5
            let arrowPt  = quadPt(from: startPt, control: control, to: endPt, t: t)
            let tangent  = quadTangent(from: startPt, control: control, to: endPt, t: t)
            drawFlowArrow(ctx: ctx, at: arrowPt,
                          angle: atan2(tangent.y, tangent.x),
                          size: s * 0.09)
        }

        // ── "~" badge so player knows it's a nebula tile ──────────────────────
        ctx.draw(
            Text("〜")
                .font(.system(size: s * 0.13))
                .foregroundStyle(K.nebulaGlow.opacity(0.75)),
            at: CGPoint(x: s * 0.13, y: s * 0.12)
        )
    }

    private func streamPerpOffset(entry: Direction?, exit: Direction?, hw: CGFloat) -> CGPoint {
        // Use entry direction to determine perpendicular axis
        let ref = entry ?? exit
        switch ref {
        case .north, .south: return CGPoint(x: hw, y: 0)
        case .east,  .west:  return CGPoint(x: 0,  y: hw)
        case nil:            return CGPoint(x: hw, y: 0)
        }
    }

    private func nebulaCornerControl(a: Direction, b: Direction, s: CGFloat) -> CGPoint {
        let d = s * 0.30
        let pair = Set([a, b])
        if pair == Set([Direction.north, .east])  { return CGPoint(x: s-d, y: d) }
        if pair == Set([Direction.east,  .south]) { return CGPoint(x: s-d, y: s-d) }
        if pair == Set([Direction.south, .west])  { return CGPoint(x: d,   y: s-d) }
        if pair == Set([Direction.west,  .north]) { return CGPoint(x: d,   y: d) }
        // Diagonal cases (entry and exit at same corner — shouldn't happen)
        return CGPoint(x: s/2, y: s/2)
    }

    private func quadPt(from p0: CGPoint, control c: CGPoint, to p2: CGPoint, t: CGFloat) -> CGPoint {
        let mt = 1 - t
        return CGPoint(x: mt*mt*p0.x + 2*mt*t*c.x + t*t*p2.x,
                       y: mt*mt*p0.y + 2*mt*t*c.y + t*t*p2.y)
    }

    private func quadTangent(from p0: CGPoint, control c: CGPoint, to p2: CGPoint, t: CGFloat) -> CGPoint {
        let mt = 1 - t
        return CGPoint(x: 2*mt*(c.x-p0.x) + 2*t*(p2.x-c.x),
                       y: 2*mt*(c.y-p0.y) + 2*t*(p2.y-c.y))
    }

    private func drawFlowArrow(ctx: GraphicsContext, at pt: CGPoint, angle: CGFloat, size: CGFloat) {
        var p = Path()
        p.move(to:    CGPoint(x: pt.x + cos(angle)*size,         y: pt.y + sin(angle)*size))
        p.addLine(to: CGPoint(x: pt.x + cos(angle+2.4)*size*0.6, y: pt.y + sin(angle+2.4)*size*0.6))
        p.addLine(to: CGPoint(x: pt.x + cos(angle-2.4)*size*0.6, y: pt.y + sin(angle-2.4)*size*0.6))
        p.closeSubpath()
        ctx.fill(p, with: .color(K.nebulaGlow.opacity(0.9)))
    }

    // MARK: - Feature symbols

    /// Computes the centroid of the sector band belonging to the starbase,
    /// so the badge stays inside the correct region even after tile rotation.
    ///
    /// Each sector edge is represented by the midpoint of its 30%-deep trapezoid:
    ///   North → (mid, bandMid)   East → (s−bandMid, mid)
    ///   South → (mid, s−bandMid) West → (bandMid, mid)
    ///
    /// We average those midpoints over the primary group's directions.
    private func starbaseCenter(groups: [[Direction]], s: CGFloat) -> CGPoint {
        let bandMid = s * 0.15      // centroid of the 30%-deep trapezoid band
        let mid     = s / 2
        guard let primary = groups.first, !primary.isEmpty else {
            return CGPoint(x: s * 0.78, y: s * 0.22)   // safe fallback
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        for dir in primary {
            switch dir {
            case .north: x += mid;           y += bandMid
            case .east:  x += s - bandMid;   y += mid
            case .south: x += mid;           y += s - bandMid
            case .west:  x += bandMid;       y += mid
            }
        }
        let n = CGFloat(primary.count)
        return CGPoint(x: x / n, y: y / n)
    }

    private func drawColony(ctx: GraphicsContext, c: CGPoint, r: CGFloat) {
        let rect = CGRect(x: c.x-r, y: c.y-r, width: r*2, height: r*2)
        ctx.fill(Path(ellipseIn: rect), with: .color(.green.opacity(0.25)))
        ctx.stroke(Path(ellipseIn: rect), with: .color(.green.opacity(0.95)), lineWidth: 1.5)
        let dr = r * 0.3
        ctx.fill(Path(ellipseIn: CGRect(x: c.x-dr, y: c.y-dr, width: dr*2, height: dr*2)),
                 with: .color(.green))
    }

    private func drawDilithium(ctx: GraphicsContext, c: CGPoint, r: CGFloat) {
        var p = Path()
        p.move(to:    CGPoint(x: c.x,   y: c.y-r))
        p.addLine(to: CGPoint(x: c.x+r, y: c.y))
        p.addLine(to: CGPoint(x: c.x,   y: c.y+r))
        p.addLine(to: CGPoint(x: c.x-r, y: c.y))
        p.closeSubpath()
        ctx.fill(p, with: .color(.yellow.opacity(0.3)))
        ctx.stroke(p, with: .color(.yellow.opacity(0.95)), lineWidth: 1.5)
    }

    private func drawStarbase(ctx: GraphicsContext, c: CGPoint, r: CGFloat) {
        var p = Path()
        for i in 0..<12 {
            let angle = CGFloat(i) * .pi / 6 - .pi/2
            let rad   = i.isMultiple(of: 2) ? r : r * 0.5
            let pt    = CGPoint(x: c.x + cos(angle)*rad, y: c.y + sin(angle)*rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(.orange.opacity(0.9)))
        ctx.stroke(p, with: .color(.orange), lineWidth: 0.8)
    }
}

// MARK: - Preview

#Preview("All Nebula Tiles") {
    let tiles = NebulaDeck.make()
    return ScrollView {
        LazyVGrid(columns: Array(repeating: .init(.fixed(110)), count: 4), spacing: 6) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { idx, tile in
                VStack(spacing: 3) {
                    TileView(tile: tile, size: 100)
                    Text(idx == 0 ? "Source" : idx == tiles.count-1 ? "Lake" : "Mid \(idx)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                    if let entry = tile.nebulaEntry, let exit = tile.nebulaExit {
                        Text("\(entry.rawValue.prefix(1).uppercased())→\(exit.rawValue.prefix(1).uppercased())")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.purple.opacity(0.8))
                    } else if tile.nebulaEntry == nil {
                        Text("→\(tile.nebulaExit?.rawValue.prefix(1).uppercased() ?? "?")")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.purple.opacity(0.8))
                    } else {
                        Text("\(tile.nebulaEntry?.rawValue.prefix(1).uppercased() ?? "?")→")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.purple.opacity(0.8))
                    }
                }
            }
        }
        .padding(8)
    }
    .background(Color(white: 0.06))
    .preferredColorScheme(.dark)
}

#Preview("All 24 Main Tiles") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: .init(.fixed(110)), count: 6), spacing: 6) {
            ForEach(TileDeck.definitions, id: \.type) { def in
                VStack(spacing: 3) {
                    TileView(
                        tile: Tile(type: def.type, edges: def.edges,
                                   features: def.features, sectorGroups: def.sectorGroups),
                        size: 100
                    )
                    Text("\(def.type.rawValue) ×\(def.count)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
    }
    .background(Color(white: 0.06))
    .preferredColorScheme(.dark)
}
