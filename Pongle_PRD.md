# Pongle — Ping Pong Score Tracking MVP PRD

_App name: **Pongle** (derived from Dongle + Ping Pong). Working name confirmed by client Cody Butler, Apr 21 2026._
_Bundle ID: `com.cynqventures.pongle`_
_Last updated: Apr 21 2026 — added haptics spec, confirmed app name_

---

## Agent Fetch References
_This section is for Codex / Claude Code via the Xcode Bridge. Fetch all URLs below before writing any code. These are the canonical Apple developer documentation pages for every API used in this project._

### WatchConnectivity (core transport)
- Framework overview: https://developer.apple.com/documentation/WatchConnectivity
- `WCSession`: https://developer.apple.com/documentation/watchconnectivity/wcsession
- `WCSessionDelegate`: https://developer.apple.com/documentation/watchconnectivity/wcsessiondelegate
- `sendMessage(_:replyHandler:errorHandler:)`: https://developer.apple.com/documentation/watchconnectivity/wcsession/sendmessage(_:replyhandler:errorhandler:)
- `isReachable`: https://developer.apple.com/documentation/watchconnectivity/wcsession/isreachable
- `updateApplicationContext(_:)`: https://developer.apple.com/documentation/watchconnectivity/wcsession/1615621-updateapplicationcontext

### Watch Haptics
- `WKHapticType` (all haptic constants): https://developer.apple.com/documentation/watchkit/wkhaptictype
- `WKInterfaceDevice` (call `.play(_ type:)` on this): https://developer.apple.com/documentation/watchkit/wkinterfacedevice

### Audio — iPhone
- `AVSpeechSynthesizer`: https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer
- `AVSpeechUtterance`: https://developer.apple.com/documentation/avfaudio/avspeechutterance
- `AVSpeechSynthesisVoice`: https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice
- Speech synthesis overview: https://developer.apple.com/documentation/avfoundation/speech-synthesis
- `AVAudioSession`: https://developer.apple.com/documentation/avfaudio/avaudiosession
- `AVAudioSession.Mode`: https://developer.apple.com/documentation/avfaudio/avaudiosession/mode

### Future / Backlog (fetch when starting phase 2)
- `MPRemoteCommandCenter` (headphone button input): https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter

---

## Recommendation

The clearest product direction is a **watch-first, phone-visible, no-onboarding MVP**: the Apple Watch is the input surface, the iPhone is the live scoreboard and audio surface, and the app should **launch directly into play** rather than asking the user to configure anything first. That recommendation matches both the market signal and the platform guidance. On the current App Store listings, Table Tennis Scoreboard Pro positions itself around remote score input from Apple Watch, headphones, Flic buttons, and touch, with spoken score output; adjacent apps like Voice Table Tennis Scoreboard and smartscore also validate that people value wearable input and spoken score more than deep setup at first launch. At the same time, Apple's Human Interface Guidelines explicitly recommend launching fast, making the first screen available immediately, and postponing nonessential setup or customization.

For this MVP, the product should therefore be even more direct than the reference app: **open straight into the single-player scoreboard scene**, with no onboarding, no pre-game wizard, and no "choose mode" gate on launch. Settings should exist, but they should live behind a gear button or bottom sheet, not as the first thing the user sees.

---

## Competitive landscape

**Table Tennis Scoreboard Pro** is the closest competitive reference and the most useful product benchmark. Its public listing says it supports score control from Apple Watch, headphones, Flic buttons, and touch, reads the score aloud, and tells the user who serves next. Its version history shows how the product evolved: rules settings were added mid-2024, Apple Watch support in July 2025, Bluetooth remote support in August 2025, game history in September 2025, an AirPlay picker in October 2025, simplified settings in January 2026, and Flic Duo support plus more announcer options in early 2026. That sequence is revealing: even the closest competitor started from a core scoreboard and then progressively accumulated inputs, rules, history, replay, and audio niceties. The lesson for this MVP is not "match parity"; it is "ship the narrow core that competitors built around, then layer breadth later."

The UI language of that app — dark, rounded-card layout, grouped settings, separate surfaces for input controls — is a useful style reference but also a warning: it is a **configuration-first** entrance, not a **match-first** entrance. For a product whose stated purpose is fast real-game testing, that is too much friction on day one.

Two adjacent competitors sharpen the opportunity. **Voice Table Tennis Scoreboard** emphasizes voice announcements and Apple Watch score updates — useful proof that spoken score feedback and watch-based updating matter. **smartscore** goes further with multiple score systems, Bluetooth input, statistics, and imports — clearly a larger product than this MVP needs to be. A third cross-sport reference, **ScoreBot** for padel, mirrors your intended physical-button logic almost exactly: press once for your point, twice for the opponent's point, hold to undo, with Apple Watch and Flic button support. The input model is already validated in market behavior even outside table tennis.

The competitive conclusion is straightforward: the winning pattern is **remote input + live visible board + spoken confirmation**. The losing pattern would be starting with doubles support, history, replay, or setup-heavy rules screens.

---

## Product direction

The MVP ships with **Apple Watch input active**, **Flic marked as Coming Soon**, and all future Flic implementation references collected now so phase two is easy. Flic is a valid phase-two target but introduces additional work: URL scheme registration, application-query schemes, Bluetooth permissions, optional Bluetooth background mode, app-to-app grab flow, and restore-state handling. Not the right thing to stake the core MVP on when the user already has an Apple Watch in hand.

The launch philosophy is **zero onboarding, zero setup, reasonable defaults**. No player-side assignment screen. No rules wizard. No modal explaining gestures on first run. The app opens. The scoreboard is there. The user starts scoring.

Default rules align with common table tennis play and stay invisible unless actively changed: **11-point games, win by 2, best-of-3 optional in settings** — fully consistent with ITTF rules and the client's stated preference.

---

## Final UI and scoreboard scene

**iPhone scoreboard scene:** High-contrast dark board with two dominant score zones. Each player gets one vertical half or one large stacked score panel — numbers are the clear hero. Small labels read "Player 1" and "Player 2" by default. If match mode is enabled, tiny set indicators sit near the top edge of each player section. A compact top bar includes only a **gear icon** and a small **connection status pill** ("Watch Connected"). A compact bottom action rail holds **Undo**, **Mute/Audio**, and **Reset**, with destructive actions protected by confirmation.

**Settings surface:** A sheet, not a home page. Four groups only:
- **Scoring** — 11 points default, best-of-3 default
- **Audio** — on/off and voice selection
- **Watch Input** — on-screen tap input
- **More Inputs** — disabled row reading "Flic Button — Coming Soon"

**Apple Watch scene:** Gesture-driven screen for the exact scoring actions confirmed by client. On-screen tap input is the scoring surface. Visual confirmation on each accepted point. Haptic confirmation per gesture (see Haptics spec below).

**Immersive visual-table UI (v2 only):** Client has a sketch concept for a literal table illustration with circular score elements. This is a promising v2 exploration — validate the bare scoreboard first, then test the immersive board as an optional theme after the input loop is proven.

---

## Haptics spec _(confirmed by client Apr 21 2026)_

Client explicitly requested distinct haptic responses per gesture on Apple Watch. Implementation uses `WKHapticType` via `WKInterfaceDevice.current().play()`.

| Gesture | Haptic | `WKHapticType` |
|---|---|---|
| 1 tap → Player 1 point | Short crisp pulse | `.success` |
| 2 taps → Player 2 point | Double pulse | `.directionUp` twice with short delay |
| Press and hold → Undo | Longer rumble | `.notification` |

Note: Apple warns against firing watch haptics repeatedly in quick succession. Haptic feedback should be gated so it fires once per accepted event, not on every intermediate touch state.

---

## Technical architecture and implementation references

**Build structure:** watchOS app with companion iOS app (paired model). Watch is the event source, iPhone is the live mirror and audio surface.

**WatchConnectivity transport:**
- `sendMessage` — immediate delivery when counterpart is reachable
- `isReachable` — check before sending
- `updateApplicationContext` — last-known state sync for recovery
- A message sent from the watch while active can wake the iPhone app in background; sending from iPhone does not wake the watch extension. Watch = event source is therefore the correct architecture.

**Input debounce:** Input queue on the Watch must accept rapid repeated taps without dropping points. Debounce window should be tight (50–100ms) — fast enough for real play, long enough to distinguish single from double tap.

**Double-tap detection:** Use a short timer window (~300ms) after first tap to wait for a second tap before committing the Player 1 point event. If a second tap arrives within the window, fire Player 2 event instead.

**Audio stack (iPhone):**
- `AVSpeechSynthesizer` — on-device, queue-based, no server dependency
- Utterances: "7–5" after each point, "Game — Player 1" or "Game — Player 2" on win
- `AVSpeechSynthesisVoice` — expose voice choice in settings later without architecture change
- `AVAudioSession` + route-change handling — announcements continue correctly over speaker, Bluetooth, or headphones

**Future Flic references (keep pinned for phase 2):**
- Flic iOS SDK: push, double push, hold event model
- URL scheme registration and application-query schemes
- Bluetooth permissions and optional background mode
- App-to-app grab flow and restore-state handling
- Flic 2 developer-assets repository: technical overview, protocol specs, iOS library path

**Reference stack:**
- watchOS paired app setup + WatchConnectivity overview
- `WCSession.sendMessage`, `isReachable`, `updateApplicationContext`
- `WKHapticType` for watch haptics
- `AVSpeechSynthesizer`, `AVSpeechSynthesisVoice`, `AVAudioSession`, audio route changes
- `MPRemoteCommandCenter` (future headphone/remote input)
- Flic iOS SDK docs + Flic 2 developer assets

---

## Product requirements document

**Product name.** Pongle. Derived from Dongle + Ping Pong. Confirmed by client Cody Butler.

**Problem.** In live table tennis, players lose focus or stop play to remember the score. Existing apps prove there is demand for wearable-first score entry and spoken feedback, but the strongest competitors drift toward wider feature sets and configuration. This MVP solves the narrowest version of the problem: record points during rallies without interrupting play, show the score immediately on iPhone, and confirm it by audio.

**Target user.** A player, practice partner, or casual umpire who wants to keep score during real games with as little interaction overhead as possible.

**Primary platforms.** Apple Watch for input and iPhone for live scoreboard plus speech. Paired watchOS + companion iOS experience, not a watch-only utility.

**Launch behavior.** The app launches directly into the scoreboard. No onboarding, no tutorial carousel, no first-run mode selection, no mandatory pre-match setup. Settings changes persist and app restores previous state on relaunch.

**Default rules.** First to 11, win by 2. Best-of-3 available as a setting, must not block entry into play.

**Core user flow.**
1. User opens Pongle on iPhone → lands immediately on live scoreboard
2. User opens Pongle on Apple Watch → begins logging points
3. Watch sends score events via WatchConnectivity
4. iPhone updates scoreboard and speaks the new score
5. Undo removes the most recent point event
6. Reset clears the current game after confirmation

**Functional requirements.**
- Watch: on-screen tap input
- Watch: distinct haptic per gesture (see Haptics spec)
- Watch: input queue handles rapid taps without dropping points
- Watch: double-tap window (~300ms) distinguishes P1 from P2 event
- iPhone: large legible scoreboard visible at all times
- iPhone: audio feedback routing to speaker or connected audio output
- WatchConnectivity: immediate messaging when reachable; `updateApplicationContext` fallback for recovery
- Settings: scoring rules, audio on/off, Flic Coming Soon row

**Non-goals for this milestone.** Flic input (Coming Soon only), headphone-button input, Bluetooth remote input, doubles mode, replay, match history, statistics, export/import, advanced rules tuning, AirPlay controls, immersive table visuals.

**Acceptance criteria.**
- App opens directly into scoreboard with no onboarding
- Apple Watch: points log correctly, haptics are distinct per gesture, rapid taps don't drop
- iPhone: scoreboard updates in order, latest score always visible
- Spoken score works on-device
- Undo removes most recent point
- Reset requires confirmation
- App usable even when Flic is not enabled
- Flic integration path is documented for phase 2

**Backlog after MVP.**
1. Flic button support — push = P1, double push = P2, hold = undo (same event model, validated by market)
2. Optional match history
3. Optional service indication
4. Headphone-button input experiments
5. Immersive visual-table UI theme (client's sketch concept)
