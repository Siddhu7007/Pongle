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

enum MatchLength: Int, CaseIterable, Identifiable {
    case oneSet = 1
    case bestOfThree = 3
    case bestOfFive = 5
    case bestOfSeven = 7

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .oneSet: "1 game"
        case .bestOfThree: "Best of 3"
        case .bestOfFive: "Best of 5"
        case .bestOfSeven: "Best of 7"
        }
    }

    var gamesToWin: Int {
        switch self {
        case .oneSet: 1
        case .bestOfThree: 2
        case .bestOfFive: 3
        case .bestOfSeven: 4
        }
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

enum AnnouncementSpeed: String, CaseIterable, Identifiable {
    case oneX = "1x"
    case onePointFiveX = "1.5x"
    case twoX = "2x"
    case twoPointFiveX = "2.5x"

    var id: String { rawValue }
    var label: String { rawValue }

    var speechRate: Float {
        switch self {
        case .oneX:
            return Self.clamped(0.50)
        case .onePointFiveX:
            return Self.clamped(0.58)
        case .twoX:
            return Self.clamped(0.66)
        case .twoPointFiveX:
            return Self.clamped(0.74)
        }
    }

    private static func clamped(_ rate: Float) -> Float {
        min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    }
}

// MARK: - AppSettings

@MainActor
final class AppSettings: ObservableObject {
    static let playerNameLimit = 18

    private enum Key {
        static let scoringMode = "pongle.scoringMode"
        static let matchLength = "pongle.matchLength"
        static let announcementsEnabled = "pongle.announcementsEnabled"
        static let announceScore = "pongle.announceScore"
        static let announceWinner = "pongle.announceWinner"
        static let announcePointWinner = "pongle.announcePointWinner"
        static let announceNextServer = "pongle.announceNextServer"
        static let announceCurrentScore = "pongle.announceCurrentScore"
        static let announceCriticalPoints = "pongle.announceCriticalPoints"
        static let announceDeuce = "pongle.announceDeuce"
        static let announceUndoLastPoint = "pongle.announceUndoLastPoint"
        static let announcementSpeed = "pongle.announcementSpeed"
        static let voiceIdentifier = "pongle.voiceIdentifier"
        static let playerOneName = "pongle.playerOneName"
        static let playerTwoName = "pongle.playerTwoName"
        static let playerOneBatColor = "pongle.playerOneBatColor"
        static let playerTwoBatColor = "pongle.playerTwoBatColor"
        static let iphoneTapInputEnabled = "iphoneTapInputEnabled"
        static let flicInputEnabled = "pongle.flicInputEnabled"
        static let oneInputPerPlayer = "pongle.oneInputPerPlayer"
        static let flicButtonAssignments = "pongle.flicButtonAssignments"
        static let watchAssignedPlayer = "pongle.watchAssignedPlayer"
    }

    @Published var scoringMode: ScoringMode {
        didSet { UserDefaults.standard.set(scoringMode.rawValue, forKey: Key.scoringMode) }
    }

    @Published var matchLength: MatchLength {
        didSet { UserDefaults.standard.set(matchLength.rawValue, forKey: Key.matchLength) }
    }

    var onAnnouncementsChanged: (@Sendable (Bool) -> Void)?

    @Published var announcementsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(announcementsEnabled, forKey: Key.announcementsEnabled)
            if announcementsEnabled != oldValue {
                onAnnouncementsChanged?(announcementsEnabled)
            }
        }
    }

    @Published var announceScore: Bool {
        didSet { UserDefaults.standard.set(announceScore, forKey: Key.announceScore) }
    }

    @Published var announceWinner: Bool {
        didSet { UserDefaults.standard.set(announceWinner, forKey: Key.announceWinner) }
    }

    @Published var announcePointWinner: Bool {
        didSet { UserDefaults.standard.set(announcePointWinner, forKey: Key.announcePointWinner) }
    }

    @Published var announceNextServer: Bool {
        didSet { UserDefaults.standard.set(announceNextServer, forKey: Key.announceNextServer) }
    }

    @Published var announceCurrentScore: Bool {
        didSet { UserDefaults.standard.set(announceCurrentScore, forKey: Key.announceCurrentScore) }
    }

    @Published var announceCriticalPoints: Bool {
        didSet { UserDefaults.standard.set(announceCriticalPoints, forKey: Key.announceCriticalPoints) }
    }

    @Published var announceDeuce: Bool {
        didSet { UserDefaults.standard.set(announceDeuce, forKey: Key.announceDeuce) }
    }

    @Published var announceUndoLastPoint: Bool {
        didSet { UserDefaults.standard.set(announceUndoLastPoint, forKey: Key.announceUndoLastPoint) }
    }

    @Published var announcementSpeed: AnnouncementSpeed {
        didSet { UserDefaults.standard.set(announcementSpeed.rawValue, forKey: Key.announcementSpeed) }
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

    @Published var iphoneTapInputEnabled: Bool {
        didSet { UserDefaults.standard.set(iphoneTapInputEnabled, forKey: Key.iphoneTapInputEnabled) }
    }

    @Published var flicInputEnabled: Bool {
        didSet { UserDefaults.standard.set(flicInputEnabled, forKey: Key.flicInputEnabled) }
    }

    /// When ON, each player binds to their own input source (a Flic button or
    /// the Apple Watch) and a single press/tap scores that player. When OFF
    /// (default) the V1 single-input behavior is preserved exactly.
    @Published var oneInputPerPlayer: Bool {
        didSet { UserDefaults.standard.set(oneInputPerPlayer, forKey: Key.oneInputPerPlayer) }
    }

    /// Maps a Flic button identifier (UUID string) to the player it scores.
    @Published var flicButtonAssignments: [String: Player] {
        didSet {
            UserDefaults.standard.set(flicButtonAssignments.mapValues(\.rawValue), forKey: Key.flicButtonAssignments)
        }
    }

    /// The single Apple Watch's assigned player, if any (one watch total).
    @Published var watchAssignedPlayer: Player? {
        didSet {
            if let raw = watchAssignedPlayer?.rawValue {
                UserDefaults.standard.set(raw, forKey: Key.watchAssignedPlayer)
            } else {
                UserDefaults.standard.removeObject(forKey: Key.watchAssignedPlayer)
            }
        }
    }

    init() {
        let defaults = UserDefaults.standard

        self.scoringMode = ScoringMode(rawValue: defaults.string(forKey: Key.scoringMode) ?? "") ?? .eleven
        self.matchLength = MatchLength(rawValue: defaults.integer(forKey: Key.matchLength)) ?? .bestOfThree

        self.announcementsEnabled = (defaults.object(forKey: Key.announcementsEnabled) as? Bool) ?? true
        self.announceScore = (defaults.object(forKey: Key.announceScore) as? Bool) ?? true
        self.announceWinner = (defaults.object(forKey: Key.announceWinner) as? Bool) ?? true
        self.announcePointWinner = (defaults.object(forKey: Key.announcePointWinner) as? Bool) ?? false
        self.announceNextServer = (defaults.object(forKey: Key.announceNextServer) as? Bool) ?? false
        self.announceCurrentScore = (defaults.object(forKey: Key.announceCurrentScore) as? Bool) ?? true
        self.announceCriticalPoints = (defaults.object(forKey: Key.announceCriticalPoints) as? Bool) ?? true
        self.announceDeuce = (defaults.object(forKey: Key.announceDeuce) as? Bool) ?? true
        self.announceUndoLastPoint = (defaults.object(forKey: Key.announceUndoLastPoint) as? Bool) ?? true
        self.announcementSpeed = AnnouncementSpeed(rawValue: defaults.string(forKey: Key.announcementSpeed) ?? "") ?? .oneX
        let preferredVoiceIdentifier = Self.samanthaVoiceIdentifier() ?? ""
        self.voiceIdentifier = preferredVoiceIdentifier
        defaults.set(preferredVoiceIdentifier, forKey: Key.voiceIdentifier)
        self.playerOneName = Self.limitedPlayerName(defaults.string(forKey: Key.playerOneName) ?? "")
        self.playerTwoName = Self.limitedPlayerName(defaults.string(forKey: Key.playerTwoName) ?? "")
        self.playerOneBatColor = PlayerBatColor(rawValue: defaults.string(forKey: Key.playerOneBatColor) ?? "") ?? .teal
        self.playerTwoBatColor = PlayerBatColor(rawValue: defaults.string(forKey: Key.playerTwoBatColor) ?? "") ?? .orange
        self.iphoneTapInputEnabled = (defaults.object(forKey: Key.iphoneTapInputEnabled) as? Bool) ?? false
        self.flicInputEnabled = (defaults.object(forKey: Key.flicInputEnabled) as? Bool) ?? false
        self.oneInputPerPlayer = (defaults.object(forKey: Key.oneInputPerPlayer) as? Bool) ?? false
        let rawFlic = (defaults.dictionary(forKey: Key.flicButtonAssignments) as? [String: Int]) ?? [:]
        self.flicButtonAssignments = rawFlic.compactMapValues(Player.init(rawValue:))
        self.watchAssignedPlayer = (defaults.object(forKey: Key.watchAssignedPlayer) as? Int).flatMap(Player.init(rawValue:))
    }

    var scoringRules: ScoringRules {
        scoringMode.rules
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

    // MARK: - One-input-per-player assignment

    func player(forFlicButtonID id: String) -> Player? {
        flicButtonAssignments[id]
    }

    func assignedFlicButtonID(for player: Player) -> String? {
        flicButtonAssignments.first { $0.value == player }?.key
    }

    func usesWatch(_ player: Player) -> Bool {
        watchAssignedPlayer == player
    }

    func hasInput(for player: Player) -> Bool {
        usesWatch(player) || assignedFlicButtonID(for: player) != nil
    }

    var bothPlayersHaveInput: Bool {
        hasInput(for: .playerOne) && hasInput(for: .playerTwo)
    }

    /// Assign a Flic button to a player. One source per slot: removes any other
    /// button on that player. If it replaces the Watch, the Watch moves to the
    /// other open player slot so mixed Watch/Flic setups can be swapped directly.
    func assignFlicButton(_ id: String, to player: Player) {
        let displacedWatch = watchAssignedPlayer == player
        var updated = flicButtonAssignments
        for (key, value) in updated where value == player {
            updated.removeValue(forKey: key)
        }
        updated[id] = player
        flicButtonAssignments = updated

        if displacedWatch {
            watchAssignedPlayer = assignedFlicButtonID(for: player.opposite) == nil
                ? player.opposite
                : nil
        }
    }

    /// Assign the single Watch to a player. If that slot already uses a Flic,
    /// move the Flic to the other open slot instead of requiring another scan.
    func assignWatch(to player: Player) {
        let displacedButtonID = assignedFlicButtonID(for: player)
        var updated = flicButtonAssignments

        if let displacedButtonID {
            updated.removeValue(forKey: displacedButtonID)
            if !updated.values.contains(player.opposite) {
                updated[displacedButtonID] = player.opposite
            }
        }

        flicButtonAssignments = updated
        watchAssignedPlayer = player
    }

    func clearInput(for player: Player) {
        if let buttonID = assignedFlicButtonID(for: player) {
            flicButtonAssignments.removeValue(forKey: buttonID)
        }
        if watchAssignedPlayer == player {
            watchAssignedPlayer = nil
        }
    }

    func removeFlicButtonAssignment(id: String) {
        flicButtonAssignments.removeValue(forKey: id)
    }

    var announcementSpeechRate: Float {
        announcementSpeed.speechRate
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

    private static func samanthaVoiceIdentifier() -> String? {
        AVSpeechSynthesisVoice.speechVoices()
            .first { $0.name == "Samantha" && $0.language.hasPrefix("en") }?
            .identifier
    }
}

// MARK: - Match Controls Panel

struct MatchControlsDock: View {
    @EnvironmentObject var settings: AppSettings
    let isWatchConnected: Bool
    let isWatchAvailable: Bool
    let externalInputAvailable: Bool
    @ObservedObject var flicInput: FlicInputController
    let onEditPlayerNames: () -> Void
    @State private var isAnnouncementDetailsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            section(title: "Players") {
                PlayerCustomizationPanel(onEditPlayerNames: onEditPlayerNames)
                    .padding(.vertical, 12)
            }

            section(title: "Settings") {
                SettingsPickerRow(
                    title: "Mode",
                    selection: $settings.scoringMode,
                    options: ScoringMode.allCases,
                    label: { $0.shortLabel }
                )

                divider

                SettingsPickerRow(
                    title: "Sets",
                    selection: $settings.matchLength,
                    options: MatchLength.allCases,
                    label: { $0.shortLabel }
                )

                divider

                SettingsToggleRow(
                    title: "Announcements",
                    isOn: $settings.announcementsEnabled
                )

                divider

                SettingsToggleRow(
                    title: "Speak score after point",
                    isOn: $settings.announceScore
                )
                .disabled(!settings.announcementsEnabled)
                .opacity(settings.announcementsEnabled ? 1 : 0.48)

                divider

                SettingsToggleRow(
                    title: "Speak game winner",
                    isOn: $settings.announceWinner
                )
                .disabled(!settings.announcementsEnabled)
                .opacity(settings.announcementsEnabled ? 1 : 0.48)

                divider

                AnnouncementDetailsDisclosure(isExpanded: $isAnnouncementDetailsExpanded)
            }

            section(title: "Input Device Options") {
                SettingsIconStatusRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    value: watchStatusText,
                    valueColor: watchStatusColor
                )

                divider

                SettingsToggleRow(
                    title: "Enable Screen Tap Input",
                    isOn: $settings.iphoneTapInputEnabled,
                    isLocked: !externalInputAvailable,
                    lockedSubtitle: "Required — no Watch or Flic is connected"
                )

                divider

                SettingsToggleRow(
                    title: "Assign inputs to players",
                    subtitle: "Give each player a dedicated Watch or Flic control",
                    isOn: $settings.oneInputPerPlayer
                )
                .onChange(of: settings.oneInputPerPlayer) { _, _ in
                    flicInput.reapplyTriggerMode()
                }

                divider

                if settings.oneInputPerPlayer {
                    PlayerInputSlotsView(controller: flicInput, isWatchAvailable: isWatchAvailable)
                } else {
                    FlicControlRow(controller: flicInput)
                }

                divider

                SettingsIconBadgeRow(
                    icon: "airpods",
                    title: "Headphones",
                    badge: "Later"
                )
            }
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

    private var watchStatusText: String {
        if isWatchConnected {
            return "Connected"
        }
        return isWatchAvailable ? "Available" : "Not Available"
    }

    private var watchStatusColor: Color {
        if isWatchConnected {
            return .green
        }
        return isWatchAvailable ? .pongleAccent : .white.opacity(0.45)
    }
}

private struct AnnouncementDetailsDisclosure: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var isExpanded: Bool

    private var pointControlsEnabled: Bool {
        settings.announcementsEnabled && settings.announceScore
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                announcementToggle("Point Winner", isOn: $settings.announcePointWinner)

                divider

                announcementToggle("Next Server", isOn: $settings.announceNextServer)

                divider

                SettingsToggleRow(title: "Undo Last Point", isOn: $settings.announceUndoLastPoint)

                divider

                announcementToggle("Current Score", isOn: $settings.announceCurrentScore)

                divider

                announcementToggle("Set / Match Point", isOn: $settings.announceCriticalPoints)

                divider

                announcementToggle("Deuce", isOn: $settings.announceDeuce)

                divider

                speedPicker
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.pongleAccent)
                    .frame(width: 20)

                Text("Customize Announcements")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))

                Spacer()

                Text(settings.announcementSpeed.label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .frame(minHeight: 42)
            .contentShape(Rectangle())
        }
        .tint(.white.opacity(0.58))
        .disabled(!settings.announcementsEnabled)
        .opacity(settings.announcementsEnabled ? 1 : 0.48)
    }

    private func announcementToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        SettingsToggleRow(title: title, isOn: isOn)
            .disabled(!pointControlsEnabled)
            .opacity(pointControlsEnabled ? 1 : 0.5)
    }

    private var speedPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speech Speed")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            Picker("Speech Speed", selection: $settings.announcementSpeed) {
                ForEach(AnnouncementSpeed.allCases) { speed in
                    Text(speed.label).tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.pongleAccent)
        }
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}

private struct PlayerCustomizationPanel: View {
    @EnvironmentObject var settings: AppSettings
    let onEditPlayerNames: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            PlayerCustomizationCard(
                player: .playerOne,
                displayName: settings.displayName(for: .playerOne),
                selectedColor: batColorBinding(for: .playerOne),
                onEditName: onEditPlayerNames
            )

            PlayerCustomizationCard(
                player: .playerTwo,
                displayName: settings.displayName(for: .playerTwo),
                selectedColor: batColorBinding(for: .playerTwo),
                onEditName: onEditPlayerNames
            )
        }
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
    let displayName: String
    @Binding var selectedColor: PlayerBatColor
    let onEditName: () -> Void

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

            PlayerNameEditButton(
                player: player,
                displayName: displayName,
                action: onEditName
            )
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

private struct PlayerNameEditButton: View {
    let player: Player
    let displayName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(displayName)
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.085))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(player.displayName) name")
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

                    if let detailText {
                        Text(detailText)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)
                    }
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

    private var detailText: String? {
        switch controller.status {
        case .notSetUp:
            nil
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

// MARK: - One-input-per-player slots

private struct PlayerInputSlotsView: View {
    @ObservedObject var controller: FlicInputController
    let isWatchAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Player Input Assignments", systemImage: "person.2.badge.gearshape")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))

            Text("Single press or Watch tap scores the assigned player. Double press is ignored. Press and hold undoes.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))

            PlayerInputSlotRow(player: .playerOne, controller: controller, isWatchAvailable: isWatchAvailable)
            PlayerInputSlotRow(player: .playerTwo, controller: controller, isWatchAvailable: isWatchAvailable)

            if let problem = globalProblemText {
                Text(problem)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.red.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
    }

    /// Bluetooth/permission issues shared across both slots.
    private var globalProblemText: String? {
        switch controller.status {
        case .bluetoothOff:
            return "Turn on Bluetooth to use Flic buttons."
        case .unauthorized:
            return "Allow Bluetooth access in Settings to use Flic."
        case .unsupported:
            return "This device does not support Flic input."
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}

private struct PlayerInputSlotRow: View {
    @EnvironmentObject var settings: AppSettings
    let player: Player
    @ObservedObject var controller: FlicInputController
    let isWatchAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(player == .playerOne ? Color.white.opacity(0.9) : Color(white: 0.12))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(player == .playerOne ? "Player 1 Input" : "Player 2 Input")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(settings.displayName(for: player))
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: sourceIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text(statusText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(statusColor.opacity(0.13)))
                    .overlay(Capsule().stroke(statusColor.opacity(0.32), lineWidth: 1))
            }

            HStack(spacing: 8) {
                Button {
                    controller.scan(assignTo: player)
                } label: {
                    Label(
                        controller.assignedButton(for: player) == nil ? "Add Flic" : "Replace Flic",
                        systemImage: "button.programmable"
                    )
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pongleAccent.opacity(controller.isScanning ? 0.45 : 1))
                )
                .disabled(controller.isScanning)

                Button {
                    settings.assignWatch(to: player)
                } label: {
                    Label(
                        isWatchAvailable ? "Use Watch" : "Watch Unavailable",
                        systemImage: "applewatch"
                    )
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(settings.usesWatch(player) ? .black : .white)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(settings.usesWatch(player) ? Color.green : Color.white.opacity(0.08))
                )
                .disabled(!isWatchAvailable)
                .opacity(isWatchAvailable || settings.usesWatch(player) ? 1 : 0.5)

                if settings.hasInput(for: player) {
                    Button(role: .destructive) {
                        controller.removeButton(for: player)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(width: 38, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(player.displayName) input")
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }

    private var sourceIcon: String {
        if settings.usesWatch(player) {
            return "applewatch"
        }
        return controller.assignedButton(for: player) != nil ? "button.programmable" : "circle.dashed"
    }

    private var statusText: String {
        if controller.scanningPlayer == player {
            return "Scanning"
        }
        if settings.usesWatch(player) {
            return isWatchAvailable ? "Apple Watch" : "Watch Off"
        }
        if let button = controller.assignedButton(for: player) {
            return button.isReady ? "Connected" : "Disconnected"
        }
        return "Not Set Up"
    }

    private var statusColor: Color {
        if controller.scanningPlayer == player {
            return .pongleAccent
        }
        if settings.usesWatch(player) {
            return isWatchAvailable ? .green : .white.opacity(0.5)
        }
        if let button = controller.assignedButton(for: player) {
            return button.isReady ? .green : .white.opacity(0.58)
        }
        return .white.opacity(0.58)
    }
}

// MARK: - Row primitives

private struct SettingsToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    /// When true the toggle is forced ON, disabled, and uses `lockedSubtitle`
    /// (when provided) in place of `subtitle`. Used to make settings honest
    /// about state that the app overrides on the user's behalf.
    var isLocked: Bool = false
    var lockedSubtitle: String? = nil

    private var effectiveSubtitle: String? {
        isLocked ? (lockedSubtitle ?? subtitle) : subtitle
    }

    private var displayBinding: Binding<Bool> {
        isLocked ? .constant(true) : $isOn
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))

                if let effectiveSubtitle {
                    Text(effectiveSubtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Toggle("", isOn: displayBinding)
                .labelsHidden()
                .tint(Color.pongleAccent)
                .disabled(isLocked)
        }
        .frame(minHeight: effectiveSubtitle == nil ? 40 : 52)
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

private struct SettingsPickerRow<Value: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let label: (Value) -> String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Menu {
                Picker(title, selection: $selection) {
                    ForEach(options) { option in
                        Text(label(option)).tag(option)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(label(selection))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 40)
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
