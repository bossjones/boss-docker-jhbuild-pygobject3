project := boss-docker-jhbuild-pygobject3
projects := boss-docker-jhbuild-pygobject3

.DEFAULT_GOAL := help

# http://misc.flogisoft.com/bash/tip_colors_and_formatting

RED=\033[0;31m
GREEN=\033[0;32m
ORNG=\033[38;5;214m
BLUE=\033[38;5;81m
NC=\033[0m

export RED
export GREEN
export NC
export ORNG
export BLUE

# verify that certain variables have been defined off the bat
check_defined = \
    $(foreach 1,$1,$(__check_defined))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $(value 2), ($(strip $2)))))

list_allowed_args := name

.PHONY: help
help:
	@printf "\033[21m\n\n"
	@printf "=======================================\n"
	@printf "\n"
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

list:
	@$(MAKE) -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort

# docker-build:
# 	docker-compose -f docker-compose.yml -f ci/build.yml build

# docker-build-run: docker-build
# 	docker run -i -t --rm scarlettos_scarlett_master bash

.PHONY: test
test:
	@docker-compose -f docker-compose.yml -f ci_build.yml up --build

.PHONY: docker-compose-build
docker-compose-build:
	@docker-compose -f docker-compose-devtools.yml build

.PHONY: docker-compose-up
docker-compose-up:
	@docker-compose -f docker-compose.yml -f ci_build.yml up

.PHONY: docker-compose-up-build
docker-compose-up-build:
	@docker-compose -f docker-compose.yml -f ci_build.yml up --build

.PHONY: docker-compose-down
docker-compose-down:
	@docker-compose -f docker-compose.yml -f ci_build.yml down

.PHONY: docker-version
docker-version:
	@docker --version
	@docker-compose --version

.PHONY: docker-exec
docker-exec:
	@docker exec -i -t bossdockerjhbuildpygobject3_jhbuild_pygobject3_1 bash

.PHONY: docker-exec-master
docker-exec-master:
	@docker exec -i -t bossdockerjhbuildpygobject3_jhbuild_pygobject3_1 bash

.PHONY: rake_deps
rake_deps:
	@gem install httparty -v 0.15.5
	@gem install bundler -v 1.15.1
	@bundle install --path .vendor

.PHONY: rake_deps_build
rake_deps_build: rake_deps
	@bundle exec rake build

.PHONY: rake_deps_build_push
rake_deps_build_push: rake_deps_build
	@bundle exec rake push
