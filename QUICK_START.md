# 🚀 Быстрый запуск проекта

## Варианты запуска

### 1. Самый простой способ (2 минуты)

**Для Windows:**
```bash
# Двойной клик на файл или в командной строке:
start.bat

# Или PowerShell:
.\start.ps1
```

**Для Linux/Mac:**
```bash
# Сделать скрипт исполняемым
chmod +x start.sh
./start.sh
```

### 2. Ручной запуск

#### Локальная разработка (Node.js)
```bash
# Установить зависимости
npm install

# Запустить приложение
npm start

# Открыть в браузере
open http://localhost:3000
```

#### Docker разработка
```bash
# Запустить в Docker
docker-compose -f docker-compose.simple.yml up --build

# Открыть в браузере
open http://localhost:3000
```

#### Полный Docker стек
```bash
# Запустить все сервисы (React + мониторинг)
docker-compose up --build

# Доступные URL:
# - React App: http://localhost:3000
# - Grafana: http://localhost:3001
# - Prometheus: http://localhost:9090
```

## 🎯 Что вы увидите

После запуска вы получите:

1. **React приложение** - современный блог с компонентами
2. **Мониторинг** - Grafana дашборды (если запустили полный стек)
3. **Логи** - структурированные логи в консоли

## 📊 Мониторинг (опционально)

Если запустили полный стек, доступны:

- **Grafana**: http://localhost:3001 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **OpenSearch**: http://localhost:9200

## 🛠️ Разработка

### Структура проекта
```
src/
├── components/          # React компоненты
│   ├── ArticlesList.js
│   ├── CommentsList.js
│   └── UpvotesSection.js
├── pages/              # Страницы приложения
│   ├── HomePage.js
│   ├── ArticlePage.js
│   └── ArticlesListPage.js
└── App.js             # Главный компонент
```

### Горячая перезагрузка
При изменении файлов в `src/` приложение автоматически перезагрузится.

## 🐛 Troubleshooting

### Проблема: Порт 3000 занят
```bash
# Найти процесс
netstat -ano | findstr :3000

# Остановить процесс (замените PID)
taskkill /PID <PID> /F
```

### Проблема: Docker не запускается
```bash
# Проверить статус Docker
docker --version

# Перезапустить Docker Desktop
```

### Проблема: Зависимости не устанавливаются
```bash
# Очистить кэш npm
npm cache clean --force

# Удалить node_modules и переустановить
rm -rf node_modules package-lock.json
npm install
```

## 📚 Следующие шаги

После успешного запуска:

1. **Изучите код** - посмотрите на структуру компонентов
2. **Добавьте функциональность** - создайте новые компоненты
3. **Настройте мониторинг** - изучите Grafana дашборды
4. **Деплой в AWS** - следуйте инструкциям в `docs/DEPLOYMENT.md`

## 🔗 Полезные ссылки

- **Документация**: `README.md`
- **Архитектура**: `docs/ARCHITECTURE.md`
- **Деплой**: `docs/DEPLOYMENT.md`
- **Безопасность**: `docs/SECURITY.md`
- **Мониторинг**: `docs/MONITORING.md`

---

**Готово! Ваш проект запущен и готов к разработке! 🎉**
