#!/bin/bash
# shellcheck disable=SC2190,SC2128,SC1091

# F*ck it, all GNU-ism
# Credits:
#   https://docs.linuxfoundation.org/v2/security-service/\
# manage-false-positives/regular-expressions-cheat-sheet
#   https://github.com/dylanaraps/pure-bash-bible

#### TODO ####
# [X] Random title & texts
# [ ] optimizations (+ make script look less dumb)
# [ ] unit tests
# [-] Source vars from a conf file that can be overwritten by setting runtime vars
# [ ] Random side pictures too
# [ ] One-time first interval

# attempt to read from a .env file
source "$(dirname "$0")"/.env 2>/dev/null

# interval in minutes
# this makes sure [ -z "$POMO_INTERVAL_1" ] always false
readonly POMO_INTERVAL_1="${POMO_INTERVAL_1:-25}" 
readonly POMO_INTERVAL_2="${POMO_INTERVAL_2-5}" # INTERVAL_2 can be set to "" idc

readonly POMO_RESOURCE_PATHS="${POMO_RESOURCE_PATHS-$(dirname "$0")/resources:$HOME/.local/share/needlessly-pomo}"

readonly LABEL_FILE_PREFIX="${LABEL_FILE_PREFIX-labels_content}"

readonly EMPTY_F="921b85de-dae2-4b78-83ca-d30cc41a6ce9"

trstr() {
# trim trailing white space and EMPTY_F from string
# I only added the `sed` at the end, not sure what magic's going on 
# in here
# Credits:
#   https://github.com/dylanaraps/pure-bash-bible

    # Usage: trim_string "   example   string    "
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_" | sed -E "s/$EMPTY_F//g"
}

# prevent closing right away when running as a (headless?) terminal app 
trap '[ "$?" -ne 0 ] && \
    {
        printf "\033[5m\033[1mINFO: Script stopped. Hit ENTER to exit...\033[0m";
        read;
        printf "\033[1A\033[2KINFO: Script stopped. Hit ENTER to exit...\n";
    }' EXIT

# load flavor texts from file
# the file should look something like this:
#
# ############ labels_content.txt  ############
# [header section goes here (place holder, don't do anything for now)]
# ---
# [title label texts goes here]
# ---
# [text label texts goes here]
# ---
# [cancel label texts goes here]
# ---
# [ok label texts goes here]
# ---
# 
# ############      END FILE       ############
#
# * we use `---` as deliminator and relies on the position of the text
#   to figure out  what is what. do note the white spaces, 'tis important.
# * Empty fields must be denoted with the string in variable 'EMPTY_F'
# 
# * under the hood the sequence `\n---\n` get converted into `\t` which is
#   then used as delim for `read` to slice into a 6 elements array, w each 
#   element being a multiline string
# 
# * the way we do it, the last line of each array element MUST
#   NOT have a trailing newline (\n)
# 
# why not using `awk` or `sed`? good question...

if [ -z "$POMO_RESOURCE_PATHS" ]; then
    echo "INFO: POMO_RESOURCE_PATHS was set to empty"
    echo "    Will not attempt to load extra labels."
    declare -g _ext_dir=false
fi

# if _ext_dir flag isn't set or is set to `true`...
# ...attempted to get extra labels from file
# if _ext_dir is set to `false`, skip the whole thing
if [ -z "$_ext_dir" ] || $_ext_dir; then
    # I didn't know bash has key val variables!
    declare -gA dict=(
        "title" ""
        "text"  ""
        "no"    ""
        "yes"   ""
    ) BRK=$'\n'
    echo "INFO: Attempting to grab resources from '\$POMO_RESOURCE_PATHS'"
    # breaks the `:`-separated list into bits
    while read -d ':' -r conf_path; # the POMO_RESOURCE_PATHS in down below
    do
        echo "INFO: looking in $conf_path..."
        shopt -s nullglob
        label_prefix_path="${conf_path}"/"${LABEL_FILE_PREFIX}"
        for label_file in "$label_prefix_path"*; do
            shopt -u nullglob
            echo -n "    > found '$(basename "$label_file")', attempt to read..."
            # break
            if data="$(cat "$label_file" 2>/dev/null)"; then
                IFS=$'\t' read -d '' -r -a data_arr \
                    <<< "${data//$'\n'---/$'\t'}"
                # declare -p data_arr
                declare -gA dict=(
                    "title" "${dict['title']}$(trstr "${data_arr[1]}")$BRK"
                    "text"  "${dict['text']}$(trstr "${data_arr[2]}")$BRK"
                    "no"    "${dict['no']}$(trstr "${data_arr[3]}")$BRK"
                    "yes"   "${dict['yes']}$(trstr "${data_arr[4]}")$BRK"
                ) # this kinda str concat makes sense I swear
                echo " [ DONE ]"
# break 8
            else echo " [ FAILED ]"
            fi
        done
    done <<< "${POMO_RESOURCE_PATHS}:"

    echo "INFO: Label statistic:"

    for key in "title" "text" "no" "yes"; do
        unset lines;
        lines=$(( "$(wc -l <<< "${dict["$key"]}")" - 1 ))
        echo -e "  dict[$key]:\t($lines) entries"
        # check if there are actually multiple values for a given key
        if [ $lines -gt 0 ]; then
            declare -g _multi_$key=true
        else
            declare -g _multi_$key=false
        fi
    done
# break 8 # only here to debug, remove this later

    # if nothing was found at all, _ext_dir=false, else _ext_dir=true
    # shellcheck disable=SC2154
    if ! $_multi_title && ! $_multi_text && ! $_multi_no && ! $_multi_yes;
    then # there has to be a better what than this
        echo "INFO: Insufficient amount of entries in all elements of dict,"
        echo "    will not use external label entries"
        declare -g _ext_dir=false
    else 
        declare -g _ext_dir=true
    fi
fi




# until we implement Random title & texts, this'll always be true
# if true; then declare -g _ext_dir=false; fi


# exit 2 # only here to debug, remove this later
declare -Ag texts=()

function get_texts {
    $_ext_dir \
        && {
        # shellcheck disable=SC2086
        for key in "title" "text" "no" "yes"; do
            "$(eval echo "\$_multi_$key")" &&\
                declare ${key}_value="$(shuf -n 1 <<< ${dict[$key]})"
        done
        texts=(
            "title" "${title_value:=Pomo}"
            "text"  "${text_value:=De-focus time}"
            "no"    "${no_value:=nope ᕕ( ᐛ )ᕗ}"
            "yes"   "${yes_value:=alright...}"
        )
        } \
        || texts=(
            "title" "UwU"
            "text"  "De-focus time"
            "no"    "nope ᕕ( ᐛ )ᕗ"
            "yes"   "alright..."
        )
}

printf 'Running with interval(s): '
# shellcheck disable=SC2046 # this is an abomination
if (printf '%.2f/' $(eval echo $(printf '"$%s" ' "${!POMO_INTERVAL_@}"))); then
    #        ↓ removed the last `/`
    echo -e "\033[1D\033[K minutes" 
else
    echo -e "\033[2K\nERROR: Some interval seems to not be in number formats,"\
        "double check environmental variables and try again"
        exit 1
fi


declare -g _first_cycle=true
declare -g _b4_2nd_cycle=true
declare -g minutes=0

# zenity --question --title="OwO" --text="start tim!"
# minutes=0
# want more intervals? just set more runtime vars lol
while true; do
    for interval in "${!POMO_INTERVAL_@}"; do
        # check if minutes is number in {0..999}
        # simultaneous type check and value limit, feelsgoodman
        if [[ "$minutes" =~ ^[0-9]{1,3}(.[0-9]*)?$ ]]; then
            # sleep first
            $_first_cycle || \
            echo "INFO: Sleeping for the next ${minutes} minutes..."
            sleep "${minutes}m"


            # and *then* we get next interval time...
            minutes="$(eval echo "\$$interval")"

            if $_ext_dir || $_b4_2nd_cycle; then 
                $_first_cycle && {
                    texts=(
                        "title" "OwO"
                        "text"  "start tim!"
                        "no"    "uh no..."
                        "yes"   "of course"
                    ) && _first_cycle=false
                } || {
                    get_texts &&\
                    $_b4_2nd_cycle&&\
                    _b4_2nd_cycle=false
                }
            fi
            
            zenity \
                --question \
                --title="${texts['title']}" \
                --text="${texts['text']}"\
                --ok-label="${texts['yes']} ($minutes mins)"\
                --cancel-label="${texts['no']}"

            # shellcheck disable=SC2181
            if [ $? -ne 0 ]; then
                echo "exiting..."
                break 2;
            fi
        elif [ -z "$minutes" ]; then
            # we'll just let it pass, for now
            continue
        else
            echo "ERROR: '$interval' was set to '$(eval echo "\$$interval")'"\
                "- which is either too big or not a number."
            exit 1
        fi
    done
done

    
