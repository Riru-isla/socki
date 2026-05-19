<script setup lang="ts">
import { ref, onMounted } from "vue";
import { fetchCategoryTypes, createCategoryType } from "../lib/api";

const types = ref<any[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

const newName = ref("");
const newGender = ref("male");
const newTeam = ref(false);
const newRank = ref("");
const saving = ref(false);
const formError = ref<string | null>(null);

onMounted(async () => {
  try {
    types.value = await fetchCategoryTypes();
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load";
  } finally {
    loading.value = false;
  }
});

async function submit() {
  if (!newName.value) {
    formError.value = "Name is required";
    return;
  }
  saving.value = true;
  formError.value = null;
  try {
    const created = await createCategoryType({
      name: newName.value,
      gender: newGender.value,
      team: newTeam.value,
      rank: newRank.value || undefined,
    });
    types.value.unshift(created);
    newName.value = "";
    newRank.value = "";
    newTeam.value = false;
  } catch (e: any) {
    formError.value = e.response?.data?.errors?.join(", ") || "Failed to create";
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 640px; margin: 0 auto">
    <h1>Category Types</h1>

    <div v-if="loading">Loading…</div>
    <div v-else-if="error" style="color: #dc2626; background: #fef2f2; padding: 16px; border-radius: 8px">⚠️ {{ error }}</div>
    <template v-else>
      <!-- Create form -->
      <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin: 16px 0">
        <h3 style="margin: 0 0 12px 0; font-size: 15px">New Category Type</h3>
        <div v-if="formError" style="color: #dc2626; font-size: 13px; margin-bottom: 8px">⚠️ {{ formError }}</div>
        <div style="display: grid; gap: 10px">
          <input v-model="newName" type="text" placeholder="Name (e.g. Individual Masculino)" style="padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px" />
          <div style="display: flex; gap: 10px">
            <select v-model="newGender" style="flex: 1; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; background: white">
              <option value="male">Male</option>
              <option value="female">Female</option>
              <option value="mixed">Mixed</option>
            </select>
            <input v-model="newRank" type="text" placeholder="Rank (optional)" style="flex: 1; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px" />
          </div>
          <label style="display: flex; align-items: center; gap: 8px; font-size: 14px; cursor: pointer">
            <input v-model="newTeam" type="checkbox" />
            Team category
          </label>
          <button @click="submit" :disabled="saving" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
            {{ saving ? "Saving…" : "Add Category Type" }}
          </button>
        </div>
      </div>

      <!-- List -->
      <div style="display: grid; gap: 8px">
        <div v-for="t in types" :key="t.id" style="padding: 12px 16px; border: 1px solid #e5e7eb; border-radius: 10px; background: white; display: flex; justify-content: space-between; align-items: center">
          <div>
            <div style="font-weight: 600">{{ t.name }}</div>
            <div style="color: #6b7280; font-size: 12px; text-transform: capitalize">{{ t.gender }} {{ t.team ? "· Team" : "" }} {{ t.rank ? "· " + t.rank : "" }}</div>
          </div>
        </div>
        <div v-if="!types.length" style="color: #6b7280; text-align: center; padding: 24px">No category types yet.</div>
      </div>
    </template>
  </div>
</template>
