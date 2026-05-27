//
//  LCARSComponents.swift
//  Starcassonne
//
//  Shared LCARS design system — colors, shapes, typography, audio.
//

import SwiftUI
import AVFoundation

// MARK: - Color palette

extension Color {
    /// Butterscotch — primary LCARS orange
    static let lcarsOrange  = Color(red: 1.00, green: 0.60, blue: 0.40)
    /// Sunflower — lighter peach accent
    static let lcarsPeach   = Color(red: 1.00, green: 0.80, blue: 0.60)
    /// Golden orange — warm highlight
    static let lcarsGold    = Color(red: 1.00, green: 0.67, blue: 0.00)
    /// African violet — purple accent
    static let lcarsPurple  = Color(red: 0.80, green: 0.60, blue: 1.00)
    /// Moonlit violet — deep purple
    static let lcarsViolet  = Color(red: 0.60, green: 0.40, blue: 1.00)
    /// Ice — cool blue
    static let lcarsIce     = Color(red: 0.60, green: 0.80, blue: 1.00)
    /// Mariner — mid blue
    static let lcarsBlue    = Color(red: 0.20, green: 0.40, blue: 0.80)
    /// Hopbush — magenta-pink
    static let lcarsMagenta = Color(red: 0.80, green: 0.33, blue: 0.60)
    /// Mars red — alert/warning
    static let lcarsRed     = Color(red: 0.80, green: 0.13, blue: 0.13)
}

// MARK: - Typography

enum LCARSFont {
    /// Compressed heavy — LCARS display headers
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black).width(.compressed)
    }
    /// Compressed bold — button labels, section headers
    static func label(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .bold).width(.compressed)
    }
    /// Monospaced — data readouts, scores
    static func data(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .heavy, design: .monospaced)
    }
    /// Small compressed — captions, tracking labels
    static func caption(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .bold).width(.compressed)
    }
}

// MARK: - Audio

/// Plays short TNG computer beep sounds on UI interactions.
/// Sounds must be added to the Xcode target's "Copy Bundle Resources".
@MainActor
final class LCARSAudio {
    static let shared = LCARSAudio()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        preload("lcars_tap")
        preload("lcars_confirm")
        preload("lcars_engage")
        preload("lcars_rotate")
        preload("lcars_alert")
        // Item 8: Trek audio polish
        preload("trek_transporter")
        preload("trek_computerbeep5")
        preload("trek_computerbeep11")
        preload("trek_qflash")
    }

    private func preload(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        players[name] = player
    }

    func play(_ name: String) {
        guard let player = players[name] else { return }
        if player.isPlaying { player.currentTime = 0 } else { player.play() }
    }

    // Convenience — original LCARS sounds
    func tap()     { play("lcars_tap") }
    func confirm() { play("lcars_confirm") }
    func engage()  { play("lcars_engage") }
    func rotate()  { play("lcars_rotate") }
    func alert()   { play("lcars_alert") }

    // Item 8: Trek-specific sounds
    func transporter()     { play("trek_transporter") }
    func factionBeep()     { play("trek_computerbeep5") }
    func playerCountBeep() { play("trek_computerbeep11") }
    func placement()       { play("trek_qflash") }
}

// MARK: - Shapes

/// Classic LCARS "elbow" — fills the top header strip + left sidebar.
/// Outer top-left corner is convex; the inner corner where header meets sidebar is concave.
struct LCARSTopElbow: Shape {
    var headerHeight: CGFloat
    var sidebarWidth: CGFloat
    var outerRadius:  CGFloat = 44
    var innerRadius:  CGFloat = 30

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let or = min(outerRadius, rect.width / 2, rect.height / 2)
        let ir = innerRadius

        p.move(to: CGPoint(x: 0, y: or))
        // Outer convex top-left arc
        p.addArc(center: CGPoint(x: or, y: or), radius: or,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        // Top edge → full width
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        // Right edge down to bottom of header
        p.addLine(to: CGPoint(x: rect.width, y: headerHeight))
        // Header bottom going left to inner corner
        p.addLine(to: CGPoint(x: sidebarWidth + ir, y: headerHeight))
        // Inner concave arc (cuts the corner inward)
        p.addArc(center: CGPoint(x: sidebarWidth + ir, y: headerHeight + ir), radius: ir,
                 startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        // Down the sidebar right edge
        p.addLine(to: CGPoint(x: sidebarWidth, y: rect.height))
        // Sidebar bottom → left
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()
        return p
    }
}

/// Mirrored elbow for the bottom: left sidebar connects via a concave inner corner to footer bar.
struct LCARSBottomElbow: Shape {
    var footerHeight: CGFloat
    var sidebarWidth: CGFloat
    var outerRadius:  CGFloat = 44
    var innerRadius:  CGFloat = 30

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let or = min(outerRadius, rect.width / 2, rect.height / 2)
        let ir = innerRadius

        p.move(to: CGPoint(x: 0, y: 0))
        // Sidebar top-left → right
        p.addLine(to: CGPoint(x: sidebarWidth, y: 0))
        // Down sidebar to concave corner
        p.addLine(to: CGPoint(x: sidebarWidth, y: rect.height - footerHeight - ir))
        // Inner concave arc
        p.addArc(center: CGPoint(x: sidebarWidth + ir, y: rect.height - footerHeight - ir),
                 radius: ir,
                 startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        // Footer top edge → full width
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - footerHeight))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        // Footer bottom → bottom-left convex arc
        p.addLine(to: CGPoint(x: or, y: rect.height))
        p.addArc(center: CGPoint(x: or, y: rect.height - or), radius: or,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Pill button

struct LCARSPill: View {
    let label: String
    var color: Color = .lcarsOrange
    var textColor: Color = .black
    var width: CGFloat? = nil
    var height: CGFloat = 38
    var fontSize: CGFloat = 14
    var tracking: CGFloat = 3
    let action: () -> Void

    var body: some View {
        Button(action: {
            LCARSAudio.shared.tap()
            action()
        }) {
            Text(label)
                .font(LCARSFont.label(fontSize))
                .foregroundStyle(textColor)
                .tracking(tracking)
                .frame(width: width, height: height)
                .padding(.horizontal, width == nil ? 22 : 0)
                .background(color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data readout block

/// A left-label + right-value LCARS readout panel.
/// The label has a colored pill background; the value shows on dark.
struct LCARSReadout: View {
    let label: String
    let value: String
    var labelColor: Color = .lcarsOrange
    var valueColor: Color = .lcarsPeach
    var height: CGFloat = 32

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(LCARSFont.caption(10))
                .foregroundStyle(.black)
                .tracking(2)
                .padding(.horizontal, 10)
                .frame(height: height)
                .background(labelColor)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: height / 2,
                    bottomLeadingRadius: height / 2,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                ))

            Text(value)
                .font(LCARSFont.data(14))
                .foregroundStyle(valueColor)
                .padding(.horizontal, 10)
                .frame(height: height)
                .background(Color(white: 0.1))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 4
                ))
        }
    }
}

// MARK: - Horizontal divider bar

struct LCARSDivider: View {
    var color: Color = .lcarsOrange
    var height: CGFloat = 6

    var body: some View {
        Capsule()
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - Status blip row

/// A row of small colored blips used as decorative separators / status indicators in sidebars.
struct LCARSBlipRow: View {
    let colors: [Color]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(colors.indices, id: \.self) { i in
                Capsule()
                    .fill(colors[i])
                    .frame(height: 14)
            }
        }
    }
}
