# syntax=docker/dockerfile:1
#
# Base image for dcc. Deliberately WITHOUT any specific language stack –
# Java, Go, .NET or anything else gets installed by Claude from inside
# (it has passwordless sudo). Once the environment is set up the way you
# want, `dcc snapshot` bakes it into a new image.
#
FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg locales \
      git git-lfs openssh-client \
      build-essential pkg-config make \
      python3 python3-pip python3-venv \
      ripgrep fd-find jq tree \
      less vim nano tmux zsh bash-completion \
      htop procps psmisc lsof \
      unzip zip tar xz-utils rsync \
      iproute2 iputils-ping dnsutils netcat-openbsd \
      util-linux sudo gosu man-db \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && sed -i '/^# *en_US.UTF-8/s/^# *//' /etc/locale.gen && locale-gen \
  && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Node.js – the base image no longer ships it, but Claude Code itself needs it to run
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
  && apt-get update && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# GitHub CLI – useful across stacks
RUN mkdir -p -m 755 /etc/apt/keyrings \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

# User: non-root is a requirement for --dangerously-skip-permissions
RUN groupadd -g 1000 dev && \
    useradd -m -u 1000 -g 1000 -s /bin/bash dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-dev && \
    chmod 0440 /etc/sudoers.d/90-dev

# npm prefix outside /usr/local, so `claude update` also works at runtime
ENV NPM_CONFIG_PREFIX=/opt/npm-global
ENV PATH=/opt/npm-global/bin:$PATH

RUN mkdir -p /opt/npm-global \
  && npm install -g @anthropic-ai/claude-code \
  && npm cache clean --force

# Without this, .claude.json (OAuth account) would end up outside the mounted home
ENV CLAUDE_CONFIG_DIR=/home/dev/.claude

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
