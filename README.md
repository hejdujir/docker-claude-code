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

Homebrew will refuse to load a freshly tapped formula until you trust it:

```bash
brew trust hejdujir/tap
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

## A dev-flow skill for Claude Code itself

`dcc create` offers to install a prepackaged **`flow`** skill – give it a
task and it works through `recon` → `spec` → `implement` → `review` instead
of jumping straight to code:

- **`recon`** explores the codebase once and caches the result to
  `.dcc/recon.md` – refreshed only when the repo's `HEAD` has actually
  moved since, not on every run.
- **`spec`** turns the task into a written specification under
  `.dcc/specs/`, grounded in that recon.
- **`implement`** builds it against the spec, then marks the spec done
  (`<slug>.done.md`) so a later run knows what's left.
- **`review`** checks the diff against the spec's acceptance criteria –
  read-only, it reports findings instead of fixing them itself.

Run the whole pipeline with `/flow` inside Claude Code, or any step on its
own (`/recon`, `/spec`, `/implement`, `/review`). `flow` runs each step as
its **own subagent**, so that step's exploration and reasoning stay out of
the main conversation – you only see short progress lines and the final
summary, plus a real question on the rare occasion a step genuinely needs
your input (relayed to you and fed back into that same subagent, not a
restart). Those questions go through `grill-me`, a round-based
clarifying-interview skill the other steps call when something's unclear.
Short on time? `/flow --skip-rev` runs recon → spec → implement only.

See [skills/README.md](skills/README.md) for the full catalog and how to
add your own skills to it.

## What are all my sessions doing? (`dcc ps`, `dcc top`)

With several instances and several sessions each, `dcc ps` gives one
overview across all of them – which session is working, which one is
**waiting for you**, what's done, and how far each `/flow` run got:

```
dcc · 3 instances (2 running) · 4 sessions · 1 waiting · 1 agent running · 11:42:05

INSTANCE   SESSION  STATE         AGE  UP   AGENTS DIR            FLOW / LAST
work       7c20aa00 ◆ waiting     3m   30m  0/2    web            recon✓ spec?  question
work       86f761ce ● working     1s   21m  1/3    ptl-app-quadro recon✓ spec✓ impl▶ rev· 270k  Agent · /flow add CSV export
osobni     e8110000 ✓ done        1m   25m  0/4    blog           recon✓ spec✓ impl✓ rev✓ 655k  /flow new post
klient-x            ■ stopped
```

`AGENTS` is running/total subagents of the session, the number after the
flow steps is how many tokens its subagents have used so far. `dcc ps
<session-id>` (any unique prefix) breaks a flow down step by step:

```
86f761ce · work · ptl-app-quadro · ● working · 21m up · /flow add CSV export
agents 1 running / 3 total

  STEP        MODEL              STATE  TIME     TOKENS   OUTPUT
  recon       opus-5-5           ✓      2m09s    110k     15k
  spec        opus-5-5           ✓      1m28s    70k      8.8k
  implement   opus-5-5           ▶      4m10s…   89k      13k
  review      –                  ·      –        –        –
  total                                 7m47s    270k     37k
```

TOKENS counts input, output and cache writes of each step's subagent
(cache reads – the same context read again on every turn – are left out),
taken from the subagents' own transcripts in the home.

`dcc top` is the same, refreshed live (`q` quits, `a` toggles ended
sessions, `-n 5` refreshes every 5 s). With `--notify` it also pops a
desktop notification (macOS / `notify-send`) when a session finishes or
starts waiting for input.

Press `n` in `dcc top` (or run `dcc new`) to **start a new session**: pick
the instance (skipped when there's only one), then one of its mounted
folders or a project directly inside one – cache mounts under `/home/dev`
like `~/.m2` aren't offered. Uses `fzf` when it's installed, a numbered
menu otherwise. From `dcc top` (and `dcc new --tab`) the session opens in a
new tab/window of the terminal you're in – iTerm2, Terminal.app, tmux,
WezTerm, kitty (with remote control enabled) or Ghostty; in any other
terminal it runs right there and you're back in `top` when it ends. The
first time, macOS asks whether your terminal may control itself
(Automation permission) – allow it. `DCC_HOME=<home> dcc` does the same
by hand when a folder is mounted into more than one instance.

It's fed by a small **session status hook**: `dcc create` offers to add it
to the home's `settings.json` (existing homes: `dcc hooks install`, undo
with `dcc hooks rm`). On each session event Claude Code runs
`.dcc/hooks/status.sh` inside the container, which writes one line per
session (plus the flow's token counts) to `<home>/.dcc-status/` – the host only reads those lines as
plain data. The `flow` skill names its subagents `flow: <step>`, which is
how the hook knows the pipeline's progress (`✓` done, `▶` running, `?`
waiting for your answer, `‖` stopped mid-step).

A session whose terminal was killed without a proper exit can't report
it; `dcc ps` notices there are fewer `claude` processes in the container
than open records and hides the oldest extra ones as `gone` (`dcc ps -a`
shows them).

### Sessions don't outlive their tab

Closing a terminal tab ends `docker exec` on the host, but not what it
started inside the container – left alone, every closed tab would keep its
Claude Code running (and holding ~300 MB) until the container stops. So dcc
starts each session through a small launcher (`.dcc/bin/launch.sh`) that
ends it with a SIGTERM – Claude Code saves the conversation, `claude
--resume` brings it back – when:

- **the tab is gone.** While a tab is open, dcc refreshes
  `<home>/.dcc-tabs/<tab>` every 30 s and removes it once the tab closes;
  the session ends ~10 s later. If the file stops changing (the host froze,
  dcc was killed hard) it ends after 5 minutes the container was awake – a
  sleeping Mac doesn't count.
- **nobody typed into it for 24 hours.** Change that with
  `DCC_IDLE_HOURS=48 dcc`, turn it off with `DCC_IDLE_HOURS=0`. Applies to
  Claude Code sessions only, not to `dcc shell` / `exec`.

Every such end is logged in `<home>/.dcc-tabs/ended.log`. Sessions started
by an older dcc aren't covered – end them by hand or restart the container.

## Commands

| | |
|---|---|
| `dcc` | Claude Code (working directory based on cwd) |
| `dcc <folder>` | Claude Code in a specific folder |
| `dcc login` / `shell` / `exec -- <cmd>` | log in, bash, one-off command |
| `dcc mount list\|add\|rm` | manage mounts (updates compose and restarts) |
| `dcc port list\|add\|rm` | forward an extra host<->container port (updates compose and restarts) |
| `dcc up\|down\|restart\|status\|logs` | container lifecycle |
| `dcc doctor` | what's missing, what's not running, what's not logged in |
| `dcc homes` | list of all instances and their mounts |
| `dcc ps [-a]` / `dcc top [--notify]` | sessions of all instances and what they're doing, once or live |
| `dcc ps <session-id>` | one session's flow step by step: model, time, tokens |
| `dcc new [--tab]` | pick an instance and a mounted folder, start a session there |
| `dcc hooks install\|rm\|status` | the session status hook that feeds `ps` / `top` |
| `dcc build` / `update` | (re)build the base image |
| `dcc claude-update` | update Claude Code – rebuilds just its layer of the base image, or re-bakes the instance's snapshot |
| `dcc snapshot [tag]` / `reset` | bake the container state / revert to base |
| `dcc destroy` | removes the container and cache, leaves the home alone |

Claude Code runs with its classic renderer, so the conversation stays in
your terminal's scrollback. Newer versions otherwise draw fullscreen in the
alternate screen, where the terminal keeps no history and you scroll inside
Claude instead – `DCC_FULLSCREEN=1 dcc` keeps that.

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

`dcc create` asks for a name for the instance – that's what shows up as the
container and Docker Compose project name in Docker Desktop, so you can
tell instances apart at a glance. Press Enter to keep the auto-generated
one (`dcc-<folder>-<hash>`).

Port `54545` (OAuth callback) is only published to the instance that grabs
it first; for the others you'll copy the code from the browser by hand
during `dcc login`. `dcc doctor` will flag this.

## Reaching a web app running inside the container

Every instance's whole port block maps 1:1 to the host (host port ==
container port), so the easiest way to preview something is to make it
listen on a port inside your instance's block (`dcc doctor` shows it, e.g.
`8080-8089`):

```bash
PORT=8081 npm run dev        # or --port 8081, -p 8081, whatever the tool wants
```

Then open `http://localhost:8081` on the host. Up to 10 apps can run this
way at once per instance, each on its own port from the block.

If you need a fixed/well-known port outside the block (say Postgres on
`5432`), forward it explicitly:

```bash
dcc port add 5432          # host 5432 -> container 5432
dcc port add 5432 5433     # host 5433 -> container 5432, if 5432 is taken on the host
dcc port list
dcc port rm 5433
```

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
- The home's `.dcc/` is mounted read-only inside the container, and on the
  host dcc never sources or evals anything from it: `instance`, `mounts` and
  `ports` are parsed as plain data and validated, `docker-compose.yml` is
  regenerated on every run, and only homes listed in the registry are used.
  After upgrading, run `dcc restart` once so the read-only mount takes effect.
- Docker is not a hypervisor. For hard isolation consider gVisor
  (`--runtime=runsc`) or a VM.

## Releasing a new version

1. Bump `DCC_VERSION` in `bin/dcc`, commit, tag `v0.x.y`, push (`git push origin v0.x.y`).
2. Update the `url` in `dcc.rb` to point at the new tag, then
   `shasum -a 256` the tarball and update `sha256` in `dcc.rb`.
3. Copy the updated `dcc.rb` into `Formula/dcc.rb` in
   [hejdujir/homebrew-tap](https://github.com/hejdujir/homebrew-tap), commit, push.
4. `brew upgrade dcc` (or `brew reinstall dcc` if the version didn't change
   but the formula did).
