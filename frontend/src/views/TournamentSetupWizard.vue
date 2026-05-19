<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { fetchTournament, fetchCategoryTypes, createCategory, createShiajo } from "../lib/api";

const route = useRoute();
const router = useRouter();
const tournamentId = route.params.id as string;

type Step = 1 | 2 | 3 | 4;
const STEPS: { id: Step; label: string }[] = [
  { id: 1, label: "Categories & Shiajos" },
  { id: 2, label: "Competitors" },
  { id: 3, label: "Enrolments" },
  { id: 4, label: "Matches" },
];

const tournament = ref<any>(null);
const categoryTypes = ref<any[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);
const currentStep = ref<Step>(1);

// step 1 — add category form
const newCategoryName = ref("");
const newCategoryTypeId = ref<number | null>(null);
const addingCategory = ref(false);
const categoryError = ref<string | null>(null);

// step 1 — add shiajo form (one active category at a time)
const newShiajoName = ref("");
const activeCategoryId = ref<number | null>(null);
const addingShiajo = ref(false);
const shiajoError = ref<string | null>(null);

const step1Complete = computed(() => {
  const cats = tournament.value?.categories ?? [];
  return cats.length > 0 && cats.every((c: any) => c.shiajos.length > 0);
});

onMounted(async () => {
  await load();
  // Resume on the first incomplete step.
  if (step1Complete.value) currentStep.value = 2;
});

async function load() {
  try {
    const [t, types] = await Promise.all([
      fetchTournament(tournamentId),
      fetchCategoryTypes(),
    ]);
    tournament.value = t;
    categoryTypes.value = types;
    if (types.length && newCategoryTypeId.value === null) {
      newCategoryTypeId.value = types[0].id;
    }
  } catch (e: any) {
    error.value = e.response?.data?.error || "Failed to load championship";
  } finally {
    loading.value = false;
  }
}

async function addCategory() {
  if (!newCategoryName.value || !newCategoryTypeId.value) {
    categoryError.value = "Name and type are required";
    return;
  }
  addingCategory.value = true;
  categoryError.value = null;
  try {
    await createCategory(tournamentId, {
      name: newCategoryName.value,
      category_type_id: newCategoryTypeId.value,
    });
    // Reload so we get the full category payload (with empty shiajos array) consistently.
    await load();
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
    await createShiajo(categoryId, { name: newShiajoName.value });
    await load();
    newShiajoName.value = "";
    activeCategoryId.value = null;
  } catch (e: any) {
    shiajoError.value = e.response?.data?.errors?.join(", ") || "Failed to add shiajo";
  } finally {
    addingShiajo.value = false;
  }
}

function goToStep(step: Step) {
  currentStep.value = step;
}

function next() {
  if (currentStep.value < 4) currentStep.value = (currentStep.value + 1) as Step;
}

function prev() {
  if (currentStep.value > 1) currentStep.value = (currentStep.value - 1) as Step;
}

function finish() {
  router.push(`/tournaments/${tournamentId}`);
}

const canAdvanceFromStep1 = computed(() => step1Complete.value);
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 960px; margin: 0 auto">
    <div v-if="loading">Loading…</div>
    <div v-else-if="error" style="color: #dc2626; background: #fef2f2; padding: 16px; border-radius: 8px">⚠️ {{ error }}</div>
    <template v-else-if="tournament">
      <!-- header -->
      <div style="margin-bottom: 24px">
        <div style="font-size: 12px; color: #6b7280; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px">Setup</div>
        <div style="display: flex; align-items: baseline; gap: 12px; margin-bottom: 8px">
          <h1 style="margin: 0">{{ tournament.title }}</h1>
          <span v-if="tournament.official" style="font-size: 11px; font-weight: 700; text-transform: uppercase; background: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 999px">Official</span>
        </div>
        <div style="color: #6b7280; font-size: 14px">
          {{ tournament.region }} · {{ tournament.season.name }} · {{ tournament.starts_on }} → {{ tournament.ends_on }}
        </div>
      </div>

      <!-- step indicator -->
      <div style="display: flex; gap: 4px; margin-bottom: 32px; border-bottom: 1px solid #e5e7eb; padding-bottom: 0">
        <button
          v-for="s in STEPS"
          :key="s.id"
          @click="goToStep(s.id)"
          :style="{
            padding: '10px 16px',
            border: 'none',
            background: 'transparent',
            cursor: 'pointer',
            fontSize: '14px',
            fontWeight: currentStep === s.id ? 700 : 500,
            color: currentStep === s.id ? '#171717' : '#9ca3af',
            borderBottom: currentStep === s.id ? '2px solid #171717' : '2px solid transparent',
            marginBottom: '-1px',
          }"
        >
          <span style="font-variant-numeric: tabular-nums; opacity: 0.6">{{ s.id }}.</span>
          {{ s.label }}
        </button>
      </div>

      <!-- step 1: Categories & Shiajos -->
      <div v-if="currentStep === 1">
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
            <div v-else style="color: #9ca3af; font-size: 13px; margin-bottom: 12px">No shiajos yet — at least one is required to advance.</div>

            <div v-if="activeCategoryId === cat.id" style="display: flex; gap: 8px; align-items: center">
              <input v-model="newShiajoName" type="text" placeholder="Shiajo name (e.g. Mat 1)" @keyup.enter="addShiajo(cat.id)" style="flex: 1; padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px" />
              <button @click="addShiajo(cat.id)" :disabled="addingShiajo" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">Add</button>
              <button @click="activeCategoryId = null; shiajoError = null" style="padding: 8px 14px; font-size: 13px; border: 1px solid #d1d5db; background: white; border-radius: 8px; cursor: pointer">Cancel</button>
            </div>
            <button v-else @click="activeCategoryId = cat.id; shiajoError = null" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #f3f4f6; border: none; border-radius: 8px; cursor: pointer; color: #374151">+ Add Shiajo</button>
            <div v-if="shiajoError && activeCategoryId === cat.id" style="color: #dc2626; font-size: 12px; margin-top: 6px">⚠️ {{ shiajoError }}</div>
          </div>

          <div v-if="!tournament.categories.length" style="color: #6b7280; text-align: center; padding: 40px 0">
            No categories yet. Add the first one above.
          </div>
        </div>
      </div>

      <!-- step 2/3/4 placeholders -->
      <div v-if="currentStep === 2" style="border: 1px dashed #d1d5db; border-radius: 12px; padding: 48px; text-align: center; color: #6b7280">
        <div style="font-size: 32px; margin-bottom: 8px">🥋</div>
        <div style="font-weight: 600; margin-bottom: 4px">Competitors</div>
        <div style="font-size: 13px">Coming in the next chunk: add competitors to the global pool.</div>
      </div>
      <div v-if="currentStep === 3" style="border: 1px dashed #d1d5db; border-radius: 12px; padding: 48px; text-align: center; color: #6b7280">
        <div style="font-size: 32px; margin-bottom: 8px">📝</div>
        <div style="font-weight: 600; margin-bottom: 4px">Enrolments</div>
        <div style="font-size: 13px">Coming in the next chunk: assign competitors to each category.</div>
      </div>
      <div v-if="currentStep === 4" style="border: 1px dashed #d1d5db; border-radius: 12px; padding: 48px; text-align: center; color: #6b7280">
        <div style="font-size: 32px; margin-bottom: 8px">⚔️</div>
        <div style="font-weight: 600; margin-bottom: 4px">Matches</div>
        <div style="font-size: 13px">Coming in the next chunk: create matches between enrolled competitors. Later, the draw button lives here.</div>
      </div>

      <!-- footer nav -->
      <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 32px; padding-top: 20px; border-top: 1px solid #e5e7eb">
        <button @click="prev" :disabled="currentStep === 1" :style="{ padding: '10px 18px', fontSize: '14px', border: '1px solid #d1d5db', background: 'white', borderRadius: '8px', cursor: currentStep === 1 ? 'not-allowed' : 'pointer', opacity: currentStep === 1 ? 0.5 : 1 }">
          ← Back
        </button>

        <div style="display: flex; gap: 12px">
          <button v-if="currentStep === 1 && !canAdvanceFromStep1" disabled style="padding: 10px 18px; font-size: 14px; background: #e5e7eb; color: #9ca3af; border: none; border-radius: 8px; cursor: not-allowed">
            Add a category with a shiajo to continue
          </button>
          <button v-else-if="currentStep < 4" @click="next" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
            Next →
          </button>
          <button v-else @click="finish" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #166534; color: white; border: none; border-radius: 8px; cursor: pointer">
            Finish
          </button>
        </div>
      </div>
    </template>
  </div>
</template>
