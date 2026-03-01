install:
	zig build -Doptimize=ReleaseFast

#uninstall:
	 # zig build uninstall -Doptimize=ReleaseFast

clean:
	@rm -rf .zig-cache zig-out

test:
	@zig build test --summary all
	@rm -rf ./test_update_commit_message

.PHONY: install clean test uninstall
