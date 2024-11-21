install:
	@zig build --release=small --prefix-exe-dir ~/.git_hooks/

clean:
	@rm -rf .zig-cache zig-out

test:
	@zig build test

.PHONY: install clean test