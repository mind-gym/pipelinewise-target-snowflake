SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

OBJS := $(shell find . -type f -name "*.py" -not -path "*$(VENV)/*" -not -path "*build/*" -not -path "*dist/*")
VENV := .venv
PYTHON := python3.7
VERSION := 1.10.0

## all: dist/pipelinewise-target-snowflake-$(VERSION).tar.gz
all: dist/pipelinewise-target-snowflake-$(VERSION).tar.gz
.PHONY: all

clean:
	rm -rf $(VENV)
	rm -rf dist
	rm -rf build
	rm -rf tmp
	rm -rf pipelinewise_target_snowflake.egg-info
.PHONY: clean

tmp/.sentinel.installed-venv: requirements.txt setup.py
	@mkdir -p $(@D)
	test -d $(VENV) && rm -rf $(VENV)
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install .[test]
	$(VENV)/bin/pip install pylint
	$(VENV)/bin/pip install setuptools wheel twine
	touch $@

tmp/.sentinel.lint: tmp/.sentinel.installed-venv $(OBJS)
	@mkdir -p $(@D)
	$(VENV)/bin/pylint target_snowflake -d C,W,unexpected-keyword-arg,duplicate-code
	touch $@

tmp/.sentinel.unit-tests: tmp/.sentinel.installed-venv $(OBJS)
	@mkdir -p $(@D)
	$(VENV)/bin/nosetests --where=tests/unit
	touch $@

tmp/.sentinel.integration-tests: tmp/.sentinel.installed-venv $(OBJS)
	@mkdir -p $(@D)
	$(VENV)/bin/nosetests --where=tests/integration
	touch $@

dist/pipelinewise-target-snowflake-$(VERSION).tar.gz: tmp/.sentinel.lint tmp/.sentinel.unit-tests tmp/.sentinel.integration-tests
	@mkdir -p $(@D)
	$(VENV)/bin/python setup.py sdist bdist_wheel
	echo "twine upload dist/* to somewhere now!"
	touch $@

## help: provides help
help : Makefile
	@sed -n 's/^##//p' $<
.PHONY : help
