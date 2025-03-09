#!/bin/bash
# shellcheck source=.env
# shellcheck disable=SC1091
if ! source "$(dirname "$0")"/.env; then
    echo "ERROR: Could not open '$(dirname "$0")/.env'."\
        "I wouldn't be able to tell where to remove files from."\
        "Please delete files yourself."
    exit 1;
fi

if which gio >/dev/null 2>/dev/null; then
    RM_CMD="gio trash"
    echo "INFO: \`gio\` is available."\
        "I'll move all relevant files & folders to Trash."\
        "Don't forget to empty it later!"
else
    RM_CMD="rm --verbose --recursive --interactive"
    echo "INFO: \`gio\` NOT available."\
        "I'll be using \`rm --recursive\`,"\
        "which deletes files permanency." 

fi

echo "INFO: If you are having second thoughts, now is the chance!"\
    "Hit [ Ctrl+C ] to cancel."
counter=8
while 
    echo -en "Continue in: $counter\r"
    sleep 1
    [ $((--counter)) -gt 0 ]
do :
done

echo "Uninstallation started."

if [ -n "$DESKTOP" ]; then
    $RM_CMD "$DESKTOP" &&\
        echo "INFO: Removed '$DESKTOP'."
fi

if [ -n "$LINK" ]; then
    $RM_CMD "$LINK" &&\
        echo "INFO: Removed '$LINK'."
fi


$RM_CMD "$(dirname "$0")"&&\
        echo "INFO: Removed '$(dirname "$0")'."

echo "INFO: Uninstallation complete."
