# 🍎 Инструкция запуска MERN Blog DevOps проекта на MacBook

## 📋 Предварительные требования

### 1. Установите необходимые инструменты

```bash
# Установка Homebrew (если не установлен)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Установка Node.js
brew install node

# Установка Docker Desktop
brew install --cask docker

# Установка Git (если не установлен)
brew install git

# Установка AWS CLI (опционально)
brew install awscli

# Установка Terraform (опционально)
brew install terraform

# Установка kubectl (опционально)
brew install kubectl

# Установка Helm (опционально)
brew install helm
```

### 2. Проверьте установку

```bash
node --version    # Должно быть v18.x или выше
npm --version     # Должно быть v9.x или выше
docker --version  # Docker version 20.10+
git --version     # Git version 2.x+
```

## 🚀 Быстрый запуск (5 минут)

### 1. Клонирование и настройка проекта

```bash
# Клонируйте репозиторий
git clone https://github.com/sawqqer/mern-blog-devops.git
cd mern-blog-devops

# Установите зависимости
npm install

# Настройте Git (если нужно)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 2. Запуск локального окружения

```bash
# Запустите React приложение
npm start

# В новом терминале запустите backend API
cd backend
npm install
node server.js

# В третьем терминале запустите мониторинг
docker run -d --name grafana -p 3001:3000 grafana/grafana:latest
docker run -d --name prometheus -p 9090:9090 prom/prometheus:latest
```

### 3. Проверьте работу сервисов

- **React приложение**: http://localhost:3000
- **Backend API**: http://localhost:8000/health
- **Grafana**: http://localhost:3001 (admin/admin123)
- **Prometheus**: http://localhost:9090

## 🔧 Подробная настройка

### 1. Настройка Docker Desktop

```bash
# Запустите Docker Desktop
open /Applications/Docker.app

# Дождитесь запуска (иконка Docker в строке меню станет зеленой)
# Проверьте работу
docker ps
```

### 2. Запуск полного стека с мониторингом

```bash
# Запустите все сервисы через Docker Compose
docker-compose -f docker-compose.simple.yml up -d

# Или запустите только мониторинг
docker run -d --name grafana -p 3001:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
  grafana/grafana:latest

docker run -d --name prometheus -p 9090:9090 \
  prom/prometheus:latest
```

### 3. Настройка GitHub Actions

#### Вариант A: Если есть доступ к GitHub Actions

```bash
# Убедитесь, что репозиторий подключен к GitHub
git remote -v

# Сделайте коммит для запуска CI/CD
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

#### Вариант B: Если GitHub Actions заблокированы

```bash
# Используйте минимальный пайплайн
# Уже создан файл .github/workflows/minimal-ci.yml

# Запустите тесты локально
npm test -- --watchAll=false

# Запустите сборку
npm run build
```

## 📊 Мониторинг и логи

### 1. Проверка статуса сервисов

```bash
# Проверьте запущенные Docker контейнеры
docker ps

# Проверьте логи
docker logs grafana
docker logs prometheus

# Проверьте порты
lsof -i :3000  # React
lsof -i :8000  # Backend
lsof -i :3001  # Grafana
lsof -i :9090  # Prometheus
```

### 2. Настройка Grafana

1. Откройте http://localhost:3001
2. Войдите: admin/admin123
3. Добавьте источник данных Prometheus: http://prometheus:9090
4. Импортируйте дашборды из папки `monitoring/grafana-dashboards/`

## 🏗️ Инфраструктура как код (Terraform)

### 1. Настройка AWS (опционально)

```bash
# Настройте AWS CLI
aws configure
# Введите: Access Key ID, Secret Access Key, Region (us-west-2), Output format (json)

# Проверьте подключение
aws sts get-caller-identity
```

### 2. Запуск Terraform

```bash
cd terraform

# Инициализация
terraform init

# Просмотр плана
terraform plan

# Применение (осторожно - создаст ресурсы в AWS!)
terraform apply
```

## 🐳 Docker и контейнеризация

### 1. Сборка собственного образа

```bash
# Соберите Docker образ
docker build -t mern-blog:latest .

# Запустите контейнер
docker run -p 3000:80 mern-blog:latest

# Проверьте образ
docker images
```

### 2. Docker Compose

```bash
# Запуск всех сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

## ☸️ Kubernetes (опционально)

### 1. Настройка kubectl

```bash
# Если используете AWS EKS
aws eks update-kubeconfig --region us-west-2 --name mern-blog-eks

# Проверьте подключение
kubectl get nodes
```

### 2. Деплой в Kubernetes

```bash
# Примените манифесты
kubectl apply -f k8s/

# Проверьте статус
kubectl get pods -n mern-blog
kubectl get services -n mern-blog
```

## 🧪 Тестирование

### 1. Локальные тесты

```bash
# Запуск всех тестов
npm test

# Запуск тестов без watch mode
npm test -- --watchAll=false

# Запуск с покрытием
npm test -- --coverage
```

### 2. Тестирование API

```bash
# Проверка health endpoint
curl http://localhost:8000/health

# Тестирование API статей
curl http://localhost:8000/api/articles/learn-react

# Тестирование upvote
curl -X POST http://localhost:8000/api/articles/learn-react/upvote
```

## 🔍 Troubleshooting

### Проблема: Порт занят

```bash
# Найти процесс на порту
lsof -i :3000

# Остановить процесс
kill -9 <PID>

# Или использовать другой порт
PORT=3001 npm start
```

### Проблема: Docker не запускается

```bash
# Перезапустите Docker Desktop
sudo pkill -f Docker
open /Applications/Docker.app

# Проверьте статус
docker info
```

### Проблема: Зависимости не устанавливаются

```bash
# Очистите кэш npm
npm cache clean --force

# Удалите node_modules и переустановите
rm -rf node_modules package-lock.json
npm install
```

### Проблема: Git ошибки

```bash
# Настройте SSH ключи для GitHub
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub
# Добавьте ключ в GitHub Settings → SSH and GPG keys
```

## 📚 Полезные команды

### Управление сервисами

```bash
# Запуск всех сервисов
./start.sh  # Если есть скрипт

# Или вручную:
npm start &                    # React в фоне
cd backend && node server.js & # Backend в фоне
docker run -d --name grafana -p 3001:3000 grafana/grafana:latest
docker run -d --name prometheus -p 9090:9090 prom/prometheus:latest
```

### Мониторинг ресурсов

```bash
# Использование CPU и памяти
top
htop  # если установлен: brew install htop

# Использование диска
df -h

# Сетевые соединения
netstat -an | grep LISTEN
```

### Очистка системы

```bash
# Очистка Docker
docker system prune -a

# Очистка npm кэша
npm cache clean --force

# Очистка неиспользуемых пакетов Homebrew
brew cleanup
```

## 🎯 Следующие шаги

1. **Изучите код** - посмотрите структуру компонентов в `src/`
2. **Настройте мониторинг** - создайте дашборды в Grafana
3. **Изучите Kubernetes** - попробуйте деплой манифестов
4. **Настройте AWS** - запустите Terraform для создания инфраструктуры
5. **Изучите CI/CD** - настройте GitHub Actions или альтернативы

## 📞 Поддержка

- **Документация**: `README.md`, `GETTING_STARTED.md`
- **Архитектура**: `docs/ARCHITECTURE.md`
- **Мониторинг**: `docs/MONITORING.md`
- **Безопасность**: `docs/SECURITY.md`

---

**Готово! Ваш MERN Blog DevOps проект запущен на MacBook! 🚀**
