# _claude-safely-skip-permissions_

_A `--safely-skip-permissions` flag for [Claude Code](https://claude.com/claude-code)._

_Works like `--dangerously-skip-permissions` but blocks destructive file removal commands (`rm -rf`, `find -delete`, `shred`, etc.)._

## _Install_

```bash
curl -fsSL https://raw.githubusercontent.com/jepeake/claude-safely-skip-permissions/main/install.sh | bash
```

## _Usage_

```bash
claude --safely-skip-permissions
```

_All permission prompts are skipped, except destructive file removal commands are blocked:_

| _Blocked_ |
|---|
| `rm -rf`, `rm -r`, `rm -f` |
| `find . -delete` |
| `xargs rm` |
| `shred`, `wipe` |


## _Requirements_

- [Claude Code](https://claude.com/claude-code)
- `jq` (`brew install jq` / `apt install jq`)
- bash or zsh
