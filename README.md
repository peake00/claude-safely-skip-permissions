# _claude-safely-skip-permissions_

_Run Claude autonomously without dangerous commands._

## _Install_

```bash
curl -fsSL https://raw.githubusercontent.com/jepeake/claude-safely-skip-permissions/main/install.sh | bash
```

## _Use_

```bash
claude --safely-skip-permissions
```

_Blocked commands:_

| _Blocked_ |
|---|
| `rm -rf`, `rm -r`, `rm -f` |
| `find . -delete` |
| `xargs rm` |
| `shred`, `wipe` |

