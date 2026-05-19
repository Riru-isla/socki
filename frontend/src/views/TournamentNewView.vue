<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { createTournament, fetchSeasons } from "../lib/api";

const router = useRouter();

const title = ref("");
const region = ref("");
const tournamentType = ref("regional_championship");
const official = ref(true);
const startsOn = ref("");
const endsOn = ref("");
const seasonId = ref<number | null>(null);
const seasons = ref<any[]>([]);

const saving = ref(false);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    seasons.value = await fetchSeasons();
    if (seasons.value.length) seasonId.value = seasons.value[0].id;
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load seasons";
  }
});

async function submit() {
  if (!title.value || !region.value || !startsOn.value || !endsOn.value || !seasonId.value) {
    error.value = "Please fill all required fields";
    return;
  }
  saving.value = true;
  error.value = null;
  try {
    const created = await createTournament({
      title: title.value,
      region: region.value,
      tournament_type: tournamentType.value,
      official: official.value,
      starts_on: startsOn.value,
      ends_on: endsOn.value,
      season_id: seasonId.value,
    });
    router.push(`/tournaments/${created.id}/setup`);
  } catch (e: any) {
    saving.value = false;
    error.value = e.response?.data?.errors?.join(", ") || "Failed to create championship";
  }
}
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 640px; margin: 0 auto">
    <h1>New Championship</h1>

    <div v-if="error" style="color: #dc2626; background: #fef2f2; padding: 12px 16px; border-radius: 8px; margin: 12px 0">
      ⚠️ {{ error }}
    </div>

    <form @submit.prevent="submit" style="display: grid; gap: 16px; margin-top: 16px">
      <div>
        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Title *</label>
        <input v-model="title" type="text" placeholder="Campeonato de Madrid 2026" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box" />
      </div>

      <div>
        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Region *</label>
        <input v-model="region" type="text" placeholder="Madrid" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box" />
      </div>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px">
        <div>
          <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Starts *</label>
          <input v-model="startsOn" type="date" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box" />
        </div>
        <div>
          <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Ends *</label>
          <input v-model="endsOn" type="date" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box" />
        </div>
      </div>

      <div>
        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Season *</label>
        <select v-model="seasonId" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box; background: white">
          <option v-for="s in seasons" :key="s.id" :value="s.id">{{ s.name }} ({{ s.discipline }})</option>
        </select>
      </div>

      <div>
        <label style="display: block; font-size: 13px; font-weight: 600; margin-bottom: 6px; color: #374151">Type</label>
        <select v-model="tournamentType" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 15px; box-sizing: border-box; background: white">
          <option value="regional_championship">Regional Championship</option>
          <option value="national_championship">National Championship</option>
          <option value="open_tournament">Open Tournament</option>
          <option value="local">Local</option>
        </select>
      </div>

      <label style="display: flex; align-items: center; gap: 8px; font-size: 14px; color: #374151; cursor: pointer">
        <input v-model="official" type="checkbox" />
        Official championship
      </label>

      <div style="display: flex; gap: 12px; margin-top: 8px">
        <button type="button" @click="router.back()" style="padding: 12px 20px; font-size: 15px; border: 1px solid #d1d5db; background: white; border-radius: 8px; cursor: pointer">Cancel</button>
        <button type="submit" :disabled="saving" style="padding: 12px 20px; font-size: 15px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer; flex: 1">
          {{ saving ? "Creating…" : "Create Championship" }}
        </button>
      </div>
    </form>
  </div>
</template>
