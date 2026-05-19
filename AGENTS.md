# Socki — Agent Notes

## Seeded Admin Credentials
- **Email:** `admin@socki.app`
- **Password:** `password123`

## Auth Endpoints
- `POST /api/v1/auth/sign_in` — login
- `DELETE /api/v1/auth/sign_out` — logout
- `POST /api/v1/auth` — register

Protect admin controllers with `before_action :authenticate_admin!`.

## Docker Compose
- Backend: `http://localhost:3000`
- Frontend: `http://localhost:5173`
- Postgres and Redis are internal-only

## Project Structure
- `backend/` — Rails 7.2 API
- `frontend/` — Vue 3 + Vite
