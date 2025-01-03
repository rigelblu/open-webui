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

# =====================================
# Update
update-to-latest:
	git checkout main
	git pull upstream
	$(MAKE) mac-launch-stop
	rm -rf .venv
	make local-install
	$(MAKE) mac-launch-start
	git push origin main

# =====================================
# Local targets
PYTHON_VERSION := 3.11
PYTHON_BREW_FORMULA := python@$(PYTHON_VERSION)
PYTHON := python$(PYTHON_VERSION)
VENV := .venv

local-start: local-install
	$(VENV)/bin/open-webui serve

local-install: $(VENV)

$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/pip install open-webui

# =====================================
# MacOS target
LAUNCH_AGENT := ~/Library/LaunchAgents/com.$(USER).open-webui.plist
PYTHON_BREW_FORMULA := python@$(PYTHON_VERSION)

mac-local-start: mac-deps
	$(MAKE) local-start

mac-launch-start: mac-install
	launchctl load $(LAUNCH_AGENT)

mac-launch-restart: mac-launch-stop
	$(MAKE) mac-launch-start

mac-launch-stop:
	launchctl unload $(LAUNCH_AGENT)

mac-clean:
	rm -rf $(VENV)

mac-install: mac-deps local-install
	sed "s/\$$USER/$(USER)/g" com.user.open-webui.plist > $(LAUNCH_AGENT)
	chmod 644 $(LAUNCH_AGENT)
	@echo
	@echo ">> Add to /etc/hosts"
	@echo "127.0.0.1   openllm.local"
	@echo

mac-deps:
	@brew list $(PYTHON_BREW_FORMULA) >/dev/null 2>&1 || brew install $(PYTHON_BREW_FORMULA)

# =====================================
# Phony targets
.PHONY: docker-install docker-remove docker-start docker-build docker-stop docker-update \
        local-install local-start macos-launchtl
