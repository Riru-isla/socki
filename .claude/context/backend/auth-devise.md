# Auth (Devise) ✅ wired, ⚠️ enforcement currently stubbed

**Current state:** Devise is fully set up — User model, routes, seeded admin, `authenticate_admin!` helper. Every admin-mutating controller declares its `before_action :authenticate_admin!`. **But the method itself is currently a no-op** (single TODO marker in `ApplicationController`) because the frontend has no login UI yet. Flipping enforcement back on is a one-line change once login lands.

Search for `TODO(auth-restore)` to find the toggle.

## Setup

- `gem "devise", "~> 5.0"` in `backend/Gemfile`.
- `User` model: `:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`. Has `is_admin` boolean column.
- Routes mount at `/api/v1/auth`:

  ```ruby
  devise_for :users, path: "api/v1/auth", controllers: {
    sessions:      "api/v1/users/sessions",
    registrations: "api/v1/users/registrations"
  }
  ```

## Seeded credentials (dev only)

| Email             | Password      | Role  |
| ----------------- | ------------- | ----- |
| `admin@socki.app` | `password123` | admin |

Rotate before any non-local deployment.

## Endpoints

| Method | Path                       | Purpose  |
| ------ | -------------------------- | -------- |
| POST   | `/api/v1/auth/sign_in`     | Login    |
| DELETE | `/api/v1/auth/sign_out`    | Logout   |
| POST   | `/api/v1/auth`             | Register |

`ApplicationController` includes `ActionController::Cookies` + `ActionController::RequestForgeryProtection` — Devise uses cookie-based session for now (not JWT).

## Gating actions

```ruby
class Api::V1::TournamentsController < ApplicationController
  before_action :authenticate_admin!, only: [:create]
end
```

`authenticate_admin!` is defined in `ApplicationController`. The intended body is currently commented out (look for `TODO(auth-restore)`); the live method is a no-op:

```ruby
def authenticate_admin!
  # TODO(auth-restore): when login UI lands, uncomment:
  # unless user_signed_in? && current_user.is_admin?
  #   render json: { error: "Forbidden" }, status: :forbidden
  # end
end
```

When restored, it returns **403** on failure (not 401). If you want a 401 for "not signed in" and 403 only for "signed in but not admin", split the check at that time.

## Where it's declared (gate definitions, currently no-op)

| Controller                | `authenticate_admin!` on        |
| ------------------------- | ------------------------------- |
| `TournamentsController`   | `:create`                       |
| `CategoriesController`    | **all actions**                 |
| `SeasonsController`       | `:create`                       |
| `CategoryTypesController` | `:create`                       |
| `ShiajosController`       | `:create`                       |
| `CompetitorsController`   | `:create`, `:destroy`           |
| `EnrolmentsController`    | `:create`, `:destroy`           |
| `MatchesController`       | `:create`                       |

Not gated (intentional): `MatchEventsController`, `MatchesController#show`, `Shiajos#projector`/`#summary`, `Disciplines#index`, `RuleSetsController#index`. These read endpoints are public; score events specifically are unauthenticated so a tablet mesa doesn't need login.

## The ActionCable gap

`backend/app/channels/application_cable/connection.rb` is an empty `ActionCable::Connection::Base` subclass — no `identified_by`, no `connect` method, no Devise integration. Anyone can subscribe to any `match_id` or `shiajo_id`. To close this:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      User.find_by(id: cookies.signed[:user_id]) || reject_unauthorized_connection
    end
  end
end
```

Adjust to whatever cookie/session Devise actually sets (verify before pasting).
