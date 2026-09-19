NVIM ?= nvim

.PHONY: test
test:
	NVIM_LOG_FILE=$$(mktemp) $(NVIM) --headless -u tests/minimal_init.lua -l tests/run.lua
