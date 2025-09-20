# Makefile для проекта health-api
# Использование: make up / make down / make reup / make status

PROJECT_NAME := health-api
COMPOSE_FILES := \
	-f docker-compose.app.yml \
	-f docker-compose.db.yml \
	-f docker-compose.kafka.yml \
	-f docker-compose.swagger.yml \
	-f docker-compose.observability.yml

DC := docker compose $(COMPOSE_FILES) -p $(PROJECT_NAME)

# Поднять проект
up:
	$(DC) up -d
	@make status

# Остановить и удалить все контейнеры, сети, тома
down:
	$(DC) down --remove-orphans -v -t 0
	@make status

# Перезапуск-жёсткий (сносит абсолютно всё, старт с чистого листа)
reup: down up

# Показать статус всех сервисов
status:
	@$(DC) ps -a

# Вывести логи всех сервисов
logs:
	$(DC) logs --no-color
