# Championship setup wizard ✅

`frontend/src/views/TournamentSetupWizard.vue` at route `/tournaments/:id/setup`. The primary UI for getting a championship from "just created" to "ready to run on the mat". Reached from `TournamentsView` (clicking a championship) and from `TournamentNewView` (after creating one).

## Steps

| # | Label                 | What you do                                                       | Advance gate |
| - | --------------------- | ----------------------------------------------------------------- | ------------ |
| 1 | Categories & Shiajos  | Add categories (with a `CategoryType` template) + a shiajo each   | Every category has ≥1 shiajo |
| 2 | Competitors           | Manage the **global** pool — add new athletes, remove orphans     | ≥2 competitors exist globally |
| 3 | Enrolments            | Per category, tick which competitors are in it                    | At least one category has ≥2 enrolments |
| 4 | Matches               | Per category, create matches (Add Match form). Each side can pick a competitor OR "winner of match #N" (bracket source) | Finish (no gate) |

Each step has a placeholder hint inside it pointing back at a missing prerequisite (e.g. step 4 tells you to go back to step 3 if a category has fewer than 2 enrolments).

## Resume logic

On mount, the wizard computes the first incomplete step from the current data and opens there:

```
step1Complete → categories non-empty AND all have shiajos
step2Complete → competitors.length >= 2
step3Complete → at least one category has >= 2 enrolments
```

So bookmarking `/tournaments/:id/setup` and coming back later "just works" — you land where you left off.

## Step indicator

Tabs at the top (1—2—3—4). Clicking any tab jumps to it directly (no advance-gate enforcement on backwards navigation, by design — going back to fix a thing should be free). Advance gates only constrain the "Next" button.

## Data fetching

`load()` runs once on mount and after every mutation. Single Promise.all:

```ts
fetchTournament(id)     → tournament with categories[shiajos, enrolments, matches]
fetchCategoryTypes()    → for step 1's "type" dropdown
fetchCompetitors()      → for step 2's list and step 3's enrolment checkboxes
fetchRuleSets()         → for step 4's rule-set dropdown
```

Mutations call `await load()` afterwards to refresh the whole picture rather than threading optimistic updates. Fine for the dogfooding scale; revisit if it becomes laggy.

## Step 4 source-match dropdown

Each side (Red / White) in the Add Match form is a single `<select>` with two `<optgroup>`s:

- **Competitors** — every enrolled competitor in this category.
- **Winners of…** — every existing match in this category (so M3's red can be "winner of M1").

Selected value is encoded as `"competitor:5"` or `"match:3"` (string) and parsed in `addMatch()` to decide whether to send `red_competitor_id` or `red_source_match_id` (same for white). See `backend/domain-model.md` for the propagation callback that fills the slot when the upstream match's winner is set.

## What the wizard does NOT do (yet)

- **Set match winners.** Step 4 creates matches and links them via `*_source_match_id`, but there's no "Finish match" button anywhere. The next chunk to close the bracket loop is a `PATCH /api/v1/matches/:id` endpoint + a button in MesaView.
- **Auto-draw.** Issue #12's eventual "click to generate all matches for N enrolled competitors". The Add Match button is manual one-at-a-time today.
- **Edit / delete categories or matches.** Only create + (for enrolments and competitors) destroy. Anything else needs the Rails console.
- **Import competitors in bulk.** Form is one-row-at-a-time; the bulk-paste / CSV import is issue #21.

## Patterns for the next chunk

If you're adding a new step or replacing one:

1. Add the `Step` ID and label in the `STEPS` array.
2. Add a `stepNComplete` computed for the new advance gate.
3. Extend the `onMounted` resume-logic ladder.
4. Add a step `<div v-if="currentStep === N">` block in the template.
5. Add the Next button branch for that step in the footer nav.

If you're adding a fully new view that lives outside the wizard, follow the standard pattern in `views.md` instead.
