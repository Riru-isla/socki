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
    at_second: number;
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
