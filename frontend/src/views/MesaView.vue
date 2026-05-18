<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import { fetchMatch, postMatchEvent } from "../lib/api";
import { subscribeMatch } from "../lib/cable";

type Side = "red" | "white";
type EventType = "men" | "kote" | "do" | "tsuki";

interface Competitor {
  id: number;
  name: string;
}

interface MatchScore {
  red: number;
  white: number;
}

interface MatchCompetitors {
  red: Competitor | null;
  white: Competitor | null;
}

interface MatchEvent {
  id: number;
  side: Side;
  event_type: string;
  at_second: number;
  created_at: string;
}

interface MatchData {
  id: number;
  competitors: MatchCompetitors;
  score: MatchScore;
  events: MatchEvent[];
}

const props = defineProps<{ matchId: string }>();
const match = ref<MatchData | null>(null);
const status = ref("Loading…");
const running = ref(false);
const startedAt = ref<number | null>(null); // ms timestamp when started
const pausedAccum = ref(0); // ms accumulated while paused/resumed
const nowTick = ref(0); // forces computed update
let timerId: number | null = null;
let unsubscribe: null | (() => void) = null;
const sending = ref(false);
const historyExpanded = ref(false);

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
    nowTick.value; // dependency: forces re-evaluation on every rAF tick
    if (!startedAt.value) return pausedAccum.value;
    return Math.max(0, msNow() - startedAt.value + pausedAccum.value);
}

async function sendPoint(side: Side, event_type: EventType) {
    if (!match.value) return;
    pause();
    sending.value = true;
    status.value = `Sending ${side} · ${event_type} @ ${Math.floor(currentMs() / 1000)}s…`;

    const competitor_id =
        side === "red"
            ? match.value.competitors.red!.id
            : match.value.competitors.white!.id;

    try {
        const res = await postMatchEvent(props.matchId, {
            competitor_id,
            side,
            event_type,
            at_second: Math.floor(currentMs() / 1000),
        });
        if (!res.ok) {
            status.value = `Error: ${res.error || "unknown"}`;
            sending.value = false;
            return;
        }
        status.value = "Sent. Waiting confirmation…";
        // Wait for Cable to update UI; keep buttons disabled until then
    } catch (e: any) {
        status.value = `Network error: ${e?.message || e}`;
        sending.value = false;
    }
}

onMounted(async () => {
    try {
        match.value = await fetchMatch(props.matchId);
        status.value = "Ready";
    } catch (e: any) {
        status.value = `Failed to load match: ${e?.message || e}`;
        return;
    }
    unsubscribe = subscribeMatch(props.matchId, {
        connected: () => (status.value = "Cable connected"),
        received: (payload: MatchData) => {
            if (payload?.id == Number(props.matchId)) {
                match.value = payload;
                sending.value = false;
                status.value = "Confirmed ✅";
            }
        },
        disconnected: () => (status.value = "Cable disconnected"),
    });
});

onBeforeUnmount(() => {
    if (unsubscribe) unsubscribe();
    if (timerId) cancelAnimationFrame(timerId);
});
</script>

<template>
    <div
        style="
            font-family: system-ui, sans-serif;
            padding: 24px;
            max-width: 860px;
        "
    >
        <h1>Mesa · Match {{ matchId }}</h1>
        <p>{{ status }}</p>

        <div
            style="
                display: flex;
                align-items: center;
                gap: 12px;
                margin: 12px 0;
            "
        >
            <div style="font-size: 28px; font-weight: 700">
                {{
                    String(Math.floor(currentMs() / 60000)).padStart(2, "0")
                }}:
                {{
                    String(Math.floor((currentMs() % 60000) / 1000)).padStart(
                        2,
                        "0",
                    )
                }}.{{ String(Math.floor((currentMs() % 1000) / 100)) }}
            </div>
            <button :disabled="sending" @click="resetTimer">Reset</button>
        </div>

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

        <div
            v-if="match"
            style="
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 16px;
                margin-top: 8px;
            "
        >
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
                    <button
                        :disabled="sending"
                        @click="sendPoint('red', 'men')"
                    >
                        Men
                    </button>
                    <button
                        :disabled="sending"
                        @click="sendPoint('red', 'kote')"
                    >
                        Kote
                    </button>
                    <button :disabled="sending" @click="sendPoint('red', 'do')">
                        Do
                    </button>
                    <button
                        :disabled="sending"
                        @click="sendPoint('red', 'tsuki')"
                    >
                        Tsuki
                    </button>
                </div>
            </div>

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
                    <button
                        :disabled="sending"
                        @click="sendPoint('white', 'men')"
                    >
                        Men
                    </button>
                    <button
                        :disabled="sending"
                        @click="sendPoint('white', 'kote')"
                    >
                        Kote
                    </button>
                    <button
                        :disabled="sending"
                        @click="sendPoint('white', 'do')"
                    >
                        Do
                    </button>
                    <button
                        :disabled="sending"
                        @click="sendPoint('white', 'tsuki')"
                    >
                        Tsuki
                    </button>
                </div>
            </div>
        </div>

        </div>

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
