// scripts/serve_web_build.mjs
//
// Minimal static file server for the compiled Flutter web build
// (build/web), used to test the app on a real phone via ngrok without
// needing Flutter's debug-mode VM service connection (which doesn't
// tunnel cleanly through a single ngrok port). Run with:
//   node scripts/serve_web_build.mjs
// then re-run `flutter build web` and restart this script whenever you
// want the phone to see new changes.

import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { join, extname } from 'node:path';

const ROOT = join(import.meta.dirname, '..', 'build', 'web');
const PORT = 5052;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
};

const server = createServer(async (req, res) => {
  try {
    let urlPath = decodeURIComponent(req.url.split('?')[0]);
    let filePath = join(ROOT, urlPath);
    const info = await stat(filePath).catch(() => null);
    if (!info || info.isDirectory()) {
      filePath = join(ROOT, 'index.html');
    }
    const data = await readFile(filePath);
    const ext = extname(filePath);
    // Flutter web's service worker aggressively caches main.dart.js etc. —
    // without this, a phone can keep running a stale build indefinitely
    // even after a hard refresh, since it never re-fetches fresh files.
    res.writeHead(200, {
      'Content-Type': MIME[ext] ?? 'application/octet-stream',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
    });
    res.end(data);
  } catch (e) {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(PORT, () => {
  console.log(`Serving build/web at http://localhost:${PORT}`);
});
