#!/bin/bash

# 🍎 MERN Blog DevOps - macOS Startup Script
# Автоматический запуск всех сервисов на MacBook

set -e  # Остановить при ошибке

echo "🚀 Запуск MERN Blog DevOps проекта на macOS..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода цветного текста
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка предварительных требований
check_requirements() {
    print_status "Проверка предварительных требований..."
    
    # Проверка Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js не установлен. Установите: brew install node"
        exit 1
    fi
    
    # Проверка npm
    if ! command -v npm &> /dev/null; then
        print_error "npm не установлен. Установите: brew install node"
        exit 1
    fi
    
    # Проверка Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен. Установите: brew install --cask docker"
        exit 1
    fi
    
    # Проверка запуска Docker
    if ! docker info &> /dev/null; then
        print_error "Docker не запущен. Запустите Docker Desktop"
        exit 1
    fi
    
    print_success "Все предварительные требования выполнены"
}

# Установка зависимостей
install_dependencies() {
    print_status "Установка зависимостей..."
    
    # Установка основных зависимостей
    if [ ! -d "node_modules" ]; then
        print_status "Установка npm зависимостей..."
        npm install
    else
        print_status "npm зависимости уже установлены"
    fi
    
    # Установка backend зависимостей
    if [ -d "backend" ] && [ ! -d "backend/node_modules" ]; then
        print_status "Установка backend зависимостей..."
        cd backend
        npm install
        cd ..
    fi
    
    print_success "Зависимости установлены"
}

# Остановка существующих сервисов
stop_existing_services() {
    print_status "Остановка существующих сервисов..."
    
    # Остановка Node.js процессов
    pkill -f "npm start" || true
    pkill -f "node.*server.js" || true
    
    # Остановка Docker контейнеров
    docker stop grafana prometheus 2>/dev/null || true
    docker rm grafana prometheus 2>/dev/null || true
    
    print_success "Существующие сервисы остановлены"
}

# Запуск мониторинга
start_monitoring() {
    print_status "Запуск сервисов мониторинга..."
    
    # Запуск Grafana
    docker run -d \
        --name grafana \
        -p 3001:3000 \
        -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
        grafana/grafana:latest
    
    # Запуск Prometheus
    docker run -d \
        --name prometheus \
        -p 9090:9090 \
        prom/prometheus:latest
    
    # Ждем запуска
    sleep 5
    
    print_success "Мониторинг запущен"
}

# Запуск backend API
start_backend() {
    print_status "Запуск backend API..."
    
    if [ -f "backend/server.js" ]; then
        cd backend
        nohup node server.js > ../backend.log 2>&1 &
        cd ..
        print_success "Backend API запущен на http://localhost:8000"
    else
        print_warning "Backend server.js не найден, пропускаем"
    fi
}

# Запуск React приложения
start_frontend() {
    print_status "Запуск React приложения..."
    
    nohup npm start > frontend.log 2>&1 &
    
    # Ждем запуска
    sleep 10
    
    print_success "React приложение запущено на http://localhost:3000"
}

# Проверка статуса сервисов
check_services() {
    print_status "Проверка статуса сервисов..."
    
    # Проверка портов
    local services=("3000:React" "8000:Backend" "3001:Grafana" "9090:Prometheus")
    
    for service in "${services[@]}"; do
        port=$(echo $service | cut -d: -f1)
        name=$(echo $service | cut -d: -f2)
        
        if lsof -i :$port > /dev/null 2>&1; then
            print_success "$name работает на порту $port"
        else
            print_warning "$name не отвечает на порту $port"
        fi
    done
}

# Вывод информации о доступе
show_access_info() {
    echo ""
    echo "🎉 Все сервисы запущены!"
    echo ""
    echo "📱 Доступные сервисы:"
    echo "   • React приложение: http://localhost:3000"
    echo "   • Backend API:      http://localhost:8000"
    echo "   • Grafana:          http://localhost:3001 (admin/admin123)"
    echo "   • Prometheus:       http://localhost:9090"
    echo ""
    echo "📊 Полезные команды:"
    echo "   • Просмотр логов:   tail -f frontend.log backend.log"
    echo "   • Остановка:        ./stop-macos.sh"
    echo "   • Статус Docker:    docker ps"
    echo ""
}

# Основная функция
main() {
    echo "🍎 MERN Blog DevOps - macOS Startup Script"
    echo "=========================================="
    echo ""
    
    check_requirements
    install_dependencies
    stop_existing_services
    start_monitoring
    start_backend
    start_frontend
    check_services
    show_access_info
    
    print_success "Запуск завершен успешно! 🚀"
}

# Обработка сигналов для корректного завершения
trap 'echo ""; print_warning "Получен сигнал завершения. Используйте ./stop-macos.sh для остановки сервисов"; exit 0' INT TERM

# Запуск основной функции
main "$@"
