import Foundation
import HealthKit

enum WatchMatchModeState: Equatable {
    case inactive
    case requestingAuthorization
    case starting
    case active(startedAt: Date)
    case ending
    case unavailable
    case authorizationDenied
    case failed(String)

    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }

    var canStart: Bool {
        switch self {
        case .inactive, .authorizationDenied, .failed:
            true
        case .requestingAuthorization, .starting, .active, .ending, .unavailable:
            false
        }
    }

    var statusText: String {
        switch self {
        case .inactive:
            "Match Mode"
        case .requestingAuthorization:
            "Allowing..."
        case .starting:
            "Starting..."
        case .active:
            "Match Mode On"
        case .ending:
            "Ending..."
        case .unavailable:
            "Unavailable"
        case .authorizationDenied:
            "Health Access Needed"
        case .failed:
            "Match Mode Paused"
        }
    }
}

@MainActor
final class WatchMatchSessionController: NSObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate: Date?
    private var stateDidChange: (WatchMatchModeState) -> Void = { _ in }

    private(set) var state: WatchMatchModeState = .inactive {
        didSet {
            stateDidChange(state)
        }
    }

    init(stateDidChange: @escaping (WatchMatchModeState) -> Void) {
        self.stateDidChange = stateDidChange
        super.init()
    }

    func start() {
        guard state.canStart else {
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            state = .unavailable
            return
        }

        state = .requestingAuthorization
        let workoutType = HKObjectType.workoutType()

        healthStore.requestAuthorization(toShare: [workoutType], read: []) { [weak self] _, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.state = .failed(error.localizedDescription)
                    return
                }

                guard self.healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized else {
                    self.state = .authorizationDenied
                    return
                }

                self.beginWorkoutSession()
            }
        }
    }

    func end(saveToHealth: Bool) {
        guard state != .ending else {
            return
        }

        guard session != nil || builder != nil else {
            state = .inactive
            return
        }

        state = .ending

        guard saveToHealth else {
            builder?.discardWorkout()
            session?.end()
            finishAndReset(errorMessage: nil)
            return
        }

        session?.end()

        let endDate = Date()
        builder?.endCollection(withEnd: endDate) { [weak self] success, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                guard success, error == nil else {
                    self.finishAndReset(errorMessage: error?.localizedDescription ?? "Could not end match mode.")
                    return
                }

                self.finishWorkout()
            }
        }
    }

    private func beginWorkoutSession() {
        state = .starting

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .tableTennis
        configuration.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            session.delegate = self
            builder.delegate = self

            let startDate = Date()
            self.session = session
            self.builder = builder
            self.startDate = startDate

            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if success {
                        self.state = .active(startedAt: startDate)
                    } else {
                        self.session?.end()
                        self.finishAndReset(errorMessage: error?.localizedDescription ?? "Could not start match mode.")
                    }
                }
            }
        } catch {
            finishAndReset(errorMessage: error.localizedDescription)
        }
    }

    private func finishWorkout() {
        builder?.finishWorkout { [weak self] _, error in
            Task { @MainActor [weak self] in
                self?.finishAndReset(errorMessage: error?.localizedDescription)
            }
        }
    }

    private func finishAndReset(errorMessage: String?) {
        session?.delegate = nil
        builder?.delegate = nil
        session = nil
        builder = nil
        startDate = nil
        state = errorMessage.map(WatchMatchModeState.failed) ?? .inactive
    }
}

extension WatchMatchSessionController: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self, self.state != .ending else {
                return
            }

            self.end(saveToHealth: false)
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.finishAndReset(errorMessage: error.localizedDescription)
        }
    }
}

extension WatchMatchSessionController: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {}
}
