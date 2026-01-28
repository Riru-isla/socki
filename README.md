# 🥋 Socki  
### Sistema de Organización de Campeonatos de Kendo e Iaido

Socki is a **real-time tournament management system** designed for **martial arts competitions** such as **Kendo** and **Iaido**.  
It focuses on **live scoring**, **clear public displays**, and **reliable data collection**, with a strong emphasis on usability during real events.

This project is being built as a **production-ready MVP**, with scalability and future expansion in mind.

---

## 🎯 What problem does Socki solve?

In many martial arts championships:

- Scores are tracked manually or with ad-hoc tools
- Public projector screens are confusing or outdated
- Competitors don’t know *where* or *when* they fight next
- Match data is lost after the event
- Analytics and transparency are almost nonexistent

Socki aims to **centralize everything**:
- Live match control
- Public real-time visualization
- Accurate historical data
- Future analytics and transparency

---

## 🧠 High-level overview

Socki is split into two main parts:

### 🖥 Backend (Ruby on Rails – API-first)
- Models the full championship structure
- Receives match events (points, penalties, etc.)
- Broadcasts live updates using **Action Cable**
- Persists all data for analytics and reporting

### 📺 Frontend (Vue 3 + Vite)
- **Projector UI**: big screens showing live matches
- **Mesa UI** (in progress): tablet interface for referees
- Real-time updates via WebSockets
- Designed to be simple, robust, and readable under pressure

---

## 🏗 Domain model (simplified)

```ruby
Discipline (Kendo / Iaido / …)
└── Season (e.g. "Kendo 2025")
└── Tournament (Madrid Championship 2025)
└── Category (Masculino Individual, 1º Dan, Teams…)
└── Shiajo (competition area)
└── Match
└── MatchEvents (Men, Kote, Hansoku, etc.)
```


Each **MatchEvent** stores:
- Who scored
- What was scored
- Which side (red / white)
- Exact time in the match

This allows **live scoring**, **automatic winner resolution**, and **future analytics**.

---

## ⚡ Real-time features

Socki uses **Action Cable (WebSockets)** to provide:

- Live score updates on projector screens
- Instant propagation of referee actions
- Event-driven UI (no manual refresh)
- Resilient design (API fallback if WebSocket fails)

---

## 🖥 Current features (MVP)

### ✅ Implemented
- API-first Rails backend
- Strong relational data model
- Match + event system
- Live projector view with:
  - Competitor names
  - Live scores
  - Timeline of scoring actions
- Real-time updates via WebSockets
- Fully tested domain models (RSpec + FactoryBot)

### 🚧 In progress
- Mesa (referee) UI
- Match flow control (start / pause / end)
- Better state handling for matches
- Improved projector transitions

---

## 🚀 Next steps

### Short-term
- Complete Mesa tablet UI
- Add timer control logic
- Finalize match state transitions
- Improve error handling & offline safety

### Mid-term
- User roles (admin / referee / viewer)
- Authentication & permissions
- Championship dashboards
- Better public displays (animations, transitions)

### Long-term vision
- Competitor profiles & statistics
- Historical performance analytics
- National federation reporting
- Streaming integration per Shiajo
- Multi-discipline support
- Public transparency & rankings

---

## 🧪 Tech stack

**Backend**
- Ruby on Rails (API-only)
- PostgreSQL
- Action Cable (WebSockets)
- RSpec + FactoryBot

**Frontend**
- Vue 3
- Vite
- TypeScript
- WebSockets + REST API

---

## 🧩 Why this project matters

Socki is not a tutorial app.

It is:
- Built from real competition experience
- Designed for stressful real-world usage
- Focused on correctness, clarity, and extensibility
- Structured to evolve into a full SaaS platform

This repository showcases:
- Domain modeling
- Real-time systems
- API design
- Frontend-backend communication
- Pragmatic engineering decisions

---

## 👤 Author

Built with ❤️ by **Diego Isla**  
Senior Ruby on Rails Backend Developer

> “I wanted to build the tool I wish we had during championships.”
