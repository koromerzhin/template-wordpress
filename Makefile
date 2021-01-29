.DEFAULT_GOAL := help
STACK         := wordpress
NETWORK       := proxynetwork

APACHE         := $(STACK)_apache
APACHEFULLNAME := $(APACHE).1.$$(docker service ps -f 'name=$(APACHE)' $(APACHE) -q --no-trunc | head -n1)

PHPFPM         := $(STACK)_phpfpm
PHPFPMFULLNAME := $(PHPFPM).1.$$(docker service ps -f 'name=$(PHPFPM)' $(PHPFPM) -q --no-trunc | head -n1)

MAILHOG         := $(STACK)_mailhog
MAILHOGFULLNAME := $(MAILHOG).1.$$(docker service ps -f 'name=$(MAILHOG)' $(MAILHOG) -q --no-trunc | head -n1)

MARIADB         := $(STACK)_mariadb
MARIADBFULLNAME := $(MARIADB).1.$$(docker service ps -f 'name=$(MARIADB)' $(MARIADB) -q --no-trunc | head -n1)

PHPMYADMIN         := $(STACK)_phpmyadmin
PHPMYADMINFULLNAME := $(PHPMYADMIN).1.$$(docker service ps -f 'name=$(PHPMYADMIN)' $(PHPMYADMIN) -q --no-trunc | head -n1)

DOCKER_EXECPHP := @docker exec $(PHPFPMFULLNAME)

SUPPORTED_COMMANDS := composer contributors docker logs git linter ssh tests update inspect sleep
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

%:
	@:

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

package-lock.json: package.json
	@npm install

node_modules: package-lock.json
	@npm install

apps/composer.lock: apps/composer.json
	@docker exec $(PHPFPMFULLNAME) make composer.lock
	
apps/vendor: apps/composer.lock
	@docker exec $(PHPFPMFULLNAME) make vendor

sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

composer: ## Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	$(DOCKER_EXECPHP) make composer suggests
else ifeq ($(COMMAND_ARGS),outdated)
	$(DOCKER_EXECPHP) make composer outdated
else ifeq ($(COMMAND_ARGS),fund)
	$(DOCKER_EXECPHP) make composer fund
else ifeq ($(COMMAND_ARGS),prod)
	$(DOCKER_EXECPHP) make composer prod
else ifeq ($(COMMAND_ARGS),dev)
	$(DOCKER_EXECPHP) make composer dev
else ifeq ($(COMMAND_ARGS),update)
	$(DOCKER_EXECPHP) make composer update
else ifeq ($(COMMAND_ARGS),validate)
	$(DOCKER_EXECPHP) make composer validate
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make composer ARGUMENT"
	@echo "---"
	@echo "suggests: suggestions package pour PHP"
	@echo "outdated: Packet php outdated"
	@echo "fund: Discover how to help fund the maintenance of your dependencies."
	@echo "prod: Installation version de prod"
	@echo "dev: Installation version de dev"
	@echo "update: COMPOSER update"
	@echo "validate: COMPOSER validate"
endif

contributors: ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

docker: ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),image-pull)
	@docker image pull httpd
	@docker image pull koromerzhin/phpfpm:7.4.12-xdebug
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "image-pull: Get docker image"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

logs: ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),apache)
	@docker service logs -f --tail 100 --raw $(APACHEFULLNAME)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service logs -f --tail 100 --raw $(PHPFPMFULLNAME)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service logs -f --tail 100 --raw $(MAILHOGFULLNAME)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service logs -f --tail 100 --raw $(MARIADBFULLNAME)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service logs -f --tail 100 --raw $(PHPMYADMINFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

git: ## Scripts GIT
ifeq ($(COMMAND_ARGS),commit)
	@npm run commit
else ifeq ($(COMMAND_ARGS),status)
	@git status
else ifeq ($(COMMAND_ARGS),check)
	@make composer validate -i
	@make composer outdated -i
	@make bdd validate -i
	@make contributors check -i
	@make linter all -i
	@make git status -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "commit: Commit data"
	@echo "check: CHECK before"
	@echo "status: status"
endif

install: node_modules ## Installation
	@make docker deploy -i

linter: ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter eslint -i
	@make linter container -i
	@make linter phpstan -i
	@make linter phpcpd -i
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else ifeq ($(COMMAND_ARGS),eslint)
	@npm run eslint
else ifeq ($(COMMAND_ARGS),eslint-fix)
	@npm run eslint-fix
else ifeq ($(COMMAND_ARGS),phpcbf)
	$(DOCKER_EXECPHP) make linter phpcbf
else ifeq ($(COMMAND_ARGS),phpcpd)
	$(DOCKER_EXECPHP) make linter phpcpd
else ifeq ($(COMMAND_ARGS),phpcs)
	$(DOCKER_EXECPHP) make linter phpcs
else ifeq ($(COMMAND_ARGS),phpcs-onlywarning)
	$(DOCKER_EXECPHP) make linter phpcs-onlywarning
else ifeq ($(COMMAND_ARGS),phpcs-onlyerror)
	$(DOCKER_EXECPHP) make linter phpcs-onlyerror
else ifeq ($(COMMAND_ARGS),phploc)
	$(DOCKER_EXECPHP) make linter phploc
else ifeq ($(COMMAND_ARGS),phpmd)
	$(DOCKER_EXECPHP) make linter phpmd
else ifeq ($(COMMAND_ARGS),phpmnd)
	$(DOCKER_EXECPHP) make linter phpmnd
else ifeq ($(COMMAND_ARGS),phpstan)
	$(DOCKER_EXECPHP) make linter phpstan
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
	@echo "eslint: indique les erreurs sur le code JavaScript à partir d'un standard"
	@echo "eslint-fix: fixe le code JavaScript à partir d'un standard"
	@echo "phpcbf: fixe le code PHP à partir d'un standard"
	@echo "phpcpd: Vérifie s'il y a du code dupliqué"
	@echo "phpcs: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phpcs-onlywarning: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phpcs-onlyerror: indique les erreurs de code non corrigé par PHPCBF"
	@echo "phploc: phploc"
	@echo "phpmd: indique quand le code PHP contient des erreurs de syntaxes ou des erreurs"
	@echo "phpmnd: Si des chiffres sont utilisé dans le code PHP, il est conseillé d'utiliser des constantes"
	@echo "phpstan: regarde si le code PHP ne peux pas être optimisé"
endif

ssh: ## SSH
ifeq ($(COMMAND_ARGS),apache)
	@docker exec -it $(APACHEFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker exec -it $(PHPFPMFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker exec -it $(PHPFPMFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker exec -it $(MAILHOGFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker exec -it $(MARIADBFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker exec -it $(PHPMYADMINFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

update: ## update
ifeq ($(COMMAND_ARGS),apache)
	@docker service update $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service update $(PHPFPM)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service update $(PHPFPM)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service update $(MAILHOG)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service update $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service update $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

inspect: ## inspect
ifeq ($(COMMAND_ARGS),apache)
	@docker service inspect $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service inspect $(PHPFPM)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service inspect $(PHPFPM)
else ifeq ($(COMMAND_ARGS),mailhog)
	@docker service inspect $(MAILHOG)
else ifeq ($(COMMAND_ARGS),mariadb)
	@docker service inspect $(MARIADB)
else ifeq ($(COMMAND_ARGS),phpmyadmin)
	@docker service inspect $(PHPMYADMIN)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "mailhog: MAILHOG"
	@echo "mariadb: MARIADB"
	@echo "phpfpm: PHPFPM"
	@echo "phpmyadmin: PHPMYADMIN"
endif

tests: ## Scripts tests
ifeq ($(COMMAND_ARGS),launch)
	@docker exec $(PHPFPMFULLNAME) make tests all
else ifeq ($(COMMAND_ARGS),behat)
	@docker exec $(PHPFPMFULLNAME) make tests behat
else ifeq ($(COMMAND_ARGS),simple-phpunit-unit-integration)
	@docker exec $(PHPFPMFULLNAME) make tests simple-phpunit-unit-integration
else ifeq ($(COMMAND_ARGS),simple-phpunit)
	@docker exec $(PHPFPMFULLNAME) make tests simple-phpunit
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make tests ARGUMENT"
	@echo "---"
	@echo "launch: Launch all tests"
	@echo "behat: Lance les tests behat"
	@echo "simple-phpunit-unit-integration: lance les tests phpunit"
	@echo "simple-phpunit: lance les tests phpunit"
endif