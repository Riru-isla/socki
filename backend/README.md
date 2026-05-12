# 🥋 Socki — Backend
### Real-time Tournament Management for Kendo & Iaido

Socki is a **real-time tournament management system** designed for martial arts competitions such as **Kendo** and **Iaido**.

This repository contains the **backend application**, responsible for:
- Modeling the championship domain
- Handling match logic and scoring
- Broadcasting real-time updates
- Persisting reliable historical data

The project was developed as a **production-oriented MVP**, based on real competition experience.

---

## 🎯 Problem Space

In many martial arts championships:

- Match data is tracked manually or with ad-hoc tools
- Real-time updates are unreliable or nonexistent
- Results and match events are lost after the event
- There is no structured data for transparency or analytics

Socki addresses this by providing a **centralized backend system** that:
- Controls match flow and scoring
- Acts as a single source of truth
- Supports real-time consumption by multiple clients
- Preserves complete historical data

---

## 🧠 Backend Responsibilities

The backend is responsible for:

- Modeling the full championship structure
- Receiving and validating match events (points, penalties, etc.)
- Managing match state and transitions
- Broadcasting live updates via WebSockets
- Persisting all data for post-event analysis and reporting

The system is **API-first** and designed to support multiple real-time consumers.

---

## 🏗 Domain Model (Simplified)

```text
Discipline (Kendo / Iaido / …)
└─ Season
   └─ Tournament
      └─ Category
         └─ Shiajo (competition area)
            └─ Match
               └─ MatchEvents
````

Each **MatchEvent** records:

* Scoring action or penalty
* Side (red / white)
* Timestamp within the match

This enables:

* Live score calculation
* Automatic winner resolution
* Full traceability of match history

---

## ⚡ Real-time Architecture

Socki uses **Action Cable (WebSockets)** to:

* Broadcast match state changes
* Push scoring events instantly
* Keep all connected clients in sync

The system is designed to be **event-driven**, with the API acting as a fallback when real-time connections are unavailable.

---

## 🧪 Current Status

### ✅ Implemented

* API-first Rails backend
* Strong relational domain model
* Match and event system
* Real-time broadcasting via WebSockets
* Fully tested domain logic (RSpec + FactoryBot)

### 🚧 In Progress

* Match flow control (start / pause / end)
* Improved state handling and transitions
* Hardening for real-world event conditions

---

## 🛠 Tech Stack

* **Ruby on Rails** (API-first)
* **PostgreSQL**
* **Action Cable** (WebSockets)
* **RSpec + FactoryBot**

---

## 👤 About the author

Created by **Diego Isla** — Senior Backend Engineer · Real-time Systems.

If you’re a recruiter or hiring manager, this repository is meant to be **read, not just run**.
Feel free to explore the codebase and reach out — feedback is always welcome.

