# Local, read-only system information helpers for the startup display.
# No values are transmitted, and no security scans are performed.

ib_detect_user() {
  local detected=''

  if ib_has_command id; then
    detected=$(id -un 2>/dev/null || :)
  fi

  if [[ -n $detected ]]; then
    printf '%s\n' "$detected"
  elif [[ ${EUID+x} ]]; then
    printf 'uid %s\n' "$EUID"
  else
    printf '%s\n' 'Unavailable'
  fi
}

ib_detect_hostname() {
  local detected=''

  if ib_has_command hostname; then
    detected=$(hostname 2>/dev/null || :)
  fi
  if [[ -z $detected ]] && ib_has_command uname; then
    detected=$(uname -n 2>/dev/null || :)
  fi

  printf '%s\n' "${detected:-Unavailable}"
}

ib_detect_os() {
  local detected=''

  # os-release is the standard Linux distribution identification file.
  if [[ -r /etc/os-release ]]; then
    detected=$(
      (
        # shellcheck disable=SC1091
        . /etc/os-release
        printf '%s' "${PRETTY_NAME:-}"
      ) 2>/dev/null || :
    )
  fi

  if [[ -z $detected ]] && ib_has_command uname; then
    detected=$(uname -s 2>/dev/null || :)
  fi

  printf '%s\n' "${detected:-Unavailable}"
}

ib_detect_kernel() {
  if ib_has_command uname; then
    uname -r 2>/dev/null || printf '%s\n' 'Unavailable'
  else
    printf '%s\n' 'Unavailable'
  fi
}

ib_detect_architecture() {
  if ib_has_command uname; then
    uname -m 2>/dev/null || printf '%s\n' 'Unavailable'
  else
    printf '%s\n' 'Unavailable'
  fi
}

ib_detect_shell() {
  if [[ -n ${BASH_VERSION:-} ]]; then
    printf 'Bash %s\n' "${BASH_VERSION%%(*}"
  else
    printf '%s\n' 'Unavailable'
  fi
}

# Python is optional: query it only if an interpreter is installed.
ib_detect_python() {
  local detected=''

  if ib_has_command python3; then
    detected=$(python3 --version 2>&1 || :)
  elif ib_has_command python; then
    detected=$(python --version 2>&1 || :)
  fi

  printf '%s\n' "${detected:-Not installed}"
}

ib_detect_uptime() {
  local raw_seconds seconds days hours minutes

  if [[ -r /proc/uptime ]]; then
    IFS=' ' read -r raw_seconds _ < /proc/uptime || raw_seconds=''
    raw_seconds=${raw_seconds%%.*}

    if [[ $raw_seconds =~ ^[0-9]+$ ]]; then
      seconds=$((10#$raw_seconds))
      days=$((seconds / 86400))
      hours=$(((seconds % 86400) / 3600))
      minutes=$(((seconds % 3600) / 60))

      if (( days > 0 )); then
        printf '%dd %02dh %02dm\n' "$days" "$hours" "$minutes"
      elif (( hours > 0 )); then
        printf '%dh %02dm\n' "$hours" "$minutes"
      else
        printf '%dm\n' "$minutes"
      fi
      return 0
    fi
  fi

  if ib_has_command uptime; then
    local fallback=''
    fallback=$(uptime -p 2>/dev/null || :)
    if [[ -n $fallback ]]; then
      printf '%s\n' "$fallback"
      return 0
    fi
  fi

  printf '%s\n' 'Unavailable'
}

# Report local route configuration only; this is not an internet connectivity test.
ib_detect_network() {
  local route4='' route6=''

  if ib_has_command ip; then
    route4=$(ip -4 route show default 2>/dev/null || :)
    route6=$(ip -6 route show default 2>/dev/null || :)
    if [[ -n $route4 || -n $route6 ]]; then
      printf '%s\n' 'DEFAULT ROUTE DETECTED'
      return 0
    fi
  fi

  local observed=0
  local interface destination gateway flags remainder flag_value

  if [[ -r /proc/net/route ]]; then
    observed=1
    local first_line=1
    while IFS=$' \t' read -r interface destination gateway flags remainder; do
      if (( first_line )); then
        first_line=0
        continue
      fi
      [[ $destination == '00000000' && $flags =~ ^[[:xdigit:]]+$ ]] || continue
      flag_value=$((16#$flags))
      if (( flag_value & 1 )); then
        printf '%s\n' 'DEFAULT ROUTE DETECTED'
        return 0
      fi
    done < /proc/net/route
  fi

  local destination6 prefix6 source6 source_prefix6 next_hop metric ref_count use_count flags6
  if [[ -r /proc/net/ipv6_route ]]; then
    observed=1
    while read -r destination6 prefix6 source6 source_prefix6 next_hop metric ref_count use_count flags6; do
      [[ $destination6 == '00000000000000000000000000000000' && $prefix6 == '00' ]] || continue
      [[ $flags6 =~ ^[[:xdigit:]]+$ ]] || continue
      flag_value=$((16#$flags6))
      if (( flag_value & 1 )); then
        printf '%s\n' 'DEFAULT ROUTE DETECTED'
        return 0
      fi
    done < /proc/net/ipv6_route
  fi

  if (( observed )); then
    printf '%s\n' 'NO DEFAULT ROUTE DETECTED'
  else
    printf '%s\n' 'UNAVAILABLE'
  fi
}
