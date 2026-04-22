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

            section(title: "Controls") {
                SettingsIconStatusRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    value: isWatchConnected ? "Connected" : "Not Connected",
                    valueColor: isWatchConnected ? .pongleAccent : .white.opacity(0.45)
                )

                divider

                SettingsIconBadgeRow(
                    icon: "button.programmable",
                    title: "Flic Buttons",
                    badge: "Coming Soon"
                )

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

// MARK: - Row primitives

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.pongleAccent)
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
