# Pongle V2 Client Response Draft

## Paste-ready message

Hey Cody, I reviewed your Google Doc comments and all of the follow-up notes from the Chris test at Miller Wellness Center.

My main takeaway is that the test strongly validates the core Pongle idea, but I would treat it as a reason to keep V2 focused rather than expand V2 into every possible device, club, ranking, and social scenario.

Here is how I would adjust the V2 scope:

1. Keep User and Player separate. A User is someone who logs in. A Player is someone who builds match history/rating. For the simpler V2 boundary, the logged-in User must be one of the two Players in the match.
2. Support same-device play without neutral facilitator mode. One iPhone or iPad per table should be enough for V2, but the User is selecting themselves plus one opponent before the match starts. A coach/teacher/club admin running Player A vs. Player B is V3.
3. Add table photos and practical table notes. The Miller Wellness Center photos make this more obvious: a table record should show the table, quality, surroundings, access notes, and location.
4. Add a simple post-session recap. Chris's comment about wanting stats is a good V2-sized feature if we keep it simple: number of matches/games played, formats, elapsed time, opponents, table, scores, and winners.
5. Improve input assignment, but avoid a huge device matrix. Instead of trying to design all 88 possible combinations, V2 should support a simple model: each input source is assigned to a Player. Single press adds a point for that Player. Press-and-hold can be tested as undo for that Player's last point if it proves reliable. Watch + Flic is the first practical test, and second Flic button support should remain subject to hardware/SDK validation.
6. Add a final-score pause between games in a match. After Game 1 of a Best of 3, the app should pause on the final game score until the players tap/press to continue. That is small, practical, and came directly from real play.
7. Keep ladders, ELO, ITTF-style ratings, richer leaderboards, club administration, branded match cards, and social posting workflows as V3/later. V2 should store the clean match/game data needed for these features, but should not promise a full ranking or social system yet.

So my recommended boundary is:

V2 = play, save, and remember.
V3 = clubs, rankings, social sharing, and richer competition systems.

That keeps V2 achievable and useful quickly, while still setting Pongle up for Tyson, SDSU Ping-Pong Club, and the other real-world testers you are uncovering.

## Internal stance

Accept into V2:

- User vs Player separation.
- Unclaimed Player records.
- Same-device match flow where the logged-in User is one of the two Players.
- Table photos and table condition/surrounding notes.
- Simple match/session recap.
- Assigned input source model.
- Watch + Flic validation.
- Optional second-Flic validation if reliable.
- Final-score pause before advancing to the next game.

Keep out of V2:

- Full youth/parent consent workflow.
- Full club administration.
- Tournament brackets.
- True ladder/ranking engine.
- ITTF-style ranking mode.
- Result disputes and multi-party confirmation.
- Duplicate profile merge UI.
- Branded social match cards or social feed.
- Generalized support for every device/scoring combination.
- Neutral facilitator mode where the logged-in User runs a match between two other Players.

Recommended framing:

- Say the field test validated the product.
- Say V2 should capture clean data first.
- Say V3 can be planned around SDSU/Tyson after real V2 tester feedback.
- Avoid saying "impossible"; say "separate scope" or "V3 candidate."
