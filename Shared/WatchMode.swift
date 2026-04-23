import Foundation

enum WatchMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case inputPad
    case scoreGlance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inputPad: "Input Pad"
        case .scoreGlance: "Score Glance"
        }
    }

    var subtitle: String {
        switch self {
        case .inputPad: "Watch is input only"
        case .scoreGlance: "Watch shows scores at a glance"
        }
    }

    var systemImage: String {
        switch self {
        case .inputPad: "hand.tap.fill"
        case .scoreGlance: "applewatch"
        }
    }
}
