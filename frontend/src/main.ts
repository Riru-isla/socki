import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import App from "./App.vue";

import ProjectorView from "./views/ProjectorView.vue";
import MesaView from "./views/MesaView.vue";
import ShiajoProjectorView from "./views/ShiajoProjectorView.vue";
import TournamentsView from "./views/TournamentsView.vue";
import TournamentNewView from "./views/TournamentNewView.vue";
import TournamentDetailView from "./views/TournamentDetailView.vue";
import TournamentSetupWizard from "./views/TournamentSetupWizard.vue";
import SeasonsView from "./views/SeasonsView.vue";
import CategoryTypesView from "./views/CategoryTypesView.vue";

const routes = [
  { path: "/", redirect: "/tournaments" },
  { path: "/tournaments", component: TournamentsView },
  { path: "/tournaments/new", component: TournamentNewView },
  { path: "/tournaments/:id", component: TournamentDetailView, props: true },
  { path: "/tournaments/:id/setup", component: TournamentSetupWizard, props: true },
  { path: "/seasons", component: SeasonsView },
  { path: "/category-types", component: CategoryTypesView },
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
