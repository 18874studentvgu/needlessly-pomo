#!/bin/bash

: "${BIN_PATH:=$HOME/.local/bin}"
: "${INSTALL_PATH:=$BIN_PATH/needlessly-pomo}"

prompt_yes_no(){
    # Yes-No dialog, with default fallback
    prompt="${*=Choose}"
    # 0=yes; 1=no
    default="${DEFAULT:=1}"
    while
        printf "\nQUESTION: %s\n(y[es]/n[o] - case insensitive): " "$prompt"
        read -r REPLY
        case "$(echo "${REPLY}" | tr '[:upper:]' '[:lower:]')" in
            (y|yes)
                return 0
                ;;
            (n|no)
                return 1
                ;;
            ("")
                printf "...I'll take that as a '%s'.\n" \
                    "$([ "$default" -eq 0 ] && echo Yes || echo No)"
                return "$default"
                ;;
            (*)
                printf "Option '%s' not recognized, please try again.\n" "${REPLY}"
                continue
                ;;
        esac
        # do we even need to add a break condition here? 
    do :
    done        
}

echo "OVER ENGINEER POMODORO SCRIPT INSTALLATION"

if prompt_yes_no "Do you want to move the script"\
    "alongside it's resources to ${INSTALL_PATH}?"; then
    _install_in_dir=true
else
    _install_in_dir=false
fi


if prompt_yes_no "Do you want to have a shortcut"\
    "to the script in ${BIN_PATH}?"; then
    _ln_to_bin=true
else
    _ln_to_bin=false
fi

if prompt_yes_no "Do you want to add a desktop shortcut?"; then
    _dot_desktop=true
else
    _dot_desktop=false
fi

if ! ($_install_in_dir || $_ln_to_bin || $_dot_desktop);
then
    count=3
    while [ "$count" -gt 0 ]; do
        echo -n "."
        : $((--count))
        sleep 0.8
    done
    echo "what are you doing here then?"
    sleep 0.8
    exit 0;
fi

echo -e "\nINFO: Installation started."

if $_install_in_dir; then
    WORK_DIR="${INSTALL_PATH}"
    mkdir -p --verbose "${WORK_DIR}"
    for item in "resources" "pomodoro.bash" "uninstall.bash" "install.bash";
    do
        cp --interactive --verbose --recursive ./"${item}" "${WORK_DIR}/${item}"
    done
fi

# set WORK_DIR if it hasn't been set
: "${WORK_DIR:=$(dirname "$0")}"

echo "INFO: Creating '${WORK_DIR}/.env', which is the configuration file."
cat > "${WORK_DIR}/.env" <<ENV
#!/bin/bash

# This is basically a configuration file
# (should we put it in ~/.config instead?)
# 
# If you wanna have set values you can later overwrite, use 
# this Shell syntax (yes the ":" is mandatory):
# : "\${VARIABLE_NAME=the value you want to set}"
# 
# For example, to set a cycle of 45/10/5 minutes as the default:
# : "\${POMO_INTERVAL_1=45}"
# : "\${POMO_INTERVAL_2=10}"
# : "\${POMO_INTERVAL_3=5}"
ENV

if $_ln_to_bin; then
    : "${LN_NAME:=pomodoro}"
    ln --interactive --relative --symbolic \
        "${WORK_DIR}/pomodoro.bash" "${BIN_PATH}/${LN_NAME}"
    chmod u+x "${BIN_PATH}/${LN_NAME}"

    echo "LINK='${BIN_PATH}/${LN_NAME}'" >> "$WORK_DIR/.env"
fi

if $_dot_desktop; then
    : "${DESKTOP_FILE:=needlessly-pomo.desktop}"
    : "${APPLICATION_DIR:=$HOME/.local/share/applications}"
    echo "INFO: Generating a .desktop file in '${APPLICATION_DIR}...'"

    cat > "$APPLICATION_DIR/$DESKTOP_FILE.temp" <<DOT_DESKTOP
[Desktop Entry]
Type=Application

# The name of the application
Name=Needlessly Complex Pomodoro

# A comment which can/will be used as a tooltip
Comment=Pomodoro that is kinda over engineered :3

# The path to the folder in which the executable is run
Path=$WORK_DIR

# The executable of the application, possibly with arguments.
Exec=bash "$WORK_DIR/pomodoro.bash"

# The name of the icon that will be used to display this entry
Icon=$WORK_DIR/resources/icon.svg

# Describes whether this application needs to be run in a terminal or not
Terminal=true

# Describes the categories in which this entry should be shown
Categories=ConsoleOnly;Time;Utility;Education;

DOT_DESKTOP
    # doing it this way prevents accidentally overwriting an existing file
    mv --interactive --verbose \
        "$APPLICATION_DIR/$DESKTOP_FILE.temp" "$APPLICATION_DIR/$DESKTOP_FILE"

    
    echo "DESKTOP='$APPLICATION_DIR/$DESKTOP_FILE'" >> "$WORK_DIR/.env"
fi

echo "INFO: Installation complete."