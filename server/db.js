const mysql = require('mysql2/promise');

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 5,
};

if (process.env.DB_SOCKET) {
  // App Engine -> Cloud SQL (same idea as the PDO unix_socket DSN)
  config.socketPath = process.env.DB_SOCKET;
} else {
  // Local dev
  config.host = process.env.DB_HOST || '127.0.0.1';
  config.port = Number(process.env.DB_PORT || 3306);
}

module.exports = mysql.createPool(config);