.PHONY: default
default: build

.PHONY: build
build:
ifeq (, $(shell which mkosi))
	@echo "mkosi couldn't be found, please install it and try again"
	exit 1
endif
	$(shell command -v mkosi) --profile desktop build
