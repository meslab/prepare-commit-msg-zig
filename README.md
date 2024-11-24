# git prepare-commit-msg hook

A simple commit message hook that prepends the current branch name to the commit message.  
Exceptions are the `main` and `master` branches, where the commit message remains unchanged.

## Installation
```
git clone https://github.com/meslab/prepare-commit-msg-zig.git
cd prepare-commit-msg-zig
make install
```

## How it works