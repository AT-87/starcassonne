//
//  GameView.swift
//  Starcassonne
//

import SwiftUI

struct GameView: View {
    @State var vm: GameViewModel
    @State private var showEndGame  = false
    @State private var confirmQuit  = false
    // Item 3: score toast state
    @State private var activeToast:  (points: Int, factions: [Faction])? = nil
    @State private var toastOpacity: Double = 0
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── LCARS top header bar ──────────────────────────────────────
                LCARSTopBar(vm: vm, confirmQuit: $confirmQuit)
                    .confirmationDialog("ABANDON THIS MISSION?",
                                        isPresented: $confirmQuit,
                                        titleVisibility: .visible) {
                        Button("Quit to Setup", role: .destructive) { dismiss() }
                        Button("Cancel", role: .cancel) {}
                    }

                // ── Legend ────────────────────────────────────────────────────
                LCARSLegendBar()

                // ── Phase banner ──────────────────────────────────────────────
                LCARSPhaseBanner(phase: vm.phase)

                // ── Status message ────────────────────────────────────────────
                Text(vm.message)
                    .font(LCARSFont.caption(11))
                    .foregroundStyle(Color.lcarsPeach.opacity(0.8))
                    .tracking(2)
                    .padding(.vertical, 5)
                    .animation(.default, value: vm.message)

                // ── Board ─────────────────────────────────────────────────────
                BoardView(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Item 2: Recall bar (colony/dilithium ship recall) ─────────
                if !vm.awaitingShip && !vm.recallableTiles.isEmpty && vm.phase == .exploration {
                    LCARSRecallBar(vm: vm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── Ship placement ────────────────────────────────────────────
                if vm.awaitingShip {
                    LCARSShipBar(vm: vm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // ── Bottom bar ────────────────────────────────────────────────
                if !vm.awaitingShip {
                    LCARSBottomBar(vm: vm)
                }
            }

            // ── Item 3: Score toast overlay ───────────────────────────────────
            if let toast = activeToast {
                let toastColor = toast.factions.first?.color ?? Color.lcarsOrange
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(toastColor, lineWidth: 1.5)
                        )
                    Text("+\(toast.points) PTS")
                        .font(LCARSFont.display(30))
                        .foregroundStyle(toastColor)
                }
                .frame(width: 190, height: 60)
                .opacity(toastOpacity)
                .shadow(color: toastColor.opacity(0.5), radius: 12)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: vm.phase) { _, newPhase in
            if newPhase == .ended {
                LCARSAudio.shared.alert()
                vm.triggerEndGameScoring()
                showEndGame = true
                // Clear save slot when the game completes
                GamePersistence.deleteSave()
            }
        }
        .onChange(of: vm.pendingToasts.count) { _, count in
            if count > 0 { showNextToast() }
        }
        .sheet(isPresented: $showEndGame) {
            LCARSEndGameView(players: vm.gameState.players)
        }
    }

    // MARK: - Toast helpers

    private func showNextToast() {
        guard !vm.pendingToasts.isEmpty else { return }
        activeToast = vm.pendingToasts.removeFirst()
        withAnimation(.easeIn(duration: 0.2)) { toastOpacity = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.35)) { toastOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeToast = nil
                if !vm.pendingToasts.isEmpty { showNextToast() }
            }
        }
    }
}

// MARK: - Top Header Bar

private struct LCARSTopBar: View {
    var vm: GameViewModel
    @Binding var confirmQuit: Bool
    private let h: CGFloat = 52

    var body: some View {
        ZStack {
            Color.lcarsOrange.ignoresSafeArea(edges: .top)

            HStack(spacing: 0) {
                // QUIT pill (left)
                Button {
                    LCARSAudio.shared.tap()
                    confirmQuit = true
                } label: {
                    Text("QUIT")
                        .font(LCARSFont.label(12))
                        .foregroundStyle(.black)
                        .tracking(3)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(Color.lcarsRed)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 14)

                // Item 4: SAVE pill
                Button {
                    LCARSAudio.shared.confirm()
                    vm.saveGame()
                } label: {
                    Text("SAVE")
                        .font(LCARSFont.label(12))
                        .foregroundStyle(.black)
                        .tracking(3)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color.lcarsIce)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)

                Spacer()

                // Title
                Text("✦ STARCASSONNE")
                    .font(LCARSFont.display(20))
                    .foregroundStyle(.black)
                    .tracking(4)

                Spacer()

                // Current player badge
                let p = vm.gameState.currentPlayer
                HStack(spacing: 6) {
                    Text(p.faction.shipSymbol)
                        .font(.system(size: 14))
                        .foregroundStyle(p.faction.color)
                    Text(p.name.uppercased())
                        .font(LCARSFont.label(11))
                        .foregroundStyle(.black)
                        .tracking(2)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(Color.lcarsPeach)
                .clipShape(Capsule())
                .padding(.trailing, 14)
            }
            .frame(height: h)
        }
        .frame(height: h)
    }
}

// MARK: - Legend Bar

private struct LCARSLegendBar: View {
    struct Entry: Identifiable {
        let id = UUID()
        let color: Color
        let label: String
    }

    let entries: [Entry] = [
        Entry(color: .blue,         label: "SECTOR"),
        Entry(color: .cyan,         label: "WARP CORRIDOR"),
        Entry(color: Color(white: 0.5), label: "OPEN SPACE"),
        Entry(color: .green,        label: "COLONY"),
        Entry(color: .yellow,       label: "DILITHIUM"),
        Entry(color: .orange,       label: "STARBASE"),
        Entry(color: .purple,       label: "NEBULA"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(entries) { e in
                    HStack(spacing: 0) {
                        // Colored left blob
                        RoundedRectangle(cornerRadius: 3)
                            .fill(e.color)
                            .frame(width: 10, height: 22)
                            .padding(.trailing, 1)

                        Text(e.label)
                            .font(LCARSFont.caption(9))
                            .foregroundStyle(.black)
                            .tracking(1)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(e.color.opacity(0.35))
                    }
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(e.color.opacity(0.6), lineWidth: 1))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .background(Color(white: 0.06))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.lcarsOrange.opacity(0.4)).frame(height: 2)
        }
    }
}

// MARK: - Phase Banner

private struct LCARSPhaseBanner: View {
    let phase: GamePhase

    private var phaseColor: Color {
        phase == .nebula ? .lcarsPurple : phase == .exploration ? .lcarsIce : .lcarsRed
    }
    private var phaseText: String {
        switch phase {
        case .nebula:      return "NEBULA PHASE  —  CHART THE ANOMALY"
        case .exploration: return "EXPLORATION PHASE  —  EXPAND THE FRONTIER"
        case .ended:       return "MISSION COMPLETE  —  FINAL SCORING"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored end-cap
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0,
                                   bottomTrailingRadius: 0, topTrailingRadius: 0)
                .fill(phaseColor)
                .frame(width: 8, height: 28)

            // Label pill
            Text(phaseText)
                .font(LCARSFont.label(11))
                .foregroundStyle(.black)
                .tracking(3)
                .padding(.horizontal, 14)
                .frame(height: 28)
                .background(phaseColor)

            // Thin trailing line
            Rectangle()
                .fill(phaseColor.opacity(0.35))
                .frame(height: 3)
                .padding(.vertical, 12)

            Spacer()
        }
        .background(Color(white: 0.06))
        .animation(.easeInOut, value: phase)
    }
}

// MARK: - Ship Placement Bar

private struct LCARSShipBar: View {
    var vm: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header strip
            HStack {
                Capsule()
                    .fill(Color.lcarsOrange)
                    .frame(width: 30, height: 6)
                Text("DEPLOY SHIP TO SECTOR")
                    .font(LCARSFont.caption(10))
                    .foregroundStyle(Color.lcarsOrange)
                    .tracking(4)
                Capsule()
                    .fill(Color.lcarsOrange.opacity(0.3))
                    .frame(height: 4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.availableShipOptions) { option in
                        Button {
                            LCARSAudio.shared.confirm()
                            withAnimation { vm.placeShip(option: option) }
                        } label: {
                            VStack(spacing: 5) {
                                Image(systemName: featureIcon(option.feature))
                                    .font(.title3)
                                    .foregroundStyle(featureColor(option.feature))
                                Text(option.label)
                                    .font(LCARSFont.caption(9))
                                    .foregroundStyle(.black)
                                    .tracking(1)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(width: 88, height: 58)
                            .background(featureColor(option.feature).opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }

                    // Pass
                    Button {
                        LCARSAudio.shared.tap()
                        withAnimation { vm.placeShip(option: nil) }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(Color(white: 0.4))
                            Text("PASS")
                                .font(LCARSFont.caption(9))
                                .foregroundStyle(Color(white: 0.5))
                                .tracking(2)
                        }
                        .frame(width: 88, height: 58)
                        .background(Color(white: 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(white: 0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 10)
        }
        .background(Color(white: 0.08))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.lcarsOrange.opacity(0.5)).frame(height: 2)
        }
    }

    private func featureName(_ f: PlacedFeature) -> String {
        switch f {
        case .sector:       return "Sector"
        case .warpCorridor: return "Warp"
        case .colony:       return "Colony"
        case .openSpace:    return "Trader"
        case .dilithium:    return "Dilithium"
        }
    }

    private func featureIcon(_ f: PlacedFeature) -> String {
        switch f {
        case .sector:       return "shield.fill"
        case .warpCorridor: return "arrow.forward"
        case .colony:       return "globe"
        case .openSpace:    return "star"
        case .dilithium:    return "diamond.fill"
        }
    }

    private func featureColor(_ f: PlacedFeature) -> Color {
        switch f {
        case .sector:       return Color(red: 0.2, green: 0.4, blue: 0.9)
        case .warpCorridor: return Color(red: 0.0, green: 0.7, blue: 0.8)
        case .colony:       return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .openSpace:    return Color(white: 0.45)
        case .dilithium:    return Color(red: 0.85, green: 0.75, blue: 0.1)
        }
    }
}

// MARK: - Bottom Bar

private struct LCARSBottomBar: View {
    var vm: GameViewModel

    var body: some View {
        HStack(spacing: 12) {

            // ── Player score readouts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.gameState.players) { player in
                        let isCurrent = vm.gameState.currentPlayer.id == player.id
                        VStack(spacing: 0) {
                            // Faction header — brighter + "▶" chevron when it's this player's turn
                            HStack(spacing: 4) {
                                Text(player.faction.shipSymbol)
                                    .font(.system(size: 11))
                                Text(player.name.uppercased())
                                    .font(LCARSFont.caption(9))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                                    .tracking(1)
                                if isCurrent {
                                    Spacer(minLength: 0)
                                    Text("▶")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(.black.opacity(0.65))
                                }
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(
                                isCurrent
                                    ? player.faction.color
                                    : player.faction.color.opacity(0.38)
                            )
                            .clipShape(UnevenRoundedRectangle(
                                topLeadingRadius: 11, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 11
                            ))

                            // Score + ships remaining
                            VStack(spacing: 1) {
                                Text("\(player.score)")
                                    .font(LCARSFont.data(16))
                                    .foregroundStyle(
                                        isCurrent ? player.faction.color : Color(white: 0.5)
                                    )
                                    .frame(height: 22)

                                HStack(spacing: 2) {
                                    Text(player.faction.shipSymbol)
                                        .font(.system(size: 8))
                                        .foregroundStyle(
                                            isCurrent
                                                ? player.faction.color.opacity(0.9)
                                                : Color(white: 0.4)
                                        )
                                    Text("×\(player.shipsRemaining)")
                                        .font(LCARSFont.data(10))
                                        .foregroundStyle(
                                            isCurrent
                                                ? player.faction.color.opacity(0.85)
                                                : Color(white: 0.4)
                                        )
                                }
                                .frame(height: 14)
                            }
                            .frame(minWidth: 52)
                            .padding(.bottom, 4)
                            .background(
                                isCurrent ? Color(white: 0.13) : Color(white: 0.09)
                            )
                            .clipShape(UnevenRoundedRectangle(
                                topLeadingRadius: 0, bottomLeadingRadius: 6,
                                bottomTrailingRadius: 6, topTrailingRadius: 0
                            ))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(
                                    player.faction.color,
                                    lineWidth: isCurrent ? 2.5 : 0.5
                                )
                                .opacity(isCurrent ? 1 : 0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .shadow(
                            color: isCurrent ? player.faction.color.opacity(0.55) : .clear,
                            radius: 6
                        )
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: 300)

            Spacer()

            // ── Next tile panel
            VStack(spacing: 0) {
                Text("NEXT TILE")
                    .font(LCARSFont.caption(8))
                    .foregroundStyle(.black)
                    .tracking(3)
                    .padding(.horizontal, 8)
                    .frame(height: 18)
                    .frame(maxWidth: .infinity)
                    .background(Color.lcarsOrange)

                if let tile = vm.currentTile {
                    TileView(tile: tile, size: 64)
                        .frame(width: 64, height: 64)
                } else {
                    Color(white: 0.12)
                        .frame(width: 64, height: 64)
                        .overlay(Text("—").foregroundStyle(.secondary))
                }
            }
            .background(Color(white: 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.lcarsOrange.opacity(0.5), lineWidth: 1))
            .frame(width: 80)

            // ── Rotate button
            Button {
                LCARSAudio.shared.rotate()
                vm.rotateTile()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                    Text("ROTATE")
                        .font(LCARSFont.caption(9))
                        .foregroundStyle(.black)
                        .tracking(2)
                }
                .frame(width: 64, height: 50)
                .background(vm.currentTile == nil ? Color.lcarsOrange.opacity(0.3) : Color.lcarsOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(vm.currentTile == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(white: 0.07))
        .overlay(alignment: .top) {
            // LCARS top border accent
            HStack(spacing: 4) {
                Capsule().fill(Color.lcarsOrange).frame(width: 60, height: 5)
                Capsule().fill(Color.lcarsPurple).frame(width: 30, height: 5)
                Capsule().fill(Color.lcarsIce).frame(width: 20, height: 5)
                Rectangle().fill(Color.lcarsOrange.opacity(0.2)).frame(height: 3)
                    .padding(.vertical, 1)
            }
            .padding(.horizontal, 12)
        }
    }
}

// MARK: - Item 2: Recall Bar

private struct LCARSRecallBar: View {
    var vm: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header strip
            HStack {
                Capsule()
                    .fill(Color.lcarsGold)
                    .frame(width: 30, height: 6)
                Text("RECALL MINING SHIP")
                    .font(LCARSFont.caption(10))
                    .foregroundStyle(Color.lcarsGold)
                    .tracking(4)
                Capsule()
                    .fill(Color.lcarsGold.opacity(0.3))
                    .frame(height: 4)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.recallableTiles, id: \.pos) { entry in
                        Button {
                            withAnimation { vm.recallShip(at: entry.pos) }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.lcarsGold)
                                Text("+\(entry.score) PTS")
                                    .font(LCARSFont.caption(9))
                                    .foregroundStyle(.black)
                                    .tracking(1)
                            }
                            .frame(width: 88, height: 52)
                            .background(Color.lcarsGold.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 8)
        }
        .background(Color(white: 0.08))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.lcarsGold.opacity(0.5)).frame(height: 2)
        }
    }
}

// MARK: - End Game View

struct LCARSEndGameView: View {
    let players: [Player]
    @Environment(\.dismiss) var dismiss

    var sortedPlayers: [Player] { players.sorted { $0.score > $1.score } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                endHeader
                accentStrip
                scoreList
                Spacer()

                // Footer
                ZStack {
                    Color.lcarsOrange
                    LCARSPill(label: "NEW MISSION", color: .lcarsPeach,
                              width: 220, height: 44, fontSize: 17) {
                        LCARSAudio.shared.engage()
                        dismiss()
                    }
                }
                .frame(height: 68)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var endHeader: some View {
        ZStack {
            Color.lcarsOrange
            Text("MISSION DEBRIEF  —  FINAL SCORES")
                .font(LCARSFont.display(22))
                .foregroundStyle(.black)
                .tracking(4)
        }
        .frame(height: 60)
        .ignoresSafeArea(edges: .top)
    }

    private var accentStrip: some View {
        HStack(spacing: 4) {
            Capsule().fill(Color.lcarsPeach).frame(height: 6)
            Capsule().fill(Color.lcarsPurple).frame(height: 6)
            Capsule().fill(Color.lcarsIce).frame(height: 6)
            Capsule().fill(Color.lcarsMagenta).frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var scoreList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { idx, player in
                    scoreRow(idx: idx, player: player)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 10)
        }
    }

    private func scoreRow(idx: Int, player: Player) -> some View {
        let isFirst = idx == 0
        let rankColor: Color = isFirst ? .lcarsGold : .lcarsOrange
        let rankLabel = idx == 0 ? "01" : idx == 1 ? "02" : idx == 2 ? "03" : "\(idx+1)"
        return HStack(spacing: 0) {
            Text(rankLabel)
                .font(LCARSFont.display(20))
                .foregroundStyle(.black)
                .frame(width: 52, height: 52)
                .background(isFirst ? Color.lcarsGold : Color.lcarsOrange.opacity(0.6))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 26, bottomLeadingRadius: 26,
                    bottomTrailingRadius: 0, topTrailingRadius: 0
                ))
            Rectangle()
                .fill(rankColor.opacity(isFirst ? 1.0 : 0.3))
                .frame(width: 4, height: 52)
            HStack(spacing: 14) {
                Text(player.faction.shipSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(player.faction.color)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name.uppercased())
                        .font(LCARSFont.display(17))
                        .foregroundStyle(Color.lcarsPeach)
                    Text(player.faction.displayName.uppercased())
                        .font(LCARSFont.caption(10))
                        .foregroundStyle(player.faction.color)
                        .tracking(2)
                }
                Spacer()
                Text("\(player.score)")
                    .font(LCARSFont.data(34))
                    .foregroundStyle(isFirst ? Color.lcarsGold : Color.lcarsPeach)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isFirst ? Color(white: 0.14) : Color(white: 0.08))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(isFirst ? RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.lcarsGold.opacity(0.5), lineWidth: 1) : nil)
    }
}

// MARK: - Preview

#Preview {
    GameView(vm: GameViewModel(players: [
        Player(name: "Adam",     faction: .federation),
        Player(name: "Player 2", faction: .klingon),
    ]))
}
