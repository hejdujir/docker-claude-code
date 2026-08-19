#!/usr/bin/env bash
set -euo pipefail

HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

CUR_UID="$(id -u dev)"
CUR_GID="$(id -g dev)"

# Align UID/GID with the host => files created inside don't belong to root
[ "$HOST_GID" != "$CUR_GID" ] && groupmod -o -g "$HOST_GID" dev
[ "$HOST_UID" != "$CUR_UID" ] && usermod -o -u "$HOST_UID" dev

chown "$HOST_UID:$HOST_GID" /home/dev

# Walk the home directory and SKIP mountpoints – they have an owner
# from the host, and a recursive chown on them would be slow and unwanted.
shopt -s dotglob nullglob
for entry in /home/dev/*; do
    [ -d "$entry" ] && mountpoint -q "$entry" && continue
    find "$entry" ! -user "$HOST_UID" -exec chown -h "$HOST_UID:$HOST_GID" {} + 2>/dev/null || true
done
shopt -u dotglob nullglob

find /opt/npm-global ! -user "$HOST_UID" -exec chown -h "$HOST_UID:$HOST_GID" {} + 2>/dev/null || true

# /workspace may contain repositories owned by someone else
git config --system --add safe.directory '*' 2>/dev/null || true

# Marker for `dcc doctor` to tell init has finished
touch /tmp/.dcc-ready
chmod 666 /tmp/.dcc-ready

exec gosu dev "$@"
