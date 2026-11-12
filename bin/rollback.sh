
#!/bin/bash

# ============================================================
# JW LIBRARY ROLL-BACK
# ============================================================

set -Eeuo pipefail

VERSION="1.0.0"
APP_ID="672417831"
VERSION_ID="878901217"
IPA="$HOME/Downloads/JWLibrary-15.6.ipa"

TOTAL_STEPS=7
CURRENT_STEP=0
CURRENT_STAGE="Initialisation"
START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
FAILED_COMMAND=""
FAILED_LINE=""

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

line() {
    echo "============================================================"
}

header() {
    clear
    line
    echo "                 JW LIBRARY ROLL-BACK"
    line
    echo
}

step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    CURRENT_STAGE="$1"

    echo
    line
    echo " STEP $CURRENT_STEP OF $TOTAL_STEPS: $CURRENT_STAGE"
    line
    echo
}

done_msg() {
    echo
    echo "[DONE] $1"
}

pause() {
    echo
    read -r -p "Press Enter to continue..."
}

confirm() {
    local answer
    while true; do
        read -r -p "$1 (y/n): " answer
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please enter y or n." ;;
        esac
    done
}

fail() {
    echo
    echo "[ERROR] $1"
    return 1
}

# ============================================================
# ERROR HANDLING
# ============================================================

classify_error() {
    local message="$1"

    case "$message" in
        *"curl"*|*"resolve"*|*"timed out"*|*"network"*|*"Network"*|*"connection"*|*"Connection"*)
            echo "POSSIBLY TEMPORARY"
            ;;
        *"ipatool"*|*"authentication"*|*"Authentication"*|*"Apple Account"*)
            echo "APPLE ACCOUNT / APP STORE"
            ;;
        *"idevice"*|*"device"*|*"Device"*|*"USB"*|*"Trust"*)
            echo "DEVICE CONNECTION"
            ;;
        *"brew"*|*"Homebrew"*)
            echo "HOMEBREW INSTALLATION"
            ;;
        *"permission"*|*"Permission"*|*"not found"*|*"No such file"*)
            echo "SYSTEM CONFIGURATION"
            ;;
        *)
            echo "UNKNOWN - FURTHER INVESTIGATION REQUIRED"
            ;;
    esac
}

error_handler() {
    local exit_code=$?
    local failed_command="${BASH_COMMAND:-Unknown}"
    local failed_line="${BASH_LINENO[0]:-Unknown}"

    trap - ERR
    set +e

    echo
    line
    echo "                  INSTALLATION FAILED"
    line
    echo
    echo "Something went wrong. The installer has stopped."
    echo
    echo "STAGE: $CURRENT_STAGE"
    echo "STEP: $CURRENT_STEP of $TOTAL_STEPS"
    echo "EXIT CODE: $exit_code"
    echo "SCRIPT LINE: $failed_line"
    echo
    echo "FAILED COMMAND:"
    echo "$failed_command"
    echo

    local classification
    classification="$(classify_error "$failed_command")"

    echo "ASSESSMENT: $classification"
    echo

    case "$classification" in
        "POSSIBLY TEMPORARY")
            echo "This may be a temporary Internet or server problem."
            echo
            echo "WHAT TO DO:"
            echo "  1. Check your Internet connection."
            echo "  2. Wait a few minutes."
            echo "  3. Run the installer again."
            echo "  4. If it fails again, send the information below."
            ;;
        "APPLE ACCOUNT / APP STORE")
            echo "The problem may involve Apple Account authentication"
            echo "or communication with Apple's App Store services."
            echo
            echo "WHAT TO DO:"
            echo "  1. Check your Apple Account authentication."
            echo "  2. Complete any outstanding verification."
            echo "  3. Try running the installer again."
            ;;
        "DEVICE CONNECTION")
            echo "The problem may involve your iPhone or iPad."
            echo
            echo "WHAT TO DO:"
            echo "  1. Check your USB cable."
            echo "  2. Unlock your device."
            echo "  3. Select Trust if prompted."
            echo "  4. Reconnect your device and retry."
            ;;
        "HOMEBREW INSTALLATION")
            echo "There was a problem installing or updating Homebrew tools."
            echo
            echo "WHAT TO DO:"
            echo "  1. Check the messages displayed above."
            echo "  2. Check your Internet connection."
            echo "  3. Retry after a few minutes."
            ;;
        "SYSTEM CONFIGURATION")
            echo "A required file, command or permission may be missing."
            echo
            echo "WHAT TO DO:"
            echo "Please send the information below to the guide author."
            ;;
        *)
            echo "The cause could not be identified automatically."
            echo
            echo "WHAT TO DO:"
            echo "Please send the information below to the guide author."
            ;;
    esac

    echo
    line
    echo "                 DIAGNOSTIC INFORMATION"
    line
    echo

    echo "Date/time: $(date)"
    echo "Installation started: $START_TIME"
    echo "Failed stage: $CURRENT_STAGE"
    echo "Step: $CURRENT_STEP of $TOTAL_STEPS"
    echo "Exit code: $exit_code"
    echo "Script version: $VERSION"
    echo "Script line: $failed_line"
    echo "Failed command: $failed_command"
    echo
    echo "MAC INFORMATION:"
    echo "macOS: $(sw_vers -productVersion 2>/dev/null || echo Unknown)"
    echo "Architecture: $(uname -m)"
    echo "Bash: $BASH_VERSION"
    echo
    echo "INSTALLED TOOLS:"
    echo "Homebrew: $(command -v brew 2>/dev/null || echo Not found)"
    echo "ipatool: $(command -v ipatool 2>/dev/null || echo Not found)"
    echo "ideviceinstaller: $(command -v ideviceinstaller 2>/dev/null || echo Not found)"
    echo
    echo "CONNECTED DEVICES:"
    if command -v idevice_id >/dev/null 2>&1; then
        idevice_id -l 2>/dev/null || echo "Unable to detect devices"
    else
        echo "idevice_id is unavailable"
    fi
    echo
    echo "DOWNLOADED IPA:"
    if [ -s "$IPA" ]; then
        ls -lh "$IPA"
    else
        echo "Not found or empty"
    fi

    echo
    line
    echo "                 END OF DIAGNOSTIC INFORMATION"
    line
    echo
    echo "PLEASE SEND THE FOLLOWING TO THE GUIDE AUTHOR:"
    echo
    echo "  1. The stage where the installation failed."
    echo "  2. The error messages displayed above."
    echo "  3. The diagnostic information above."
    echo
    echo "You can select and copy the Terminal output."
    echo
    echo "IMPORTANT:"
    echo "Check the output before sharing it."
    echo "Never share passwords or verification codes."
    echo
    echo "Your downloaded IPA, if present, has been kept."
    echo "You can retry after resolving the problem."
    echo
    line

    exit "$exit_code"
}

trap error_handler ERR

# ============================================================
# INTRODUCTION
# ============================================================

header

echo "Welcome!"
echo
echo "This installer will guide you through rolling back to"
echo "JW Library version 15.6 on your iPhone or iPad."
echo
echo "The process includes:"
echo
echo "  1. Checking/installing Homebrew."
echo "  2. Installing the required Mac tools."
echo "  3. Connecting your iPhone or iPad."
echo "  4. Signing in to your Apple Account."
echo "  5. Downloading JW Library 15.6."
echo "  6. Preparing your device."
echo "  7. Installing JW Library 15.6."
echo
echo "IMPORTANT: BACK UP YOUR JW LIBRARY DATA FIRST!"
echo
echo "On your device, go to:"
echo
echo "Personal Study > Create Backup"
echo
echo "You will need to restore this backup after installation."
echo "You will also need to re-download your official"
echo "Bibles, publications, videos and other content."
echo
line
echo "USER INTERACTION REQUIRED"
line
echo
echo "During this process, you may need to:"
echo
echo "  - Enter your Mac login password."
echo "  - Follow Homebrew installation instructions."
echo "  - Sign in to your Apple Account."
echo "  - Complete two-factor authentication."
echo "  - Unlock your iPhone or iPad."
echo "  - Select Trust This Computer."
echo "  - Manually delete the existing JW Library app."
echo
echo "The installer will pause whenever your attention"
echo "or action is required."
echo

confirm "Have you successfully created a JW Library backup?" ||
    fail "Please create a backup before continuing."

# ============================================================
# STEP 1: HOMEBREW
# ============================================================

step "CHECKING HOMEBREW"

if command -v brew >/dev/null 2>&1; then
    BREW="$(command -v brew)"
    done_msg "Homebrew is already installed."
else
    echo "Homebrew is not installed."
    echo "We will now install it."
    echo
    echo "The Homebrew installer may ask for your Mac"
    echo "login password or require additional instructions."
    echo
    echo "When entering your password, Terminal will not"
    echo "display the characters. This is normal."
    echo

    pause

    CURRENT_STAGE="Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ -x /opt/homebrew/bin/brew ]; then
        BREW="/opt/homebrew/bin/brew"
    elif [ -x /usr/local/bin/brew ]; then
        BREW="/usr/local/bin/brew"
    else
        fail "Homebrew could not be located after installation."
    fi
fi

eval "$("$BREW" shellenv)"

done_msg "Homebrew is ready."

# ============================================================
# STEP 2: REQUIRED TOOLS
# ============================================================

step "INSTALLING REQUIRED TOOLS"

echo "The following tools are required:"
echo
echo "  ipatool - communicates with Apple's App Store."
echo "  ideviceinstaller - installs apps on your device."
echo
echo "Homebrew will install or update both tools."
echo "This may take a few minutes."
echo

CURRENT_STAGE="Updating Homebrew"
brew update

CURRENT_STAGE="Installing ipatool and ideviceinstaller"
brew install ipatool ideviceinstaller

done_msg "Both required tools are ready."

# ============================================================
# STEP 3: CONNECT DEVICE
# ============================================================

step "CONNECTING YOUR IPHONE OR IPAD"

echo "Connect your device to your Mac using a USB cable."
echo
echo "Make sure:"
echo "  - Your device is switched on."
echo "  - Your device is unlocked."
echo "  - You select TRUST if prompted."
echo
echo "If you see a Trust This Computer message,"
echo "follow the instructions on your device."
echo

pause

CURRENT_STAGE="Checking device connection"

devices="$(idevice_id -l)"

if [ -z "$devices" ]; then
    fail "No connected device was detected."
fi

device_count="$(printf '%s\n' "$devices" | grep -c .)"

if [ "$device_count" -ne 1 ]; then
    fail "Please connect only one iPhone or iPad."
fi

done_msg "One trusted device has been detected."

# ============================================================
# STEP 4: APPLE ACCOUNT AUTHENTICATION
# ============================================================

step "APPLE ACCOUNT AUTHENTICATION"

echo "You will now sign in to your Apple Account using ipatool."
echo
echo "Follow the instructions displayed in Terminal."
echo
echo "Apple may request two-factor authentication."
echo "Complete any verification requested."
echo
echo "Your credentials are handled by ipatool."
echo "This installer does not collect your password."
echo

pause

CURRENT_STAGE="Apple Account authentication"

ipatool auth login

done_msg "Apple Account authentication completed."

# ============================================================
# STEP 5: DOWNLOAD JW LIBRARY
# ============================================================

step "DOWNLOADING JW LIBRARY 15.6"

if [ -s "$IPA" ]; then
    echo "An existing JW Library 15.6 IPA was found:"
    echo
    echo "$IPA"
    echo

    if confirm "Would you like to reuse this downloaded file?"; then
        done_msg "Using the existing IPA."
    else
        echo "Downloading a fresh copy."
        rm -f "$IPA"

        CURRENT_STAGE="Downloading JW Library 15.6"

        ipatool download \
            --app-id "$APP_ID" \
            --external-version-id "$VERSION_ID" \
            --output "$IPA" \
            --purchase
    fi
else
    echo "Downloading JW Library 15.6 from the App Store."
    echo
    echo "This may take a few minutes."
    echo

    CURRENT_STAGE="Downloading JW Library 15.6"

    ipatool download \
        --app-id "$APP_ID" \
        --external-version-id "$VERSION_ID" \
        --output "$IPA" \
        --purchase
fi

[ -s "$IPA" ] || fail "The downloaded IPA is missing or empty."

done_msg "JW Library 15.6 has been downloaded."
echo "Location: $IPA"

# ============================================================
# STEP 6: PREPARE DEVICE
# ============================================================

step "PREPARING YOUR DEVICE"

echo "IMPORTANT: READ BEFORE CONTINUING."
echo
echo "Before installing version 15.6:"
echo
echo "  1. Make sure your personal backup is safe."
echo "  2. Manually delete the existing JW Library app."
echo "  3. Keep your iPhone or iPad connected to your Mac."
echo
echo "The installer WILL NOT delete the existing app."
echo
echo "Delete the app itself, not just its Home Screen icon."
echo
echo "Your existing app data will be removed when you delete it."
echo "Only proceed if your backup is safely stored."
echo

confirm "Have you deleted the existing JW Library app?" ||
    fail "Installation cancelled. The downloaded IPA has been kept."

CURRENT_STAGE="Checking device before installation"

devices="$(idevice_id -l)"

if [ -z "$devices" ]; then
    fail "Your device is no longer detected. Reconnect it."
fi

device_count="$(printf '%s\n' "$devices" | grep -c .)"

if [ "$device_count" -ne 1 ]; then
    fail "Please connect only one iPhone or iPad."
fi

done_msg "Device is connected and ready."

# ============================================================
# STEP 7: INSTALL
# ============================================================

step "INSTALLING JW LIBRARY 15.6"

echo "The installation is about to begin."
echo
echo "IMPORTANT:"
echo "  - Do NOT disconnect your device."
echo "  - Keep your device unlocked if possible."
echo "  - Wait until installation finishes."
echo
echo "This may take a few minutes."
echo

pause

CURRENT_STAGE="Installing JW Library 15.6"

ideviceinstaller install "$IPA"

done_msg "The installation command completed successfully."

# ============================================================
# COMPLETION
# ============================================================

CURRENT_STAGE="Installation completed"

echo
line
echo "                INSTALLATION COMPLETED!"
line
echo
echo "JW Library 15.6 has been installed."
echo
echo "Please open JW Library on your device and"
echo "confirm that it starts correctly."
echo
echo "YOUR NEXT STEPS:"
echo
echo "  1. Import all the custom JWPUB archives you may ever need."
echo "     It's easy to remove them later, but to add new ones,"
echo "     you will need to repeat this process."
echo "  2. Update JW Library to the latest version."
echo "  3. Restore your personal backup."
echo "  4. Re-download your official publications,"
echo "     Bibles, videos and other content."
echo
echo "Your downloaded IPA has been kept here:"
echo "$IPA"
echo
echo "Keep this file in case you need it again."
echo
line
echo "Thank you!"
line
echo
