import axios from "axios";

// Axios instance pointing at our Vite proxy (/api -> Rails :3000)
export const api = axios.create({
  baseURL: "/api/v1",
  headers: { "Content-Type": "application/json" },
});

// ---- Example endpoints we'll use right away ----
export async function fetchMatch(id: string | number) {
  const { data } = await api.get(`/matches/${id}`);
  return data;
}

export async function postMatchEvent(
  matchId: string | number,
  payload: {
    competitor_id: number;
    side: "red" | "white";
    event_type: "men" | "kote" | "do" | "tsuki";
    at_second: string;
  },
) {
  const { data } = await api.post(`/matches/${matchId}/match_events`, {
    event: payload,
  });
  return data;
}

export async function fetchShiajoSummary(id: string | number) {
  const { data } = await api.get(`/shiajos/${id}/summary`);
  return data;
}

export async function fetchTournaments() {
  const { data } = await api.get("/tournaments");
  return data;
}

export async function fetchTournament(id: string | number) {
  const { data } = await api.get(`/tournaments/${id}`);
  return data;
}

export async function createTournament(payload: {
  title: string;
  region: string;
  tournament_type: string;
  official: boolean;
  starts_on: string;
  ends_on: string;
  season_id: number;
}) {
  const { data } = await api.post("/tournaments", { tournament: payload });
  return data;
}

export async function createCategory(tournamentId: string | number, payload: {
  name: string;
  category_type_id: number;
}) {
  const { data } = await api.post(`/tournaments/${tournamentId}/categories`, { category: payload });
  return data;
}

export async function createShiajo(categoryId: string | number, payload: {
  name: string;
  position?: number;
}) {
  const { data } = await api.post(`/categories/${categoryId}/shiajos`, { shiajo: payload });
  return data;
}

export async function fetchSeasons() {
  const { data } = await api.get("/seasons");
  return data;
}

export async function fetchCategoryTypes() {
  const { data } = await api.get("/category_types");
  return data;
}

export async function createCategoryType(payload: {
  name: string;
  gender: string;
  team: boolean;
  rank?: string;
}) {
  const { data } = await api.post("/category_types", { category_type: payload });
  return data;
}

export async function createSeason(payload: {
  name: string;
  discipline_id: number;
}) {
  const { data } = await api.post("/seasons", { season: payload });
  return data;
}

export async function fetchDisciplines() {
  const { data } = await api.get("/disciplines");
  return data;
}
