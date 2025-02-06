const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'your_jwt_secret_key'; // Секретный ключ для JWT

// Регистрация пользователя
router.post('/register', async (req, res) => {
    const { username, email, password } = req.body;
  
    if (!email || !password) { // Убрали проверку на username
      return res.status(400).json({ msg: 'Заполните все поля' });
    }
  
    try {
      const db = req.db;
      if (!db) return res.status(500).json({ msg: 'Database not connected' });
  
      // Проверка, существует ли уже пользователь
      const [existingUser] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
      if (existingUser.length > 0) return res.status(400).json({ msg: 'Email уже используется' });
  
      // **Автоматически задаем username, если он не указан**
      const finalUsername = username?.trim() ? username : email.split('@')[0];
  
      // Хешируем пароль
      const hashedPassword = await bcrypt.hash(password, 10);
      
      // Добавляем пользователя в базу данных
      const [result] = await db.execute(
        'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
        [finalUsername, email, hashedPassword]
      );
  
      // Создаем токен
      const token = jwt.sign({ id: result.insertId }, JWT_SECRET, { expiresIn: '1h' });
      res.json({ token, user: { id: result.insertId, username: finalUsername, email } });
  
    } catch (error) {
      console.error(error);
      res.status(500).json({ msg: 'Ошибка сервера' });
    }
  });  

// Вход пользователя
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ msg: 'Заполните все поля' });

  try {
    const db = req.db;
    if (!db) return res.status(500).json({ msg: 'Database not connected' });

    // Ищем пользователя в базе
    const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) return res.status(400).json({ msg: 'Неверный email или пароль' });

    const user = users[0];

    // Проверяем пароль
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ msg: 'Неверный email или пароль' });

    // Генерируем токен
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '1h' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email } });

  } catch (error) {
    console.error(error);
    res.status(500).json({ msg: 'Ошибка сервера' });
  }
});

// Удаление пользователя
router.delete('/delete', async (req, res) => {
    const { email } = req.body;  // Получаем email пользователя, которого нужно удалить
    if (!email) return res.status(400).json({ msg: 'Не указан email пользователя' });

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Удаляем пользователя из базы
        const [result] = await db.execute('DELETE FROM users WHERE email = ?', [email]);

        if (result.affectedRows === 0) {
            return res.status(400).json({ msg: 'Пользователь не найден' });
        }

        res.json({ msg: 'Пользователь успешно удален' });

    } catch (error) {
        console.error(error);
        res.status(500).json({ msg: 'Ошибка сервера' });
    }
});

// Сохранение секретного вопроса и ответа
router.post('/saveSecretQuestion', async (req, res) => {
    const { email, question, answer } = req.body;

    if (!email || !question || !answer) {
        return res.status(400).json({ msg: 'Заполните все поля' });
    }

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Ищем пользователя по email
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(400).json({ msg: 'Пользователь не найден' });
        }

        // Хешируем ответ
        const saltRounds = 10;
        const hashedAnswer = await bcrypt.hash(answer, saltRounds);

        // Обновляем информацию о секретном вопросе и хешированном ответе
        const [result] = await db.execute(
            'UPDATE users SET secret_question = ?, secret_answer = ? WHERE email = ?',
            [question, hashedAnswer, email]
        );

        if (result.affectedRows === 0) {
            return res.status(500).json({ msg: 'Ошибка при обновлении данных' });
        }

        res.json({ msg: 'Секретный вопрос и ответ сохранены' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ msg: 'Ошибка сервера' });
    }
});

router.post('/verifySecretAnswer', async (req, res) => {
    const { email, answer } = req.body;

    if (!email || !answer) {
        return res.status(400).json({ msg: 'Заполните все поля' });
    }

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Получаем хешированный ответ из базы
        const [users] = await db.execute('SELECT secret_answer FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(400).json({ msg: 'Пользователь не найден' });
        }

        const hashedAnswer = users[0].secret_answer;

        // Сравниваем введенный ответ с хешем
        const isMatch = await bcrypt.compare(answer, hashedAnswer);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Неправильный ответ на секретный вопрос' });
        }

        res.json({ msg: 'Ответ верный. Теперь можете сбросить пароль.' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ msg: 'Ошибка сервера' });
    }
});

router.post('/updatePassword', async (req, res) => {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
        return res.status(400).json({ msg: "Некорректные данные" });
    }

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Проверяем, существует ли пользователь
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(404).json({ msg: "Пользователь не найден" });
        }

        // Хэшируем новый пароль
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Обновляем пароль в базе
        const [result] = await db.execute(
            'UPDATE users SET password = ? WHERE email = ?',
            [hashedPassword, email]
        );

        if (result.affectedRows === 0) {
            return res.status(500).json({ msg: 'Ошибка при обновлении пароля' });
        }

        res.json({ msg: "Пароль успешно изменен" });

    } catch (error) {
        console.error("Ошибка смены пароля:", error);
        res.status(500).json({ msg: "Ошибка сервера" });
    }
});

// Сохранение Dota ID пользователя
router.post('/saveDotaId', async (req, res) => {
    const { email, dotaId } = req.body;

    if (!email || !dotaId) {
        return res.status(400).json({ msg: 'Заполните все поля' });
    }

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Ищем пользователя по email
        const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
        if (users.length === 0) {
            return res.status(400).json({ msg: 'Пользователь не найден' });
        }

        // Обновляем Dota ID пользователя
        const [result] = await db.execute(
            'UPDATE users SET dota_id = ? WHERE email = ?',
            [dotaId, email]
        );

        if (result.affectedRows === 0) {
            return res.status(500).json({ msg: 'Ошибка при обновлении Dota ID' });
        }

        res.json({ msg: 'Dota ID успешно сохранен' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ msg: 'Ошибка сервера' });
    }
});

// Получение Dota ID пользователя по email
router.get('/getDotaId', async (req, res) => {
    const { email } = req.query;
    console.log('Получен email:', email); // Логируем полученный email

    if (!email) {
        return res.status(400).json({ msg: 'Не указан email' });
    }

    try {
        const db = req.db;
        if (!db) return res.status(500).json({ msg: 'Database not connected' });

        // Ищем пользователя по email
        const [result] = await db.execute('SELECT dota_id FROM users WHERE email = ?', [email]);
        console.log('Найденные пользователи:', result); // Логируем найденных пользователей

        if (result.length === 0) {
            return res.status(400).json({ msg: 'Пользователь не найден' });
        }

        const dotaId = result[0].dota_id;
        res.json({ dotaId });
    } catch (error) {
        console.error(error);
        res.status(500).json({ msg: 'Ошибка сервера' });
    }
});


module.exports = router;
