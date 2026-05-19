<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { fetchTournaments } from "../lib/api";

const router = useRouter();
const tournaments = ref<any[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    tournaments.value = await fetchTournaments();
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load tournaments";
  } finally {
    loading.value = false;
  }
});

function goNew() {
  router.push("/tournaments/new");
}

function goDetail(id: number) {
  router.push(`/tournaments/${id}`);
}
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 960px; margin: 0 auto">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px">
      <h1 style="margin: 0">Championships</h1>
      <button @click="goNew" style="padding: 10px 18px; font-size: 15px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
        + New Championship
      </button>
    </div>

    <div v-if="loading">Loading…</div>
    <div v-else-if="error" style="color: #dc2626; background: #fef2f2; padding: 16px; border-radius: 8px">
      ⚠️ {{ error }}
    </div>
    <div v-else-if="!tournaments.length" style="color: #6b7280; padding: 40px 0; text-align: center">
      No championships yet.
    </div>
    <div v-else style="display: grid; gap: 12px">
      <div
        v-for="t in tournaments"
        :key="t.id"
        @click="goDetail(t.id)"
        style="padding: 16px; border: 1px solid #e5e7eb; border-radius: 12px; cursor: pointer; background: #fafafa; display: flex; justify-content: space-between; align-items: center"
      >
        <div>
          <div style="font-weight: 700; font-size: 16px">{{ t.title }}</div>
          <div style="color: #6b7280; font-size: 13px; margin-top: 4px">
            {{ t.region }} · {{ t.season.name }} · {{ t.starts_on }} → {{ t.ends_on }}
          </div>
        </div>
        <div style="display: flex; gap: 8px; align-items: center">
          <span v-if="t.official" style="font-size: 11px; font-weight: 700; text-transform: uppercase; background: #dcfce7; color: #166534; padding: 4px 8px; border-radius: 999px">Official</span>
          <span style="font-size: 12px; color: #6b7280">{{ t.category_count }} categories</span>
        </div>
      </div>
    </div>
  </div>
</template>
