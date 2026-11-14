#!/bin/bash

# ============================================================
# JW LIBRARY ROLL-BACK
# Installs JW Library 15.6 on a connected iPhone/iPad from a Mac.
#
# Run it as a file (NOT piped), because it asks you questions:
#   bash rollback.sh
#   /bin/bash -c "$(curl -fsSL <url>)"
# ============================================================

set -Eeuo pipefail

VERSION="2.0.0"
APP_ID="672417831"
VERSION_ID="878901217"
MIN_IPATOOL="2.8.0"
IPA="$HOME/Downloads/JWLibrary-15.6.ipa"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
HOMEBREW_UNINSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"

MODE=""                 # "full" (download + install) or "saved" (use own IPA)
TOTAL_STEPS=6           # becomes 4 in "saved" mode
CURRENT_STEP=0
CURRENT_STAGE="Starting"
STAGE_KIND="other"
START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
BREW=""
TOOLS=()
SHOWN_TOOLS=()
NEED_TOOLS=1
BREW_IS_NEW=0           # 1 if this installer installed Homebrew itself
BREW_BEFORE=""          # file: the formulae that existed before our install
NEW_FORMULAE=()         # formulae this installer added (for the optional cleanup)
CALLOUT_LEAD=1          # 0 = no blank line above a callout (see important_top)
RUN_LOG=""              # output of the command run_quiet is hiding
RUN_PID=""

# ============================================================
# COLOURS (readable on both light and dark Terminal themes)
# Coloured bars with fixed backgrounds are used for emphasis,
# so nothing depends on the theme's text colours.
#
#   blue    = title          yellow = heads-up (important)
#   cyan    = information    green  = success / done
#   orange  = a problem (with an X), deliberately not full red
#             so that it gets attention without alarming
# ============================================================

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RESET=$'\033[0m'
    BOLD=$'\033[1m'
    GRAY=$'\033[90m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    CYAN=$'\033[36m'
    ORANGE=$'\033[38;5;208m'
    BAND_TITLE=$'\033[1;37;44m'      # white on blue
    BAND_WARN=$'\033[1;30;43m'       # black on yellow
    BAND_INFO=$'\033[1;30;46m'       # black on cyan
    BAND_OK=$'\033[1;30;42m'         # black on green
    BAND_PROBLEM=$'\033[1;30;48;5;208m'   # black on orange
    BAND_NEUTRAL=$'\033[1;30;47m'   # black on light gray
else
    RESET="" BOLD="" GRAY="" GREEN="" YELLOW="" CYAN="" ORANGE=""
    BAND_TITLE="" BAND_WARN="" BAND_INFO="" BAND_OK="" BAND_PROBLEM="" BAND_NEUTRAL=""
fi

# Marks every place where the installer waits for the user.
ARROW="${YELLOW}▶${RESET}"

RULE=""
_i=0
while [ "$_i" -lt 60 ]; do
    RULE="${RULE}━"
    _i=$((_i + 1))
done

# ============================================================
# DISPLAY FUNCTIONS
#
# Every screen is kept short (about 22 lines) so that it fits in a
# small Terminal window. A terminal always scrolls to the prompt at
# the bottom, so long screens would hide their top part.
# ============================================================

clear_screen() {
    if [ -t 1 ]; then
        printf '\033[2J\033[H'
    fi
}

# Full-width coloured bar. Text must be plain ASCII (for padding).
band() {
    printf '%s %-58s %s\n' "$1" "$2" "$RESET"
}

# Coloured title bar followed by a left-barred block of lines.
# callout BAND_COLOUR BAR_COLOUR "TITLE" "line" "line" ...
callout() {
    local band_c="$1" bar_c="$2" title="$3" l
    shift 3
    if [ "$CALLOUT_LEAD" -eq 1 ]; then
        echo
    fi
    printf '  %s %-56s %s\n' "$band_c" "$title" "$RESET"
    for l in "$@"; do
        echo "  ${bar_c}┃${RESET} $l"
    done
    echo
}

important() { callout "$BAND_WARN" "$YELLOW" "$@"; }

# For a callout directly under a screen header, which already ends with a
# blank line (otherwise there would be two).
important_top() {
    CALLOUT_LEAD=0
    callout "$BAND_WARN" "$YELLOW" "$@"
    CALLOUT_LEAD=1
}

note() { callout "$BAND_INFO" "$CYAN" "$@"; }

# Something did not work. An orange title bar with an X inside it (the
# counterpart of the green check mark), and bold lines so it stands out.
# problem "TITLE" "line" "line" ...
problem() {
    local title="$1" l
    shift
    echo
    printf '  %s ✖ %-54s %s\n' "$BAND_PROBLEM" "$title" "$RESET"
    for l in "$@"; do
        echo "  ${ORANGE}┃${RESET} ${BOLD}${l}${RESET}"
    done
    echo
}

say() { echo "  $*"; }

# A highlighted line for a choice the user has to pick from.
option_line() {
    printf '  %s %-56s %s\n' "$BAND_INFO" "$1" "$RESET"
}

# One paragraph with no manual line breaks. It is wrapped to the width of
# the Terminal window, and every line keeps the 2-space indent.
para() {
    local cols
    cols="$(tput cols 2>/dev/null || echo 80)"
    case "$cols" in
        ''|*[!0-9]*) cols=80 ;;
    esac
    [ "$cols" -lt 40 ] && cols=40
    printf '%s\n' "$*" | fold -s -w $((cols - 4)) | sed 's/^/  /;s/ *$//'
}

ok() { echo; echo "  ${GREEN}✔ $*${RESET}"; }

progress_dots() {
    local i=1 out=""
    while [ "$i" -le "$TOTAL_STEPS" ]; do
        if [ "$i" -lt "$CURRENT_STEP" ]; then
            out="${out}${GREEN}●${RESET} "
        elif [ "$i" -eq "$CURRENT_STEP" ]; then
            out="${out}${BOLD}◉${RESET} "
        else
            out="${out}${GRAY}○${RESET} "
        fi
        i=$((i + 1))
    done
    echo "$out"
}

banner() {
    clear_screen
    band "$BAND_TITLE" "$(printf '%-48s%10s' "JW LIBRARY ROLL-BACK" "v$VERSION")"
    echo
}

# Clears the screen and draws the current step's header (5 lines).
step_header() {
    clear_screen
    band "$BAND_TITLE" "$(printf '%-44s%14s' "JW LIBRARY ROLL-BACK" "STEP $CURRENT_STEP OF $TOTAL_STEPS")"
    echo
    echo "  $(progress_dots) ${BOLD}${CURRENT_STAGE}${RESET}"
    echo "  ${GRAY}${RULE}${RESET}"
    echo
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_STAGE="$1"
    STAGE_KIND="${2:-other}"
    step_header
}

pause() {
    local _
    echo
    read -r -p "  ${ARROW} ${BOLD}Press Enter to continue...${RESET} " _
    echo
}

confirm() {
    local prompt="$1" default="${2:-}" hint answer
    case "$default" in
        y) hint="Y/n" ;;
        n) hint="y/N" ;;
        *) hint="y/n" ;;
    esac
    while true; do
        read -r -p "  ${ARROW} ${BOLD}${prompt}${RESET} [${hint}]: " answer
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            "")
                case "$default" in
                    y) return 0 ;;
                    n) return 1 ;;
                esac
                echo "  Please type y or n."
                ;;
            *) echo "  Please type y or n." ;;
        esac
    done
}

# Returns 0 to try again, 1 to quit.
retry_or_quit() {
    local a
    echo
    read -r -p "  ${ARROW} ${BOLD}Press Enter to try again, or type q to quit:${RESET} " a
    case "$a" in
        [Qq]*) return 1 ;;
        *) return 0 ;;
    esac
}

# ============================================================
# TOOL HELPERS
# ============================================================

find_brew() {
    local p
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return 0
    fi
    for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 1
}

# Makes Homebrew's commands available in this Terminal window (it may be
# installed but not on the PATH yet). Needs BREW to be set.
load_brew() {
    local brew_env
    brew_env="$("$BREW" shellenv)"   # separate step, so a failure is not hidden by eval
    eval "$brew_env"
}

ipatool_version() {
    ipatool --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true
}

# version_ge A B  ->  success if A >= B  (both like 2.8.0)
version_ge() {
    local a1 a2 a3 b1 b2 b3
    IFS=. read -r a1 a2 a3 <<< "$1"
    IFS=. read -r b1 b2 b3 <<< "$2"
    a2="${a2:-0}"; a3="${a3:-0}"; b2="${b2:-0}"; b3="${b3:-0}"
    if [ "$a1" -ne "$b1" ]; then [ "$a1" -gt "$b1" ]; return; fi
    if [ "$a2" -ne "$b2" ]; then [ "$a2" -gt "$b2" ]; return; fi
    [ "$a3" -ge "$b3" ]
}

install_homebrew() {
    local script
    script="$(curl -fsSL "$HOMEBREW_INSTALL_URL")" || return 1
    /bin/bash -c "$script"
}

# A real .ipa is a zip archive, which always starts with "PK".
is_valid_ipa() {
    [ -s "$1" ] && [ "$(head -c 2 "$1")" = "PK" ]
}

# Opens the standard Mac "choose a file" window. Prints the chosen path;
# fails quietly if the window is canceled.
pick_file() {
    osascript -e 'POSIX path of (choose file with prompt "Select your saved JW Library 15.6 file (.ipa)" of type {"ipa"})' 2>/dev/null
}

download_ipa() {
    rm -f "$IPA"
    if ipatool download \
        --app-id "$APP_ID" \
        --external-version-id "$VERSION_ID" \
        --output "$IPA" \
        --purchase && [ -s "$IPA" ]; then
        return 0
    fi
    rm -f "$IPA"
    return 1
}

# ============================================================
# QUIET RUNNER
# Runs a command in the background, hides its (technical) output and shows
# a progress bar instead. The output is kept in RUN_LOG, and is only shown
# in the diagnostic information if something fails.
# ============================================================

# Last percentage ("45%") mentioned in the hidden output, if any.
log_percent() {
    tr '\r' '\n' < "$1" 2>/dev/null | grep -Eo '[0-9]{1,3}%' | tail -n 1 | tr -d '%' || true
}

# progress_bar PERCENT_OR_EMPTY TICK
# A filled bar when the percentage is known, otherwise a moving block.
progress_bar() {
    local pct="$1" tick="$2" width=24 i=1 out="" filled start
    filled=$((${pct:-0} * width / 100))
    start=$((tick % (width + 6)))
    while [ "$i" -le "$width" ]; do
        if [ -n "$pct" ]; then
            if [ "$i" -le "$filled" ]; then
                out="${out}${CYAN}█${RESET}"
            else
                out="${out}${GRAY}░${RESET}"
            fi
        elif [ "$i" -gt $((start - 6)) ] && [ "$i" -le "$start" ]; then
            out="${out}${CYAN}█${RESET}"
        else
            out="${out}${GRAY}░${RESET}"
        fi
        i=$((i + 1))
    done
    printf '%s' "$out"
}

# run_quiet "What is happening" command args...
# Returns the command's own exit status.
run_quiet() {
    local label="$1" pid status=0 tick=0 pct="" last_pct="" started elapsed info
    shift

    RUN_LOG="$(mktemp "${TMPDIR:-/tmp}/jwrollback.XXXXXX")"
    ( trap - ERR; "$@" ) >"$RUN_LOG" 2>&1 &
    pid=$!
    RUN_PID="$pid"
    started=$SECONDS

    say "${BOLD}${label}${RESET}"
    while kill -0 "$pid" 2>/dev/null; do
        pct="$(log_percent "$RUN_LOG")"
        case "$pct" in
            ''|*[!0-9]*) pct="" ;;
        esac
        if [ -n "$pct" ] && [ "$pct" -le 100 ]; then
            if [ -z "$last_pct" ] || [ "$pct" -ge "$last_pct" ]; then
                last_pct="$pct"
            fi
        fi
        elapsed=$((SECONDS - started))
        info="$(printf '%d:%02d' $((elapsed / 60)) $((elapsed % 60)))"
        if [ -n "$last_pct" ]; then
            info="${last_pct}%  ${info}"
        fi
        if [ -t 1 ]; then
            printf '\r\033[K  %s  %s%s%s' "$(progress_bar "$last_pct" "$tick")" "$GRAY" "$info" "$RESET"
        fi
        tick=$((tick + 1))
        sleep 0.2
    done

    wait "$pid" || status=$?
    RUN_PID=""

    if [ "$status" -eq 0 ]; then
        if [ -t 1 ]; then
            printf '\r\033[K'
        fi
        echo "  ${GREEN}✔ Done${RESET}"
        rm -f "$RUN_LOG"
        RUN_LOG=""
    elif [ -t 1 ]; then
        printf '\r\033[K'
    fi
    return "$status"
}

# The work done behind the progress bar while the tools are installed.
install_tools_job() {
    local ver
    export HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1

    # A failed list refresh is not fatal: the install below may still work.
    brew update || true

    # Every command is checked explicitly: this job runs inside an "if",
    # where bash ignores "set -e", so a failure would otherwise go unnoticed.
    brew install -y ${TOOLS[@]+"${TOOLS[@]}"} || return 1

    # An old ipatool is not replaced by "install", so update it explicitly.
    if [ "$MODE" = "full" ]; then
        ver="$(ipatool_version)"
        if [ -n "$ver" ] && ! version_ge "$ver" "$MIN_IPATOOL"; then
            brew upgrade ipatool || return 1
        fi
    fi
    return 0
}

# join_and a b c  ->  "a, b and c"
join_and() {
    local n=$# i=0 out="" x
    for x in "$@"; do
        i=$((i + 1))
        if [ "$i" -eq 1 ]; then
            out="$x"
        elif [ "$i" -eq "$n" ]; then
            out="$out and $x"
        else
            out="$out, $x"
        fi
    done
    printf '%s' "$out"
}

# ------------------------------------------------------------
# OPTIONAL CLEANUP at the end: remove only what THIS run installed.
# ------------------------------------------------------------

# Remembers which formulae exist before we install anything. If the list
# cannot be read, BREW_BEFORE stays empty and nothing will be offered
# for removal (better to leave a tool behind than to remove one by mistake).
snapshot_formulae() {
    BREW_BEFORE="$(mktemp "${TMPDIR:-/tmp}/jwrollback.XXXXXX")"
    if ! brew list --formula >"$BREW_BEFORE" 2>/dev/null; then
        rm -f "$BREW_BEFORE"
        BREW_BEFORE=""
    fi
}

# Fills NEW_FORMULAE: everything installed now that was not there before
# (the tools and the helper packages that came with them).
find_new_formulae() {
    local f
    NEW_FORMULAE=()
    if [ -z "$BREW_BEFORE" ]; then
        return 0
    fi
    while IFS= read -r f; do
        if [ -n "$f" ]; then
            NEW_FORMULAE+=("$f")
        fi
    done < <(brew list --formula 2>/dev/null | grep -vxFf "$BREW_BEFORE" || true)
    return 0
}

remove_formulae_job() {
    export HOMEBREW_NO_ENV_HINTS=1
    brew uninstall --formula "$@" || return 1
}

uninstall_homebrew() {
    local script
    script="$(curl -fsSL "$HOMEBREW_UNINSTALL_URL")" || return 1
    /bin/bash -c "$script"
}

# Offered once the install is finished. Does nothing if this run did not
# install anything. Never fails the installer: a tool left behind is harmless.
offer_cleanup() {
    local removed=0

    if [ "$BREW_IS_NEW" -eq 0 ]; then
        find_new_formulae
        if [ "${#NEW_FORMULAE[@]}" -eq 0 ]; then
            return 0
        fi
    fi
    if [ "${#SHOWN_TOOLS[@]}" -eq 0 ]; then
        return 0
    fi

    callout "$BAND_NEUTRAL" "$GRAY" "OPTIONAL CLEANUP" \
        "You can remove the tools this installer installed." \
        "Running it again will reinstall them."

    if ! confirm "Remove the installed tools now?" n; then
        say "OK. Nothing was removed."
        return 0
    fi

    echo
    if [ "$BREW_IS_NEW" -eq 1 ]; then
        say "Homebrew will show what it removes and ask you to confirm:"
        say "type y. It may also ask for your Mac password"
        say "(nothing appears as you type)."
        say "A note about a few leftover folders can be ignored."
        echo
        if uninstall_homebrew; then
            removed=1
        fi
    else
        if run_quiet "Removing the tools" remove_formulae_job "${NEW_FORMULAE[@]}"; then
            removed=1
        fi
    fi

    echo
    if [ "$removed" -eq 1 ]; then
        echo "  ${GREEN}✔ Removed.${RESET}"
    else
        note "NOT EVERYTHING COULD BE REMOVED" \
            "This is harmless. The tools can stay on your Mac." \
            "You can remove them later if you wish."
    fi
    return 0
}

NETWORK_HINTS_1="Check your Internet connection."
NETWORK_HINTS_2="If you use a VPN, make sure it is ON and routes ALL traffic"
NETWORK_HINTS_3="(not only the browser), then try again."

# retry_cmd "PROBLEM TITLE" "hint" "hint" ... -- command args...
# Runs the command; on failure shows a calm message and offers a retry.
retry_cmd() {
    local title="$1"
    shift
    local hints=()
    while [ "$1" != "--" ]; do
        hints+=("$1")
        shift
    done
    shift

    while true; do
        if "$@"; then
            return 0
        fi
        problem "$title" ${hints[@]+"${hints[@]}"}
        retry_or_quit || fail_diag "Stopped. You can run the installer again whenever you are ready."
    done
}

# Makes sure exactly one device is connected AND has trusted this Mac.
# Prints something only when there is a problem.
ensure_device() {
    local devices count
    while true; do
        devices="$(idevice_id -l 2>/dev/null || true)"
        count="$(printf '%s\n' "$devices" | grep -c . || true)"

        if [ "$count" -eq 0 ]; then
            problem "NO IPHONE / IPAD FOUND" \
                "1. Connect your device to this Mac with a USB cable." \
                "2. Switch it on and unlock it." \
                "3. If asked \"Trust This Computer?\", tap Trust and enter" \
                "   your device passcode."
        elif [ "$count" -gt 1 ]; then
            problem "MORE THAN ONE DEVICE FOUND" \
                "Please disconnect the extra devices." \
                "Only one iPhone or iPad should be connected."
        elif ! idevicepair validate >/dev/null 2>&1; then
            # Asks the device to show the Trust prompt (if not trusted yet).
            idevicepair pair >/dev/null 2>&1 || true
            problem "TRUST THIS COMPUTER ON YOUR DEVICE" \
                "Your device is connected, but it has not been set to trust" \
                "this Mac yet." \
                "1. Unlock your iPhone or iPad." \
                "2. Tap \"Trust\" when asked, then enter your passcode."
        else
            return 0
        fi

        retry_or_quit || fail_diag "Stopped: no trusted device was found." \
            "Reconnect your device, unlock it, tap Trust, then run again."
    done
}

# ============================================================
# ERROR HANDLING
# ============================================================

print_diagnostics() {
    set +e
    local ver
    ver="$(ipatool_version)"

    echo "  ${BOLD}Diagnostic information${RESET}"
    echo "  ${GRAY}${RULE}${RESET}"
    echo "  Time:       $(date '+%Y-%m-%d %H:%M:%S')  (started $START_TIME)"
    echo "  Stage:      $CURRENT_STAGE (step $CURRENT_STEP of $TOTAL_STEPS, mode: ${MODE:-not chosen})"
    echo "  Script:     v$VERSION"
    echo "  Mac:        macOS $(sw_vers -productVersion 2>/dev/null || echo unknown), $(uname -m), bash $BASH_VERSION"
    echo "  Homebrew:   $(command -v brew 2>/dev/null || echo 'not found')"
    echo "  ipatool:    $(command -v ipatool 2>/dev/null || echo 'not found') ${ver:+(version $ver)}"
    echo "  installer:  $(command -v ideviceinstaller 2>/dev/null || echo 'not found')"
    if command -v idevice_id >/dev/null 2>&1; then
        echo "  Device(s):  $(idevice_id -l 2>/dev/null | tr '\n' ' ')"
        if idevicepair validate >/dev/null 2>&1; then
            echo "  Trusted:    yes"
        else
            echo "  Trusted:    no / unknown"
        fi
    else
        echo "  Device(s):  idevice_id not available"
    fi
    if [ -s "$IPA" ]; then
        echo "  IPA file:   $(ls -lh "$IPA" | awk '{print $5}') at $IPA"
    else
        echo "  IPA file:   not found or empty"
    fi
    if [ -n "${RUN_LOG:-}" ] && [ -s "$RUN_LOG" ]; then
        echo "  Last messages from the failed step:"
        tr '\r' '\n' < "$RUN_LOG" | LC_ALL=C sed $'s/\033\\[[0-9;]*[A-Za-z]//g' |
            grep -v '^[[:space:]]*$' | tail -n 8 | cut -c1-100 | sed 's/^/    /'
    fi
    echo "  ${GRAY}${RULE}${RESET}"
    echo
}

# Short, calm stop (for things the user can fix by themselves).
fail() {
    trap - ERR
    problem "COULD NOT CONTINUE" "$@"
    exit 1
}

# Same, plus a compact block of diagnostics for the guide author.
fail_diag() {
    trap - ERR
    set +e
    problem "COULD NOT CONTINUE" "$@" \
        "" \
        "If you need help or would like to report an issue, copy" \
        "the diagnostic information below and send it to the author."
    print_diagnostics
    exit 1
}

# The user chose to stop (e.g. answered "n"). Not an error, so exit code 0.
cancel() {
    trap - ERR
    callout "$BAND_INFO" "$CYAN" "STOPPED" "$@"
    exit 0
}

# classify_error "<failed command>" "<stage kind>"
# The command's FIRST WORD decides (so "brew install ipatool" is Homebrew,
# not Apple). If the command is not recognisable (assignments, eval...),
# the stage kind decides.
classify_error() {
    local cmd="$1" kind="${2:-other}" first
    first="${cmd%% *}"
    first="${first##*/}"

    case "$first" in
        curl)                                         echo "NETWORK"; return ;;
        brew)                                         echo "HOMEBREW"; return ;;
        ipatool)                                      echo "APPLE"; return ;;
        ideviceinstaller|idevice_id|idevicepair)      echo "DEVICE"; return ;;
    esac

    case "$kind" in
        homebrew|tools)    echo "HOMEBREW" ;;
        apple|download)    echo "APPLE" ;;
        device|install)    echo "DEVICE" ;;
        *)                 echo "UNKNOWN" ;;
    esac
}

print_advice() {
    case "$1" in
        NETWORK)
            say "${BOLD}Likely cause:${RESET} Internet connection."
            say "  $NETWORK_HINTS_1"
            say "  $NETWORK_HINTS_2"
            say "  $NETWORK_HINTS_3"
            ;;
        HOMEBREW)
            say "${BOLD}Likely cause:${RESET} installing the required tools."
            say "  $NETWORK_HINTS_1"
            say "  $NETWORK_HINTS_2"
            say "  $NETWORK_HINTS_3"
            ;;
        APPLE)
            say "${BOLD}Likely cause:${RESET} Apple Account or App Store."
            say "  Check your Apple Account email, password and verification code."
            say "  Also check your Internet connection / VPN."
            ;;
        DEVICE)
            say "${BOLD}Likely cause:${RESET} your iPhone or iPad."
            say "  Check the USB cable, unlock the device, tap Trust if asked."
            say "  Make sure the old JW Library app is deleted."
            ;;
        *)
            say "${BOLD}Likely cause:${RESET} could not be identified automatically."
            ;;
    esac
}

# Safety net for any failure that is not handled with a friendly message.
error_handler() {
    local exit_code="$1" failed_line="$2" failed_command="$3" kind
    trap - ERR
    set +e

    kind="$(classify_error "$failed_command" "$STAGE_KIND")"

    problem "SOMETHING WENT WRONG" \
        "The installer stopped at: ${CURRENT_STAGE} (step $CURRENT_STEP of $TOTAL_STEPS)." \
        "Your IPA file, if any, has been kept."
    print_advice "$kind"
    echo
    say "Fix this, then run the installer again."
    say "If you need help or would like to report an issue, copy"
    say "the diagnostic information below and send it to the author."
    echo
    echo "  ${GRAY}Failed command: ${failed_command}  (exit code ${exit_code}, script line ${failed_line})${RESET}"
    echo
    print_diagnostics
    exit "$exit_code"
}

trap 'error_handler "$?" "$LINENO" "$BASH_COMMAND"' ERR
on_interrupt() {
    trap - ERR
    if [ -n "$RUN_PID" ]; then
        pkill -P "$RUN_PID" 2>/dev/null || true
        kill "$RUN_PID" 2>/dev/null || true
    fi
    echo; echo
    echo "  Stopped. You can run the installer again at any time."
    echo
    exit 130
}
trap on_interrupt INT

# ============================================================
# START SCREENS
# ============================================================

# Screen 1: welcome + choice of how to start.
choose_mode() {
    local ans
    banner

    say "${BOLD}Welcome!${RESET}"
    say "This installer rolls JW Library on your iPhone or iPad"
    say "back to version 15.6."
    echo
    say "${BOLD}How would you like to start?${RESET}"
    echo
    option_line "1  Full install"
    say "   Downloads JW Library 15.6 from the App Store,"
    say "   then installs it. (Needs your Apple Account.)"
    echo
    option_line "2  I already have a saved JW Library 15.6 file (.ipa)"
    say "   Skips the Apple sign-in and the download. You will"
    say "   be asked to select the file if it is not in Downloads."
    echo

    while true; do
        read -r -p "  ${ARROW} ${BOLD}Type 1 or 2, then press Enter:${RESET} " ans
        case "$ans" in
            1) MODE="full";  TOTAL_STEPS=6; return 0 ;;
            2) MODE="saved"; TOTAL_STEPS=4; return 0 ;;
            *) say "Please type 1 or 2." ;;
        esac
    done
}

# Screen 1b (option 2 only): find the saved file. It is checked quietly in
# Downloads first; only if it is not there is the user asked to pick it.
choose_saved_ipa() {
    local issue="" ans picked

    if is_valid_ipa "$IPA"; then
        return 0
    fi

    while true; do
        banner
        important_top "CHOOSE YOUR SAVED FILE" \
            "Please use the file picker to select your" \
            "previously saved .ipa file."

        if [ -n "$issue" ]; then
            problem "FILE NOT READY" "$issue"
        fi

        echo
        read -r -p "  ${ARROW} ${BOLD}Press Enter to choose the file, or type q to quit:${RESET} " ans
        case "$ans" in
            [Qq]*) cancel "Stopped. Nothing was changed." ;;
        esac

        picked="$(pick_file)" || picked=""
        if [ -z "$picked" ]; then
            issue="No file was selected."
        elif is_valid_ipa "$picked"; then
            IPA="$picked"
            return 0
        else
            issue="That file does not look like a valid .ipa file."
        fi
    done
}

# Quietly checks what is already on this Mac. Fills TOOLS (what to install)
# and SHOWN_TOOLS (what the user is told). If nothing is missing, the whole
# "required tools" step is skipped and the step numbers are adjusted.
check_tools() {
    local ver
    BREW="$(find_brew || true)"

    # Homebrew may be installed but not yet on this Terminal's PATH.
    if [ -n "$BREW" ]; then
        load_brew
    fi

    if [ "$MODE" = "full" ]; then
        ver=""
        if command -v ipatool >/dev/null 2>&1; then
            ver="$(ipatool_version)"
        fi
        if [ -z "$ver" ] || ! version_ge "$ver" "$MIN_IPATOOL"; then
            TOOLS+=(ipatool)
            SHOWN_TOOLS+=("ipatool")
        fi
    fi

    if ! command -v ideviceinstaller >/dev/null 2>&1 ||
       ! command -v idevice_id >/dev/null 2>&1 ||
       ! command -v idevicepair >/dev/null 2>&1; then
        TOOLS+=(ideviceinstaller)
        SHOWN_TOOLS+=("ideviceinstaller")
    fi

    if [ "${#TOOLS[@]}" -eq 0 ]; then
        # Nothing to install, so Homebrew is not needed either.
        NEED_TOOLS=0
        TOTAL_STEPS=$((TOTAL_STEPS - 1))
    elif [ -z "$BREW" ]; then
        # The tools are installed through Homebrew, which goes first.
        SHOWN_TOOLS=("Homebrew" "${SHOWN_TOOLS[@]}")
    fi
}

# Screen 2: what will happen + backup reminder.
show_intro() {
    local n=1
    banner

    if [ "$MODE" = "saved" ]; then
        say "Your saved file was found here:"
        say "${BOLD}${CYAN}$IPA${RESET}"
        echo
    fi

    say "${BOLD}Here is what will happen:${RESET}"
    echo
    if [ "$NEED_TOOLS" -eq 1 ]; then
        say " $n. Install the required tools"
        n=$((n + 1))
    fi
    say " $n. Connect your iPhone or iPad"
    n=$((n + 1))
    if [ "$MODE" = "full" ]; then
        say " $n. Sign in to your Apple Account"
        n=$((n + 1))
        say " $n. Download JW Library 15.6"
        n=$((n + 1))
    fi
    say " $n. Prepare your device"
    n=$((n + 1))
    say " $n. Install JW Library 15.6"

    important "BACK UP YOUR JW LIBRARY DATA FIRST!" \
        "On your device, open JW Library and go to:" \
        "${BOLD}Personal Study > Create Backup${RESET}" \
        "" \
        "You will restore this backup afterwards and" \
        "re-download your Bibles and publications."

    confirm "Have you created a JW Library backup?" ||
        cancel "No problem. Create the backup first:" \
               "Personal Study > Create Backup" \
               "Then run the installer again."
}

# ============================================================
# STEPS THAT ONLY EXIST IN THE FULL INSTALL
# ============================================================

step_apple_login() {
    step "Sign in to your Apple Account" apple

    say "Terminal will ask, one after another, for your:"
    say " 1. Apple Account email"
    say " 2. Apple Account password"
    say " 3. Verification code, if Apple asks for one"

    note "PLEASE NOTE" \
        "After you enter your Apple Account details, a Mac window" \
        "may pop up that asks you to enter the password for your" \
        "keychain. Don't be alarmed, this is normal. Just type the" \
        "password you use to unlock this Mac, then click" \
        "\"Always Allow\" so it won't ask again."

    say "This installer never sees or stores your password."

    pause

    while true; do
        if ipatool auth login; then
            break
        fi
        problem "SIGN-IN DID NOT WORK" \
            "Check your email, password, verification code" \
            "and Internet connection." \
            "$NETWORK_HINTS_2" \
            "$NETWORK_HINTS_3"
        retry_or_quit || fail_diag "Sign-in was not completed."
    done

    ok "Signed in to your Apple Account."
    sleep 2
}

step_download() {
    local use_existing=0

    step "Download JW Library 15.6" download

    if [ -s "$IPA" ]; then
        say "A downloaded copy was found:"
        say "${GRAY}$IPA${RESET}"
        echo
        if confirm "Reuse it instead of downloading again?"; then
            use_existing=1
        fi
        echo
    fi

    if [ "$use_existing" -eq 1 ]; then
        ok "Using the existing file."
    else
        say "Downloading from the App Store. This may take a few minutes."
        echo

        retry_cmd "THE DOWNLOAD DID NOT FINISH" \
            "$NETWORK_HINTS_1" "$NETWORK_HINTS_2" "$NETWORK_HINTS_3" \
            -- run_quiet "Downloading JW Library 15.6" download_ipa
    fi

    if [ ! -s "$IPA" ]; then
        fail_diag "The downloaded file is missing or empty."
    fi

    ok "JW Library 15.6 is downloaded."
    say "${GRAY}$IPA${RESET}"
    sleep 2
}

# ============================================================
# SANITY CHECKS
# ============================================================

if [ "$(uname -s)" != "Darwin" ]; then
    fail "This installer is for a Mac (macOS) only."
fi

if [ ! -t 0 ]; then
    fail "This installer needs to ask you questions, so it can't be started this way." \
         "" \
         "Please start it in one of these ways instead:" \
         "  bash rollback.sh" \
         "  /bin/bash -c \"\$(curl -fsSL <the link from the guide>)\""
fi

# ============================================================
# INTRODUCTION
# ============================================================

choose_mode
check_tools

if [ "$MODE" = "saved" ]; then
    choose_saved_ipa
fi

show_intro

# ============================================================
# STEP 1: REQUIRED TOOLS
# Only shown when something is actually missing (see check_tools).
# ============================================================

if [ "$NEED_TOOLS" -eq 1 ]; then
    step "Install the required tools" tools

    # First-time users (no Homebrew yet) get an explanation first, because
    # Homebrew's own installer shows plain technical text and pauses to ask
    # for details. Everyone else just gets the tools installed quietly.
    if [ -z "$BREW" ]; then
        tool_list="$(join_and "${SHOWN_TOOLS[@]}")"

        if [ "$MODE" = "full" ]; then
            purpose="to talk to Apple and to your device"
        else
            purpose="to talk to your device"
        fi

        para "This installer needs some free tools $purpose. They will be installed automatically on your Mac."
        echo
        say "Installing tools: $tool_list"

        note "WHAT TO EXPECT WHILE THESE TOOLS INSTALL" \
            "• Plain technical text will scroll by. This is normal." \
            "• When it pauses, it is asking you for something: type" \
            "  your Mac password (nothing appears as you type) or" \
            "  follow its instructions." \
            "• This can take a while. Please be patient."

        confirm "Proceed with the installation?" ||
            cancel "Nothing was installed. Nothing was changed." \
                   "Run the installer again when you are ready."
    fi

    # Homebrew's own installer needs the keyboard (Mac password, Enter),
    # so its messages stay visible. Everything else runs behind the scenes.
    if [ -z "$BREW" ]; then
        step_header
        important_top "REMEMBER" \
            "When it pauses and asks for a password, type your Mac" \
            "password (nothing appears as you type), then press Enter." \
            "Follow any other instructions."

        say "Installing tools: $(join_and "${SHOWN_TOOLS[@]}")"
        say "Technical messages below are normal."
        para "This may take a while, even if it looks stuck. Please wait until all the tools are fully installed."
        echo

        retry_cmd "THE REQUIRED TOOLS COULD NOT BE INSTALLED" \
            "$NETWORK_HINTS_1" "$NETWORK_HINTS_2" "$NETWORK_HINTS_3" \
            -- install_homebrew

        BREW="$(find_brew || true)"
        if [ -z "$BREW" ]; then
            fail_diag "The required tools could not be set up."
        fi
        load_brew
        BREW_IS_NEW=1
    fi

    # Homebrew was already here: note what it holds, to know afterwards
    # exactly what this installer added.
    if [ "$BREW_IS_NEW" -eq 0 ]; then
        snapshot_formulae
    fi

    step_header
    say "Installing tools: $(join_and "${TOOLS[@]}")"
    say "Please wait."
    echo

    retry_cmd "THE REQUIRED TOOLS COULD NOT BE INSTALLED" \
        "$NETWORK_HINTS_1" "$NETWORK_HINTS_2" "$NETWORK_HINTS_3" \
        -- run_quiet "Installing the required tools" install_tools_job

    tool_version=""
    if [ "$MODE" = "full" ]; then
        tool_version="$(ipatool_version)"
    fi

    for tool in ${TOOLS[@]+"${TOOLS[@]}"} idevice_id idevicepair; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            fail_diag "A required tool is missing after installation:" "$tool"
        fi
    done

    if [ "$MODE" = "full" ]; then
        if [ -z "$tool_version" ] || ! version_ge "$tool_version" "$MIN_IPATOOL"; then
            fail_diag "One of the required tools is out of date" \
                      "(ipatool ${tool_version:-unknown}, version $MIN_IPATOOL or newer is needed)." \
                      "Run this command, then start the installer again:" \
                      "  brew upgrade ipatool"
        fi
    fi

    ok "All required tools are ready."
    sleep 2
fi

# ============================================================
# STEP 2: CONNECT DEVICE
# ============================================================

step "Connect your iPhone or iPad" device

say "Connect your device to this Mac with a USB cable."

important "BEFORE YOU CONTINUE" \
    "• Switch your device on and UNLOCK it." \
    "• If it asks \"Trust This Computer?\", tap ${BOLD}Trust${RESET}" \
    "  and enter your device passcode."

pause

say "Checking your device..."
ensure_device

ok "One trusted device is connected."
sleep 2

# ============================================================
# STEPS 3 + 4 (full install only): APPLE ACCOUNT + DOWNLOAD
# ============================================================

if [ "$MODE" = "full" ]; then
    step_apple_login
    step_download
fi

# ============================================================
# PREPARE DEVICE
# ============================================================

step "Prepare your device" device

say "Checking that your device is still connected and trusted..."
ensure_device
ok "Device is connected and trusted."
sleep 2

# Second page, so the instructions fit a small window.
step_header

important_top "BEFORE YOU DELETE THE JW LIBRARY APP" \
    "Deleting the app also deletes its data from the device." \
    "Continue only if your backup is saved somewhere safe."

say "${BOLD}Now delete the JW Library app from your device:${RESET}"
echo
say "   1. Touch and hold the JW Library icon."
say "   2. Tap ${BOLD}Remove App${RESET}, then ${BOLD}Delete App${RESET}, then ${BOLD}Delete${RESET}."
say "      ${BOLD}Do NOT${RESET} choose \"Remove from Home Screen\":"
say "      that only hides the app and keeps it installed."
echo
say "Keep your device connected to this Mac."
echo

confirm "Have you deleted the JW Library app?" ||
    cancel "Installation canceled. Nothing was changed." \
           "Your IPA file has been kept:" \
           "$IPA" \
           "Run the installer again when you are ready."

echo
say "Checking your device again..."
ensure_device
ok "Device is connected and ready."
sleep 2

# ============================================================
# INSTALL
# ============================================================

step "Install JW Library 15.6" install

if [ ! -s "$IPA" ]; then
    fail_diag "The JW Library file is missing or empty." "$IPA"
fi

say "Everything is ready to install JW Library 15.6."
echo

confirm "Install JW Library 15.6 now?" ||
    cancel "Installation canceled." \
           "The old JW Library app has already been deleted," \
           "so JW Library is not on your device right now." \
           "Your IPA file has been kept:" \
           "$IPA" \
           "Run the installer again when you are ready."

step_header

important_top "WHILE INSTALLING" \
    "• Do NOT disconnect your device." \
    "• Wait until this screen says it is finished."

say "This may take a few minutes."
echo

while true; do
    if run_quiet "Installing JW Library 15.6" ideviceinstaller install "$IPA"; then
        break
    fi
    problem "THE INSTALLATION DID NOT FINISH" \
        "• Is your device still connected?" \
        "• Did you delete the old JW Library app?" \
        "• Try another USB cable or port."
    retry_or_quit || fail_diag "The installation was not completed." \
        "Your IPA file has been kept: $IPA"
    ensure_device
done

# The saved Apple Account login is no longer needed, so it is removed. This
# also lets the next run use a different Apple Account. Silent, and never
# worth stopping for.
if [ "$MODE" = "full" ]; then
    ipatool auth revoke >/dev/null 2>&1 || true
fi

# ============================================================
# COMPLETION
# ============================================================

CURRENT_STAGE="Installation completed"

clear_screen
band "$BAND_OK" "$(printf '%-48s%10s' "INSTALLATION COMPLETE" "v$VERSION")"
echo
echo "  ${GREEN}✔ JW Library 15.6 has been installed.${RESET}"
say "Open JW Library on your device and check that it starts."

note "YOUR NEXT STEPS" \
    "1. Import every custom JWPUB archive you may ever need." \
    "   (Adding new ones later means repeating this process.)" \
    "2. Update JW Library to the latest version." \
    "   Your imported archives will stay in the app." \
    "3. Restore your personal backup." \
    "4. Re-download your Bibles, publications and videos."

if [ "$MODE" = "full" ]; then
    say "Your downloaded IPA has been kept here:"
else
    say "Your IPA file is here:"
fi
say "${BOLD}${YELLOW}$IPA${RESET}"
say "Keep this file in case you repeat this process."
say "Next time, choose option 2 at the start to save time."

offer_cleanup

echo
say "${BOLD}Thank you!${RESET}"
echo
