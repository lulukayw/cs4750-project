import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pool from './db.js';

const app = express();
app.use(express.json());

// DB connectivity check: returns the database name and its tables
app.get('/api/health', async (req, res) => {
  try {
    const [[info]] = await pool.query('SELECT DATABASE() AS db, NOW() AS serverTime');
    const [tables] = await pool.query(
      'SELECT table_name AS name FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY table_name'
    );
    res.json({ ok: true, ...info, tables: tables.map((t) => t.name) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ ok: false, error: err.code || err.message });
  }
});

// Serve the built React app
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join(__dirname, '..', 'client', 'dist');
app.use(express.static(dist));
app.use((req, res) => res.sendFile(path.join(dist, 'index.html')));

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Listening on ${port}`));
