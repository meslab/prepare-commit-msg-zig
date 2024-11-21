install:
	@zig build --release=small --prefix-exe-dir ~/.git_hooks/

uninstall:
	@rm -rf ~/.git_hooks/prepare-commit-msg

clean:
	@rm -rf .zig-cache zig-out

test:
	@zig build test
	@rm -rf ./test_update_commit_message

.PHONY: install clean test uninstall