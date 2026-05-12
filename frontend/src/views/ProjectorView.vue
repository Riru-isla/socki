<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { fetchMatch } from '../lib/api'
import { subscribeMatch } from '../lib/cable'

type EventType = 'men' | 'kote' | 'do' | 'tsuki'
type Side = 'red' | 'white'

const props = defineProps<{ matchId: string }>()
const match = ref<any>(null)
const cable = ref<'connecting'|'connected'|'disconnected'>('connecting')
let unsubscribe: null | (() => void) = null

async function loadOnce() {
  const data = await fetchMatch(props.matchId)
  match.value = data
}

onMounted(async () => {
  await loadOnce()
  unsubscribe = subscribeMatch(props.matchId, {
    connected: () => (cable.value = 'connected'),
    disconnected: () => (cable.value = 'disconnected'),
    received: (payload) => {
      if (payload?.id == Number(props.matchId)) match.value = payload
    },
  })
})

onBeforeUnmount(() => { if (unsubscribe) unsubscribe() })

function mmss(totalSeconds?: number) {
  const s = Number(totalSeconds ?? 0)
  const mPart = Math.floor(s / 60).toString().padStart(2, '0')
  const sPart = Math.floor(s % 60).toString().padStart(2, '0')
  return `${mPart}:${sPart}`
}
function label(et: EventType) {
  // Capitalize Spanish-ish labels
  const map: Record<string,string> = { men: 'Men', kote: 'Kote', do: 'Do', tsuki: 'Tsuki' }
  return map[et] || et
}

const redEvents = computed(() => (match.value?.events || []).filter((e: any) => e.side === 'red'))
const whiteEvents = computed(() => (match.value?.events || []).filter((e: any) => e.side === 'white'))

const redScore = computed(() => redEvents.value.length)
const whiteScore = computed(() => whiteEvents.value.length)
</script>

<template>
  <div class="screen" v-if="match">
    <header class="topbar">
      <div class="left">
        <div class="shiajo">Shiajo: {{ match.shiajo?.name || '—' }}</div>
        <div class="category">{{ match.category?.name }}</div>
      </div>
      <div class="right">
        <span class="badge" :class="match.status">{{ match.status?.replace('_',' ') }}</span>
        <span class="cable" :data-state="cable">●</span>
      </div>
    </header>

    <main class="grid4">
      <!-- LEFT: RED competitor -->
      <section class="side red">
        <div class="side-head red-head">ROJO</div>
        <div class="name clamp">{{ match.competitors.red?.name || '—' }}</div>
      </section>

      <!-- COL 2: RED SCORE -->
      <section class="score red-score">
        <div class="score-num">{{ redScore }}</div>
        <div class="score-label">PUNTOS</div>
      </section>

      <!-- COL 3: WHITE SCORE -->
      <section class="score white-score">
        <div class="score-num">{{ whiteScore }}</div>
        <div class="score-label">PUNTOS</div>
      </section>

      <!-- RIGHT: WHITE competitor -->
      <section class="side white">
        <div class="side-head white-head">BLANCO</div>
        <div class="name clamp">{{ match.competitors.white?.name || '—' }}</div>
      </section>
    </main>

    <!-- ✨ NEW: timelines under the points -->
    <section class="timelines">
      <div class="timeline red-tl">
        <h3>Acciones ROJO</h3>
        <ul>
          <li v-for="(e, idx) in redEvents" :key="'r'+idx">
            <span class="pill red-pill">{{ label(e.event_type) }}</span>
            <span class="time">@ {{ mmss(e.at_second) }}</span>
          </li>
          <li v-if="!redEvents.length" class="muted">—</li>
        </ul>
      </div>

      <div class="timeline white-tl">
        <h3>Acciones BLANCO</h3>
        <ul>
          <li v-for="(e, idx) in whiteEvents" :key="'w'+idx">
            <span class="pill white-pill">{{ label(e.event_type) }}</span>
            <span class="time">@ {{ mmss(e.at_second) }}</span>
          </li>
          <li v-if="!whiteEvents.length" class="muted">—</li>
        </ul>
      </div>
    </section>

    <footer class="footer">
      <div class="time">
        Tiempo (config): {{ match.rule_set?.max_time }}s
      </div>
      <div class="meta">
        Match #{{ match.id }}
      </div>
    </footer>
  </div>

  <div v-else class="screen loading">Cargando…</div>
</template>

<style scoped>
:root { --bg:#0b0b0d; --card:#121216; --muted:#8b8b94; --white:#f5f5f7; }
.screen {
  background: var(--bg);
  color: var(--white);
  min-height: 100vh;
  padding: 24px 32px;
  box-sizing: border-box;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, "Helvetica Neue", Arial, "Noto Sans", "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji", sans-serif;
}

.topbar {
  display: flex; justify-content: space-between; align-items: baseline;
  margin-bottom: 16px;
}
.topbar .left { display: flex; gap: 14px; align-items: baseline; }
.shiajo { font-weight: 800; letter-spacing: .06em; color: #d0d0d5; text-transform: uppercase; }
.category { color: var(--muted); font-weight: 600; }
.topbar .right { display: flex; gap: 12px; align-items: center; }

.badge {
  padding: 6px 10px; border-radius: 8px; font-weight: 700; font-size: 14px; text-transform: uppercase;
  background: #22232a; color: #c9c9cf; letter-spacing: .04em;
}
.badge.in_progress { background: #1b3a1b; color: #aef3ae; }
.badge.upcoming    { background: #232130; color: #cfc8ff; }
.badge.finished    { background: #3a1b1b; color: #f3b0ae; }

.cable { font-size: 12px; line-height: 1; }
.cable[data-state="connected"]   { color: #4ade80; text-shadow: 0 0 10px rgba(74,222,128,.5); }
.cable[data-state="connecting"]  { color: #f59e0b; }
.cable[data-state="disconnected"]{ color: #ef4444; }

.grid4 {
  display: grid;
  grid-template-columns: 1.5fr 1fr 1fr 1.5fr;
  gap: 24px;
  align-items: stretch;
}

/* Side cards */
.side {
  background: var(--card);
  border-radius: 20px;
  padding: 18px 20px;
  display: flex; flex-direction: column; gap: 16px;
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.05), 0 8px 30px rgba(0,0,0,.35);
}
.side-head {
  font-weight: 900; letter-spacing: .12em; font-size: 18px; line-height: 1;
  padding: 10px 12px; border-radius: 12px; display: inline-block;
}
.red-head   { background: #b51414; color: #fff; }
.white-head { background: #e5e5e5; color: #101014; }
.name {
  font-size: 40px; font-weight: 800; line-height: 1.1;
  text-shadow: 0 2px 0 rgba(0,0,0,.25);
}

/* Score tiles */
.score {
  background: linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0.02));
  border-radius: 20px;
  padding: 18px 20px;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.06), 0 8px 30px rgba(0,0,0,.35);
}
.score-num {
  font-size: 110px; font-weight: 1000; letter-spacing: .02em; line-height: 0.9;
  text-shadow: 0 8px 0 rgba(0,0,0,.25);
}
.red-score .score-num   { color: #ffb0b0; }
.white-score .score-num { color: #e9e9e9; }
.score-label {
  margin-top: 6px; font-size: 14px; letter-spacing: .18em; color: #a6a6ad; font-weight: 800;
}

/* ✨ Timelines */
.timelines {
  margin-top: 18px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18px;
}
.timeline {
  background: var(--card);
  border-radius: 16px;
  padding: 14px 16px;
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.05), 0 6px 22px rgba(0,0,0,.28);
}
.timeline h3 {
  margin: 0 0 10px 0; font-size: 16px; letter-spacing: .14em; text-transform: uppercase; color: #cfcfd6;
}
.timeline ul { margin: 0; padding: 0; list-style: none; }
.timeline li {
  display:flex; align-items:center; gap:8px;
  padding: 6px 0; border-bottom: 1px solid rgba(255,255,255,0.06);
}
.timeline li:last-child { border-bottom: none; }
.pill {
  padding: 4px 8px; border-radius: 999px; font-weight: 800; font-size: 12px; letter-spacing: .08em;
}
.red-pill   { background:#b51414; color:#fff; }
.white-pill { background:#e5e5e5; color:#111; }
.time { color:#bdbdc7; font-weight:700; font-size: 12px; }
.muted { color:#7b7b86; }

.footer {
  display:flex; justify-content: space-between; align-items:center;
  margin-top: 22px; color: #a7a7b1; font-weight: 600;
}
.time { opacity: .85; }
.meta { opacity: .65; }

/* name clamp to avoid overflow */
.clamp {
  display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;
}

/* Basic responsiveness */
@media (max-width: 1100px) {
  .grid4 { grid-template-columns: 1fr 1fr; }
  .score { min-height: 180px; }
  .name { font-size: 28px; }
  .score-num { font-size: 80px; }
  .timelines { grid-template-columns: 1fr; }
}
</style>
