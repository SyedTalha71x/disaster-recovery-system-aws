import express from 'express';
import mysql from 'mysql2';
import bodyParser from 'body-parser';
import { configDotenv } from 'dotenv';

configDotenv();


const app = express();
app.use(bodyParser.json());


const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_NAME = process.env.DB_NAME || 'disaster-recovery-db';
const DB_USER = process.env.DB_USER || 'root';
const DB_PASS = process.env.DB_PASS || 'Root@1234';

const db = mysql.createConnection({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASS,
  database: DB_NAME
});

db.connect((err) => {
  if (err) {
    console.error('Database connection failed:', err);
    process.exit(1);
  }
  console.log('Connected to MySQL database');
});

app.get('/health', (req, res) => {
  db.query('SELECT 1 as health', (err) => {
    if (err) {
      return res.status(503).json({
        status: 'unhealthy',
        error: err.message,
        timestamp: new Date().toISOString()
      });
    }

    res.status(200).json({
      status: 'healthy',
      region: process.env.REGION || 'unknown',
      database: 'connected',
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    });
  });
});

app.get('/users', (req, res) => {
  db.query(
    'SELECT * FROM users ORDER BY created_at DESC',
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.json({
        region: process.env.REGION || 'unknown',
        count: results.length,
        data: results
      });
    }
  );
});

app.post('/users', (req, res) => {
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'Name and email required' });
  }

  // Check if read-only mode
  if (process.env.READ_ONLY === 'true') {
    return res.status(503).json({
      error: 'Read-only mode',
      message: 'This is a DR replica. Write to primary region.',
      region: process.env.REGION || 'unknown'
    });
  }

  db.query(
    'INSERT INTO users (name, email) VALUES (?, ?)',
    [name, email],
    (err, result) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }

      res.status(201).json({
        message: 'User created',
        id: result.insertId,
        region: process.env.REGION || 'unknown'
      });
    }
  );
});

app.get('/', (req, res) => {
  const region = process.env.REGION || 'unknown';
  const role = process.env.READ_ONLY === 'true' ? 'Secondary/DR' : 'Primary';

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>DR App - ${region}</title>
      <style>
        body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #2c3e50; }
        .status {
          padding: 15px;
          background: ${role === 'Primary' ? '#2ecc71' : '#f39c12'};
          color: white;
          border-radius: 5px;
          margin: 20px 0;
        }
        a {
          display: inline-block;
          margin: 10px 10px 10px 0;
          padding: 10px 20px;
          background: #3498db;
          color: white;
          text-decoration: none;
          border-radius: 5px;
        }
      </style>
    </head>
    <body>
      <h1>Disaster Recovery Application</h1>
      <div class="status">
        <strong>Region:</strong> ${region}<br>
        <strong>Role:</strong> ${role}
      </div>
      <a href="/health">Health</a>
      <a href="/users">Users</a>
    </body>
    </html>
  `);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(
    `Server running on port ${PORT} - Region: ${process.env.REGION || 'unknown'}`
  );
});
