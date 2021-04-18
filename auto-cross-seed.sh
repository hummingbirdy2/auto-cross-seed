#!/bin/bash

#=========================================
#             auto-cross-seed             
#=========================================
# Search and add to a client cross-seedable torrents for Movies and TV.
# by Hummingbirdy The Second https://github.com/hummingbirdy-second/auto-cross-seed
#
# Requires:
#   - rTorrent, Deluge, qBittorrent or Transmission for AutoTorrent
#   - Jackett for Cross-Seed-AutoDL
#
# Dependencies:
#   - AutoTorrent by JohnDoee https://github.com/JohnDoee/autotorrent (thanks !)
#   - python >= 3.6 for AutoTorrent and Cross-Seed-AutoDL
#   - Cross-Seed-AutoDL by BC44 https://github.com/BC44/Cross-Seed-AutoDL [only if the search is enabled]  (thanks !)
#   - apprise by caronc https://github.com/caronc/apprise [only if the notification is enabled]  (thanks !)
#   - mktemp, tee, printf, grep
#
# Changelog:
#   - V1.3.0:
#       - [ADD] Path to call Cross-Seed-AutoDL and AutoTorrent
#
#   - V1.2.1:
#       - [FIX] Still checking search options with the "--no-search"
#
#   - V1.2.0:
#       - [ADD] Control of Cross-Seed-AutoDL and AutoTorrent run smoothly
#       - [ADD] Send a notification if Cross-Seed-AutoDL and AutoTorrent exit with en error
#       - [FIX] Adjustment for recent changes of Cross-Seed-AutoDL
#       - [IMPROV] Better behavior if SEARCH_DIR have empty dir
#       - [IMPROV] Small change for notification texts
#
#   - V1.1.0:
#       - [ADD] Support for comma-separated list in SEARCH_DIR
#
#   - V1.0.0:
#       - [INIT] Initial version
#=========================================

# ------------------------------
# EDITABLE AREA
python3='python3' #-> call for Python 3
cross_seed='/app/cross-seed/CrossSeedAutoDL.py' #-> call for Cross-Seed-AutoDL
auto_torrent='/usr/bin/autotorrent' #-> call for AutoTorrent
# DO NOT EDIT NEXT LINES
# ------------------------------

# Constant values
readonly CONST_DELAY=10

# Default values
torrent_dir=''
keep_torrent=false
no_search=false
ignore_pattern=''
jackett_url=''
jackett_key=''
delay=$CONST_DELAY
trackers=''
search_dir_list=''
old_filter='none'
config_path=''
autotorrent_output_dir=''
notification='off'
notif_config_path=''
cs_fail=false
at_fail=false
nbTorrent=0
nbOK=0
nbSeeded=0
nbMissing=0
nbExists=0
nbFailed=0

# Functions
_error ()   { printf >&2 '%sERROR%s: %s\n' $'\033[0;31m' $'\033[0m' "$@" ; }
_warning () { printf     '%sWARNING%s: %s\n' $'\033[0;33m' $'\033[0m' "$@" ; }
_info ()    { printf     '%sINFO%s: %s\n' $'\033[0;34m' $'\033[0m' "$@" ; }

_check_directory ()     {
    # Support comma separated list
    IFS=","
    for i in $1
    do
        [ ! -d "$i" ]  && { _error "\"$2 '$i'\" does not exist !" ;exit 1 ; }
    done
    IFS=""
}

_check_file ()          { [ ! -f "$1" ]  && { _error "\"$2 '$1'\" is not a file !" ;exit 1 ; } }
_check_filled_value ()  { [ "$1" == '' ] && { _error "\"$2\"  need to be declared !" ;exit 1 ; } }

_cap_min_integer () {
    [[ ! $1 =~ ^-?[0-9]+$ ]] && { _error "'$1' is not an integer ! ($3 need to be well declared)" ;exit 1 ; }
    [[ ! $2 =~ ^-?[0-9]+$ ]] && { _error "'$2' is not an integer ! (_cap_min_integer)" ;exit 1 ; }
    if [ $1 -lt $2 ] ; then
        _warning "$3 set at $2 (minimum value)."
        cap_min_integer_result=$2
    else
        cap_min_integer_result=$1
    fi
}

_dirname () {
    local dirname="$1"
    local result="${dirname%"${dirname##*[!/]}"}"
    result="${result##*/}"
    printf '%s\n' "$result" # Out put the dir name (/path/to/dir_name/ -> dir_name)
}

_help () {
    printf '
Usage:
   auto-cross-seed.sh -T [TORRENT_DIR] -u [JACKETT_URL] -k [JACKETT_KEY] -t [TRACKER_LIST] 
                      -s [SEARCH_DIR] -c [CONFIG_PATH] (-h) (-K) (-d [DELAY]) (-N)
                      (-i [IGNORE_PATTERN]) (-o {day|week|month|none}) (-r [AT_OUTPUT_DIR])
                      (-n {off,simple,list} [NOTIF_CONFIG_PATH])

    Search and add to a client cross-seedable torrents for Movies and TV.

Options:
  general options:
  -h, --help                        Print this help text and exit.
  -T, --torrent-dir <TORRENT_DIR>   Directory to store downloaded torrents.
  -K, --keep-torrent                Do not remove torrent files at the end.

  search (cross-seed) options:
  -N, --no-search                   Disable torrent search.
  -i, --ignore-pattern <IGNORE_PATTERN>
                                    Search will be ignored on folder starting
                                    with this pattern.

  -u, --jackett-url <JACKETT_URL>   URL for your Jackett instance, including
                                    port number if needed.

  -k, --jackett-key <JACKETT_KEY>   API key for your Jackett instance.
  -d, --delay <DELAY>               Pause duration [in seconds] between
                                    searches. (default: 10)

  -t, --trackers <TRACKER_LIST>     Comma-separated list of Jackett tracker
                                    IDs for the research.
                                    See Cross-Seed-AutoDL documentation.

  -s, --search-dir <SEARCH_DIR>     Comma-separated list of folders where
                                    movies or tv shows are stored.

  -o, --filter-old {day|week|month|none} 
                                    Filter file older than a "day", a "week" or
                                    a "month". "none" disable the filter.
                                    (default: none)

  add torrent (AutoTorrent) options:
  -c, --config-path <CONFIG_PATH>   Path to the AutoTorrent config file.
                                    See autotorrent wiki.
  -r, --autotorrent-output-dir <AT_OUTPUT_DIR>
                                    Directory to write AutoTorrent output.
                                    (default: temp folder)

  notification (Apprise) option:
  -n, --notification {off,simple,list} [NOTIF_CONFIG_PATH]
                                    Notification parameters.

    Notification mode:
        off:      Disabled. (default)
        simple:   Send the number of added torrents.
        list:     Send the name of each torrent.

    Configuration file path:
        <NOTIF_CONFIG_PATH>         Only requested, if notification are enabled.
                                    Should be in TEXT or YAML format.
                                    See Apprise wiki.
'
}

# Runtime options
while true ; do
    case "$1" in
        -h|--help)
            _help ;exit 0 ;;
        -T|--torrent-dir)
            torrent_dir="$2" ;shift 2 ;;
        -K|--keep-torrent)
            keep_torrent=true ;shift 1 ;;
        -N|--no-search)
            no_search=true ;shift 1 ;;
        -i|--ignore-pattern)
            ignore_pattern="$2" ;shift 2 ;;
        -u|--jackett-url)
            jackett_url="$2" ;shift 2 ;;
        -k|--jackett-key)
            jackett_key="$2" ;shift 2 ;;
        -d|--delay)
            delay="$2" ;shift 2 ;;
        -t|--trackers)
            trackers="$2" ;shift 2 ;;
        -s|--search-dir)
            search_dir_list="$2" ;shift 2 ;;
        -o|--filter-old)
            case "$2" in
            day|week|month|none) old_filter="$2" ;;
            *) _error "Unknown '-o/--filter-old' parameter: '$2' (day, week, month or none)" ;_help ;exit 1 ;;
            esac
            shift 2 ;;
        -c|--config-path)
            config_path="$2" ;shift 2 ;;
        -r|--autotorrent-output-dir)
            autotorrent_output_dir="$2" ;shift 2 ;;
        -n|--notification)
            case "$2" in
            off|simple|list) notification="$2" ;;
            *) _error "Unknown '-n/--notification' parameter: '$2' (off, simple or list)" ;_help ;exit 1 ;;
            esac
            if [[ "${2}" == 'off' ]] ; then
                shift 2
            else
                notif_config_path="$3"
                _check_file "${notif_config_path}" '-n/--notification'
                shift 3
            fi ;;
        -?*)
            _error "Unknown option: '$1'" ;_help ;exit 1 ;;
        *)
            break ;;
    esac
done

# Check options
_check_directory "${torrent_dir}" '-T/--torrent-dir'
if [[ $no_search != true ]]; then
    _check_filled_value "${jackett_url}" '-u/--jackett-url'
    _check_filled_value "${jackett_key}" '-k/--jackett-key'
    _cap_min_integer "${delay}" 1 '-d/--delay'
    delay=$cap_min_integer_result
    [[ "${delay}" == "${CONST_DELAY}" ]] && { _info "-d/--delay set at ${CONST_DELAY}s (default value)." ; }
    _check_filled_value "${trackers}" '-t/--trackers'
    _check_directory "${search_dir_list}" '-s/--search-dir'
fi
_check_file "${config_path}" '-c/--config-path'
[[ "${autotorrent_output_dir}" == '' ]] && { autotorrent_output_dir=$(mktemp -d) ; }
_check_directory "${autotorrent_output_dir}" '-r/--autotorrent-output-dir'

# Finds cross-seedable torrents 
echo -e '\n''[ SEARCH TORRENT WITH CROSS-SEED-AUTODL ]'
if [[ $no_search != true ]]; then

    # Support for comma-separated list
    IFS=","
    for search_dir in ${search_dir_list}
    do
        echo -e "> ${search_dir}:"'\n'
        [[ -z "$(ls -A ${search_dir})" ]] && { _info "Empty directory" ; echo ; continue ; }
        # List Path to check with Cross-Seed-AutoDL
        for pathToCheck in "${search_dir}"/*; do
            dirnameToCheck=$(_dirname "$pathToCheck")
            if [[ "$ignore_pattern" == '' ]] || [[ "$pathToCheck" != "${search_dir}/${ignore_pattern}"* ]]; then
                if [[ "$old_filter" != 'none' ]] && [[ $(date +%s -r "$pathToCheck") -lt $(date +%s --date="1 $old_filter ago") ]]; then
                    _info "Skipped by option \"-o/--filter-old '$old_filter'\": $dirnameToCheck (older than a $old_filter)"
                    continue
                fi
                echo "(> $pathToCheck <)"
                [[ "$old_filter" != 'none' ]] && { echo "(younger than 1 ${old_filter} ago)" ; }
                "${python3}" "${cross_seed}" \
                    -d "${delay}" \
                    -i "${pathToCheck}" \
                    -s "${torrent_dir}" \
                    -u "${jackett_url}" \
                    -k "${jackett_key}" \
                    -t "${trackers}"
                [[ $? != 0 ]] && { _error "Cross-Seed-AutoDL fail" ; cs_fail=true ; }
                echo
            else
                _info "Ignored folder by option \"-i/--ignore-pattern '${ignore_pattern}'\": $dirnameToCheck (name start with '${ignore_pattern}')"
                continue
            fi
        done
        echo
    done
    IFS=""
else
    _info "Torrents search skipped by '-N/--no-search'"
fi

# Rebuilds the database of AutoTorrent
echo -e '\n''[ REBUILDING DATABASE OF AUTOTORRENT ]'
$auto_torrent -c "${config_path}" -r
[[ $? != 0 ]] && { _error "AutoTorrent fail" ; at_fail=true ; }

# Add all torrents with autotorrent
echo -e '\n''[ ADD TORRENTS TO THE TORRENT CLIENT ]'
if [[ $(find "${torrent_dir}" -name "*.torrent" -type f) = '' ]]; then
    _warning "No torrent files in ${torrent_dir}"
else
    at_outputPath="${autotorrent_output_dir}/autotorrent_$(date +%F_%H.%M.%S)".log
    $auto_torrent \
        -c "${config_path}" \
        -a "${torrent_dir}/"* \
        | tee "${at_outputPath}"
    [[ ${PIPESTATUS[0]} != 0 ]] && { _error "AutoTorrent fail" ; at_fail=true ; }
    _info "AutoTorrent output saved to ${at_outputPath}"

    # Parsing Autotorrent Output
    echo -e '\n''[ PARSING AUTOTORRENT OUTPUT ]'

    pattern="(?<=').*(?=')|(?<=\").*(?=\")"
    while IFS= read -r line; do
    case "$line" in
        Found*)
            nbTorrent=$(echo "$line" | grep -Po '\d+')
            ;;
        \ [*OK*)
            nameOK[$nbOK]=$(echo "$line" | grep -Po "$pattern")
            nbOK=$(( nbOK + 1 ))
            ;;
        \ [*Seeded*)
            nameSeeded[$nbSeeded]=$(echo "$line" | grep -Po "$pattern")
            nbSeeded=$(( nbSeeded + 1 ))
            ;;
        \ [*Missing*)
            nameMissing[$nbMissing]=$(echo "$line" | grep -Po "$pattern")
            nbMissing=$(( nbMissing + 1 ))
            ;;
        \ [*Exists*)
            nameExists[$nbExists]=$(echo "$line" | grep -Po "$pattern")
            nbExists=$(( nbExists + 1 ))
            ;;
        \ [*Failed*)
            nameFailed[$nbFailed]=$(echo "$line" | grep -Po "$pattern")
            nbFailed=$(( nbFailed + 1 ))
            ;;
        *)
            _warning "Unknown line from AutoTorrent output: '${line}'"
            ;;
    esac
    done < "${at_outputPath}"
    echo Done.
fi

if [[ $nbFailed -gt 0 ]]; then
    _error "$nbFailed torrent(s) failed to be added:"
    printf '%s\n' "${nameFailed[@]}"
fi

# Notification
echo -e '\n''[ NOTIFICATION ]'
case "$notification" in
    off)
        _info "Notification skipped by '-n/--notification off'"
        ;;
    simple)
        if [[ $cs_fail = true ]]; then
            apprise -b "❌ Cross-Seed-AutoDL fail !" -c "${notif_config_path}"
        elif [[ $at_fail = true ]]; then
            apprise -b "❌ AutoTorrent fail !" -c "${notif_config_path}"
        elif [[ $nbOK -gt 0 ]]; then
            apprise -b "✅ $nbOK torrent(s) added successfully." -c "${notif_config_path}"
        fi
        [[ $nbFailed -gt 0 ]] && apprise -b "⚠️ $nbOK torrent(s) failed during the addition." -c "${notif_config_path}"
        echo Done.
        ;;
    list)
        if [[ $cs_fail = true ]]; then
            apprise -b "❌ Cross-Seed-AutoDL fail !" -c "${notif_config_path}"
        fi
        if [[ $at_fail = true ]]; then
            apprise -b "❌ AutoTorrent fail !" -c "${notif_config_path}"
        fi
        if [[ $nbOK -gt 0 ]]; then
            apprise -t "$nbOK torrent(s) added successfully:" -b "" -c "${notif_config_path}"
            for i in "${nameOK[@]}"; do
                apprise -b "- ✅ $i" -c "${notif_config_path}"
            done
        fi
        if [[ $nbFailed -gt 0 ]]; then
            apprise -t "$nbFailed torrent(s) failed during the addition:" -b "" -c "${notif_config_path}"
            for i in "${nameFailed[@]}"; do
                apprise -b "- ⚠️ $i" -c "${notif_config_path}"
            done
        fi
        echo Done.
        ;;
esac

# Flush torrents
echo -e '\n''[ REMOVE TORRENTS ]'
if [[ $cs_fail != true ]] &&  [[ $at_fail != true ]]; then
    if [[ $keep_torrent != true ]]; then
        find "${torrent_dir}" -name "*.torrent" -type f -exec rm -v {} \;
        echo Done.
    else
        _info "Removal skipped by '-K/--keep-torrent'"
    fi
else
    _warning "Torrents have been kept after a fail of Cross-Seed-AutoDL or AutoTorrent"
fi
echo
