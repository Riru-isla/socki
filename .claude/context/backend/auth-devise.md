# Auth (Devise) ✅

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

`authenticate_admin!` is defined in `ApplicationController`:

```ruby
def authenticate_admin!
  unless user_signed_in? && current_user.is_admin?
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

Returns **403** on failure, not 401. If you want a 401 for "not signed in" and 403 only for "signed in but not admin", split the check.

## Where it's actually applied today

| Controller             | `authenticate_admin!` on |
| ---------------------- | ------------------------ |
| `TournamentsController` | `:create` |
| `CategoriesController`  | **all actions** |
| `SeasonsController`     | `:create` |
| `CategoryTypesController` | `:create` |
| `ShiajosController`     | `:create` |

`MatchEventsController`, `MatchesController#show`, `Shiajos#projector`/`#summary`, `Disciplines#index` are **not gated** — anonymous clients can post score events and read matches. This is acceptable for the LAN-only tournament use case but must be revisited before any public deployment.

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
