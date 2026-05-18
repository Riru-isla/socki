// useMatch.ts — reusable match subscription logic
// Usage: const { match, status, connected } = useMatch("1")
// match is reactive and auto-updates from ActionCable

import { ref, onMounted, onBeforeUnmount } from "vue";
import { fetchMatch } from "../lib/api";
import { subscribeMatch } from "../lib/cable";

export function useMatch(matchId: string | number) {
  const match = ref<any>(null);
  const status = ref("Loading…");
  const connected = ref(false);
  let unsubscribe: (() => void) | null = null;

  onMounted(async () => {
    try {
      match.value = await fetchMatch(matchId);
      status.value = "Ready";
    } catch (e: any) {
      status.value = `Failed to load: ${e?.message || e}`;
      return;
    }

    unsubscribe = subscribeMatch(matchId, {
      connected: () => {
        connected.value = true;
        status.value = "Live";
      },
      received: (payload: any) => {
        if (payload?.id == Number(matchId)) {
          match.value = payload;
          status.value = "Updated";
        }
      },
      disconnected: () => {
        connected.value = false;
        status.value = "Disconnected";
      },
    });
  });

  onBeforeUnmount(() => {
    if (unsubscribe) unsubscribe();
  });

  return { match, status, connected };
}
