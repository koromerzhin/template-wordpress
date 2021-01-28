.DEFAULT_GOAL   := help

%:
	@:

SUPPORTED_COMMANDS   := bdd composer contributors encore env geocode git install linter logs messenger sleep ssh tests workflow-png
SUPPORTS_MAKE_ARGS   := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

.PHONY: 

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

composer.lock: composer.json
	composer update

composer: ## Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	@composer suggests --by-suggestion
else ifeq ($(COMMAND_ARGS),outdated)
	@composer outdated
else ifeq ($(COMMAND_ARGS),fund)
	@composer fund
else ifeq ($(COMMAND_ARGS),prod)
	@composer install --no-dev --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMAND_ARGS),dev)
	@composer install --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMAND_ARGS),update)
	@composer update
else ifeq ($(COMMAND_ARGS),validate)
	@composer validate
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


linter: phpcpd.phar phploc.phar phpmd.phar ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter twig -i
	@make linter container -i
	@make linter yaml -i
	@make linter phpstan -i
	@make linter phpcpd -i
	@make linter phpcs -i
	@make linter phpmd -i
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),phpcbf)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcbf
else ifeq ($(COMMAND_ARGS),phpcpd)
	@php phpcpd.phar src tests
else ifeq ($(COMMAND_ARGS),phpcs)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs
else ifeq ($(COMMAND_ARGS),phpcs-onlywarning)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs-onlywarning
else ifeq ($(COMMAND_ARGS),phpcs-onlyerror)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpcs-onlyerror
else ifeq ($(COMMAND_ARGS),phploc)
	@php phploc.phar src
else ifeq ($(COMMAND_ARGS),phpmd)
	@php phpmd.phar src,features/bootstrap,tests ansi phpmd.xml
else ifeq ($(COMMAND_ARGS),phpmnd)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpmnd
else ifeq ($(COMMAND_ARGS),phpstan)
	@COMPOSER_MEMORY_LIMIT=-1 composer run phpstan
else ifeq ($(COMMAND_ARGS),container)
	${SYMFONY_EXEC} lint:container
else ifeq ($(COMMAND_ARGS),twig)
	${SYMFONY_EXEC} lint:twig templates
else ifeq ($(COMMAND_ARGS),yaml)
	${SYMFONY_EXEC} lint:yaml config
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
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