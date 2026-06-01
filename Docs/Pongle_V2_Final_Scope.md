# Pongle V2 — Final Scope (for sign-off)

Hi Cody,

This is the cleaned-up V2 scope, pulled together from the original draft, your comments on the Google Doc, and everything we worked through from the Chris/Miller Wellness test through Tyson and your neighbors. The goal here is to give us a single document we can both point at as "this is what V2 is," so we can move to a contract with no ambiguity on either side.

I have tried to keep V2 as simple as it can be while still doing the thing you actually want: let real players, on real tables, save real match history and start building a Pongle profile. Anything bigger than that is V3 — not because it is not valuable, but because we want V2 to ship clean and give you real tester feedback before we layer on clubs, rankings, and social.

Nothing here changes my willingness to put in extra polish, small tweaks, and reasonable in-flight adjustments during the build. The point of this doc is to be clear about what is committed, what is best-effort, and what is for a later phase.

---

## 1. What V1 already delivered (not part of V2)

These are done and live on TestFlight. V2 builds around them, not on top of them:

- iPhone + iPad + Apple Watch scoring app
- Live scorekeeper, server tracking, auto-rotating first serve across games
- Landscape scoreboard, swap sides, undo, reset
- iPad name editing, large-font scoreboard, prominent serve indicator
- Configurable announcements (point winner, next server, current score, deuce, set/match point, undo) with 1x–2.5x speed
- Watch input via Apple Watch app, Flic button input, iPhone tap input
- Apple Watch screen kept alive during a match via HealthKit Workout permission
- Settings: choose first server (single/double press), announcement toggles

V1 polish bugs that come up after we lock V2 will still be fixed under the V1 umbrella at no charge, same as we have been doing.

---

## 2. V2 in one sentence

**V2 is the play / save / remember loop**: a User logs in, picks themselves plus one opponent, plays a match on a known table using the existing scorekeeper, saves the result, and can reopen the app later to see everything that happened.

---

## 3. What is locked into V2

### 3.1 Accounts and profiles
- **User accounts** with phone number as the unique identifier (email optional).
- **Player profiles**, separate from User accounts. A Player has match history and lightweight rating fields whether or not they have ever logged in.
- **Unclaimed Player profiles** for opponents who do not have Pongle yet (your brother Canon, kids in Tyson's future club, casual opponents).
- **SMS invite / claim flow** so an unclaimed Player can later become a logged-in User and inherit their existing match history.
- **V2 rule**: the logged-in User must be one of the two Players in every V2 match. A User cannot be a neutral scorer/facilitator for Player A vs. Player B until V3.

### 3.2 Tables
- Add a table with: name, building/venue, street address, GPS coordinates (so a table inside a building is locatable), visibility (private / shared), access notes, quality and surroundings notes, 1–3 photos, who added it, and optional owner/ambassador.
- Browse / search tables.

### 3.3 Match setup and play
- Pick two Players (self + one opponent).
- Pick a table (existing or quick-add).
- Pick **match format**: games to 3, 11, or 21 points.
- Pick **set format**: single game (1), Best of 3, Best of 5, or Best of 7.
- Hand off to the existing scorekeeper from V1.

### 3.4 Scoring inputs
- Existing V1 inputs all continue to work: iPhone tap, Apple Watch, single Flic.
- **Assigned-input model**: each connected input source (Watch, Flic) is assigned to one Player. A single press is always +1 for that Player. Press-and-hold is +undo for that Player's last point if it proves reliable on the relevant device.
- **Watch + Flic on the same device** is supported as a first-class dual-input combo, since we already validated it works in real play.

### 3.5 Match flow improvements
- **Final-score pause** between games inside a Best-of match: when a game ends, the scoreboard holds on the final game score until the players tap/press to continue. No auto-advance.
- The existing announcement settings carry over unchanged.

### 3.6 Saving and remembering
- **Match record**: players, table, date, start/end time, duration, format, per-game scores, match winner, unique match ID.
- **Game records** under each match.
- **Post-session recap**: at the end of a session, the app shows how many matches and games were played, formats used, total elapsed time, opponents, table, scores, and winners. This is what Chris asked for after the Miller Wellness session.
- **Player profile screen**: list of past matches and basic counts (matches played, win/loss, recent opponents, recent tables).
- **Match history screen**: the user's own match history, filterable by opponent or table.

### 3.7 Ratings
- Lightweight rating fields on each Player: enough to capture data and show a simple Pongle rating, but **not** a true ranking system. ELO, ladders, ITTF-style ratings, and leaderboards are V3.

### 3.8 Backend and delivery
- Supabase for accounts, database, storage, sync, and SMS triggers.
- Native Swift iPhone / iPad / Apple Watch app stays the front end.
- TestFlight delivery, same as V1.

### 3.9 UI / UX execution
- I will own the iOS-native UI/UX execution for the V2 screens in this scope.
- Your sketches, page ideas, and rough wireframes are very useful input, but they do not need to be complete before V2 starts. We can build the skeleton, test it on device, and refine from there.
- V2 uses Pongle's existing visual direction plus native SwiftUI polish. A full custom artwork/brand package is not required for V2.

---

## 4. Stretch / validation items (best-effort, not V2 blockers)

These are worth pursuing inside V2 if hardware and SDK behavior cooperate. If they do not, they do not block V2 from being considered complete.

- **Two Flic buttons connected to one scoring device**, one per Player. Flic SDK suggests up to six is possible; iOS behavior with two simultaneous inputs needs real-hardware confirmation.
- **Press-and-hold undo** on dual-input setups (especially with the Flic on the paddle handle).

If a stretch item proves unreliable, the fallback is the assigned-input model with single press only — which is already in V2.

---

## 5. What V2 does *not* include (V3 parking lot)

I want to be upfront: almost every item on this list is a real, valuable idea — and most of them came from you, Tyson, Josh, Zeke, or Chris. None of this is "no" and none of it is permanent. The reason these are V3 instead of V2 is simply that each one deserves its own design pass, its own tester feedback, and (in some cases) its own legal or business decision. Squeezing them into V2 would either make V2 ship late, ship sloppy, or both — and you would feel that in the product before you saw it in the calendar.

The honest framing: V2 builds the foundation that makes all of this V3 work *possible*. The data model in V2 is being designed so that when we open V3, we are extending — not refactoring.

- **Club administration** (SDSU Ping-Pong Club, Tyson's youth club, Pickleball-style leagues): club records, admin roles, scheduled meetups, attendance, club-scoped leaderboards. This is genuinely exciting and probably the highest-value V3 chunk given Tyson and SDSU are already real testers. It deserves its own discovery pass before we lock its design.
- **Tournaments / brackets**: single-elim, double-elim, round-robin, ladder challenges. Natural next layer once Clubs exist.
- **True ranking engines**: ELO, ladder rankings, ITTF-style ratings, public global leaderboards. V2 stores the clean match data needed to feed any of these — we just do not commit to the engine itself yet, because the right rating math depends on which use case (casual vs. club vs. competitive) wins.
- **Result confirmation / dispute handling**: both players confirming a match result, contested-result workflow. Worth doing well once we have enough match volume to know how often disputes actually happen.
- **Duplicate profile merge tool**: a User-facing UI to merge two Player records. V2 will try to avoid duplicates at creation time, which buys us time to build this properly in V3.
- **Social sharing**: branded match cards, share-to-social feeds, in-app activity feed. Big growth lever, deserves its own design and brand pass — not a rushed V2 add.
- **Full custom artwork / brand package**: logo refresh, illustration system, marketing graphics, or a full screen-by-screen design deck as a separate deliverable. Rough sketches are welcome and helpful; they just do not need to become a separate design project before V2 can start.
- **Payments**: per-game credits, subscriptions, paid features. Pongle stays free during V2 on purpose, so we can grow the tester base without friction. We revisit monetization after V2 ships and we see what people actually pay for.
- **TV / large-display mode**: dedicated cast-to-TV scoreboard. Josh's "man cave with TV" idea is great. AirPlay screen mirroring already works today as a free workaround, which is enough to keep this for V3.
- **AirPods as an input device**: interesting, worth prototyping in V3.
- **Android app**: same V2 logic ported to Android is meaningful work and best treated as its own project.
- **Pickleball, tennis, badminton, or other racket sports**: multi-sport is a strategic decision, not a technical one. V2 stays table-tennis-only on purpose so we ship something specific and great, then expand.
- **Full parent/guardian consent workflow** for minors. V2 supports unclaimed Player records for kids; the legal consent layer needs its own scope and (probably) outside review.
- **True neutral facilitator mode** (User running a match between two other Players where the User is not one of them). Deferred per your May 24 decision to keep V2 simpler — and I agree.

If any of these start to feel like must-haves before V2 wraps, we can pull one forward as a paid add-on — the only thing I want to avoid is silently absorbing big new scope into the V2 number, because that is how every "fixed price" project blows up.

---

## 6. Acceptance criteria (how we know V2 is done)

V2 is complete when, on TestFlight:

1. A new User can sign up using their phone number.
2. The User can add a new table with photos, address, GPS, and notes — or pick an existing one.
3. The User can pick themselves plus one opponent from existing Players, or quick-add a new opponent Player (claimed or unclaimed).
4. The User can pick a match format (3/11/21 points) and set format (1, Best of 3/5/7) and start a match.
5. The match runs through the existing V1 scorekeeper with the assigned-input model and final-score pause between games.
6. At the end of a match, the result is saved automatically.
7. At the end of a session, the User sees a recap of matches, games, formats, time, opponents, table, scores, and winners.
8. Reopening the app later shows the saved match in the User's history, on the Player profile screen, and against the table record.
9. An unclaimed Player can receive an SMS invite, claim their account, and inherit their existing match history.
10. Apple Watch + Flic both work as scoring inputs inside a single match.

---

## 7. Timeline

- **3–4 weeks** of focused build, assuming we stay inside this scope and TestFlight feedback comes back quickly.
- Target build order:
  - **Step 1 (week 1–2)**: Auth, User/Player models, table records, opponent picker, match setup, save match, basic Player profile and match history screens.
  - **Step 2 (week 2–3)**: Unclaimed Players, SMS invite/claim, self-plus-opponent setup guard, lightweight rating fields, final-score pause, session recap, Watch+Flic dual-input wiring.
  - **Step 3 (week 3–4)**: Two-Flic validation (if hardware cooperates), polish, TestFlight builds, bug-fix loop against your testers.
- Realistic stretch target for "V2 on TestFlight in front of testers": late June. If you want to demo to SDSU and Tyson before August 15, this timeline gets us there with buffer.

---

## 8. In-flight flexibility (this is the friendly part)

I do not want to nickel-and-dime small requests during the build, and the way we worked through V1 — small bugs flagged in Upwork, patched same day, no contract changes — is the way I want to keep working in V2. So here is the explicit deal, with concrete examples on both sides so neither of us has to guess later.

**Included, no extra charge, no friction — just send it over in Upwork like you have been:**

- *Copy / wording changes.* "Change 'Opponent' to 'Player 2'" — yes, just do it.
- *Visual polish on existing V2 screens.* "Make the table photos bigger on the table detail screen" — yes.
- *Sketch-based refinements to existing V2 screens.* If you sketch a match setup screen or table detail idea, I will treat it as input and fold the useful parts into the native app design.
- *Small layout / spacing / color / icon tweaks.* "The serve indicator is hard to see on iPad in sunlight" — yes.
- *Small behavior tweaks inside an already-scoped feature.* "When I save a match, also show me the opponent's win/loss against me" — yes, that is inside the Player profile feature.
- *V1 bug fixes that surface during V2 testing.* Same as we have been doing — flag it, I patch it, no contract change.
- *Field-discovered fixes to V2 features after testers use them.* "The post-session recap should show date first instead of duration" — yes.

**Worth a quick conversation first — these are usually still in, but I want to flag them so we both know what we are agreeing to:**

- A new field on an existing object. "Tables should also have an indoor / outdoor flag" — almost always yes, just want it on the record.
- A new screen that is small and serves a feature already in V2. "Add a quick 'recent opponents' shortcut on the home screen" — usually yes.
- A small dependency choice (e.g. which map provider, which SMS service).

**Add-on territory — I will price these separately rather than silently absorb them:**

- *Anything from the V3 parking lot* (clubs, tournaments, ELO/ladders, ITTF rating, social cards, payments, TV mode, AirPods input, Android, other sports, neutral facilitator mode, full consent flows, full custom artwork/brand package).
- *A whole new screen, flow, or data model* that is not in section 3.
- *A new platform or device class* (Android, Apple TV app, Vision Pro, web app, etc.).
- *A new input device* beyond what is in section 3.4.
- *Anything that would push the V2 timeline past 4 weeks* even if it sounds small individually.

**My commitment on the grey area:** if something lands in between "obvious yes" and "obvious add-on," I will message you in Upwork with "this feels like an add-on because X — want me to scope it as a small V2 extra, fold it into V3, or skip it?" and let you decide. I will never silently absorb scope and then point at it as a reason V2 is late or over-budget — and I will never silently drop a request you sent without telling you.

Net effect: small stuff is on me, and you should not have to think twice about asking. Anything that meaningfully expands V2 gets a one-line "heads up, this is an add-on" from me, and we decide together.

---

## 9. Running costs (separate from the build)

Same as the previous draft — these are third-party costs you would pay directly after launch, not part of my fee:

| Cost | Expected | Notes |
| :-: | :-: | :-: |
| Apple Developer Program | $99 / year | Required for App Store + TestFlight |
| Supabase | Free for early testing; ~$25/month at production scale | Accounts, DB, storage, sync |
| SMS invites / phone verification | Usage-based, small at early volume | Depends on provider + country |
| Domain / email | Optional | Only if you want a website or branded support email |

**Practical estimate once V2 is live**: about $25–$50 / month plus the $99 / year Apple Developer account, before any large-scale SMS or marketing spend.

---

## 10. Price and next steps

I am intentionally not putting a number on this doc yet. The order I would like to follow is:

1. You read this and either approve it or send any final tweaks.
2. Once the scope is approved, we land on a fair fixed price for V2.
3. We open a new Upwork contract against the approved scope.
4. I start week 1 of the build.

If a number would be useful before you can fully evaluate, I am happy to share a range — but I would rather we both agree the scope is right first, then size the work to the scope, rather than the other way around.

---

## 11. Sign-off

If you are good with this, the cleanest thing is to reply on Upwork with something like:

> "Approved — let's open a V2 contract against this scope."

If you want changes, drop them into the Google Doc as comments the same way you did last time and I will fold them in. We can do as many passes as we need; I would rather we both feel solid about this doc than rush into a contract.

Thanks Cody — this has been one of the best client experiences I have had, and I am genuinely excited to build V2.

— Sid
