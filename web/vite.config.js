import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// The site is published from the repository albeasystems/renting, so the base path is /renting/.
export default defineConfig({
  base: process.env.BASE_PATH || '/renting/',
  plugins: [react(), tailwindcss()],
  build: { rollupOptions: { input: 'index.html' } },
});
