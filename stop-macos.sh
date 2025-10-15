#!/bin/bash

# 🛑 MERN Blog DevOps - macOS Stop Script
# Остановка всех сервисов на MacBook

set -e

echo "🛑 Остановка MERN Blog DevOps проекта..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Остановка Node.js процессов
stop_node_processes() {
    print_status "Остановка Node.js процессов..."
    
    # Остановка npm start
    pkill -f "npm start" || print_warning "npm start не найден"
    
    # Остановка backend server
    pkill -f "node.*server.js" || print_warning "backend server не найден"
    
    # Остановка других Node.js процессов проекта
    pkill -f "mern-blog" || true
    
    print_success "Node.js процессы остановлены"
}

# Остановка Docker контейнеров
stop_docker_containers() {
    print_status "Остановка Docker контейнеров..."
    
    # Остановка и удаление контейнеров
    docker stop grafana prometheus 2>/dev/null || print_warning "Docker контейнеры не найдены"
    docker rm grafana prometheus 2>/dev/null || true
    
    print_success "Docker контейнеры остановлены"
}

# Очистка логов
cleanup_logs() {
    print_status "Очистка логов..."
    
    # Удаление файлов логов
    rm -f frontend.log backend.log 2>/dev/null || true
    
    print_success "Логи очищены"
}

# Проверка остановки сервисов
check_stopped_services() {
    print_status "Проверка остановки сервисов..."
    
    local services=("3000:React" "8000:Backend" "3001:Grafana" "9090:Prometheus")
    local all_stopped=true
    
    for service in "${services[@]}"; do
        port=$(echo $service | cut -d: -f1)
        name=$(echo $service | cut -d: -f2)
        
        if lsof -i :$port > /dev/null 2>&1; then
            print_warning "$name все еще работает на порту $port"
            all_stopped=false
        else
            print_success "$name остановлен"
        fi
    done
    
    if [ "$all_stopped" = true ]; then
        print_success "Все сервисы успешно остановлены"
    else
        print_warning "Некоторые сервисы все еще работают"
    fi
}

# Основная функция
main() {
    echo "🛑 MERN Blog DevOps - macOS Stop Script"
    echo "======================================"
    echo ""
    
    stop_node_processes
    stop_docker_containers
    cleanup_logs
    check_stopped_services
    
    echo ""
    print_success "Остановка завершена! 👋"
    echo ""
    echo "💡 Для повторного запуска используйте: ./start-macos.sh"
}

# Запуск основной функции
main "$@"
