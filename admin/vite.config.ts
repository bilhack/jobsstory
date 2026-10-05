import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    // Fixed port so the bookmarked URL never changes. strictPort makes
    // Vite fail loudly (instead of silently jumping to 5174/5175) when
    // another local project already occupies it.
    port: 5180,
    strictPort: true,
  },
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});