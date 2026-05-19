# #13 — Round-robin pool format 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/13

## Intent

Real kendo tournaments often run pool play (everyone plays everyone in a small group) before a knockout bracket. Add the pool format as an alternative to single-elimination.

## Scope

- [ ] Pool creation and competitor assignment
- [ ] Automatic match generation (everyone plays everyone within a pool)
- [ ] Pool standings table (wins, points, head-to-head tiebreak)
- [ ] Top N advance to a bracket phase

## Current state

Nothing built. `Match.draw_system` is a free string today; a "round_robin" value isn't handled.

## What changes

### Schema

- `Pool` model belonging to `Category` (or `Draw` if #12 lands first). `has_many :matches` through some kind of `bracket_position` / `pool_position` column on Match.
- Pool standings could be a computed view or a `PoolStanding` projection model — pick based on read frequency.

### Match generation

For N competitors in a pool, generate `N * (N-1) / 2` matches in a sensible order (no back-to-back appearances for any competitor).

### Tiebreakers

In order of typical kendo rule sets: wins → score differential → head-to-head → coin flip (or judge call). Make this configurable per `RuleSet`.

## Considerations

- Depends on a `Pool` or `Draw` parent entity — likely best to land [#12](12-draws-brackets.md) first so this can plug into the same draw hierarchy rather than inventing a parallel one.
- The "top N advance to bracket" handoff is its own design problem — who triggers it? Auto when all pool matches finish? Manual button?

## Related

- Depends on: [#12](12-draws-brackets.md) (shared Draw/Pool hierarchy)
- Pairs with: [#14](14-scoring-enhancements.md) (hansoku affects pool standings)
