<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  fetchTournament,
  fetchCategoryTypes,
  createCategory,
  createShiajo,
  fetchCompetitors,
  createCompetitor,
  deleteCompetitor,
  createEnrolment,
  deleteEnrolment,
  fetchRuleSets,
  createMatch,
} from "../lib/api";

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
const competitors = ref<any[]>([]);
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

// step 2 — add competitor form
const newCompetitorName = ref("");
const newCompetitorAge = ref<number | null>(null);
const newCompetitorProvince = ref("");
const addingCompetitor = ref(false);
const competitorError = ref<string | null>(null);

// step 3 — enrolment errors (toggle ops are fire-and-reload)
const enrolmentError = ref<string | null>(null);

// step 4 — add match form (one active category at a time)
const ruleSets = ref<any[]>([]);
const activeMatchCategoryId = ref<number | null>(null);
const newMatchRedId = ref<number | null>(null);
const newMatchWhiteId = ref<number | null>(null);
const newMatchShiajoId = ref<number | null>(null);
const newMatchRuleSetId = ref<number | null>(null);
const addingMatch = ref(false);
const matchError = ref<string | null>(null);

const step1Complete = computed(() => {
  const cats = tournament.value?.categories ?? [];
  return cats.length > 0 && cats.every((c: any) => c.shiajos.length > 0);
});

// "Complete enough to advance" — at least two competitors exist in the
// pool (the minimum needed to form a match). This is a global pool
// check, not per-tournament.
const step2Complete = computed(() => competitors.value.length >= 2);

// Step 3 is complete when at least one category has ≥2 enrolments —
// that's the minimum required to form a match in step 4.
const step3Complete = computed(() => {
  const cats = tournament.value?.categories ?? [];
  return cats.some((c: any) => c.enrolments.length >= 2);
});

onMounted(async () => {
  await load();
  // Resume on the first incomplete step.
  if (step1Complete.value && step2Complete.value && step3Complete.value) currentStep.value = 4;
  else if (step1Complete.value && step2Complete.value) currentStep.value = 3;
  else if (step1Complete.value) currentStep.value = 2;
});

async function load() {
  try {
    const [t, types, comps, rs] = await Promise.all([
      fetchTournament(tournamentId),
      fetchCategoryTypes(),
      fetchCompetitors(),
      fetchRuleSets(),
    ]);
    tournament.value = t;
    categoryTypes.value = types;
    competitors.value = comps;
    ruleSets.value = rs;
    if (types.length && newCategoryTypeId.value === null) {
      newCategoryTypeId.value = types[0].id;
    }
    if (rs.length && newMatchRuleSetId.value === null) {
      newMatchRuleSetId.value = rs[0].id;
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

async function addCompetitor() {
  if (!newCompetitorName.value) {
    competitorError.value = "Name is required";
    return;
  }
  addingCompetitor.value = true;
  competitorError.value = null;
  try {
    await createCompetitor({
      name: newCompetitorName.value,
      age: newCompetitorAge.value || null,
      province: newCompetitorProvince.value || null,
    });
    await load();
    newCompetitorName.value = "";
    newCompetitorAge.value = null;
    newCompetitorProvince.value = "";
  } catch (e: any) {
    competitorError.value = e.response?.data?.errors?.join(", ") || "Failed to add competitor";
  } finally {
    addingCompetitor.value = false;
  }
}

async function removeCompetitor(id: number) {
  if (!confirm("Remove this competitor from the global pool?")) return;
  try {
    await deleteCompetitor(id);
    await load();
  } catch (e: any) {
    competitorError.value = e.response?.data?.error || "Failed to remove competitor";
  }
}

function enrolmentFor(category: any, competitorId: number) {
  return category.enrolments.find((e: any) => e.competitor.id === competitorId) || null;
}

async function toggleEnrolment(categoryId: number, competitorId: number, existing: { id: number } | null) {
  enrolmentError.value = null;
  try {
    if (existing) {
      await deleteEnrolment(existing.id);
    } else {
      await createEnrolment(categoryId, { competitor_id: competitorId });
    }
    await load();
  } catch (e: any) {
    enrolmentError.value = e.response?.data?.errors?.join(", ") || e.response?.data?.error || "Failed to update enrolment";
  }
}

function openMatchForm(category: any) {
  activeMatchCategoryId.value = category.id;
  matchError.value = null;
  newMatchRedId.value = null;
  newMatchWhiteId.value = null;
  newMatchShiajoId.value = category.shiajos[0]?.id ?? null;
  if (ruleSets.value.length && newMatchRuleSetId.value === null) {
    newMatchRuleSetId.value = ruleSets.value[0].id;
  }
}

function closeMatchForm() {
  activeMatchCategoryId.value = null;
  matchError.value = null;
}

async function addMatch(categoryId: number) {
  matchError.value = null;
  if (!newMatchRedId.value || !newMatchWhiteId.value) {
    matchError.value = "Pick both red and white competitors";
    return;
  }
  if (newMatchRedId.value === newMatchWhiteId.value) {
    matchError.value = "Red and white must be different competitors";
    return;
  }
  if (!newMatchShiajoId.value) {
    matchError.value = "Pick a shiajo";
    return;
  }
  if (!newMatchRuleSetId.value) {
    matchError.value = "Pick a rule set";
    return;
  }
  addingMatch.value = true;
  try {
    await createMatch(categoryId, {
      shiajo_id: newMatchShiajoId.value,
      red_competitor_id: newMatchRedId.value,
      white_competitor_id: newMatchWhiteId.value,
      rule_set_id: newMatchRuleSetId.value,
    });
    await load();
    // keep form open for fast next-match entry, but clear competitors
    newMatchRedId.value = null;
    newMatchWhiteId.value = null;
  } catch (e: any) {
    matchError.value = e.response?.data?.errors?.join(", ") || e.response?.data?.error || "Failed to create match";
  } finally {
    addingMatch.value = false;
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
const canAdvanceFromStep2 = computed(() => step2Complete.value);
const canAdvanceFromStep3 = computed(() => step3Complete.value);
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

      <!-- step 2: Competitors (global pool) -->
      <div v-if="currentStep === 2">
        <div style="color: #6b7280; font-size: 13px; margin-bottom: 16px">
          Athletes are shared across all championships. Add anyone missing from the pool below — you'll assign them to categories in the next step.
        </div>

        <div style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; margin-bottom: 24px">
          <h3 style="margin: 0 0 12px 0; font-size: 15px">Add Competitor</h3>
          <div v-if="competitorError" style="color: #dc2626; font-size: 13px; margin-bottom: 8px">⚠️ {{ competitorError }}</div>
          <form @submit.prevent="addCompetitor" style="display: flex; gap: 10px; align-items: flex-end">
            <div style="flex: 2">
              <input v-model="newCompetitorName" type="text" placeholder="Name *" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; box-sizing: border-box" />
            </div>
            <div style="width: 80px">
              <input v-model.number="newCompetitorAge" type="number" min="0" placeholder="Age" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; box-sizing: border-box" />
            </div>
            <div style="flex: 1">
              <input v-model="newCompetitorProvince" type="text" placeholder="Province" style="width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; box-sizing: border-box" />
            </div>
            <button type="submit" :disabled="addingCompetitor" style="padding: 10px 18px; font-size: 14px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 8px; cursor: pointer">
              {{ addingCompetitor ? "Adding…" : "Add" }}
            </button>
          </form>
        </div>

        <div style="margin-bottom: 8px; font-size: 13px; color: #6b7280; font-weight: 600">
          {{ competitors.length }} {{ competitors.length === 1 ? "competitor" : "competitors" }} in pool
        </div>

        <div v-if="competitors.length" style="display: grid; gap: 8px">
          <div v-for="c in competitors" :key="c.id" style="display: flex; justify-content: space-between; align-items: center; border: 1px solid #e5e7eb; border-radius: 10px; padding: 12px 16px; background: white">
            <div>
              <div style="font-weight: 600">{{ c.name }}</div>
              <div v-if="c.age || c.province" style="font-size: 12px; color: #6b7280; margin-top: 2px">
                <span v-if="c.age">{{ c.age }} yrs</span>
                <span v-if="c.age && c.province"> · </span>
                <span v-if="c.province">{{ c.province }}</span>
              </div>
            </div>
            <button @click="removeCompetitor(c.id)" title="Remove from pool" style="background: transparent; color: #9ca3af; border: none; cursor: pointer; font-size: 18px; padding: 4px 8px">×</button>
          </div>
        </div>
        <div v-else style="color: #9ca3af; text-align: center; padding: 40px 0">
          No competitors yet. Add the first one above.
        </div>
      </div>
      <!-- step 3: Enrolments per category -->
      <div v-if="currentStep === 3">
        <div style="color: #6b7280; font-size: 13px; margin-bottom: 16px">
          Tick each competitor to enrol them in a category. The same competitor can be in multiple categories (e.g. Individual + Team).
        </div>

        <div v-if="enrolmentError" style="color: #dc2626; background: #fef2f2; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-size: 13px">⚠️ {{ enrolmentError }}</div>

        <div v-if="!competitors.length" style="color: #9ca3af; text-align: center; padding: 40px 0">
          No competitors in the pool yet — go back to step 2 and add some.
        </div>

        <div v-else style="display: grid; gap: 16px">
          <div v-for="cat in tournament.categories" :key="cat.id" style="border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; background: white">
            <div style="display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 12px">
              <div>
                <div style="font-weight: 700; font-size: 16px">{{ cat.name }}</div>
                <div style="font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600; margin-top: 2px">{{ cat.category_type.name }} · {{ cat.category_type.gender }}</div>
              </div>
              <div style="font-size: 12px; color: #6b7280; font-weight: 600">
                {{ cat.enrolments.length }} / {{ competitors.length }} enrolled
              </div>
            </div>

            <div style="display: grid; gap: 4px">
              <label
                v-for="c in competitors"
                :key="c.id"
                style="display: flex; align-items: center; gap: 10px; padding: 8px 10px; border-radius: 6px; cursor: pointer"
                :style="{ background: enrolmentFor(cat, c.id) ? '#f0fdf4' : 'transparent' }"
              >
                <input
                  type="checkbox"
                  :checked="!!enrolmentFor(cat, c.id)"
                  @change="toggleEnrolment(cat.id, c.id, enrolmentFor(cat, c.id))"
                  style="cursor: pointer"
                />
                <span style="font-weight: 500">{{ c.name }}</span>
                <span v-if="c.province" style="font-size: 12px; color: #6b7280">· {{ c.province }}</span>
              </label>
            </div>
          </div>
        </div>
      </div>
      <!-- step 4: Matches -->
      <div v-if="currentStep === 4">
        <div style="color: #6b7280; font-size: 13px; margin-bottom: 16px">
          Create matches by picking red and white from enrolled competitors. Each match also needs a shiajo and a rule set. Once a match exists, you can run it from the mesa view.
        </div>

        <div v-if="matchError" style="color: #dc2626; background: #fef2f2; padding: 10px 14px; border-radius: 8px; margin-bottom: 12px; font-size: 13px">⚠️ {{ matchError }}</div>

        <div style="display: grid; gap: 16px">
          <div v-for="cat in tournament.categories" :key="cat.id" style="border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; background: white">
            <div style="display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 12px">
              <div>
                <div style="font-weight: 700; font-size: 16px">{{ cat.name }}</div>
                <div style="font-size: 12px; color: #6b7280; text-transform: uppercase; font-weight: 600; margin-top: 2px">{{ cat.enrolments.length }} enrolled · {{ cat.matches.length }} matches</div>
              </div>
            </div>

            <!-- existing matches -->
            <div v-if="cat.matches.length" style="display: grid; gap: 8px; margin-bottom: 12px">
              <div v-for="m in cat.matches" :key="m.id" style="display: flex; align-items: center; gap: 10px; padding: 10px 12px; border: 1px solid #e5e7eb; border-radius: 8px; background: #fafafa">
                <span style="font-size: 12px; color: #6b7280; font-weight: 600; font-variant-numeric: tabular-nums">#{{ m.position }}</span>
                <span style="font-weight: 600">{{ m.red_competitor?.name || "TBD" }}</span>
                <span style="color: #9ca3af">vs</span>
                <span style="font-weight: 600">{{ m.white_competitor?.name || "TBD" }}</span>
                <span style="font-size: 12px; color: #6b7280">· {{ m.shiajo.name }}</span>
                <span :style="{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  padding: '2px 8px',
                  borderRadius: '999px',
                  background: m.status === 'in_progress' ? '#fef3c7' : m.status === 'finished' ? '#dcfce7' : '#e5e7eb',
                  color: m.status === 'in_progress' ? '#92400e' : m.status === 'finished' ? '#166534' : '#374151',
                }">{{ m.status }}</span>
                <span style="flex: 1"></span>
                <router-link :to="`/mesa/${m.id}`" style="font-size: 13px; padding: 4px 10px; border-radius: 6px; background: #171717; color: white; text-decoration: none; font-weight: 600">▶ Mesa</router-link>
                <router-link :to="`/projector/${m.id}`" style="font-size: 13px; padding: 4px 10px; border-radius: 6px; background: #f3f4f6; color: #374151; text-decoration: none; font-weight: 600">👁 Projector</router-link>
              </div>
            </div>

            <!-- add match form -->
            <template v-if="cat.enrolments.length >= 2 && cat.shiajos.length">
              <div v-if="activeMatchCategoryId === cat.id" style="background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 10px; padding: 12px; display: grid; gap: 10px">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
                  <div>
                    <label style="display: block; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; margin-bottom: 4px">Red</label>
                    <select v-model="newMatchRedId" style="width: 100%; padding: 8px 10px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px; background: white">
                      <option :value="null" disabled>Pick competitor…</option>
                      <option v-for="e in cat.enrolments" :key="e.id" :value="e.competitor.id" :disabled="e.competitor.id === newMatchWhiteId">{{ e.competitor.name }}</option>
                    </select>
                  </div>
                  <div>
                    <label style="display: block; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; margin-bottom: 4px">White</label>
                    <select v-model="newMatchWhiteId" style="width: 100%; padding: 8px 10px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px; background: white">
                      <option :value="null" disabled>Pick competitor…</option>
                      <option v-for="e in cat.enrolments" :key="e.id" :value="e.competitor.id" :disabled="e.competitor.id === newMatchRedId">{{ e.competitor.name }}</option>
                    </select>
                  </div>
                </div>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px">
                  <div>
                    <label style="display: block; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; margin-bottom: 4px">Shiajo</label>
                    <select v-model="newMatchShiajoId" style="width: 100%; padding: 8px 10px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px; background: white">
                      <option v-for="s in cat.shiajos" :key="s.id" :value="s.id">{{ s.name }}</option>
                    </select>
                  </div>
                  <div>
                    <label style="display: block; font-size: 11px; font-weight: 600; color: #6b7280; text-transform: uppercase; margin-bottom: 4px">Rule set</label>
                    <select v-model="newMatchRuleSetId" style="width: 100%; padding: 8px 10px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px; background: white">
                      <option v-for="rs in ruleSets" :key="rs.id" :value="rs.id">{{ rs.name }} ({{ rs.max_time }}s · best-of-{{ rs.best_of_points }})</option>
                    </select>
                  </div>
                </div>
                <div style="display: flex; gap: 8px; justify-content: flex-end">
                  <button @click="closeMatchForm" style="padding: 8px 14px; font-size: 13px; border: 1px solid #d1d5db; background: white; border-radius: 6px; cursor: pointer">Done</button>
                  <button @click="addMatch(cat.id)" :disabled="addingMatch" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #171717; color: white; border: none; border-radius: 6px; cursor: pointer">
                    {{ addingMatch ? "Adding…" : "Add Match" }}
                  </button>
                </div>
              </div>
              <button v-else @click="openMatchForm(cat)" style="padding: 8px 14px; font-size: 13px; font-weight: 600; background: #f3f4f6; border: none; border-radius: 6px; cursor: pointer; color: #374151">+ Add Match</button>
            </template>
            <div v-else style="font-size: 12px; color: #9ca3af; padding: 6px 0">
              <span v-if="cat.enrolments.length < 2">Need at least 2 enrolments — go back to step 3.</span>
              <span v-else>Need at least 1 shiajo — go back to step 1.</span>
            </div>
          </div>
        </div>
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
          <button v-else-if="currentStep === 2 && !canAdvanceFromStep2" disabled style="padding: 10px 18px; font-size: 14px; background: #e5e7eb; color: #9ca3af; border: none; border-radius: 8px; cursor: not-allowed">
            Add at least 2 competitors to continue
          </button>
          <button v-else-if="currentStep === 3 && !canAdvanceFromStep3" disabled style="padding: 10px 18px; font-size: 14px; background: #e5e7eb; color: #9ca3af; border: none; border-radius: 8px; cursor: not-allowed">
            Enrol at least 2 competitors in one category
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
