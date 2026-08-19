# docker-claude-code (`dcc`)

Claude Code with `--dangerously-skip-permissions` in an isolated Docker
container. One command to set up, then just `dcc`.

```
cd ~/dev/claude
dcc create          # home + mounts + build + start
dcc login           # log in

cd ~/dev/workspace/my-project
dcc                 # Claude Code right in this project
```

## Installation

```bash
brew tap hejdujir/tap
brew install dcc
```

Without Homebrew:

```bash
curl -fsSL https://raw.githubusercontent.com/hejdujir/docker-claude-code/main/install.sh | bash
```

You need a running Docker (Docker Desktop, Colima, OrbStack).

## How it works

**`dcc create`** turns the current folder into a *home* for Claude Code – in
the container it's mounted as `~/.claude`, so `CLAUDE.md`, `settings.json`,
`skills/`, `commands/`, `agents/`, login and session history all live there.
It interactively asks which directories to mount (checks they exist, offers
to create them, supports read-only) and generates `.dcc/docker-compose.yml`.

```
~/dev/claude/               <- home, `dcc create` was run here
├── CLAUDE.md
├── settings.json
├── skills/  commands/  agents/
├── .gitignore              <- filters out credentials and runtime clutter
└── .dcc/
    ├── instance            <- name, image, port block
    ├── mounts              <- host|container|rw/ro
    └── docker-compose.yml  <- generated

~/dev/workspace/            -> /workspace
~/.m2                       -> /home/dev/.m2
```

**Subsequent runs:** `dcc` anywhere inside a mounted directory finds the
right instance via the registry (`~/.config/dcc/registry`), starts the
container if it's not running, and launches Claude Code with the matching
working directory. When you're in `~/dev/workspace/api`, Claude starts in
`/workspace/api`.

The container is **long-running** – the first `dcc` spins it up, every
subsequent one just hops in via `docker compose exec`. You can have several
sessions open at once across different projects.

## Commands

| | |
|---|---|
| `dcc` | Claude Code (working directory based on cwd) |
| `dcc <folder>` | Claude Code in a specific folder |
| `dcc login` / `shell` / `exec -- <cmd>` | log in, bash, one-off command |
| `dcc mount list\|add\|rm` | manage mounts (updates compose and restarts) |
| `dcc up\|down\|restart\|status\|logs` | container lifecycle |
| `dcc doctor` | what's missing, what's not running, what's not logged in |
| `dcc homes` | list of all instances and their mounts |
| `dcc build` / `update` | (re)build the base image |
| `dcc snapshot [tag]` / `reset` | bake the container state / revert to base |
| `dcc destroy` | removes the container and cache, leaves the home alone |

## The base image is deliberately dumb

Node 22, git, gh, build-essential, python3, ripgrep, fd, jq, tmux, vim,
network tools. No Java, Go or .NET. The `dev` user has passwordless `sudo`,
so Claude can install whatever stack the project needs on its own.

So it doesn't have to do that every time:

```bash
dcc                          # "install JDK 21 and Maven"
dcc snapshot                 # docker commit -> the instance starts from here
dcc reset                    # back to the clean base
```

Snapshots are per instance, so a Java project and a Node project can each
have their own baked-in state on top of the same base.

## Multiple instances

You can run `dcc create` in several folders – each gets its own container,
its own port block (8080–8089, 8090–8099, …) and its **own login**. Handy
for separating clients, or work vs. personal accounts.

Port `54545` (OAuth callback) is only published to the instance that grabs
it first; for the others you'll copy the code from the browser by hand
during `dcc login`. `dcc doctor` will flag this.

## Security

What's isolated is the host filesystem, **not** whatever you mount.
Anything under `/workspace` can be overwritten by Claude and that change is
immediately on the host – work inside git.

- Don't mount `~/.ssh` or cloud credentials. For GitHub, use a short-lived
  token (`dcc exec -- gh auth login`).
- Mount reference directories read-only (`dcc mount add ~/docs /docs ro`).
- The container has full network access. Anthropic provides a reference
  `init-firewall.sh` (domain allowlist, requires `NET_ADMIN`/`NET_RAW`) —
  see https://github.com/anthropics/claude-code/tree/main/.devcontainer
- The login token lives in the home directory. Over an untrusted repo it's
  theoretically exfiltratable.
- Docker is not a hypervisor. For hard isolation consider gVisor
  (`--runtime=runsc`) or a VM.

## Releasing a new version

1. Bump `DCC_VERSION` in `bin/dcc`, tag `v0.x.y`, push.
2. `shasum -a 256` the GitHub tarball → into `Formula/dcc.rb`.
3. Copy the formula into your own tap (`hejdujir/homebrew-tap`).
