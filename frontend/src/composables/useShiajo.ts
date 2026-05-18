// useShiajo.ts — reusable shiajo summary subscription logic
// Usage: const { summary, status, connected } = useShiajo("1")

import { ref, onMounted, onBeforeUnmount } from "vue";
import { fetchShiajoSummary } from "../lib/api";
import { subscribeShiajo } from "../lib/cable";

export function useShiajo(shiajoId: string | number) {
  const summary = ref<any>(null);
  const status = ref("Loading…");
  const connected = ref(false);
  const error = ref<string | null>(null);
  let unsubscribe: (() => void) | null = null;

  async function load() {
    try {
      summary.value = await fetchShiajoSummary(shiajoId);
      status.value = "Live";
      error.value = null;
    } catch (e: any) {
      error.value = e?.response?.status === 404
        ? "Shiajo not found"
        : `Failed to load: ${e?.message || e}`;
      status.value = "Error";
    }
  }

  onMounted(async () => {
    await load();

    unsubscribe = subscribeShiajo(shiajoId, {
      received: () => {
        load(); // server pinged us → refresh summary
      },
    });
  });

  onBeforeUnmount(() => {
    if (unsubscribe) unsubscribe();
  });

  return { summary, status, connected, error, refresh: load };
}
