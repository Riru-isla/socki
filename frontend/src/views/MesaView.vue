<script setup lang="ts">
import { ref, computed } from "vue";
import { useMatch } from "../composables/useMatch";
import { postMatchEvent } from "../lib/api";

type Side = "red" | "white";
type EventType = "men" | "kote" | "do" | "tsuki";

const props = defineProps<{ matchId: string }>();
const { match, status: matchStatus, connected, error } = useMatch(props.matchId);

const running = ref(false);
const startedAt = ref<number | null>(null);
const pausedAccum = ref(0);
const nowTick = ref(0);
let timerId: number | null = null;
const sending = ref(false);

function msNow() {
  return performance.now();
}

function start() {
  if (running.value) return;
  running.value = true;
  startedAt.value = msNow();
  const tick = () => {
    nowTick.value = msNow();
    timerId = requestAnimationFrame(tick);
  };
  timerId = requestAnimationFrame(tick);
}

function pause() {
  if (!running.value) return;
  running.value = false;
  if (timerId) cancelAnimationFrame(timerId);
  timerId = null;
  if (startedAt.value) {
    pausedAccum.value += msNow() - startedAt.value;
    startedAt.value = null;
  }
}

function resetTimer() {
  running.value = false;
  if (timerId) cancelAnimationFrame(timerId);
  timerId = null;
  startedAt.value = null;
  pausedAccum.value = 0;
  nowTick.value = 0;
}

function currentMs(): number {
  nowTick.value; // reactivity trigger
  if (!startedAt.value) return pausedAccum.value;
  return Math.max(0, msNow() - startedAt.value + pausedAccum.value);
}

const currentSeconds = computed(() => Math.floor(currentMs() / 1000));

async function sendPoint(side: Side, event_type: EventType) {
  if (!match.value) return;
  pause();
  sending.value = true;

  const competitor_id =
    side === "red"
      ? match.value.competitors.red.id
      : match.value.competitors.white.id;

  try {
    const res = await postMatchEvent(props.matchId, {
      competitor_id,
      side,
      event_type,
      at_second: currentSeconds.value,
    });
    if (!res.ok) {
      sending.value = false;
    }
  } catch {
    sending.value = false;
  }
}

const historyExpanded = ref(false);
</script>

<template>
  <div style="font-family: system-ui, sans-serif; padding: 24px; max-width: 860px">
    <h1>Mesa · Match {{ matchId }}</h1>
    <p>{{ matchStatus }} {{ connected ? "●" : "○" }}</p>

    <div v-if="error" style="color: #dc2626; padding: 16px; background: #fef2f2; border-radius: 8px; margin: 12px 0">
      ⚠️ {{ error }}
    </div>

    <div v-else-if="!match">Loading match…</div>

    <template v-else>
    <!-- Timer row -->
    <div style="display: flex; align-items: center; gap: 12px; margin: 12px 0">
      <div style="font-size: 28px; font-weight: 700">
        {{ String(Math.floor(currentMs / 60000)).padStart(2, "0") }}:
        {{ String(Math.floor((currentMs % 60000) / 1000)).padStart(2, "0") }}
        .{{ String(Math.floor((currentMs % 1000) / 100)) }}
      </div>
      <button :disabled="sending" @click="resetTimer">Reset</button>
    </div>

    <!-- Start/Pause toggle -->
    <div style="margin: 12px 0">
      <button
        :disabled="sending"
        @click="running ? pause() : start()"
        :style="{
          width: '100%',
          fontSize: '24px',
          fontWeight: 700,
          padding: '24px',
          background: running ? '#dc2626' : '#16a34a',
          color: 'white',
          border: 'none',
          borderRadius: '12px',
          cursor: 'pointer',
        }"
      >
        {{ running ? "PAUSE" : "START" }}
      </button>
    </div>

    <!-- Competitors -->
    <div
      v-if="match"
      style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 8px"
    >
      <!-- Red -->
      <div
        style="
          padding: 12px;
          border: 2px solid #dc2626;
          border-radius: 8px;
          background: #fef2f2;
        "
      >
        <div style="font-weight: 700; margin-bottom: 8px; color: #dc2626">
          RED · {{ match.score.red }}
        </div>
        <div style="display: flex; gap: 8px; flex-wrap: wrap">
          <button :disabled="sending" @click="sendPoint('red', 'men')">Men</button>
          <button :disabled="sending" @click="sendPoint('red', 'kote')">Kote</button>
          <button :disabled="sending" @click="sendPoint('red', 'do')">Do</button>
          <button :disabled="sending" @click="sendPoint('red', 'tsuki')">Tsuki</button>
        </div>
      </div>

      <!-- White -->
      <div
        style="
          padding: 12px;
          border: 2px solid #525252;
          border-radius: 8px;
          background: #fafafa;
        "
      >
        <div style="font-weight: 700; margin-bottom: 8px; color: #171717">
          WHITE · {{ match.score.white }}
        </div>
        <div style="display: flex; gap: 8px; flex-wrap: wrap">
          <button :disabled="sending" @click="sendPoint('white', 'men')">Men</button>
          <button :disabled="sending" @click="sendPoint('white', 'kote')">Kote</button>
          <button :disabled="sending" @click="sendPoint('white', 'do')">Do</button>
          <button :disabled="sending" @click="sendPoint('white', 'tsuki')">Tsuki</button>
        </div>
      </div>
    </div>

    <!-- Collapsible history -->
    <div v-if="match && match.events.length" style="margin-top: 16px">
      <button
        @click="historyExpanded = !historyExpanded"
        style="
          width: 100%;
          padding: 12px;
          font-weight: 600;
          background: #f3f4f6;
          border: 1px solid #d1d5db;
          border-radius: 8px;
          cursor: pointer;
        "
      >
        {{ historyExpanded ? "▼" : "▶" }} History ({{ match.events.length }} events)
      </button>

      <div
        v-if="historyExpanded"
        style="
          margin-top: 8px;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          overflow: hidden;
        "
      >
        <table style="width: 100%; border-collapse: collapse; font-size: 14px">
          <thead>
            <tr style="background: #f9fafb">
              <th style="padding: 8px 12px; text-align: left">Time</th>
              <th style="padding: 8px 12px; text-align: left">Side</th>
              <th style="padding: 8px 12px; text-align: left">Point</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="e in [...match.events].reverse()"
              :key="e.id"
              style="border-top: 1px solid #e5e7eb"
            >
              <td style="padding: 8px 12px">
                {{ String(Math.floor(e.at_second / 60)).padStart(2, "0") }}:{{ String(e.at_second % 60).padStart(2, "0") }}
              </td>
              <td
                style="padding: 8px 12px; font-weight: 600"
                :style="{ color: e.side === 'red' ? '#dc2626' : '#171717' }"
              >
                {{ e.side.toUpperCase() }}
              </td>
              <td style="padding: 8px 12px; text-transform: uppercase">
                {{ e.event_type }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div v-else>Loading match…</div>
  </div>
</template>
