# git prepare-commit-msg hook

A simple commit message hook to prepend a commit message with a current branch.  
Exceptions are `main` and `master` branches for which the commit message does not change.

## Installation
```
git clone https://github.com/meslab/prepare-commit-msg-zig.git
cd prepare-commit-msg-zig
make install
```