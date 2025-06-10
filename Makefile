.PHONY: help setup setup-dev clean test test-cov lint fmt type-check security dev worker flower scheduler migrate migrate-auto seed docker-build docker-up docker-down task

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and Installation
setup: ## Install production dependencies using uv
	@echo "🔧 Installing production dependencies with uv..."
	uv pip install -e .

setup-dev: ## Install all dependencies including development tools
	@echo "🔧 Installing all dependencies with uv..."
	uv pip install -e ".[dev,lint,security,worker]"

clean: ## Clean up cache and temporary files
	@echo "🧹 Cleaning up..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .coverage htmlcov/ .pytest_cache/ .mypy_cache/ .ruff_cache/
	rm -rf celerybeat-schedule

# Development
dev: ## Start Flask development server
	@echo "🚀 Starting Flask development server..."
	flask --app app.main:create_app run --host 0.0.0.0 --port 5000 --debug

dev-prod: ## Start production server with Gunicorn
	@echo "🏭 Starting production server..."
	gunicorn --bind 0.0.0.0:5000 --workers 4 "app.main:create_app()"

# Celery Workers
worker: ## Start Celery worker
	@echo "👷 Starting Celery worker..."
	celery -A app.core.celery worker --loglevel=info

worker-dev: ## Start Celery worker in development mode
	@echo "👷 Starting Celery worker (development)..."
	celery -A app.core.celery worker --loglevel=debug --reload

flower: ## Start Flower monitoring UI
	@echo "🌸 Starting Flower monitoring UI..."
	celery -A app.core.celery flower --port=5555

scheduler: ## Start Celery Beat scheduler
	@echo "⏰ Starting Celery Beat scheduler..."
	celery -A app.core.celery beat --loglevel=info

# Testing
test: ## Run tests
	@echo "🧪 Running tests..."
	pytest

test-cov: ## Run tests with coverage
	@echo "🧪 Running tests with coverage..."
	pytest --cov=app --cov-report=html --cov-report=term-missing

test-fast: ## Run tests excluding slow tests
	@echo "⚡ Running fast tests..."
	pytest -m "not slow"

test-celery: ## Run only Celery tests
	@echo "🔄 Running Celery tests..."
	pytest -m celery

test-unit: ## Run only unit tests
	@echo "🎯 Running unit tests..."
	pytest -m unit

test-integration: ## Run only integration tests
	@echo "🔧 Running integration tests..."
	pytest -m integration

# Code Quality
lint: ## Run all linting tools
	@echo "🔍 Running linting tools..."
	ruff check .
	black --check .
	mypy .

fmt: ## Format code
	@echo "🎨 Formatting code..."
	black .
	ruff check . --fix

type-check: ## Run type checking
	@echo "🔍 Running type check..."
	mypy .

security: ## Run security checks
	@echo "🔒 Running security checks..."
	safety check
	bandit -r app/ -f json

# Database
migrate: ## Run database migrations
	@echo "📊 Running database migrations..."
	flask --app app.main:create_app db upgrade

migrate-auto: ## Generate automatic migration
	@echo "📊 Generating automatic migration..."
	@read -p "Enter migration message: " message; \
	flask --app app.main:create_app db migrate -m "$$message"

migrate-create: ## Create empty migration
	@echo "📊 Creating empty migration..."
	@read -p "Enter migration message: " message; \
	flask --app app.main:create_app db revision -m "$$message"

migrate-history: ## Show migration history
	@echo "📊 Migration history..."
	flask --app app.main:create_app db history

migrate-current: ## Show current migration
	@echo "📊 Current migration..."
	flask --app app.main:create_app db current

migrate-rollback: ## Rollback one migration
	@echo "📊 Rolling back one migration..."
	flask --app app.main:create_app db downgrade

seed: ## Seed database with initial data
	@echo "🌱 Seeding database..."
	python -m scripts.seed_data

# Task Management
task: ## Execute a specific Celery task
	@echo "🔄 Executing task: $(name)"
	@if [ -z "$(name)" ]; then \
		echo "Usage: make task name=task_name [args='arg1 arg2']"; \
		exit 1; \
	fi
	python -c "from app.worker.tasks.$(name) import $(name); print($(name).delay($(args)).id)"

task-status: ## Check task status
	@echo "📊 Checking task status: $(task_id)"
	@if [ -z "$(task_id)" ]; then \
		echo "Usage: make task-status task_id=your_task_id"; \
		exit 1; \
	fi
	python -c "from app.core.celery import celery_app; print(celery_app.AsyncResult('$(task_id)').status)"

# Docker
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t flask-ddd-template .

docker-up: ## Start services with docker-compose
	@echo "🐳 Starting services..."
	docker-compose up -d

docker-down: ## Stop services with docker-compose
	@echo "🐳 Stopping services..."
	docker-compose down

docker-logs: ## Show docker-compose logs
	@echo "📋 Showing logs..."
	docker-compose logs -f

docker-shell: ## Get shell in running container
	@echo "🐚 Opening shell in container..."
	docker-compose exec app bash

# Development services
dev-db: ## Start only database and Redis services
	@echo "🗄️ Starting database and Redis..."
	docker-compose up -d postgres redis

dev-stop: ## Stop development services
	@echo "🛑 Stopping development services..."
	docker-compose down

# Production
build: ## Build production assets
	@echo "🏗️ Building production assets..."
	docker build -t flask-ddd-template:latest .

deploy: ## Deploy to production (placeholder)
	@echo "🚀 Deploying to production..."
	@echo "Implement your deployment logic here"

# Utilities
install-uv: ## Install uv package manager
	@echo "📦 Installing uv..."
	curl -LsSf https://astral.sh/uv/install.sh | sh

check-env: ## Check if required environment variables are set
	@echo "🔍 Checking environment variables..."
	@python -c "from app.core.config import Config; print('✅ Environment configuration is valid')"

generate-secret: ## Generate a new secret key
	@echo "🔑 Generating secret key..."
	@python -c "import secrets; print(f'SECRET_KEY={secrets.token_urlsafe(32)}')"

# Flask CLI helpers
shell: ## Open Flask shell
	@echo "🐚 Opening Flask shell..."
	flask --app app.main:create_app shell

routes: ## Show all Flask routes
	@echo "🗺️ Showing all routes..."
	flask --app app.main:create_app routes

# CI/CD helpers
ci-setup: ## Setup for CI environment
	pip install uv
	make setup-dev

ci-test: ## Run tests in CI environment
	make lint
	make security
	make test-cov

# Local development helpers
dev-all: ## Start all development services
	@echo "🚀 Starting all development services..."
	make dev-db
	sleep 5
	make migrate
	@echo "Run 'make dev' in one terminal and 'make worker' in another"

reset-db: ## Reset database (WARNING: destructive)
	@echo "⚠️ Resetting database..."
	@read -p "Are you sure? This will delete all data. (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose down -v; \
		docker-compose up -d postgres redis; \
		sleep 5; \
		make migrate; \
		make seed; \
	else \
		echo "Cancelled."; \
	fi

# Monitoring
monitor: ## Show system status (processes, logs)
	@echo "📊 System Status:"
	@echo "=== Flask Process ==="
	@pgrep -f "flask.*run" || echo "Flask not running"
	@echo "=== Celery Worker ==="
	@pgrep -f "celery.*worker" || echo "Celery worker not running"
	@echo "=== Celery Beat ==="
	@pgrep -f "celery.*beat" || echo "Celery beat not running"
	@echo "=== Redis Status ==="
	@redis-cli ping || echo "Redis not accessible"