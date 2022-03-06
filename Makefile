.DEFAULT_GOAL := help


# Hyperconverged Infrastructure
ENV_OS_NAME ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')


### help : Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@if [ '$(ENV_OS_NAME)' = 'darwin' ]; then \
		awk '{ if(match($$0, /^#{3}([^:]+):(.*)$$/)){ split($$0, res, ":"); gsub(/^#{3}[ ]*/, "", res[1]); _desc=$$0; gsub(/^#{3}([^:]+):[ \t]*/, "", _desc); printf("    make %-15s : %-10s\n", res[1], _desc) } }' Makefile; \
	else \
		awk '{ if(match($$0, /^\s*#{3}\s*([^:]+)\s*:\s*(.*)$$/, res)){ printf("    make %-15s : %-10s\n", res[1], res[2]) } }' Makefile; \
	fi
	@echo


### lint : Lint source code
.PHONY: lint
lint:
	luacheck -q lib