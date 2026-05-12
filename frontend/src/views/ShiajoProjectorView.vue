<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from "vue";
import { fetchShiajoSummary } from "../lib/api";
import { subscribeShiajo } from "../lib/cable";

const props = defineProps<{ shiajoId: string }>();
const s = ref<any>(null); // summary
const status = ref("Loading…");
let unsubscribe: null | (() => void) = null;

async function load() {
    s.value = await fetchShiajoSummary(props.shiajoId);
    status.value = "Live";
}

onMounted(async () => {
    await load();
    unsubscribe = subscribeShiajo(props.shiajoId, {
        received: () => load(), // on any ping, refresh summary
    });
});
onBeforeUnmount(() => {
    if (unsubscribe) unsubscribe();
});
</script>

<template>
    <div class="screen" v-if="s">
        <header class="title">{{ s.shiajo.name }}</header>

        <section v-if="s.current_match" class="panel current">
            <h2>Match in progress</h2>
            <div class="row">
                <div class="side red">
                    <div class="name">
                        {{ s.current_match.competitors.red?.name || "—" }}
                    </div>
                    <div class="score">{{ s.current_match.score.red }}</div>
                </div>
                <div class="timer">
                    Time: {{ s.current_match.rule_set.max_time }}s
                </div>
                <div class="side white">
                    <div class="name">
                        {{ s.current_match.competitors.white?.name || "—" }}
                    </div>
                    <div class="score">{{ s.current_match.score.white }}</div>
                </div>
            </div>
        </section>

        <section v-else-if="s.just_finished" class="panel winner">
            <h2>Winner</h2>
            <div class="winner-name">
                {{
                    s.just_finished.score.red > s.just_finished.score.white
                        ? s.just_finished.competitors.red?.name
                        : s.just_finished.competitors.white?.name
                }}
            </div>
        </section>

        <section v-else class="panel idle">
            <h2>No match in progress</h2>
        </section>

        <section class="panel next">
            <h3>Next up</h3>
            <ul>
                <li v-for="(m, i) in s.next_matches" :key="m.id">
                    <strong>#{{ i + 1 }}</strong>
                    {{ m.competitors.red?.name || "TBD" }} vs
                    {{ m.competitors.white?.name || "TBD" }}
                    <span class="cat">· {{ m.category.name }}</span>
                </li>
            </ul>
        </section>

        <footer class="meta">{{ status }}</footer>
    </div>
    <div v-else class="screen">Loading…</div>
</template>

<style scoped>
.screen {
    font-family: system-ui, sans-serif;
    color: #111;
    padding: 24px;
}
.title {
    font-size: 48px;
    font-weight: 900;
    letter-spacing: 2px;
    margin-bottom: 16px;
}
.panel {
    background: #fff;
    border-radius: 16px;
    padding: 16px;
    margin-bottom: 16px;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
}
.row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
}
.side {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
    border-radius: 12px;
    color: #fff;
}
.red {
    background: #b51414;
}
.white {
    background: #d9d9d9;
    color: #111;
}
.name {
    font-size: 28px;
    font-weight: 700;
}
.score {
    font-size: 56px;
    font-weight: 900;
}
.timer {
    font-size: 20px;
    font-weight: 600;
    color: #555;
    min-width: 160px;
    text-align: center;
}
.winner-name {
    font-size: 56px;
    font-weight: 900;
    margin-top: 8px;
}
.next ul {
    list-style: none;
    padding: 0;
    margin: 0;
}
.next li {
    padding: 8px 0;
    border-bottom: 1px solid #eee;
}
.cat {
    color: #777;
    margin-left: 6px;
}
.meta {
    margin-top: 8px;
    color: #666;
    font-size: 14px;
}
</style>
