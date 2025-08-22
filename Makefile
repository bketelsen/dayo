.PHONY: default
default: build

.PHONY: build
server:
ifeq (, $(shell which mkosi))
	@echo "mkosi couldn't be found, please install it and try again"
	exit 1
endif
	$(shell command -v mkosi) -d debian -r trixie build

.PHONY: desktop
desktop:
ifeq (, $(shell which mkosi))
	@echo "mkosi couldn't be found, please install it and try again"
	exit 1
endif
	$(shell command -v mkosi) -d debian -r trixie --profile desktop build

.PHONY: clean
clean:
	rm -rf mkosi.output
	rm -rf mkosi.cache