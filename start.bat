@echo off
echo ========================================
echo   MERN Blog DevOps Project Startup
echo ========================================
echo.

echo [1/3] Checking prerequisites...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Please install Node.js 18+
    pause
    exit /b 1
)

where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Docker not found. Please install Docker Desktop
    pause
    exit /b 1
)

echo ✓ Prerequisites OK
echo.

echo [2/3] Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo ✓ Dependencies installed
echo.

echo [3/3] Starting application...
echo.
echo Choose startup method:
echo 1. Local development (Node.js) - Fastest
echo 2. Docker development - Isolated
echo 3. Docker production build - Full stack
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo Starting local development server...
    start cmd /k "npm start"
    echo ✓ Application started at http://localhost:3000
) else if "%choice%"=="2" (
    echo Starting Docker development...
    docker-compose -f docker-compose.simple.yml up --build
) else if "%choice%"=="3" (
    echo Starting full Docker stack...
    docker-compose up --build
) else (
    echo Invalid choice. Starting local development...
    start cmd /k "npm start"
    echo ✓ Application started at http://localhost:3000
)

echo.
echo ========================================
echo   Project started successfully!
echo ========================================
echo.
echo URLs:
echo - Application: http://localhost:3000
echo - Docker logs: docker-compose logs -f
echo - Stop: Ctrl+C or docker-compose down
echo.
pause
