import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import App from "./App.vue";

import ProjectorView from "./views/ProjectorView.vue";
import MesaView from "./views/MesaView.vue";
import ShiajoProjectorView from "./views/ShiajoProjectorView.vue";

const routes = [
  { path: "/", redirect: "/projector/2" }, // temp shortcut
  { path: "/projector/:matchId", component: ProjectorView, props: true },
  { path: "/mesa/:matchId", component: MesaView, props: true },
  {
    path: "/projector/shiajo/:shiajoId",
    component: ShiajoProjectorView,
    props: true,
  },
];
const router = createRouter({ history: createWebHistory(), routes });

createApp(App).use(router).mount("#app");
