import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  base: './',
  plugins: [react()],
  publicDir: path.resolve(rootDir, '../art'),
  server: {
    host: '127.0.0.1',
    port: 5175,
    strictPort: true,
    fs: {
      allow: [rootDir, path.resolve(rootDir, '..')]
    }
  },
  preview: {
    host: '127.0.0.1',
    port: 4175,
    strictPort: true
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true
  }
});

