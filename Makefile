CORE_GIT_HOOKSPATH := $(shell git config get core.hookspath)
CORE_GIT_HOOKSPATH := $(if $(CORE_GIT_HOOKSPATH),$(CORE_GIT_HOOKSPATH),~/.git_hooks)

install:
	mkdir -p ${CORE_GIT_HOOKSPATH}
	git config set --global core.hookspath $(CORE_GIT_HOOKSPATH)
	zig build --release=safe --prefix-exe-dir ${CORE_GIT_HOOKSPATH}/
	strip ${CORE_GIT_HOOKSPATH}/prepare-commit-msg

uninstall:
	@rm -rf ${CORE_GIT_HOOKSPATH}/prepare-commit-msg

clean:
	@rm -rf .zig-cache zig-out

test:
	@zig build test
	@rm -rf ./test_update_commit_message

.PHONY: install clean test uninstall