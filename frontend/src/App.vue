<script setup lang="ts">
import { useRoute, useRouter } from "vue-router";

const route = useRoute();
const router = useRouter();

function isActive(path: string) {
  return route.path.startsWith(path);
}
</script>

<template>
  <div>
    <nav style="display: flex; gap: 4px; padding: 8px 16px; background: #171717; font-family: system-ui, sans-serif; font-size: 13px">
      <a
        href="#/tournaments"
        @click.prevent="router.push('/tournaments')"
        :style="{
          padding: '6px 12px',
          borderRadius: '6px',
          textDecoration: 'none',
          fontWeight: 600,
          color: isActive('/tournaments') ? '#fff' : '#9ca3af',
          background: isActive('/tournaments') ? '#374151' : 'transparent',
          cursor: 'pointer',
        }"
      >Championships</a>
      <a
        href="#/seasons"
        @click.prevent="router.push('/seasons')"
        :style="{
          padding: '6px 12px',
          borderRadius: '6px',
          textDecoration: 'none',
          fontWeight: 600,
          color: isActive('/seasons') ? '#fff' : '#9ca3af',
          background: isActive('/seasons') ? '#374151' : 'transparent',
          cursor: 'pointer',
        }"
      >Seasons</a>
      <a
        href="#/category-types"
        @click.prevent="router.push('/category-types')"
        :style="{
          padding: '6px 12px',
          borderRadius: '6px',
          textDecoration: 'none',
          fontWeight: 600,
          color: isActive('/category-types') ? '#fff' : '#9ca3af',
          background: isActive('/category-types') ? '#374151' : 'transparent',
          cursor: 'pointer',
        }"
      >Category Types</a>
      <a
        href="#/projector/1"
        @click.prevent="router.push('/projector/1')"
        :style="{
          padding: '6px 12px',
          borderRadius: '6px',
          textDecoration: 'none',
          fontWeight: 600,
          color: isActive('/projector') ? '#fff' : '#9ca3af',
          background: isActive('/projector') ? '#374151' : 'transparent',
          cursor: 'pointer',
        }"
      >Projector</a>
      <a
        href="#/mesa/1"
        @click.prevent="router.push('/mesa/1')"
        :style="{
          padding: '6px 12px',
          borderRadius: '6px',
          textDecoration: 'none',
          fontWeight: 600,
          color: isActive('/mesa') ? '#fff' : '#9ca3af',
          background: isActive('/mesa') ? '#374151' : 'transparent',
          cursor: 'pointer',
        }"
      >Mesa</a>
    </nav>
    <router-view />
  </div>
</template>
