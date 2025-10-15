#!/usr/bin/env pwsh

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   MERN Blog DevOps Project Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install Node.js 18+" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found. Please install Docker Desktop" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

Write-Host "[2/4] Installing dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

Write-Host "[3/4] Choose startup method:" -ForegroundColor Yellow
Write-Host "1. Local development (Node.js) - Fastest" -ForegroundColor White
Write-Host "2. Docker development - Isolated" -ForegroundColor White
Write-Host "3. Docker production build - Full stack" -ForegroundColor White
Write-Host "4. AWS deployment (requires AWS CLI setup)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

Write-Host ""
Write-Host "[4/4] Starting application..." -ForegroundColor Yellow

switch ($choice) {
    "1" {
        Write-Host "Starting local development server..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start"
        Write-Host "✓ Application started at http://localhost:3000" -ForegroundColor Green
    }
    "2" {
        Write-Host "Starting Docker development..." -ForegroundColor Green
        docker-compose -f docker-compose.simple.yml up --build
    }
    "3" {
        Write-Host "Starting full Docker stack..." -ForegroundColor Green
        docker-compose up --build
    }
    "4" {
        Write-Host "Starting AWS deployment..." -ForegroundColor Green
        Write-Host "This will deploy to AWS EKS (requires AWS credentials)" -ForegroundColor Yellow
        Write-Host "Please ensure you have:" -ForegroundColor Yellow
        Write-Host "- AWS CLI configured" -ForegroundColor Yellow
        Write-Host "- kubectl installed" -ForegroundColor Yellow
        Write-Host "- Terraform installed" -ForegroundColor Yellow
        Read-Host "Press Enter to continue with AWS deployment"
        
        # Check AWS CLI
        try {
            aws sts get-caller-identity
            Write-Host "✓ AWS CLI configured" -ForegroundColor Green
        } catch {
            Write-Host "✗ AWS CLI not configured. Please run 'aws configure'" -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Write-Host "Deploying infrastructure..." -ForegroundColor Green
        cd terraform
        terraform init
        terraform apply
        Write-Host "✓ Infrastructure deployed" -ForegroundColor Green
        
        Write-Host "Deploying application..." -ForegroundColor Green
        cd ..
        kubectl apply -f k8s/
        Write-Host "✓ Application deployed" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice. Starting local development..." -ForegroundColor Yellow
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start"
        Write-Host "✓ Application started at http://localhost:3000" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Project started successfully!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URLs:" -ForegroundColor White
Write-Host "- Application: http://localhost:3000" -ForegroundColor Green
Write-Host "- Docker logs: docker-compose logs -f" -ForegroundColor Green
Write-Host "- Stop: Ctrl+C or docker-compose down" -ForegroundColor Green
Write-Host ""
Write-Host "Documentation:" -ForegroundColor White
Write-Host "- README.md - Project overview" -ForegroundColor Blue
Write-Host "- docs/ - Detailed guides" -ForegroundColor Blue
Write-Host "- GETTING_STARTED.md - Quick start guide" -ForegroundColor Blue
Write-Host ""

Read-Host "Press Enter to exit"
