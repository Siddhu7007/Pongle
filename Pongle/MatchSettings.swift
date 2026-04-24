//
//  MatchSettings.swift
//  Pongle
//

import AVFoundation
import Combine
import SwiftUI

// MARK: - Theme

extension Color {
    /// Tasteful ping-pong orange used for active UI accents (toggles, connection indicators, etc.).
    static let pongleAccent = Color(red: 0.98, green: 0.56, blue: 0.20)
}

// MARK: - Models

enum PointsToWin: Int, CaseIterable, Identifiable {
    case eleven = 11
    case twentyOne = 21

    var id: Int { rawValue }

    var shortLabel: String { "\(rawValue) pts" }
}

enum MatchLength: Int, CaseIterable, Identifiable {
    case single = 1
    case bestOfThree = 3
    case bestOfFive = 5

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .single: "Single game"
        case .bestOfThree: "Best of 3"
        case .bestOfFive: "Best of 5"
        }
    }

    var gamesToWin: Int {
        (rawValue / 2) + 1
    }
}

enum PlayerBatColor: String, CaseIterable, Identifiable {
    case teal
    case orange
    case blue
    case red
    case lime
    case purple

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .teal: "Teal"
        case .orange: "Orange"
        case .blue: "Blue"
        case .red: "Red"
        case .lime: "Lime"
        case .purple: "Purple"
        }
    }

    var imageName: String {
        switch self {
        case .teal: "BatTeal"
        case .orange: "BatOrange"
        case .blue: "BatBlue"
        case .red: "BatRed"
        case .lime: "BatLime"
        case .purple: "BatPurple"
        }
    }

    var accentColor: Color {
        switch self {
        case .teal: Color(red: 0.00, green: 0.68, blue: 0.66)
        case .orange: Color.pongleAccent
        case .blue: Color(red: 0.18, green: 0.38, blue: 0.96)
        case .red: Color(red: 0.96, green: 0.16, blue: 0.20)
        case .lime: Color(red: 0.62, green: 0.82, blue: 0.12)
        case .purple: Color(red: 0.62, green: 0.30, blue: 0.88)
        }
    }
}

// MARK: - AppSettings

@MainActor
final class AppSettings: ObservableObject {
    static let playerNameLimit = 18

    private enum Key {
        static let pointsToWin = "pongle.pointsToWin"
        static let matchLength = "pongle.matchLength"
        static let switchSides = "pongle.switchSides"
        static let switchSidesFinalSet = "pongle.switchSidesFinalSet"
        static let announcementsEnabled = "pongle.announcementsEnabled"
        static let announceScore = "pongle.announceScore"
        static let announceWinner = "pongle.announceWinner"
        static let voiceIdentifier = "pongle.voiceIdentifier"
        static let playerOneName = "pongle.playerOneName"
        static let playerTwoName = "pongle.playerTwoName"
        static let playerOneBatColor = "pongle.playerOneBatColor"
        static let playerTwoBatColor = "pongle.playerTwoBatColor"
        static let watchMode = "pongle.watchMode"
        static let watchSwipeEnabled = "pongle.watchSwipeEnabled"
        static let iphoneTapInputEnabled = "iphoneTapInputEnabled"
        static let flicInputEnabled = "pongle.flicInputEnabled"
    }

    @Published var pointsToWin: PointsToWin {
        didSet { UserDefaults.standard.set(pointsToWin.rawValue, forKey: Key.pointsToWin) }
    }

    @Published var matchLength: MatchLength {
        didSet { UserDefaults.standard.set(matchLength.rawValue, forKey: Key.matchLength) }
    }

    @Published var switchSides: Bool {
        didSet { UserDefaults.standard.set(switchSides, forKey: Key.switchSides) }
    }

    @Published var switchSidesInFinalSet: Bool {
        didSet { UserDefaults.standard.set(switchSidesInFinalSet, forKey: Key.switchSidesFinalSet) }
    }

    @Published var announcementsEnabled: Bool {
        didSet { UserDefaults.standard.set(announcementsEnabled, forKey: Key.announcementsEnabled) }
    }

    @Published var announceScore: Bool {
        didSet { UserDefaults.standard.set(announceScore, forKey: Key.announceScore) }
    }

    @Published var announceWinner: Bool {
        didSet { UserDefaults.standard.set(announceWinner, forKey: Key.announceWinner) }
    }

    @Published var voiceIdentifier: String {
        didSet { UserDefaults.standard.set(voiceIdentifier, forKey: Key.voiceIdentifier) }
    }

    @Published var playerOneName: String {
        didSet { UserDefaults.standard.set(Self.limitedPlayerName(playerOneName), forKey: Key.playerOneName) }
    }

    @Published var playerTwoName: String {
        didSet { UserDefaults.standard.set(Self.limitedPlayerName(playerTwoName), forKey: Key.playerTwoName) }
    }

    @Published var playerOneBatColor: PlayerBatColor {
        didSet { UserDefaults.standard.set(playerOneBatColor.rawValue, forKey: Key.playerOneBatColor) }
    }

    @Published var playerTwoBatColor: PlayerBatColor {
        didSet { UserDefaults.standard.set(playerTwoBatColor.rawValue, forKey: Key.playerTwoBatColor) }
    }

    @Published var watchMode: WatchMode {
        didSet { UserDefaults.standard.set(watchMode.rawValue, forKey: Key.watchMode) }
    }

    @Published var watchSwipeEnabled: Bool {
        didSet { UserDefaults.standard.set(watchSwipeEnabled, forKey: Key.watchSwipeEnabled) }
    }

    @Published var iphoneTapInputEnabled: Bool {
        didSet { UserDefaults.standard.set(iphoneTapInputEnabled, forKey: Key.iphoneTapInputEnabled) }
    }

    @Published var flicInputEnabled: Bool {
        didSet { UserDefaults.standard.set(flicInputEnabled, forKey: Key.flicInputEnabled) }
    }

    init() {
        let defaults = UserDefaults.standard

        let storedPoints = defaults.object(forKey: Key.pointsToWin) as? Int
        self.pointsToWin = PointsToWin(rawValue: storedPoints ?? 11) ?? .eleven

        let storedMatch = defaults.object(forKey: Key.matchLength) as? Int
        self.matchLength = MatchLength(rawValue: storedMatch ?? 3) ?? .bestOfThree

        self.switchSides = (defaults.object(forKey: Key.switchSides) as? Bool) ?? true
        self.switchSidesInFinalSet = (defaults.object(forKey: Key.switchSidesFinalSet) as? Bool) ?? true
        self.announcementsEnabled = (defaults.object(forKey: Key.announcementsEnabled) as? Bool) ?? true
        self.announceScore = (defaults.object(forKey: Key.announceScore) as? Bool) ?? true
        self.announceWinner = (defaults.object(forKey: Key.announceWinner) as? Bool) ?? true
        self.voiceIdentifier = defaults.string(forKey: Key.voiceIdentifier) ?? ""
        self.playerOneName = Self.limitedPlayerName(defaults.string(forKey: Key.playerOneName) ?? "")
        self.playerTwoName = Self.limitedPlayerName(defaults.string(forKey: Key.playerTwoName) ?? "")
        self.playerOneBatColor = PlayerBatColor(rawValue: defaults.string(forKey: Key.playerOneBatColor) ?? "") ?? .teal
        self.playerTwoBatColor = PlayerBatColor(rawValue: defaults.string(forKey: Key.playerTwoBatColor) ?? "") ?? .orange
        self.watchMode = WatchMode(rawValue: defaults.string(forKey: Key.watchMode) ?? "") ?? .inputPad
        self.watchSwipeEnabled = (defaults.object(forKey: Key.watchSwipeEnabled) as? Bool) ?? true
        self.iphoneTapInputEnabled = (defaults.object(forKey: Key.iphoneTapInputEnabled) as? Bool) ?? false
        self.flicInputEnabled = (defaults.object(forKey: Key.flicInputEnabled) as? Bool) ?? false
    }

    var voiceDisplayName: String {
        guard !voiceIdentifier.isEmpty,
              let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) else {
            return "System"
        }
        return voice.name
    }

    func displayName(for player: Player) -> String {
        let candidate: String
        switch player {
        case .playerOne:
            candidate = playerOneName
        case .playerTwo:
            candidate = playerTwoName
        }

        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return player.displayName
        }
        return Self.limitedPlayerName(trimmed)
    }

    func batColor(for player: Player) -> PlayerBatColor {
        switch player {
        case .playerOne: playerOneBatColor
        case .playerTwo: playerTwoBatColor
        }
    }

    func setName(_ name: String, for player: Player) {
        let limitedName = Self.limitedPlayerName(name)
        switch player {
        case .playerOne: playerOneName = limitedName
        case .playerTwo: playerTwoName = limitedName
        }
    }

    func setBatColor(_ color: PlayerBatColor, for player: Player) {
        switch player {
        case .playerOne: playerOneBatColor = color
        case .playerTwo: playerTwoBatColor = color
        }
    }

    static func limitedPlayerName(_ name: String) -> String {
        String(name.prefix(playerNameLimit))
    }
}

// MARK: - Match Controls Panel

struct MatchControlsDock: View {
    @EnvironmentObject var settings: AppSettings
    let isWatchConnected: Bool
    @ObservedObject var flicInput: FlicInputController
    let onRulesChanged: () -> Void

    @State private var isVoicePickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(title: "Settings") {
                SettingsMenuRow(
                    title: "Mode",
                    options: PointsToWin.allCases,
                    selection: Binding(
                        get: { settings.pointsToWin },
                        set: { newValue in
                            settings.pointsToWin = newValue
                            onRulesChanged()
                        }
                    ),
                    label: { "\($0.rawValue) points" }
                )

                divider

                SettingsMenuRow(
                    title: "Sets",
                    options: MatchLength.allCases,
                    selection: Binding(
                        get: { settings.matchLength },
                        set: { newValue in
                            settings.matchLength = newValue
                            onRulesChanged()
                        }
                    ),
                    label: { $0.shortLabel }
                )

                divider

                SettingsToggleRow(title: "Switch sides", isOn: $settings.switchSides)

                if settings.matchLength != .single {
                    divider
                    SettingsToggleRow(
                        title: "Switch sides in last set",
                        isOn: $settings.switchSidesInFinalSet
                    )
                }

                divider

                SettingsToggleRow(
                    title: "Announcements",
                    isOn: $settings.announcementsEnabled
                )

                if settings.announcementsEnabled {
                    divider
                    SettingsDisclosureRow(
                        title: "Voice",
                        value: settings.voiceDisplayName
                    ) {
                        isVoicePickerPresented = true
                    }

                    divider
                    SettingsToggleRow(
                        title: "Speak score after point",
                        isOn: $settings.announceScore
                    )

                    divider
                    SettingsToggleRow(
                        title: "Speak game winner",
                        isOn: $settings.announceWinner
                    )
                }
            }

            section(title: "Players") {
                PlayerCustomizationPanel()
                    .padding(.vertical, 12)
            }

            section(title: "Watch Modes") {
                WatchModePickerSection()
                    .padding(.vertical, 12)
            }

            section(title: "Controls") {
                SettingsIconStatusRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    value: isWatchConnected ? "Connected" : "Not Connected",
                    valueColor: isWatchConnected ? .pongleAccent : .white.opacity(0.45)
                )

                divider

                SettingsToggleRow(
                    title: "Enable iPhone Tap Input",
                    subtitle: "Lets the iPhone scoreboard accept direct taps for testing",
                    isOn: $settings.iphoneTapInputEnabled
                )

                divider

                FlicControlRow(controller: flicInput)

                divider

                SettingsIconBadgeRow(
                    icon: "airpods",
                    title: "Headphones",
                    badge: "Later"
                )
            }
        }
        .sheet(isPresented: $isVoicePickerPresented) {
            VoicePickerSheet()
                .environmentObject(settings)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.045))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }

}

private struct PlayerCustomizationPanel: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            PlayerCustomizationCard(
                player: .playerOne,
                name: nameBinding(for: .playerOne),
                selectedColor: batColorBinding(for: .playerOne)
            )

            PlayerCustomizationCard(
                player: .playerTwo,
                name: nameBinding(for: .playerTwo),
                selectedColor: batColorBinding(for: .playerTwo)
            )
        }
    }

    private func nameBinding(for player: Player) -> Binding<String> {
        Binding(
            get: {
                switch player {
                case .playerOne: settings.playerOneName
                case .playerTwo: settings.playerTwoName
                }
            },
            set: { settings.setName($0, for: player) }
        )
    }

    private func batColorBinding(for player: Player) -> Binding<PlayerBatColor> {
        Binding(
            get: { settings.batColor(for: player) },
            set: { settings.setBatColor($0, for: player) }
        )
    }
}

private struct PlayerCustomizationCard: View {
    let player: Player
    @Binding var name: String
    @Binding var selectedColor: PlayerBatColor

    @State private var isPickerPresented = false

    private let swatchColumns = [
        GridItem(.flexible(minimum: 24), spacing: 6),
        GridItem(.flexible(minimum: 24), spacing: 6),
        GridItem(.flexible(minimum: 24), spacing: 6)
    ]

    var body: some View {
        VStack(spacing: 10) {
            Button {
                isPickerPresented = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.03))

                    Image(selectedColor.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                }
                .frame(height: 96)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change \(player.displayName) bat color")
            .popover(isPresented: $isPickerPresented, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                BatColorPickerPopover(selectedColor: $selectedColor)
                    .presentationCompactAdaptation(.popover)
            }

            TextField(player.displayName, text: $name)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct BatColorPickerPopover: View {
    @Binding var selectedColor: PlayerBatColor
    @Environment(\.dismiss) private var dismiss

    private let swatchColumns = [
        GridItem(.flexible(minimum: 36), spacing: 8),
        GridItem(.flexible(minimum: 36), spacing: 8),
        GridItem(.flexible(minimum: 36), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: swatchColumns, spacing: 8) {
            ForEach(PlayerBatColor.allCases) { color in
                Button {
                    selectedColor = color
                    dismiss()
                } label: {
                    Image(color.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(5)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(color == selectedColor ? 0.1 : 0.04))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    color == selectedColor
                                        ? Color.white.opacity(0.55)
                                        : Color.white.opacity(0.08),
                                    lineWidth: color == selectedColor ? 1.5 : 1
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(color.displayName) bat")
            }
        }
        .padding(12)
        .presentationBackground(Color(white: 0.12))
    }
}

private struct WatchModePickerSection: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WatchMode.allCases) { mode in
                        WatchModePreviewCard(
                            mode: mode,
                            isSelected: settings.watchMode == mode
                        ) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                settings.watchMode = mode
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            SettingsToggleRow(
                title: "Allow swiping between modes",
                isOn: $settings.watchSwipeEnabled
            )

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            SettingsValueRow(title: "Default watch mode", value: settings.watchMode.title)
        }
    }
}

private struct WatchModePreviewCard: View {
    let mode: WatchMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                WatchModeMiniPreview(mode: mode)
                    .frame(height: 82)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(mode.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Spacer(minLength: 4)

                        if isSelected {
                            Text("Default")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.pongleAccent))
                        }
                    }

                    Text(mode.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(10)
            .frame(width: 174, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.09 : 0.04))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color.pongleAccent : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title), \(mode.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct WatchModeMiniPreview: View {
    let mode: WatchMode

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }

            switch mode {
            case .inputPad:
                inputPadPreview
            case .scoreGlance:
                scoreGlancePreview
            }
        }
    }

    private var inputPadPreview: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(Color.green.opacity(0.2))
                .overlay {
                    Circle()
                        .stroke(Color.green.opacity(0.85), lineWidth: 1.5)
                }
                .overlay {
                    VStack(spacing: -1) {
                        Text("+1")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("ME")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))
                    }
                }
                .frame(width: 52, height: 52)

            Text("Tap • Tap Tap • Hold")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
    }

    private var scoreGlancePreview: some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                scorePreviewTile(value: "04", accent: Color.teal)
                scorePreviewTile(value: "02", accent: Color.pongleAccent)
            }

            Text("Player 1 +1")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
                .lineLimit(1)
        }
        .padding(8)
    }

    private func scorePreviewTile(value: String, accent: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(height: 3)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct FlicControlRow: View {
    @ObservedObject var controller: FlicInputController
    @State private var isShowingRemoveConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "button.programmable")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 22)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Flic Buttons")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))

                    Text(detailText)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(statusColor.opacity(0.13)))
                    .overlay(Capsule().stroke(statusColor.opacity(0.32), lineWidth: 1))
            }

            if !controller.buttons.isEmpty {
                VStack(spacing: 6) {
                    ForEach(controller.buttons) { button in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(button.isReady ? Color.green : Color.pongleAccent)
                                .frame(width: 7, height: 7)
                            Text(button.nickname?.isEmpty == false ? button.nickname! : button.serialNumber)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.76))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                            Spacer()
                            Text(button.stateDescription)
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.46))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                        )
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: primaryAction) {
                    Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.pongleAccent.opacity(primaryButtonEnabled ? 1 : 0.45))
                )
                .disabled(!primaryButtonEnabled)

                if controller.hasButtons {
                    Button(role: .destructive) {
                        isShowingRemoveConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red.opacity(0.92))
                            .frame(width: 42, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.07))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove Flic")
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Remove Flic?", isPresented: $isShowingRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                controller.removeAllButtons()
            }
        } message: {
            Text("Pongle will forget paired Flic buttons. You can add them again later.")
        }
    }

    private var statusText: String {
        switch controller.status {
        case .notSetUp:
            "Not Set Up"
        case .restoring:
            "Restoring"
        case .scanning:
            "Scanning"
        case .ready(let count):
            count == 1 ? "Ready" : "\(count) Ready"
        case .disconnected:
            "Disconnected"
        case .bluetoothOff:
            "Bluetooth Off"
        case .unauthorized:
            "Unauthorized"
        case .unsupported:
            "Unsupported"
        case .error:
            "Error"
        }
    }

    private var detailText: String {
        switch controller.status {
        case .notSetUp:
            "Single click scores you, double click scores opponent, hold undoes."
        case .restoring:
            "Restoring paired Flic buttons."
        case .scanning(let message):
            message
        case .ready:
            "Flic input is active for this match."
        case .disconnected(let count):
            count == 1 ? "Button is paired but not connected." : "\(count) buttons are paired but not connected."
        case .bluetoothOff:
            "Turn on Bluetooth to use Flic input."
        case .unauthorized:
            "Allow Bluetooth access in Settings to use Flic."
        case .unsupported:
            "This device or OS does not support Flic input."
        case .error(let message):
            message
        }
    }

    private var statusColor: Color {
        switch controller.status {
        case .ready:
            .green
        case .scanning, .restoring:
            .pongleAccent
        case .notSetUp, .disconnected:
            .white.opacity(0.58)
        case .bluetoothOff, .unauthorized, .unsupported, .error:
            .red.opacity(0.86)
        }
    }

    private var primaryButtonTitle: String {
        switch controller.status {
        case .notSetUp:
            "Add Flic"
        case .scanning:
            "Scanning"
        default:
            "Retry"
        }
    }

    private var primaryButtonIcon: String {
        switch controller.status {
        case .notSetUp:
            "plus.circle.fill"
        case .scanning:
            "antenna.radiowaves.left.and.right"
        default:
            "arrow.clockwise"
        }
    }

    private var primaryButtonEnabled: Bool {
        !controller.isScanning
    }

    private func primaryAction() {
        switch controller.status {
        case .notSetUp:
            controller.scan()
        default:
            controller.retry()
        }
    }
}

// MARK: - Row primitives

private struct SettingsToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))

                if let subtitle {
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.pongleAccent)
        }
        .frame(minHeight: subtitle == nil ? 40 : 52)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minHeight: 40)
    }
}

private struct SettingsMenuRow<T: Hashable & Identifiable>: View {
    let title: String
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Menu {
                Picker("", selection: $selection) {
                    ForEach(options) { option in
                        Text(label(option)).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(label(selection))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .frame(minHeight: 40)
    }
}

private struct SettingsDisclosureRow: View {
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                Spacer()
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(minHeight: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsIconStatusRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 22)
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .frame(minHeight: 46)
    }
}

private struct SettingsIconBadgeRow: View {
    let icon: String
    let title: String
    let badge: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.42))
                .frame(width: 22)
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(badge)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.09)))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .frame(minHeight: 46)
    }
}

// MARK: - Voice picker

struct VoicePickerSheet: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private let previewer = AVSpeechSynthesizer()

    private var voices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    voiceRow(identifier: "", name: "System default")
                }
                Section("English voices") {
                    ForEach(voices, id: \.identifier) { voice in
                        voiceRow(identifier: voice.identifier, name: voice.name)
                    }
                }
            }
            .navigationTitle("Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func voiceRow(identifier: String, name: String) -> some View {
        Button {
            settings.voiceIdentifier = identifier
            preview(identifier: identifier)
        } label: {
            HStack {
                Text(name)
                Spacer()
                if identifier == settings.voiceIdentifier {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.pongleAccent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func preview(identifier: String) {
        if previewer.isSpeaking {
            previewer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: "Two, zero")
        if !identifier.isEmpty {
            utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
        }
        previewer.speak(utterance)
    }
}
