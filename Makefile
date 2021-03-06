.PHONY: docker python

REQS := python/requirements.txt
REQS_TEST := python/requirements-test.txt

# Used for colorizing output of echo messages
BLUE := "\\033[1\;36m"
NC := "\\033[0m" # No color/default

PRE := /app
TEMPLATES := my_resume/templates

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
  match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
  if match:
    target, help = match.groups()
    print("%-20s %s" % (target, help))
endef

export PRINT_HELP_PYSCRIPT

help:
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

app: ## run application locally
	@if [ -f /.dockerenv ]; then echo "Don't run make local inside docker container" && exit 1; fi;
	docker-compose -f docker/docker-compose.yml up --build franklin_resume

build: ## setup the build env
	python3 -m compileall .
	bash -xe tests/env_setup.sh

clean: ## Cleanup all the things
	rm -rf rst/_build
	rm -rf python/.coverage
	rm -rf python/*.egg-info
	rm -rf python/.pytest_cache
	rm -rf python/.tox
	rm -rf python/build
	rm -rf python/dist
	rm -rf python/htmlcov
	rm -rf python/myvenv
	find . -name '*.pyc' | xargs rm -rf
	find . -name '__pycache__' | xargs rm -rf

dist: ## make a pypi style dist
	if [ ! -f /.dockerenv ]; then $(MAKE) print-status MSG="Run make dist inside docker container" && exit 1; fi
	$(MAKE) print-status MSG="Make a Pypi style dist"
	cd python && python -m compileall .
	cd python && python setup.py sdist bdist

docker: python ## build docker container for testing
	if [ -f /.dockerenv ]; then $(MAKE) print-status MSG="***> Don't run make docker inside docker container <***" && exit 1; fi
	$(MAKE) print-status MSG="Building with docker-compose"
	#python3 -m compileall .
	docker-compose -f docker/docker-compose.yml build dev_franklin_resume
	@docker-compose -f docker/docker-compose.yml run dev_franklin_resume /bin/bash

print-status:
	@:$(call check_defined, MSG, Message to print)
	@echo "$(BLUE)$(MSG)$(NC)"

python: ## set up the python environment
	$(MAKE) print-status MSG="Set up the Python environment"
	if [ -f '$(REQS)' ]; then python3 -m pip install -r$(REQS); fi

test: python ## test the flask app
	if [ ! -f /.dockerenv ]; then $(MAKE) print-status MSG="Run make test inside docker container" && exit 1; fi
	$(MAKE) print-status MSG="Test the Flask App"
	if [ -f '$(REQS_TEST)' ]; then pip3 install -r$(REQS_TEST); fi
	#cd python && if [ -f "tox.ini" ]; then tox -e pylint; fi
	cd python && if [ -f "tox.ini" ]; then tox; fi
