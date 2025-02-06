const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db'); // Подключение к базе
const authRoutes = require('./routes/auth'); // Маршруты аутентификации

const app = express();
app.use(cors());
app.use(express.json());

let dbConnection;

// Подключение к базе данных
connectDB()
  .then(connection => {
    dbConnection = connection;
    console.log('✅ Database connected');

    // Передача подключения в каждый запрос
    app.use((req, res, next) => {
      if (!dbConnection) return res.status(500).json({ msg: 'Database not connected' });
      req.db = dbConnection;
      next();
    });

    // Используем маршруты
    app.use('/api/auth', authRoutes);

    app.listen(5001, () => console.log('🚀 Server started on port 5001'));
  })
  .catch(err => console.error('❌ Database connection failed:', err));

app.get('/', (req, res) => {
  res.send('Auth Server is running with MySQL');
});
