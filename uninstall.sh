#!/usr/bin/env bash
# Remove the IB AFRIDI OS startup from the current user's Bash configuration.
set -Eeuo pipefail

fail() {
  printf 'IB AFRIDI OS uninstall: %s\n' "$*" >&2
  exit 1
}

if [[ -z ${HOME:-} || $HOME != /* ]]; then
  fail 'HOME must be set to an absolute path.'
fi

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

if [[ ! -d $INSTALL_DIR ]]; then
  printf 'IB AFRIDI OS is not installed at %s. Nothing to remove.\n' "$INSTALL_DIR"
  exit 0
fi

if [[ -L $BASHRC && ! -e $BASHRC ]]; then
  fail "Refusing to follow a broken .bashrc symlink: $BASHRC"
fi
if [[ -e $BASHRC && ! -f $BASHRC ]]; then
  fail "Expected a regular .bashrc file: $BASHRC"
fi
if [[ -f $BASHRC && ! -r $BASHRC ]]; then
  fail ".bashrc is not readable: $BASHRC"
fi

start_count=0
end_count=0
if [[ -f $BASHRC ]]; then
  start_count=$(grep -Fxc -- "$START_MARKER" "$BASHRC" || :)
  end_count=$(grep -Fxc -- "$END_MARKER" "$BASHRC" || :)
fi
if (( start_count != end_count || start_count > 1 )); then
  fail 'Found an incomplete or duplicate managed block in .bashrc; repair it before uninstalling.'
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

restored_exactly=0
if (( has_hook )) && [[ -f $STATE_DIR/bashrc.installed ]] && cmp -s "$BASHRC" "$STATE_DIR/bashrc.installed"; then
  if [[ -f $STATE_DIR/bashrc.original ]]; then
    cp -p "$STATE_DIR/bashrc.original" "$BASHRC"
    restored_exactly=1
  elif [[ -f $STATE_DIR/bashrc.was-absent ]]; then
    # Remove the .bashrc created by install.sh, but never unlink a user's symlink.
    if [[ ! -L $BASHRC ]]; then
      rm -f "$BASHRC"
      restored_exactly=1
    fi
  fi
fi

if (( has_hook && ! restored_exactly )); then
  temporary_file=$(mktemp "$HOME/.ib-afridi-os.XXXXXX")
  strip_managed_block "$BASHRC" "$temporary_file" || {
    rm -f "$temporary_file"
    fail 'Could not safely remove the managed block from .bashrc.'
  }
  # Preserve any edits outside the marked block and retain the existing file.
  cat "$temporary_file" > "$BASHRC"
  rm -f "$temporary_file"
fi

rm -rf -- "$INSTALL_DIR"
printf 'IB AFRIDI OS has been removed from this user account.\n'
if (( restored_exactly )); then
  printf 'The pre-install .bashrc state was restored.\n'
elif (( has_hook )); then
  printf 'The managed .bashrc block was removed; other shell configuration edits were preserved.\n'
else
  printf 'No managed .bashrc block was found; only the installed project files were removed.\n'
fi
printf 'Open a new Bash terminal for the change to take effect in the prompt.\n'
