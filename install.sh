#!/usr/bin/env bash
# Install the branded startup for the current user only.
set -Eeuo pipefail

fail() {
  printf 'IB AFRIDI OS install: %s\n' "$*" >&2
  exit 1
}

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  fail 'HOME must be set to an absolute path.'
fi

SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if [[ -n ${XDG_DATA_HOME:-} && $XDG_DATA_HOME == /* ]]; then
  DATA_HOME=$XDG_DATA_HOME
else
  DATA_HOME=$HOME/.local/share
fi

INSTALL_DIR=$DATA_HOME/ib-afridi-os
STATE_DIR=$INSTALL_DIR/.state
BASHRC=$HOME/.bashrc
START_MARKER='# >>> IB AFRIDI OS startup >>>'
END_MARKER='# <<< IB AFRIDI OS startup <<<'

for required_path in assets config src; do
  [[ -d $SOURCE_DIR/$required_path ]] || fail "Missing project directory: $required_path"
done
[[ -f $SOURCE_DIR/README.md && -f $SOURCE_DIR/LICENSE ]] || fail 'README.md or LICENSE is missing.'

if [[ -e $INSTALL_DIR && ! -d $INSTALL_DIR ]]; then
  fail "Install destination exists but is not a directory: $INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"

# Copy only project files. The repository's .git directory is never installed.
if [[ $SOURCE_DIR != "$INSTALL_DIR" ]]; then
  cp -R "$SOURCE_DIR/assets" "$SOURCE_DIR/config" "$SOURCE_DIR/src" "$INSTALL_DIR/"
  cp "$SOURCE_DIR/README.md" "$SOURCE_DIR/LICENSE" "$SOURCE_DIR/install.sh" "$SOURCE_DIR/uninstall.sh" "$INSTALL_DIR/"
fi

chmod +x "$INSTALL_DIR/install.sh" "$INSTALL_DIR/uninstall.sh" "$INSTALL_DIR"/src/*.sh
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

if [[ -L $BASHRC && ! -e $BASHRC ]]; then
  fail "Refusing to follow a broken .bashrc symlink: $BASHRC"
fi
if [[ -e $BASHRC && ! -f $BASHRC ]]; then
  fail "Expected a regular .bashrc file: $BASHRC"
fi
if [[ -f $BASHRC && ! -r $BASHRC ]]; then
  fail ".bashrc is not readable: $BASHRC"
fi
if [[ -f $BASHRC && ! -w $BASHRC ]]; then
  fail ".bashrc is not writable: $BASHRC"
fi

start_count=0
end_count=0
if [[ -f $BASHRC ]]; then
  start_count=$(grep -Fxc -- "$START_MARKER" "$BASHRC" || :)
  end_count=$(grep -Fxc -- "$END_MARKER" "$BASHRC" || :)
fi
if (( start_count != end_count || start_count > 1 )); then
  fail 'Found an incomplete or duplicate managed block in .bashrc; repair it before installing.'
fi
has_hook=0
if (( start_count == 1 )); then
  has_hook=1
fi

strip_managed_block() {
  local input_file=$1
  local output_file=$2

  awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { inside = 1; starts++; next }
    inside && $0 == end { inside = 0; ends++; next }
    !inside { print }
    END { if (inside || starts != 1 || ends != 1) exit 2 }
  ' "$input_file" > "$output_file"
}

save_baseline_from_current_config() {
  local temporary_file

  if [[ -f $BASHRC ]]; then
    temporary_file=$(mktemp "$HOME/.ib-afridi-os.XXXXXX")
    if (( has_hook )); then
      strip_managed_block "$BASHRC" "$temporary_file" || {
        rm -f "$temporary_file"
        fail 'Could not safely read the managed block from .bashrc.'
      }
      chmod --reference="$BASHRC" "$temporary_file" 2>/dev/null || :
    else
      cp -p "$BASHRC" "$temporary_file"
    fi

    cp -p "$temporary_file" "$STATE_DIR/bashrc.original"
    chmod 600 "$STATE_DIR/bashrc.original"
    rm -f "$STATE_DIR/bashrc.was-absent"
    rm -f "$temporary_file"
  else
    rm -f "$STATE_DIR/bashrc.original"
    : > "$STATE_DIR/bashrc.was-absent"
    chmod 600 "$STATE_DIR/bashrc.was-absent"
  fi
}

has_original=0
if [[ -f $STATE_DIR/bashrc.original ]]; then
  has_original=1
fi
was_absent=0
if [[ -f $STATE_DIR/bashrc.was-absent ]]; then
  was_absent=1
fi
if (( has_original + was_absent > 1 )); then
  fail 'Installation backup state is inconsistent; .bashrc was left unchanged.'
fi

# Preserve user edits made since the last install/reinstall. When the current
# file exactly matches the prior managed snapshot, keep the original baseline.
if (( has_original + was_absent == 0 )); then
  save_baseline_from_current_config
elif [[ -f $STATE_DIR/bashrc.installed ]]; then
  if [[ -f $BASHRC ]] && cmp -s "$BASHRC" "$STATE_DIR/bashrc.installed"; then
    : # No external edits since the last install.
  else
    save_baseline_from_current_config
  fi
fi

if (( has_hook )); then
  temporary_file=$(mktemp "$HOME/.ib-afridi-os.XXXXXX")
  strip_managed_block "$BASHRC" "$temporary_file" || {
    rm -f "$temporary_file"
    fail 'Could not safely update the managed block in .bashrc.'
  }
  # Write through the existing file to preserve its mode and any symlink target.
  cat "$temporary_file" > "$BASHRC"
  rm -f "$temporary_file"
fi

startup_path=$INSTALL_DIR/src/startup.sh
{
  printf '\n%s\n' "$START_MARKER"
  printf 'if [[ $- == *i* ]] && [[ -r %q ]]; then\n' "$startup_path"
  printf '  . %q\n' "$startup_path"
  printf 'fi\n%s\n' "$END_MARKER"
} >> "$BASHRC"

cp -p "$BASHRC" "$STATE_DIR/bashrc.installed"
chmod 600 "$STATE_DIR/bashrc.installed"

printf 'IB AFRIDI OS installed for the current user.\n'
printf '  Files:      %s\n' "$INSTALL_DIR"
printf '  Bash config: %s\n' "$BASHRC"
if [[ ${SHELL##*/} != 'bash' ]]; then
  printf '  Note: your login shell is reported as %s; this startup is for Bash.\n' "${SHELL:-unknown}"
fi
printf 'Open a new interactive Bash terminal to see the startup display.\n'
