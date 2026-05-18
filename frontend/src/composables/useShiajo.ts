// useShiajo.ts — reusable shiajo summary subscription logic
// Usage: const { summary, status, connected } = useShiajo("1")

import { ref, onMounted, onBeforeUnmount } from "vue";
import { fetchShiajoSummary } from "../lib/api";
import { subscribeShiajo } from "../lib/cable";

export function useShiajo(shiajoId: string | number) {
  const summary = ref<any>(null);
  const status = ref("Loading…");
  const connected = ref(false);
  let unsubscribe: (() => void) | null = null;

  async function load() {
    try {
      summary.value = await fetchShiajoSummary(shiajoId);
      status.value = "Live";
    } catch (e: any) {
      status.value = `Failed to load: ${e?.message || e}`;
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

  return { summary, status, connected, refresh: load };
}
