//
//  SetupView.swift
//  Starcassonne
//

import SwiftUI

// MARK: - Setup View

struct SetupView: View {
    @State private var playerCount:    Int      = 2
    @State private var playerNames:    [String] = ["Player 1", "Player 2", "Player 3",
                                                    "Player 4", "Player 5", "Player 6"]
    @State private var playerFactions: [Faction] = [.federation, .klingon, .romulan,
                                                     .cardassian, .borg, .bajoran]
    @State private var startGame  = false
    @State private var showStyleLab = false   // ⚠️ TEMP — delete with StylePreviewView
    // Item 4: pre-loaded save state (nil = fresh new game)
    @State private var loadedVM: GameViewModel? = nil

    // Layout constants
    private let headerH:   CGFloat = 72
    private let footerH:   CGFloat = 70
    private let sidebarW:  CGFloat = 72
    private let outerR:    CGFloat = 44
    private let innerR:    CGFloat = 28

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Color.black.ignoresSafeArea()

                    // ── Top elbow (header + top portion of sidebar)
                    LCARSTopElbow(headerHeight: headerH, sidebarWidth: sidebarW,
                                  outerRadius: outerR, innerRadius: innerR)
                        .fill(Color.lcarsOrange)
                        .frame(width: geo.size.width, height: geo.size.height * 0.55)
                        .ignoresSafeArea(edges: .top)

                    // ── Bottom elbow (bottom portion of sidebar + footer)
                    LCARSBottomElbow(footerHeight: footerH, sidebarWidth: sidebarW,
                                     outerRadius: outerR, innerRadius: innerR)
                        .fill(Color.lcarsOrange)
                        .frame(width: geo.size.width, height: geo.size.height * 0.50)
                        .offset(y: geo.size.height * 0.50)
                        .ignoresSafeArea(edges: .bottom)

                    // ── Header content (title row)
                    headerContent
                        .frame(width: geo.size.width - sidebarW - outerR,
                               height: headerH)
                        .offset(x: sidebarW + outerR)
                        .ignoresSafeArea(edges: .top)

                    // ── Footer content (engage button)
                    footerContent
                        .frame(width: geo.size.width - sidebarW - outerR,
                               height: footerH)
                        .offset(x: sidebarW + outerR,
                                y: geo.size.height - footerH)
                        .ignoresSafeArea(edges: .bottom)

                    // ── Left sidebar: player count selector
                    sidebarContent
                        .frame(width: sidebarW, height: geo.size.height)
                        .ignoresSafeArea()

                    // ── Main content
                    mainContent
                        .padding(.leading, sidebarW + innerR + 20)
                        .padding(.trailing, 24)
                        .padding(.top, headerH + innerR + 16)
                        .padding(.bottom, footerH + innerR + 16)
                        .frame(width: geo.size.width, height: geo.size.height,
                               alignment: .topLeading)
                }
            }
            .navigationDestination(isPresented: $startGame) {
                GameView(vm: loadedVM ?? GameViewModel(players: buildPlayers()))
                    .navigationBarBackButtonHidden()
            }
            // ⚠️ TEMP — delete with StylePreviewView.swift
            .navigationDestination(isPresented: $showStyleLab) {
                StylePreviewView()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Sub-views

    private var headerContent: some View {
        HStack(spacing: 0) {
            // Thin accent line
            Rectangle()
                .fill(Color.lcarsPeach)
                .frame(width: 6, height: headerH * 0.55)

            VStack(alignment: .leading, spacing: 2) {
                Text("STARCASSONNE")
                    .font(LCARSFont.display(30))
                    .foregroundStyle(.black)
                    .tracking(5)
                Text("TACTICAL MISSION SETUP")
                    .font(LCARSFont.caption(10))
                    .foregroundStyle(.black.opacity(0.55))
                    .tracking(4)
            }
            .padding(.leading, 14)

            Spacer()

            // ⚠️ TEMP style lab button — delete with StylePreviewView.swift
            Button { showStyleLab = true } label: {
                Text("⬡ STYLE LAB")
                    .font(LCARSFont.label(10))
                    .foregroundStyle(.black)
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(Color.lcarsPeach)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)

            VStack(alignment: .trailing, spacing: 1) {
                Text("STARDATE")
                    .font(LCARSFont.caption(9))
                    .foregroundStyle(.black.opacity(0.55))
                    .tracking(3)
                Text("47634.44")
                    .font(LCARSFont.data(13))
                    .foregroundStyle(.black)
            }
            .padding(.trailing, 18)
        }
    }

    private var footerContent: some View {
        HStack {
            // Small blip strip
            LCARSBlipRow(colors: [.lcarsPurple, .lcarsIce, .lcarsPeach])
                .frame(width: 80)
                .padding(.leading, 8)

            Spacer()

            // Item 4: CONTINUE button — only shown when a save file exists
            if GamePersistence.hasSave {
                LCARSPill(label: "CONTINUE", color: .lcarsIce, width: 150, height: 44, fontSize: 16) {
                    LCARSAudio.shared.tap()
                    if let state = try? GamePersistence.load() {
                        loadedVM = GameViewModel(state: state)
                        startGame = true
                    }
                }
                .padding(.trailing, 10)
            }

            // Item 8: Voyager transporter sound on ENGAGE
            LCARSPill(label: "ENGAGE", color: .lcarsPeach, width: 180, height: 44, fontSize: 18) {
                LCARSAudio.shared.transporter()
                loadedVM = nil
                startGame = true
            }
            .padding(.trailing, 18)
        }
    }

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: headerH + innerR + 16)

            // Section label (rotated)
            Text("PLAYERS")
                .font(LCARSFont.caption(10))
                .foregroundStyle(.black.opacity(0.6))
                .tracking(3)
                .rotationEffect(.degrees(-90))
                .frame(height: 60)

            Spacer().frame(height: 4)

            // Count picker pills — left-anchored, right edge flush with sidebar
            VStack(spacing: 8) {
                ForEach(2...6, id: \.self) { n in
                    Button {
                        LCARSAudio.shared.playerCountBeep()   // Item 8
                        withAnimation(.easeInOut(duration: 0.18)) { playerCount = n }
                    } label: {
                        Text("\(n)")
                            .font(LCARSFont.label(18))
                            .foregroundStyle(.black)
                            .frame(width: sidebarW - 10, height: 38)
                            .background(n == playerCount ? Color.lcarsPeach : Color.lcarsOrange.opacity(0.45))
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 19, bottomLeadingRadius: 19,
                                    bottomTrailingRadius: 0, topTrailingRadius: 0
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Blips above bottom elbow
            VStack(spacing: 6) {
                ForEach([Color.lcarsViolet, Color.lcarsMagenta, Color.lcarsIce], id: \.self) { c in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(c)
                        .frame(width: sidebarW - 14, height: 12)
                }
            }
            .padding(.bottom, footerH + innerR + 12)
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 10) {
                LCARSDivider(color: .lcarsOrange, height: 5)
                    .frame(width: 40)
                Text("CREW MANIFEST")
                    .font(LCARSFont.caption(11))
                    .foregroundStyle(Color.lcarsOrange)
                    .tracking(5)
                LCARSDivider(color: .lcarsOrange.opacity(0.3), height: 3)
            }
            .padding(.bottom, 18)

            // Player rows
            ForEach(0..<playerCount, id: \.self) { i in
                LCARSPlayerRow(
                    index: i,
                    name: $playerNames[i],
                    faction: $playerFactions[i],
                    availableFactions: availableFactions(for: i)
                )
                .padding(.bottom, 10)
            }

            Spacer()

            // Footnote
            HStack(spacing: 8) {
                Capsule().fill(Color.lcarsViolet).frame(width: 24, height: 5)
                Text("FEDERATION STARFLEET — CLASSIFIED MISSION BRIEFING")
                    .font(LCARSFont.caption(9))
                    .foregroundStyle(Color.lcarsPurple.opacity(0.6))
                    .tracking(2)
            }
        }
    }

    // MARK: Helpers

    private func buildPlayers() -> [Player] {
        (0..<playerCount).map { i in
            Player(name: playerNames[i].isEmpty ? "Player \(i+1)" : playerNames[i],
                   faction: playerFactions[i])
        }
    }

    private func availableFactions(for index: Int) -> [Faction] {
        let chosen = (0..<playerCount)
            .filter { $0 != index }
            .map    { playerFactions[$0] }
        return Faction.allCases.filter { !chosen.contains($0) || playerFactions[index] == $0 }
    }
}

// MARK: - Player Row

private struct LCARSPlayerRow: View {
    let index: Int
    @Binding var name: String
    @Binding var faction: Faction
    let availableFactions: [Faction]

    private let rowColors: [Color] = [
        .lcarsOrange, .lcarsPeach, .lcarsGold,
        .lcarsPurple, .lcarsIce, .lcarsMagenta
    ]
    private var rowColor: Color { rowColors[index % rowColors.count] }

    var body: some View {
        HStack(spacing: 0) {
            // Index badge
            Text("\(index + 1)")
                .font(LCARSFont.display(18))
                .foregroundStyle(.black)
                .frame(width: 44, height: 48)
                .background(rowColor)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 24, bottomLeadingRadius: 24,
                    bottomTrailingRadius: 0, topTrailingRadius: 0
                ))

            // Thin spacer bar
            Rectangle()
                .fill(rowColor.opacity(0.4))
                .frame(width: 4, height: 48)

            // Name + faction on dark background
            HStack(spacing: 12) {
                // Ship symbol
                Text(faction.shipSymbol)
                    .font(.system(size: 20))
                    .foregroundStyle(faction.color)
                    .frame(width: 32)

                // Name field
                TextField("CALLSIGN", text: $name)
                    .font(LCARSFont.label(15))
                    .foregroundStyle(Color.lcarsPeach)
                    .tracking(2)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .frame(maxWidth: 160)

                Spacer()

                // Faction picker
                Picker("", selection: $faction) {
                    ForEach(availableFactions) { f in
                        HStack {
                            Image(systemName: f.sfSymbol)
                            Text(f.displayName.uppercased())
                                .font(LCARSFont.label(13))
                        }
                        .tag(f)
                    }
                }
                .pickerStyle(.menu)
                .tint(faction.color)
                .font(LCARSFont.label(13))
                .onChange(of: faction) { _, _ in LCARSAudio.shared.factionBeep() }   // Item 8
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color(white: 0.08))
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 0,
                bottomTrailingRadius: 6, topTrailingRadius: 6
            ))
        }
    }
}

// MARK: - Preview

#Preview {
    SetupView()
}
