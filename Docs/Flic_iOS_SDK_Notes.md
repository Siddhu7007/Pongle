# Flic iOS SDK Notes

## SDK

- Use the official Flic 2 / Flic Duo SDK: https://github.com/50ButtonsEach/flic2lib-ios
- Package is pinned to revision `416d4cc5192ae1b14e525fac721016ca5cc3a0eb` (`1.5.0`).
- The iOS target links product `flic2lib`; the Watch target does not link Flic.
- Required iOS target settings:
  - `NSBluetoothAlwaysUsageDescription`: `Connect your Flic button to score points during a match.`
  - `UIBackgroundModes`: `bluetooth-central`
  - `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`: `YES`

## Event Mapping

Flic input is phone-side only and feeds the same scoring path as Watch and iPhone tap input.

| Flic event | Pongle event |
| --- | --- |
| Single click | `ScoreEvent.point(player: .playerOne)` |
| Double click | `ScoreEvent.point(player: .playerTwo)` |
| Hold | `ScoreEvent.undo` |

Implementation notes:

- `FlicInputController` configures `FLICManager` with `background: true`.
- Pairing uses `scanForButtons(stateChangeHandler:completion:)`.
- Restored buttons are reloaded in `managerDidRestoreState(_:)`.
- Buttons use `triggerMode = .clickAndDoubleClickAndHold`.
- Input events use `FLICButtonEvent.isSingleOrDoubleClickOrHold`.
- Queued events older than 2 seconds are ignored.
- Duplicate events are ignored by button identifier, event count, and event type.
- Flic Duo swipe/gesture events are ignored for the MVP.

## Manual Test Checklist

- Pair a Flic through Settings -> Controls -> Flic Buttons -> Add Flic.
- Confirm single click adds Player 1.
- Confirm double click adds Player 2.
- Confirm hold undoes the latest point.
- Confirm iPhone score, spoken score, and Watch score-glance state update after Flic input.
- Confirm rapid repeated accepted clicks do not drop SDK events.
- Relaunch Pongle and confirm the paired button restores.
- Toggle Bluetooth off and confirm the UI reports Bluetooth Off.
- Deny Bluetooth permission on a fresh install and confirm the UI reports Unauthorized.
- Background/lock-screen behavior is best-effort through Core Bluetooth background mode; force-quit is not guaranteed.
