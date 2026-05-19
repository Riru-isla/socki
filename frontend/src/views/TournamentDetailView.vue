<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRoute } from "vue-router";
import { fetchTournament, createCategory, createShiajo, fetchCategoryTypes } from "../lib/api";

const route = useRoute();
const tournamentId = route.params.id as string;

const tournament = ref<any>(null);
const categoryTypes = ref<any[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

const newCategoryName = ref("");
const newCategoryTypeId = ref<number | null>(null);
const addingCategory = ref(false);
const categoryError = ref<string | null>(null);

const newShiajoName = ref("");
const activeCategoryId = ref<number | null>(null);
const addingShiajo = ref(false);
const shiajoError = ref<string | null>(null);

onMounted(async () => {
  try {
    const [t, types] = await Promise.all([fetchTournament(tournamentId), fetchCategoryTypes()]);
    tournament.value = t;
    categoryTypes.value = types;
    if (types.length) newCategoryTypeId.value = types[0].id;
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load championship";
  } finally {
    loading.value = false;
  }
});

async function addCategory() {
  if (!newCategoryName.value || !newCategoryTypeId.value) {
    categoryError.value = "Name and type are required";
    return;
  }
  addingCategory.value = true;
  categoryError.value = null;
  try {
    const created = await createCategory(tournamentId, {
      name: newCategoryName.value,
      category_type_id: newCategoryTypeId.value,
    });
    tournament.value.categories.push(created);
    newCategoryName.value = "";
  } catch (e: any) {
    categoryError.value = e.response?.data?.errors?.join(", ") || "Failed to add category";
  } finally {
    addingCategory.value = false;
  }
}

async function addShiajo(categoryId: number) {
  if (!newShiajoName.value) {
    shiajoError.value = "Name is required";
    return;
  }
  addingShiajo.value = true;
  shiajoError.value = null;
  try {
    const created = await createShiajo(categoryId, { name: newShiajoName.value });
    const cat = tournament.value.categories.find((c: any) => c.id === categoryId);
    if (cat) {
      cat.shiajos.push(created);
      cat.shiajo_count = cat.shiajos.length;
    }
    newShiajoName.value = "";
    activeCategoryId.value = null;
  } catch (e: any) {
    shiajoError.value = e.response?.data?.errors?.join(", ") || "Failed to add shiajo";
  } finally {
    addingShiajo.value = false;
  }
}
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 960px; margin: 0 auto">
    <div v-if="loading">Loading…</div>
    <div v-else-if="error" style="color: #dc2626; background: #fef2f2; padding: 16px; border-radius: 8px">
      ⚠️ {{ error }}
    </div>
    <template v-else-if="tournament">
      <div style="margin-bottom: 24px">
        <div style="display: flex; align-items: baseline; gap: 12px; margin-bottom: 8px">
          <h1 style="margin: 0">{{ tournament.title }}</h1>
          <span v-if="tournament.official" style="font-size: 11px; font-weight: 700; text-transform: uppercase; background: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 999px">Official</span>
        </div>
        <div style="color: #6b7280; font-size: 14px">
          {{ tournament.region }} · {{ tournament.season.name }} · {{ tournament.starts_on }} → {{ tournament.ends_on }}
        </div>
      </div>

      <!-- Add Category -->
      <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin-bottom: 24px">
        <h3 style="margin: 0 0 12px 0; font-size: 15px">Add Category</h3>
        <div v-if="categoryError" style="color: #dc2626; font-size: 13px; margin-bottom: 8px">⚠️ {{ categoryError }}</div>
        <div style="display: flex; gap: 10px; align-items: flex-end">
          <div style="flex: 1">
            <input v-model="newCategoryName" type="text" placeholder="Category name" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; box-sizing: border-box" />
          </div>
          <div style="flex: 1">
            <select v-model="newCategoryTypeId" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; box-sizing: border-box; background: white">
              <option v-for="t in categoryTypes" :key="t.id" :value="t.id">{{ t.name }} ({{ t.gender }})</option>
            </select>
          </div>
          <button @click="addCategory" :disabled="addingCategory" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
            {{ addingCategory ? "Adding…" : "Add" }}
          </button>
        </div>
      </div>

      <!-- Categories -->
      <div style="display: grid; gap: 16px">
        <div v-for="cat in tournament.categories" :key="cat.id" style="border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; background: white">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px">
            <div style="font-weight: 700; font-size: 16px">{{ cat.name }}</div>
            <div style="font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600">{{ cat.category_type.name }} · {{ cat.category_type.gender }}</div>
          </div>

          <div v-if="cat.shiajos.length" style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px">
            <span v-for="s in cat.shiajos" :key="s.id" style="background: #f3f4f6; padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 500">
              {{ s.name }}
            </span>
          </div>
          <div v-else style="color: #9ca3af; font-size: 13px; margin-bottom: 12px">No shiajos yet.</div>

          <!-- Add Shiajo inline -->
          <div v-if="activeCategoryId === cat.id" style="display: flex; gap: 8px; align-items: center">
            <input v-model="newShiajoName" type="text" placeholder="Shiajo name" @keyup.enter="addShiajo(cat.id)" style="flex: 1; padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px" />
            <button @click="addShiajo(cat.id)" :disabled="addingShiajo" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">Add</button>
            <button @click="activeCategoryId = null; shiajoError = null" style="padding: 8px 14px; font-size: 13px; border: 1px solid #d1d5db; background: white; border-radius: 8px; cursor: pointer">Cancel</button>
          </div>
          <button v-else @click="activeCategoryId = cat.id; shiajoError = null" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #f3f4f6; border: none; border-radius: 8px; cursor: pointer; color: #374151">+ Add Shiajo</button>
          <div v-if="shiajoError && activeCategoryId === cat.id" style="color: #dc2626; font-size: 12px; margin-top: 6px">⚠️ {{ shiajoError }}</div>
        </div>

        <div v-if="!tournament.categories.length" style="color: #6b7280; text-align: center; padding: 40px 0">
          No categories yet. Add one above.
        </div>
      </div>
    </template>
  </div>
</template>
