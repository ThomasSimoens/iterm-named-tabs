#!/bin/bash

# Array of commands you want to run
commands=(
    "ls -la"
    "tail -f /var/log/syslog"
)
# Array of corresponding tab names
tab_names=(
    "my-list"
    "my-tail"
)

# --- Sanity Checks ---
if [ "${#commands[@]}" -ne "${#tab_names[@]}" ]; then
    echo "Error: 'commands', 'tab_names'" >&2
    exit 1
fi

if [ "${#commands[@]}" -eq 0 ]; then
    echo "No commands to run."
    exit 0
fi

# --- Script Logic ---

# Function to prepare the command text.
# This new version embeds a terminal escape sequence to set the tab title
# directly from the shell, which is more reliable than setting it via AppleScript.
prepare_command_text() {
    local cmd="$1"
    local tab_name="$2"

    # This is the escape sequence to set the iTerm tab/window title.
    # \e]0; is the start sequence, \a (or \007) is the bell character terminator.
    # We use printf for reliable escaping.
    local set_title_cmd="printf '\\e]0;%s\\a' '${tab_name}'"
    echo "${set_title_cmd}; ${cmd}"
}

# Create the first tab in a new window.
# We no longer need to pass the tab_name to osascript, as it's now part of the command text.
first_command_text=$(prepare_command_text "${commands[0]}" "${tab_names[0]}")

# Note that the AppleScript is now simpler. It just needs to 'write text'.
osascript -e 'on run {command_text}' \
          -e 'tell application "iTerm2"' \
          -e '  activate' \
          -e '  tell (create window with default profile)' \
          -e '    tell current session' \
          -e '      write text command_text' \
          -e '    end tell' \
          -e '  end tell' \
          -e 'end tell' \
          -e 'end run' \
          "${first_command_text}"$'\n' # Appending newline executes the command

# Create the remaining tabs in the same window
for i in "${!commands[@]}"; do
    if [ $i -eq 0 ]; then continue; fi # Skip the first command as it's already handled

    current_command_text=$(prepare_command_text "${commands[i]}" "${tab_names[i]}")

    osascript -e 'on run {command_text}' \
              -e 'tell application "iTerm2"' \
              -e '  tell current window' \
              -e '    tell (create tab with default profile)' \
              -e '      tell current session' \
              -e '        write text command_text' \
              -e '      end tell' \
              -e '    end tell' \
              -e '  end tell' \
              -e 'end tell' \
              -e 'end run' \
              "${current_command_text}"$'\n'
done
