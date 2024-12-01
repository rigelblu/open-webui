# =====================================
# Docker target
ifneq ($(shell which docker-compose 2>/dev/null),)
    DOCKER_COMPOSE := docker-compose
else
    DOCKER_COMPOSE := docker compose
endif

docker-install:
	$(DOCKER_COMPOSE) up -d

docker-remove:
	@chmod +x confirm_remove.sh
	@./confirm_remove.sh

docker-start:
	$(DOCKER_COMPOSE) start

docker-build:
	$(DOCKER_COMPOSE) up -d --build

docker-stop:
	$(DOCKER_COMPOSE) stop

docker-update:
	chmod +x update_ollama_models.sh
	@./update_ollama_models.sh
	@git pull
	$(DOCKER_COMPOSE) down
	# Make sure the ollama-webui container is stopped before rebuilding
	@docker stop open-webui || true
	$(DOCKER_COMPOSE) up --build -d
	$(DOCKER_COMPOSE) start

