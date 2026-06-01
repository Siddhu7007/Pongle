import SwiftUI

enum FirstServerChoiceInputMode {
    case tapOnly
    case pressOnly
    case combined
    case dualButton

    static func mode(
        tapInputEnabled: Bool,
        externalInputAvailable: Bool,
        dualInputsAssigned: Bool = false
    ) -> FirstServerChoiceInputMode {
        if tapInputEnabled && externalInputAvailable {
            return .combined
        }

        if tapInputEnabled {
            return .tapOnly
        }

        return dualInputsAssigned ? .dualButton : .pressOnly
    }

    func instructionLines(playerOneName: String, playerTwoName: String) -> [String] {
        switch self {
        case .tapOnly:
            return ["Tap \(playerOneName) or \(playerTwoName) to choose who serves first"]
        case .pressOnly:
            return [
                "Single press = \(playerOneName) serves",
                "Double press = \(playerTwoName) serves"
            ]
        case .combined:
            return ["Tap a player or use single/double press to choose who serves first"]
        case .dualButton:
            return ["Each player uses their own button or watch to choose who serves first"]
        }
    }
}

struct FirstServerChoicePrompt: View {
    let playerOneName: String
    let playerTwoName: String
    let inputMode: FirstServerChoiceInputMode
    let isCompact: Bool

    var body: some View {
        VStack(spacing: isCompact ? 5 : 8) {
            Label {
                Text("Choose First Server")
            } icon: {
                Image(systemName: "hand.tap.fill")
            }
            .font(.system(size: isCompact ? 14 : 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)

            let lines = inputMode.instructionLines(playerOneName: playerOneName, playerTwoName: playerTwoName)
            VStack(spacing: isCompact ? 2 : 4) {
                ForEach(lines, id: \.self) { line in
                    promptLine(line)
                }
            }
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.66)
        .padding(.horizontal, isCompact ? 14 : 24)
        .padding(.vertical, isCompact ? 10 : 16)
        .frame(maxWidth: isCompact ? 360 : 560)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.pongleAccent.opacity(0.82), lineWidth: isCompact ? 1.5 : 2)
        )
        .shadow(color: Color.pongleAccent.opacity(0.34), radius: isCompact ? 12 : 22, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.44), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .combine)
    }

    private func promptLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 11 : 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .lineLimit(1)
            .minimumScaleFactor(0.58)
    }
}
