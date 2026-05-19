# #18 — Docker Compose 🔄 Mostly done

**GitHub:** https://github.com/Riru-isla/socki/issues/18

## Intent

One command to spin up backend + frontend + pg + redis for local development.

## Current state

✅ Largely done:

- `docker-compose.yml` exists at repo root.
- `backend/Dockerfile` (prod) and `backend/Dockerfile.dev` (dev) both present.
- `vite.config.ts` honors `API_PROXY_TARGET` env var so the frontend container can reach the backend container by service name.

## Remaining from the issue's scope

- [ ] Environment-based CORS config — `rack-cors` is still **commented out** in `backend/Gemfile`. Currently CORS works in dev (Vite proxy makes everything same-origin) and in Docker (frontend and backend share a network). It will break the moment you split origins. See `backend/overview.md`.
- [ ] CI for frontend (lint + build check) — no `.github/workflows/` for the frontend yet. `vue-tsc` runs on `npm run build` but isn't gated.
- [ ] Production deployment guide — no doc.

## What changes (per remaining item)

### CORS

```ruby
# Gemfile
gem "rack-cors"

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

`credentials: true` matters because Devise relies on session cookies.

### CI

A `.github/workflows/frontend.yml` that runs `npm ci && npm run build` (which includes `vue-tsc`) on PRs touching `frontend/`. Mirror for `backend/` with `bundle exec rspec` + `bundle exec brakeman`.

## Related

- Cross-references: [`backend/overview.md`](../backend/overview.md) (CORS gap), root `CLAUDE.md` (running locally).
