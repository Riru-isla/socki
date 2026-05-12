import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      // Rails JSON API
      "/api": { target: "http://localhost:3000", changeOrigin: true },
      // ActionCable WebSocket
      "/cable": { target: "ws://localhost:3000", ws: true, changeOrigin: true },
    },
    host: '0.0.0.0',   // <-- allow external devices
    port: 5173,
    strictPort: true   // optional: fail if 5173 taken
  },
});
