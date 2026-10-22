import { useEffect, useState } from 'react';

export default function App() {
  const [status, setStatus] = useState(null);

  useEffect(() => {
    fetch('/api/health')
      .then((res) => res.json())
      .then(setStatus)
      .catch(() => setStatus({ ok: false, error: 'API server is not reachable' }));
  }, []);

  return (
    <div style={{ maxWidth: 600, margin: '2rem auto', padding: '0 1rem', fontFamily: 'system-ui' }}>
      <h1>CS 4750 Project</h1>
      {!status && <p>Connecting to database…</p>}
      {status?.ok === false && (
        <p style={{ color: 'crimson' }}>Database connection failed: {status.error}</p>
      )}
      {status?.ok && (
        <>
          <p style={{ color: 'green' }}>Successfully connected to database <code>{status.db}</code>.</p>
          <h2>Tables ({status.tables.length})</h2>
          {status.tables.length === 0 ? (
            <p>No tables yet. Run <code>sql/schema.sql</code> to create them.</p>
          ) : (
            <ul>
              {status.tables.map((t) => <li key={t}><code>{t}</code></li>)}
            </ul>
          )}
        </>
      )}
    </div>
  );
}
