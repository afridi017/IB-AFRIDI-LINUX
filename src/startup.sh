#!/usr/bin/env bash
# IB AFRIDI OS startup display. This file is sourced from an interactive Bash
# configuration; it never runs in non-interactive shells or without a TTY.

case ${-:-} in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

[[ -t 1 ]] || return 0 2>/dev/null || exit 0

_IB_AFRIDI_SRC_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return 0 2>/dev/null || exit 0
_IB_AFRIDI_ROOT=$(cd -- "$_IB_AFRIDI_SRC_DIR/.." && pwd -P) || return 0 2>/dev/null || exit 0

[[ -r $_IB_AFRIDI_ROOT/config/theme.sh ]] || return 0 2>/dev/null || exit 0
[[ -r $_IB_AFRIDI_SRC_DIR/utils.sh ]] || return 0 2>/dev/null || exit 0
[[ -r $_IB_AFRIDI_SRC_DIR/system_info.sh ]] || return 0 2>/dev/null || exit 0

# shellcheck source=config/theme.sh
. "$_IB_AFRIDI_ROOT/config/theme.sh"
# shellcheck source=src/utils.sh
. "$_IB_AFRIDI_SRC_DIR/utils.sh"
# shellcheck source=src/system_info.sh
. "$_IB_AFRIDI_SRC_DIR/system_info.sh"

ib_init_colors
ib_clear_screen
ib_show_animation
printf '\n'

_IB_AFRIDI_COLUMNS=$(ib_terminal_width)
if (( _IB_AFRIDI_COLUMNS >= 53 )) && [[ -r $_IB_AFRIDI_ROOT/assets/logo.txt ]]; then
  while IFS= read -r _IB_AFRIDI_LOGO_LINE || [[ -n $_IB_AFRIDI_LOGO_LINE ]]; do
    printf '  %s%s%s\n' "$IB_COLOR_ACCENT" "$_IB_AFRIDI_LOGO_LINE" "$IB_COLOR_RESET"
  done < "$_IB_AFRIDI_ROOT/assets/logo.txt"
else
  # A compact fallback keeps the wordmark readable on narrow terminal windows.
  printf '  %s%s%s\n' "$IB_COLOR_ACCENT" "$IB_BRAND" "$IB_COLOR_RESET"
fi

# Keep Unicode bullets where the active locale is UTF-8; otherwise use ASCII.
_IB_AFRIDI_LOCALE=${LC_ALL:-${LC_CTYPE:-${LANG:-}}}
if [[ $_IB_AFRIDI_LOCALE != *UTF-8* && $_IB_AFRIDI_LOCALE != *UTF8* ]]; then
  IB_TAGLINE=${IB_TAGLINE// • / | }
  IB_SPECIALTIES=${IB_SPECIALTIES// • / | }
fi

ib_print_rule
printf '  %s%s%s\n' "$IB_COLOR_BOLD" "$IB_BRAND_NAME" "$IB_COLOR_RESET"
printf '  Creator: %s\n' "$IB_CREATOR"
printf '  %s\n' "$IB_TAGLINE"
printf '  %s\n' "$IB_SPECIALTIES"

_IB_AFRIDI_USER=$(ib_detect_user)
_IB_AFRIDI_HOST=$(ib_detect_hostname)
_IB_AFRIDI_OS=$(ib_detect_os)
_IB_AFRIDI_KERNEL=$(ib_detect_kernel)
_IB_AFRIDI_ARCH=$(ib_detect_architecture)
_IB_AFRIDI_SHELL=$(ib_detect_shell)
_IB_AFRIDI_PYTHON=$(ib_detect_python)
_IB_AFRIDI_UPTIME=$(ib_detect_uptime)
_IB_AFRIDI_NETWORK=$(ib_detect_network)

printf '\n  %s[ SYSTEM INFO ]%s\n' "$IB_COLOR_ACCENT" "$IB_COLOR_RESET"
ib_print_kv 'USER' "$_IB_AFRIDI_USER"
ib_print_kv 'HOSTNAME' "$_IB_AFRIDI_HOST"
ib_print_kv 'OS' "$_IB_AFRIDI_OS"
ib_print_kv 'KERNEL' "$_IB_AFRIDI_KERNEL"
ib_print_kv 'ARCHITECTURE' "$_IB_AFRIDI_ARCH"
ib_print_kv 'SHELL' "$_IB_AFRIDI_SHELL"
ib_print_kv 'PYTHON' "$_IB_AFRIDI_PYTHON"
ib_print_kv 'UPTIME' "$_IB_AFRIDI_UPTIME"

printf '\n  %s[ SYSTEM ]%s\n' "$IB_COLOR_ACCENT" "$IB_COLOR_RESET"
ib_print_kv 'OS' "$_IB_AFRIDI_OS"
# This project does not run checks, so it must not claim a security-ready state.
ib_print_kv 'SECURITY' 'NOT ASSESSED (no scan run)'
# A default route is local configuration, not proof of internet reachability.
ib_print_kv 'NETWORK' "$_IB_AFRIDI_NETWORK"
ib_print_kv 'TERMINAL' 'INTERACTIVE TTY'
ib_print_kv 'MODE' 'INTERACTIVE SHELL'

printf '\n  %s%s%s\n' "$IB_COLOR_MUTED" "$IB_QUOTE" "$IB_COLOR_RESET"
ib_print_rule
printf '\n'

# The prompt uses Bash's live user, host, working-directory and root markers.
# It is branding only; it does not change the account or machine hostname.
if (( IB_COLOR_ENABLED )); then
  PS1='\['"$IB_COLOR_ACCENT"'\]\u@\h\['"$IB_COLOR_MUTED"'\]:\w\['"$IB_COLOR_ACCENT"'\]\$\['"$IB_COLOR_RESET"'\] '
else
  PS1='\u@\h:\w\$ '
fi

# Leave only PS1 behind; helper names and theme variables should not pollute the
# user's interactive shell namespace.
unset -f ib_has_command ib_terminal_width ib_init_colors ib_clear_screen \
  ib_show_animation ib_print_rule ib_print_kv ib_detect_user ib_detect_hostname \
  ib_detect_os ib_detect_kernel ib_detect_architecture ib_detect_shell \
  ib_detect_python ib_detect_uptime ib_detect_network
unset IB_BRAND_NAME IB_BRAND IB_CREATOR IB_TAGLINE IB_SPECIALTIES IB_QUOTE
unset IB_COLOR_ENABLED IB_COLOR_RESET IB_COLOR_ACCENT IB_COLOR_MUTED IB_COLOR_OK IB_COLOR_BOLD
unset _IB_AFRIDI_SRC_DIR _IB_AFRIDI_ROOT _IB_AFRIDI_COLUMNS _IB_AFRIDI_LOGO_LINE
unset _IB_AFRIDI_LOCALE _IB_AFRIDI_USER _IB_AFRIDI_HOST _IB_AFRIDI_OS _IB_AFRIDI_KERNEL
unset _IB_AFRIDI_ARCH _IB_AFRIDI_SHELL _IB_AFRIDI_PYTHON _IB_AFRIDI_UPTIME _IB_AFRIDI_NETWORK
