# #36 — Team-based competition 🔮 (post-1.0 tracking)

**GitHub:** https://github.com/Riru-isla/socki/issues/36

## Status

**Post-1.0.** No team work scheduled before the 1.0 cut. The decisions made in 1.0, though, were designed to leave room for this — see "Team-readiness constraints" below for the distilled list of design choices to preserve.

## Intent

Support team kendo: a "team match" between two teams (e.g. "Madrid vs Andalucía") where each team fights as 3–6 member matches in a fixed order. The team match's winner is *derived* from the member match results, not declared by a human.

In real kendo:

- A team is usually 5 fighters in positions: senpō (先鋒), jihō (次鋒), chūken (中堅), fukushō (副将), taishō (大将).
- The order is significant — the taishō is the team's strongest, fighting last as the "captain".
- Team match winner: most member-match wins. Tie-broken by total ippon, then by fewer hansoku, then by a representative match between the two captains.

## Proposed domain shape

Not yet built — sketched here so the team-readiness constraints in 1.0 issues stay coherent with the eventual model.

```
Category
  has_many :teams
  has_many :team_matches

Team
  belongs_to :category
  has_many :team_members  → position 1..N, ordered
  has_many :competitors, through: :team_members

TeamMatch
  belongs_to :category, :shiajo, :rule_set
  belongs_to :red_team, :white_team  (both → Team)
  has_many :matches   ← member matches, ordered by position
  derived: status (in_progress while any member match is, finished
           when one side leads beyond reach)
  derived: winner   (computed; see tiebreak rules above)

Match (existing)
  + optional team_match_id    (nullable; nil = individual match)
  + optional team_position      (nullable; the position 1..N in a team match)
```

A `Match` thus represents either an individual bout or a member-match-inside-a-team-match. The existing scoring + state machine works identically; the team_match_id is just a parent pointer.

## Team-readiness constraints — what 1.0 issues already preserve

These are the design choices baked into in-1.0 issues *because* teams are coming. Each one shows the constraint + the issue(s) it appears in. If you're working on one of these issues and tempted to simplify away from the constraint, **stop and re-read this** — the simplification will hurt later.

### 1. `winner_id` is a parameter, not a UX inference

**Constraint**: `PATCH /api/v1/matches/:id` accepts `winner_id` from the caller. The endpoint doesn't care whether a human clicked it or an aggregator computed it.

**Why**: in team matches, the team match's winner is derived. The same PATCH path that today is called by a human clicking "Finish match" will tomorrow be called by `TeamMatch#recompute_status` when a member match settles enough to determine the team result.

**Where**: [#38 Finish match action](https://github.com/Riru-isla/socki/issues/38)

### 2. `paused` is a per-match state, not a container state

**Constraint**: when a match enters the `paused` state (#39), the state lives on `Match`, not on any container. A paused member match doesn't propagate "paused" to its team match — the team match has its own independent state derived from its members.

**Why**: in a real tournament, one member match can be paused (medical timeout) while the next member match in the same team match is already running on the same shiajo. Or the team match has paused while one member match plays. These are different concerns; don't conflate them.

**Where**: [#39 Explicit paused state](https://github.com/Riru-isla/socki/issues/39)

### 3. Void-with-parent semantics for synthesized events

**Constraint**: when an event has a synthesized child event (e.g. the auto-awarded point from a second hansoku), voiding the parent must also void the child.

**Why**: this is the same pattern that team matches will need at a different level: when a member match's result is voided (event-level), the team match's derived winner needs to recompute (container-level). Building the void-with-parent helper now means the team-match aggregator gets to call it later instead of inventing a new pattern.

**Where**: [#29 Edit / void match events](https://github.com/Riru-isla/socki/issues/29) and [#40 Hansoku rule](https://github.com/Riru-isla/socki/issues/40)

### 4. Match doesn't assume it's top-level

**Constraint**: any code that talks about "this match" — serializers, controllers, channels — should not assume the match is the highest-level competitive unit. There may be a wrapping `TeamMatch` above it.

**Why**: payloads (broadcasts, projector view) should be able to include "you're inside team match X, position 3" context when relevant. Hardcoding "this is the unit" makes that retrofit painful.

**Concretely for now**: when adding new fields to the match payload, ask "would a team match also surface this?" If yes, put it at match level. If no (e.g. team's overall current score), put it at the eventual TeamMatch level.

**Where**: [#38](https://github.com/Riru-isla/socki/issues/38), [#34 admin dashboard](https://github.com/Riru-isla/socki/issues/34) (when designing the tile payload), [#35 audience views](https://github.com/Riru-isla/socki/issues/35) (shared payload contract)

### 5. Bracket source-matches are between Matches OR TeamMatches

**Constraint**: today, `Match.red_source_match_id` points at another Match. Tomorrow, the analogous column on TeamMatch points at another TeamMatch.

**Why**: brackets work the same shape at both levels (4 quarters → 2 semis → 1 final). Don't bake "Match → Match" into the bracket UI today in a way that prevents "TeamMatch → TeamMatch" tomorrow. Specifically: when [#12 draw system](https://github.com/Riru-isla/socki/issues/12) builds the generator, parameterise the source-match concept so it can be applied to either entity.

**Where**: [#12 draws-brackets](https://github.com/Riru-isla/socki/issues/12) when the generator lands.

## Sub-issues (not yet created)

To be opened when teams becomes the active workstream:

- `[feat] Team + TeamMember models + migration`
- `[feat] Team enrolment UI — assign competitors to positions 1..N`
- `[feat] TeamMatch model + container API`
- `[feat] Team match scoreboard view (all member matches on one screen)`
- `[feat] Team match winner-derivation rules + spec`
- `[feat] Bracket support for team matches (reuses #12 generator)`

## Considerations for when it lands

- **CategoryType.team flag already exists.** The boolean on `category_types` was set up to distinguish individual from team divisions. Build on it.
- **Existing `Category` works as-is.** A team category just contains teams instead of (or in addition to) competitors.
- **Enrolment becomes one of two kinds**: individual enrolment (Competitor ↔ Category, today's `Enrolment` model) and team enrolment (Team ↔ Category, new). They could be one polymorphic table or two; lean two for clarity.
- **Tiebreak rules vary by federation.** Make the derivation function pluggable per `RuleSet`, not hardcoded in `TeamMatch`.

## What this doc replaces

The earlier `future/12-draws-brackets.md` mentions team work as a downstream concern. That doc stays focused on bracket structure; this doc owns the team-specific design.
