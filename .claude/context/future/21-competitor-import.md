# #21 — Competitor import beyond manual entry 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/21

## Intent

Today competitors are entered one-by-one through a form. Doesn't scale beyond ≈10. Add bulk import paths feeding a **staging review** — nothing hits the DB until the user confirms.

## Scope

- [ ] CSV / XLSX upload with column mapping + preview
- [ ] Reuse competitors from a previous tournament (loaded into staging)
- [ ] Staging page: inline edit / delete, manual-add rows, bulk-confirm
- [ ] Validation (duplicates within file, required fields)

## Out of scope (per issue)

- Federation API integration (no public API)
- Automatic de-duplication across tournaments

## Current state

- Manual single-competitor entry only.
- No file-upload anywhere in the app.
- `Competitor` schema is `name, age, province` — the issue mentions a `club` column that doesn't exist (also referenced in [#19](19-stats-reporting.md)). Add it as part of this work or #19 — whichever lands first.

## What changes

### Backend

- `gem "roo"` (XLSX/CSV reader) or `gem "csv"` for CSV-only first pass.
- Two new endpoints:
  - `POST /api/v1/competitors/import_csv` (multipart upload) → returns parsed rows, no DB writes. Useful for the staging preview.
  - `POST /api/v1/competitors/bulk` → takes the confirmed array, creates `Competitor` records in a transaction.
- Likely a new model `Enrolment` (Competitor ↔ Category) so an "import to this category" verb makes sense. Shared with [#12](12-draws-brackets.md) and [#19](19-stats-reporting.md).

### Frontend

- New `CompetitorsImportView.vue` — file input + preview table + per-row edit/delete + "Confirm" button.
- Source switcher: file upload vs "reuse from past tournament" dropdown.
- Staging state is a plain `ref<Row[]>` until confirm — no DB writes mid-edit.

## Considerations

- Column mapping UI: most CSVs won't use `name, age, province` headers verbatim. Allow drag/drop or dropdown mapping. Start with a simple required-headers check and grow later.
- Duplicate detection within the file: by `(name, province)` is usually enough.
- Reuse-from-past-tournament needs a clear "this creates new `Competitor` rows, it does not link to the old ones" message — otherwise users will assume continuity.

## Related

- Pairs with: an `Enrolment` model shared with [#12](12-draws-brackets.md) and [#19](19-stats-reporting.md).
