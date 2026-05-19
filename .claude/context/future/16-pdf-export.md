# #16 — PDF export 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/16

## Intent

Tournament organisers need printable PDFs: bracket sheets to post on the wall, score sheets for the referee table, and certificates for award ceremonies.

## Scope

- [ ] Bracket sheets (visual single-elim diagram)
- [ ] Individual match score sheets (referee-facing, one per match)
- [ ] Certificates for winners
- [ ] Pool result tables

## Current state

No PDF generation anywhere. No gem in `Gemfile`.

## What changes

### Gem choice

Issue suggests `prawn` or `wicked_pdf`. Tradeoffs:

- **Prawn** — programmatic Ruby DSL. Precise control, no HTML/CSS. Best for bracket diagrams (you'll be drawing lines and boxes).
- **wicked_pdf** — HTML → PDF via wkhtmltopdf. Best for templated docs (certificates, score sheets) where Rails ERB views are easier than coordinate math.

Likely use **both**: prawn for brackets, wicked_pdf for certificates and pool tables.

### Backend

- `app/pdfs/` or `app/services/pdfs/` — one class per document type.
- Controller: `GET /api/v1/tournaments/:id/bracket.pdf`, `GET /api/v1/matches/:id/score_sheet.pdf`, etc.
- Cache generated PDFs to `tmp/pdfs/` keyed by content hash — regenerate on data change.

### Frontend

- "Download PDF" buttons on `TournamentDetailView`, bracket view, etc.

## Considerations

- Depends on [#12](12-draws-brackets.md) for the bracket data being real.
- Iaido score sheets ([#15](15-iaido-scoring.md)) have different layouts than kendo — abstract by `scoring_mode`.
- Localization: Japanese names need a font that includes CJK glyphs in the PDF — both gems require explicit font registration for non-Latin scripts.

## Related

- Depends on: [#12](12-draws-brackets.md) (brackets to render), [#15](15-iaido-scoring.md) (per-mode score sheet layouts).
