@preconcurrency import flic2lib
import Combine
import Foundation

enum FlicInputStatus: Equatable {
    case notSetUp
    case restoring
    case scanning(String)
    case ready(Int)
    case disconnected(Int)
    case bluetoothOff
    case unauthorized
    case unsupported
    case error(String)
}

struct FlicButtonSnapshot: Equatable, Identifiable {
    let id: UUID
    let serialNumber: String
    let nickname: String?
    let stateDescription: String
    let isReady: Bool
    let batteryVoltage: Float
}

@MainActor
final class FlicInputController: NSObject, ObservableObject {
    @Published private(set) var status: FlicInputStatus = .notSetUp
    @Published private(set) var buttons: [FlicButtonSnapshot] = []
    @Published private(set) var isScanning = false

    private let settings: AppSettings
    private let eventHandler: (ScoreEvent) -> Void
    private var handledEventKeys: Set<FlicEventKey> = []
    private var hasRestoredManagerState = false
    private var pendingScanAfterRestore = false
    private var pendingConnectAfterRestore = false

    init(settings: AppSettings, eventHandler: @escaping (ScoreEvent) -> Void) {
        self.settings = settings
        self.eventHandler = eventHandler
        super.init()
    }

    var hasButtons: Bool {
        !buttons.isEmpty
    }

    func restoreIfEnabled() {
        guard settings.flicInputEnabled else {
            status = .notSetUp
            return
        }

        configureIfNeeded()
    }

    func scan() {
        guard let manager = configureIfNeeded() else {
            status = .error("Flic SDK is unavailable.")
            return
        }

        guard hasRestoredManagerState else {
            pendingScanAfterRestore = true
            isScanning = true
            status = .scanning("Preparing Bluetooth")
            return
        }

        startScan(using: manager)
    }

    private func startScan(using manager: FLICManager) {
        pendingScanAfterRestore = false

        guard !manager.isScanning else {
            isScanning = true
            status = .scanning("Looking for buttons")
            return
        }

        isScanning = true
        status = .scanning("Looking for buttons")

        manager.scanForButtons { [weak self] event in
            Task { @MainActor [weak self] in
                self?.status = .scanning(Self.scanStatusText(for: event))
            }
        } completion: { [weak self] button, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.isScanning = false

                if let button {
                    self.prepare(button)
                    self.settings.flicInputEnabled = true
                }

                if let error {
                    self.status = .error(error.localizedDescription)
                }

                self.refreshButtonsAndStatus(preservingError: error != nil)
            }
        }
    }

    func retry() {
        guard !isScanning else {
            return
        }

        guard let manager = configureIfNeeded() else {
            status = .error("Flic SDK is unavailable.")
            return
        }

        guard hasRestoredManagerState else {
            if settings.flicInputEnabled || !buttons.isEmpty {
                pendingConnectAfterRestore = true
                status = .restoring
            } else {
                pendingScanAfterRestore = true
                isScanning = true
                status = .scanning("Preparing Bluetooth")
            }
            return
        }

        if buttons.isEmpty {
            startScan(using: manager)
        } else {
            connectPreparedButtons(using: manager)
        }
    }

    func removeAllButtons() {
        guard let manager = configureIfNeeded() else {
            settings.flicInputEnabled = false
            buttons = []
            status = .notSetUp
            return
        }

        guard hasRestoredManagerState else {
            pendingScanAfterRestore = false
            pendingConnectAfterRestore = false
            isScanning = false
            status = .restoring
            return
        }

        let knownButtons = manager.buttons()
        guard !knownButtons.isEmpty else {
            settings.flicInputEnabled = false
            buttons = []
            status = .notSetUp
            return
        }

        for button in knownButtons {
            manager.forgetButton(button) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    self?.refreshButtonsAndStatus()
                }
            }
        }

        settings.flicInputEnabled = false
        handledEventKeys.removeAll(keepingCapacity: true)
        buttons = []
        status = .notSetUp
    }

    @discardableResult
    private func configureIfNeeded() -> FLICManager? {
        if let manager = FLICManager.shared() {
            manager.delegate = self
            manager.buttonDelegate = self
            return manager
        }

        status = .restoring
        return FLICManager.configure(with: self, buttonDelegate: self, background: true)
    }

    private func prepare(_ button: FLICButton) {
        button.delegate = self
        button.triggerMode = .clickAndDoubleClickAndHold
    }

    private func refreshButtonsAndStatus(preservingError: Bool = false) {
        guard let manager = FLICManager.shared() else {
            buttons = []
            status = settings.flicInputEnabled ? .error("Flic SDK is not configured.") : .notSetUp
            return
        }

        guard hasRestoredManagerState else {
            updateStatusBeforeRestore(for: manager.state, preservingError: preservingError)
            return
        }

        let knownButtons = manager.buttons()
        knownButtons.forEach(prepare)

        buttons = knownButtons.map(Self.snapshot(for:))

        if !knownButtons.isEmpty {
            settings.flicInputEnabled = true
        } else if !isScanning {
            settings.flicInputEnabled = false
        }

        guard !isScanning, !preservingError else {
            return
        }

        switch manager.state {
        case .poweredOn:
            if buttons.isEmpty {
                status = .notSetUp
            } else if buttons.contains(where: \.isReady) {
                status = .ready(buttons.filter(\.isReady).count)
            } else {
                status = .disconnected(buttons.count)
            }
        case .poweredOff:
            status = .bluetoothOff
        case .unauthorized:
            status = .unauthorized
        case .unsupported:
            status = .unsupported
        case .resetting, .unknown:
            status = .restoring
        @unknown default:
            status = .error("Unknown Bluetooth state.")
        }
    }

    private func connectPreparedButtons(using manager: FLICManager) {
        guard hasRestoredManagerState else {
            pendingConnectAfterRestore = true
            status = .restoring
            return
        }

        refreshButtonsAndStatus()

        guard manager.state == .poweredOn else {
            return
        }

        manager.buttons().forEach { button in
            prepare(button)
            button.connect()
        }
    }

    private func handleRestoredManager(_ manager: FLICManager) {
        hasRestoredManagerState = true

        if pendingScanAfterRestore {
            startScan(using: manager)
            return
        }

        if pendingConnectAfterRestore || settings.flicInputEnabled {
            pendingConnectAfterRestore = false
            connectPreparedButtons(using: manager)
            return
        }

        refreshButtonsAndStatus()
    }

    private func handleManagerStateUpdate(_ manager: FLICManager) {
        guard hasRestoredManagerState else {
            updateStatusBeforeRestore(for: manager.state, preservingError: false)
            return
        }

        refreshButtonsAndStatus()
    }

    private func updateStatusBeforeRestore(for state: FLICManagerState, preservingError: Bool) {
        guard !preservingError else {
            return
        }

        switch state {
        case .poweredOn:
            status = pendingScanAfterRestore ? .scanning("Preparing Bluetooth") : .restoring
        case .poweredOff:
            pendingScanAfterRestore = false
            isScanning = false
            status = .bluetoothOff
        case .unauthorized:
            pendingScanAfterRestore = false
            isScanning = false
            status = .unauthorized
        case .unsupported:
            pendingScanAfterRestore = false
            isScanning = false
            status = .unsupported
        case .resetting, .unknown:
            status = .restoring
        @unknown default:
            pendingScanAfterRestore = false
            isScanning = false
            status = .error("Unknown Bluetooth state.")
        }
    }

    private func handleButtonEvent(
        buttonID: UUID,
        eventCount: UInt32,
        kind: FlicScoreKind,
        wasQueued: Bool,
        age: Double
    ) {
        guard !wasQueued || age <= 2 else {
            return
        }

        let key = FlicEventKey(buttonID: buttonID, eventCount: eventCount, kind: kind)
        guard handledEventKeys.insert(key).inserted else {
            return
        }

        if handledEventKeys.count > 200 {
            handledEventKeys.removeAll(keepingCapacity: true)
            handledEventKeys.insert(key)
        }

        switch kind {
        case .singleClick:
            eventHandler(.point(player: .playerOne))
        case .doubleClick:
            eventHandler(.point(player: .playerTwo))
        case .hold:
            eventHandler(.undo)
        }
    }

    private static func snapshot(for button: FLICButton) -> FlicButtonSnapshot {
        FlicButtonSnapshot(
            id: button.identifier,
            serialNumber: button.serialNumber,
            nickname: button.nickname,
            stateDescription: stateDescription(for: button.state),
            isReady: button.isReady,
            batteryVoltage: button.batteryVoltage
        )
    }

    private static func stateDescription(for state: FLICButtonState) -> String {
        switch state {
        case .connected:
            "Connected"
        case .connecting:
            "Connecting"
        case .disconnected:
            "Disconnected"
        case .disconnecting:
            "Disconnecting"
        @unknown default:
            "Unknown"
        }
    }

    private static func scanStatusText(for event: FLICButtonScannerStatusEvent) -> String {
        switch event {
        case .discovered:
            "Button discovered"
        case .connected:
            "Verifying button"
        case .verified:
            "Button verified"
        case .verificationFailed:
            "Verification failed"
        @unknown default:
            "Scanning"
        }
    }
}

extension FlicInputController: FLICManagerDelegate {
    nonisolated func managerDidRestoreState(_ manager: FLICManager) {
        Task { @MainActor [weak self] in
            self?.handleRestoredManager(manager)
        }
    }

    nonisolated func manager(_ manager: FLICManager, didUpdate state: FLICManagerState) {
        Task { @MainActor [weak self] in
            self?.handleManagerStateUpdate(manager)
        }
    }
}

extension FlicInputController: FLICButtonDelegate {
    nonisolated func buttonDidConnect(_ button: FLICButton) {
        Task { @MainActor [weak self] in
            self?.refreshButtonsAndStatus()
        }
    }

    nonisolated func buttonIsReady(_ button: FLICButton) {
        Task { @MainActor [weak self] in
            self?.refreshButtonsAndStatus()
        }
    }

    nonisolated func button(_ button: FLICButton, didDisconnectWithError error: Error?) {
        Task { @MainActor [weak self] in
            if let error {
                self?.status = .error(error.localizedDescription)
            }
            self?.refreshButtonsAndStatus(preservingError: error != nil)
        }
    }

    nonisolated func button(_ button: FLICButton, didFailToConnectWithError error: Error?) {
        Task { @MainActor [weak self] in
            self?.status = .error(error?.localizedDescription ?? "Flic failed to connect.")
            self?.refreshButtonsAndStatus(preservingError: true)
        }
    }

    nonisolated func button(_ button: FLICButton, didReceive buttonEvent: FLICButtonEvent) {
        let buttonID = button.identifier
        let eventCount = buttonEvent.eventCount
        let wasQueued = buttonEvent.wasQueued
        let age = buttonEvent.age

        buttonEvent.isSingleOrDoubleClickOrHold { eventType, _ in
            let kind: FlicScoreKind?
            switch eventType {
            case .singleClick:
                kind = .singleClick
            case .doubleClick:
                kind = .doubleClick
            case .hold:
                kind = .hold
            default:
                kind = nil
            }

            guard let kind else {
                return
            }

            Task { @MainActor [weak self] in
                self?.handleButtonEvent(
                    buttonID: buttonID,
                    eventCount: eventCount,
                    kind: kind,
                    wasQueued: wasQueued,
                    age: age
                )
            }
        }
    }

    nonisolated func button(_ button: FLICButton, didUnpairWithError error: Error?) {
        Task { @MainActor [weak self] in
            self?.status = .error(error?.localizedDescription ?? "Flic pairing was removed.")
            self?.refreshButtonsAndStatus(preservingError: true)
        }
    }

    nonisolated func button(_ button: FLICButton, didUpdateBatteryVoltage voltage: Float) {
        Task { @MainActor [weak self] in
            self?.refreshButtonsAndStatus()
        }
    }

    nonisolated func button(_ button: FLICButton, didUpdateNickname nickname: String) {
        Task { @MainActor [weak self] in
            self?.refreshButtonsAndStatus()
        }
    }
}

private enum FlicScoreKind: Hashable {
    case singleClick
    case doubleClick
    case hold
}

private struct FlicEventKey: Hashable {
    let buttonID: UUID
    let eventCount: UInt32
    let kind: FlicScoreKind
}
