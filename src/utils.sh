# Shared display helpers for the IB AFRIDI OS Bash startup.
# Functions use the ib_ prefix to avoid collisions with a user's shell.

ib_has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Detect the current terminal width, falling back to Bash's COLUMNS value.
ib_terminal_width() {
  local columns=''

  if [[ -t 1 && -n ${TERM:-} && ${TERM:-dumb} != 'dumb' ]] && ib_has_command tput; then
    columns=$(tput cols 2>/dev/null || :)
  fi

  if [[ ! $columns =~ ^[0-9]+$ ]] || (( 10#$columns < 1 )); then
    columns=''
    if [[ -t 1 ]] && ib_has_command stty; then
      local rows=''
      read -r rows columns < <(stty size 2>/dev/null) || columns=''
    fi
  fi

  if [[ ! $columns =~ ^[0-9]+$ ]] || (( 10#$columns < 1 )); then
    columns=${COLUMNS:-}
  fi

  if [[ $columns =~ ^[0-9]+$ ]] && (( 10#$columns > 0 )); then
    printf '%s\n' "$((10#$columns))"
  else
    # A conservative display fallback when a terminal size cannot be queried.
    printf '%s\n' 80
  fi
}

# Enable restrained ANSI colors only when the output is a capable terminal.
# NO_COLOR is honored by presence, including when it is set to an empty value.
ib_init_colors() {
  IB_COLOR_ENABLED=0
  IB_COLOR_RESET=''
  IB_COLOR_ACCENT=''
  IB_COLOR_MUTED=''
  IB_COLOR_OK=''
  IB_COLOR_BOLD=''

  if [[ -t 1 && -z ${NO_COLOR+x} && -n ${TERM:-} && ${TERM:-dumb} != 'dumb' ]] && ib_has_command tput; then
    local color_count='0'
    color_count=$(tput colors 2>/dev/null || printf '0')

    if [[ $color_count =~ ^[0-9]+$ ]] && (( 10#$color_count >= 8 )); then
      IB_COLOR_ENABLED=1
      IB_COLOR_RESET=$(tput sgr0 2>/dev/null || :)
      IB_COLOR_ACCENT=$(tput setaf 6 2>/dev/null || :)
      IB_COLOR_MUTED=$(tput setaf 7 2>/dev/null || :)
      IB_COLOR_OK=$(tput setaf 2 2>/dev/null || :)
      IB_COLOR_BOLD=$(tput bold 2>/dev/null || :)
    fi
  fi
}

# Clear only when a real terminal description and tput are available.
ib_clear_screen() {
  [[ ${IB_AFRIDI_NO_CLEAR:-0} == '1' ]] && return 0

  if [[ -t 1 && -n ${TERM:-} && ${TERM:-dumb} != 'dumb' ]] && ib_has_command tput; then
    tput clear 2>/dev/null || :
  fi
}

# A brief visual cue only; this does not represent a scan or system operation.
ib_show_animation() {
  [[ ${IB_AFRIDI_NO_ANIMATION:-0} == '1' ]] && return 0

  printf '  %s[ IB AFRIDI ]%s Preparing terminal display' \
    "$IB_COLOR_ACCENT" "$IB_COLOR_RESET"

  if ib_has_command sleep; then
    local step=0
    while (( step < 3 )); do
      sleep 0.08 2>/dev/null || break
      printf '.'
      step=$((step + 1))
    done
  fi

  printf ' %sready%s\n' "$IB_COLOR_OK" "$IB_COLOR_RESET"
}

# Print a compact rule that respects small terminal widths.
ib_print_rule() {
  local columns rule_width rule
  columns=$(ib_terminal_width)
  rule_width=$((columns - 4))
  (( rule_width > 64 )) && rule_width=64
  (( rule_width < 1 )) && rule_width=1

  printf -v rule '%*s' "$rule_width" ''
  rule=${rule// /-}
  printf '  %s%s%s\n' "$IB_COLOR_ACCENT" "$rule" "$IB_COLOR_RESET"
}

# Print a label/value row and shorten unusually long values to fit the window.
ib_print_kv() {
  local label=$1
  local value=${2:-Unavailable}
  local columns prefix value_width

  columns=$(ib_terminal_width)
  printf -v prefix '  %-13s : ' "$label"

  # On very narrow windows, stack the value instead of forcing a wrapped row.
  if (( columns < 36 )); then
    value_width=$((columns - 4))
    if (( value_width >= 4 && ${#value} > value_width )); then
      value="${value:0:$((value_width - 3))}..."
    fi
    printf '  %s\n    %s\n' "$label" "$value"
    return 0
  fi

  value_width=$((columns - ${#prefix}))
  if (( value_width >= 4 && ${#value} > value_width )); then
    value="${value:0:$((value_width - 3))}..."
  fi

  printf '%s%s\n' "$prefix" "$value"
}
