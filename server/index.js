const express = require('express');
const path = require('path');
const pool = require('./db');

const app = express();
app.use(express.json());

// Quick DB connectivity check: open /api/health in a browser
app.get('/api/health', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT DATABASE() AS db, NOW() AS serverTime');
    res.json({ ok: true, ...rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ ok: false, error: err.code || err.message });
  }
});

app.get('/api/entries', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT entryID, guestName, content FROM entries ORDER BY entryID DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to load entries' });
  }
});

app.post('/api/entries', async (req, res) => {
  const { guestName, content } = req.body;
  if (!guestName?.trim() || !content?.trim()) {
    return res.status(400).json({ error: 'Name and content are required' });
  }
  try {
    const [result] = await pool.execute(
      'INSERT INTO entries (guestName, content) VALUES (?, ?)',
      [guestName.trim(), content.trim()]
    );
    res.status(201).json({ entryID: result.insertId, guestName, content });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to save entry' });
  }
});

// Serve the built React app (replaces the PHP front controller)
const dist = path.join(__dirname, '..', 'client', 'dist');
app.use(express.static(dist));
app.use((req, res) => res.sendFile(path.join(dist, 'index.html')));

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Listening on ${port}`));