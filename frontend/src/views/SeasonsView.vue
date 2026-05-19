<script setup lang="ts">
import { ref, onMounted } from "vue";
import { fetchSeasons, fetchDisciplines, createSeason } from "../lib/api";

const seasons = ref<any[]>([]);
const disciplines = ref<any[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

const newName = ref("");
const newDisciplineId = ref<number | null>(null);
const saving = ref(false);
const formError = ref<string | null>(null);

onMounted(async () => {
  try {
    const [s, d] = await Promise.all([fetchSeasons(), fetchDisciplines()]);
    seasons.value = s;
    disciplines.value = d;
    if (d.length) newDisciplineId.value = d[0].id;
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load";
  } finally {
    loading.value = false;
  }
});

async function submit() {
  if (!newName.value || !newDisciplineId.value) {
    formError.value = "Name and discipline are required";
    return;
  }
  saving.value = true;
  formError.value = null;
  try {
    const created = await createSeason({ name: newName.value, discipline_id: newDisciplineId.value });
    seasons.value.unshift(created);
    newName.value = "";
  } catch (e: any) {
    formError.value = e.response?.data?.errors?.join(", ") || "Failed to create";
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 640px; margin: 0 auto">
    <h1>Seasons</h1>

    <div v-if="loading">Loading…</div>
    <div v-else-if="error" style="color: #dc2626; background: #fef2f2; padding: 16px; border-radius: 8px">⚠️ {{ error }}</div>
    <template v-else>
      <!-- Create form -->
      <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin: 16px 0">
        <h3 style="margin: 0 0 12px 0; font-size: 15px">New Season</h3>
        <div v-if="formError" style="color: #dc2626; font-size: 13px; margin-bottom: 8px">⚠️ {{ formError }}</div>
        <div style="display: flex; gap: 10px; align-items: flex-end">
          <input v-model="newName" type="text" placeholder="Season name" style="flex: 1; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px" />
          <select v-model="newDisciplineId" style="flex: 1; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; background: white">
            <option v-for="d in disciplines" :key="d.id" :value="d.id">{{ d.name }}</option>
          </select>
          <button @click="submit" :disabled="saving" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
            {{ saving ? "Saving…" : "Add" }}
          </button>
        </div>
      </div>

      <!-- List -->
      <div style="display: grid; gap: 8px">
        <div v-for="s in seasons" :key="s.id" style="padding: 12px 16px; border: 1px solid #e5e7eb; border-radius: 10px; background: white; display: flex; justify-content: space-between">
          <span style="font-weight: 600">{{ s.name }}</span>
          <span style="color: #6b7280; font-size: 13px">{{ s.discipline }}</span>
        </div>
        <div v-if="!seasons.length" style="color: #6b7280; text-align: center; padding: 24px">No seasons yet.</div>
      </div>
    </template>
  </div>
</template>
