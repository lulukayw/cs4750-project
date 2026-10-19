-- Example table used by the starter /api/entries endpoints.
-- Run against the `todo-app` database (Cloud SQL Studio, or the mysql CLI through the proxy).
-- Replace with the real project schema as it's designed.
CREATE TABLE IF NOT EXISTS entries (
  entryID   INT AUTO_INCREMENT PRIMARY KEY,
  guestName VARCHAR(255) NOT NULL,
  content   VARCHAR(255) NOT NULL
);
