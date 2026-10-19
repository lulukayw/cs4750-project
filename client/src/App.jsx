import { useEffect, useState } from 'react';

export default function App() {
  const [entries, setEntries] = useState([]);
  const [guestName, setGuestName] = useState('');
  const [content, setContent] = useState('');
  const [error, setError] = useState('');

  const load = async () => {
    try {
      const res = await fetch('/api/entries');
      if (!res.ok) throw new Error();
      setEntries(await res.json());
      setError('');
    } catch {
      setError('Could not load entries');
    }
  };

  useEffect(() => { load(); }, []);

  const submit = async (e) => {
    e.preventDefault();
    const res = await fetch('/api/entries', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ guestName, content }),
    });
    if (res.ok) {
      setGuestName('');
      setContent('');
      load();
    } else {
      setError('Could not save entry');
    }
  };

  return (
    <div style={{ maxWidth: 600, margin: '2rem auto', padding: '0 1rem' }}>
      <h1>Guestbook</h1>
      {error && <p style={{ color: 'crimson' }}>{error}</p>}
      <form onSubmit={submit}>
        <input
          placeholder="Your name"
          value={guestName}
          onChange={(e) => setGuestName(e.target.value)}
        />
        <input
          placeholder="Message"
          value={content}
          onChange={(e) => setContent(e.target.value)}
        />
        <button type="submit">Sign</button>
      </form>
      <ul>
        {entries.map((en) => (
          <li key={en.entryID}><strong>{en.guestName}</strong>: {en.content}</li>
        ))}
      </ul>
    </div>
  );
}