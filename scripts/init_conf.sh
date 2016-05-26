#******************************************************************************************************************************
#
#   <init_conf> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       Initialization and Configuration file for 'pl_bash_functions'
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   GENERAL FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Sets the PL_BASH_FUNCTIONS Global Variables to readonly: we do that separate to allow for proper testing of: `tests_all.sh`
#******************************************************************************************************************************
i_set_pl_bash_function_var_readonly() {
    readonly _BF_VERSION _BF_OUT _BF_OUT_I _BF_OFF _BF_BOLD _BF_RED _BF_GREEN _BF_YELLOW _BF_BLUE _BF_MAGENTA
}


#******************************************************************************************************************************
# General Options: Keep it in a function so we can call it again if needed
#******************************************************************************************************************************
i_general_opt() {
    unset GREP_OPTIONS

    set +o allexport
    set -o braceexpand          # -o: Brace expansion is a mechanism by which arbitrary strings may be generated.
    set +o emacs
    set +o errexit              # +o: do not use this one
    # <errtrace>: needed for trap on ERR: If set, any trap on ERR is inherited by shell functions, command substitutions, and
    #             commands executed in a subshell environment.
    set -o errtrace
    set +o functrace
    set -o hashall
    set +o histexpand           # +o: need this to allow !! strings in double quotes
    set -o history
    set +o ignoreeof
    set -o interactive-comments
    set +o keyword
    set +o monitor              # +o:
    set +o noclobber            # +o: is required by some functions
    set +o noexec
    set +o noglob
    set +o nolog
    set +o notify
    set -o nounset              # -o: using this stricter setting for code robustness
    set +o onecmd
    set +o physical
    set -o pipefail             # -o: using this stricter setting for code robustness
    set +o posix                # +o: need this: otherwise tests_all.sh aborts on: readonly variable
    set -o privileged
    set +o verbose
    set +o vi
    set +o xtrace

    shopt -u autocd
    shopt -u cdable_vars
    shopt -u cdspell
    shopt -u checkhash
    shopt -u checkjobs
    shopt -u checkwinsize
    shopt -s cmdhist
    shopt -u compat31
    shopt -u compat32
    shopt -u compat40
    shopt -u compat41
    shopt -u compat42
    shopt -s complete_fullquote
    shopt -u direxpand
    shopt -u dirspell
    shopt -s dotglob                # -s: needed for some functions
    shopt -u execfail
    shopt -s expand_aliases         # -s: needed for our aliases
    shopt -s extdebug
    shopt -s extglob                # -s: needed for some functions
    shopt -s extquote
    shopt -u failglob
    shopt -s force_fignore
    shopt -u globstar
    shopt -u globasciiranges
    shopt -u gnu_errfmt
    shopt -u histappend
    shopt -u histreedit
    shopt -u histverify
    shopt -s hostcomplete
    shopt -u huponexit
    # <interactive_comments> -s: An interactive shell without the interactive_comments option enabled does not allow comments.
    shopt -s interactive_comments
    shopt -u lastpipe
    shopt -u lithist
    shopt -u login_shell
    shopt -u mailwarn
    shopt -u no_empty_cmd_completion
    shopt -u nocaseglob
    shopt -u nocasematch        # -u: needed
    shopt -u nullglob           # -u: needed
    shopt -s progcomp
    shopt -s promptvars
    shopt -u restricted_shell
    shopt -u shift_verbose
    shopt -s sourcepath
    shopt -u xpg_echo

    if [[ ! $(type -p "gettext") || ! $(type -p "tput") ]]; then
        # REMEMBER: we can not use gettext for this messages
        printf "-> FUNCTION 'i_general_opt()': MISSING COMMAND: 'gettext' and 'tput' are both required.\n\n" >&2
        exit 1
    fi

    # Set Aliases
    alias _g='gettext'
}


#******************************************************************************************************************************
# Retrieve the Process-Group-ID from any Process-ID
#
#   ARGUMENTS
#       `_retpgid`: a reference var: should be declare as integer
#       `_pid`: integer of a process PID
#
#   USAGE: declare  -i _PGID; i_get_pgid _PGID ${_PID}
#******************************************************************************************************************************
i_get_pgid() {
    local -n _retpgid=${1}
    local _pid=${2}
    # Note: ps inserts leading spaces when PID is less than five digits and right aligned
    #       assigning it directoy to a integer saves stripping this in case the _retpgid was not an integer
    declare -i _tmp=$(ps -o pgid --no-headers ${_pid})
    _retpgid=${_tmp}
}


#******************************************************************************************************************************
# Sources a file inclusive any arguments: aborts on error: This is added here so it can be used for all other sourcing.
#******************************************************************************************************************************
i_source_safe_exit() {
    (( ${#} < 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '1' argument (_file). Got '%s'")" "${#}"
    local _file=${1}

    shopt -u extglob
    source "${@}" || i_exit ${?} ${LINENO} "$(_g "Could not source file: <%s>")" "${_file}"
    shopt -s extglob     # reset SHELLOPTS
}


#******************************************************************************************************************************
# Returns the installation directory of the used: pl_bash_functions
#
#   USAGE: local _ret_r; i_pl_bash_functions_dir _ret_r
#******************************************************************************************************************************
i_pl_bash_functions_dir() {
    local -n _ret_r=${1}
    _ret_r=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
}


#******************************************************************************************************************************
# Display a warning if the pl_bash_functions version is different than the one your script was tested with
#
#   USAGE: i_has_tested_version "0.0.1"
#******************************************************************************************************************************
i_has_tested_version() {
    local __tested_vers=${1}
    local _m1=$(_g "WARNING:")
    local _m2=$(_g "This script was %sTESTET%s with <pl_bash_functions>: '%s'")
    local _m3=$(_g "You've got <pl_bash_functions>: '%s'")
    local _plfunc_dir

    if [[ ${_BF_VERSION} != ${__tested_vers} ]]; then
        printf "${_BF_YELLOW}====> ${_m1}${_BF_OFF} ${_m2}${_BF_OFF}\n" "${_BF_BOLD}" "${_BF_OFF}" "${__tested_vers}" >&2
        printf "               ${_m3}\n" "${_BF_VERSION}" >&2
        i_pl_bash_functions_dir _plfunc_dir
        printf "                 PATH: <%s>\n\n" "${_plfunc_dir}" >&2
    fi
}


#******************************************************************************************************************************
# General request for a manual input of the user to continue execution.
#
#   OPTIONAL ARGUMENTS
#       '_user': set under which user the script must run
#
#   USAGE:
#       i_ask_continue
#       i_ask_continue "root"
#******************************************************************************************************************************
i_ask_continue() {
    local _user=${1:-""}
    local _m1=$(_g "This script MUST run under User-Account: '%s'")
    local _m2=$(_g "INFO: Please run this script in %sMAXIMIZED%s terminal.")
    local _m3=$(_g "To %sINTERRUPT%s at any time press [%sctrl+c%s].")
    local _m4=$(_g "To %sCONTINUE%s type: [%sYES%s]: ")
    local _input

    printf "\n"
    if [[ -n ${_user} ]]; then
        if [[ $(whoami) != ${_user} ]]; then
            printf "${_BF_BLUE}        ${_m1}${_BF_OFF}\n" "${_user}" >&1
            i_exit 1 ${LINENO} "$(_g "Got EUID: '%s' USER: '%s'")" "$EUID" "$(whoami)"
        fi
    fi
    printf "${_BF_GREEN}====> ${_BF_OFF}${_m2}\n" "${_BF_BOLD}" "${_BF_OFF}" >&1
    printf "        ${_m3}\n\n" "${_BF_BOLD}" "${_BF_OFF}" "${_BF_GREEN}" "${_BF_OFF}" >&1
    printf "                ${_m4}" "${_BF_BOLD}" "${_BF_OFF}" "${_BF_GREEN}" "${_BF_OFF}" >&1
    read _input
    [[ ${_input} == "YES" ]] || exit 1
    printf "\n"
}


#=============================================================================================================================#
#
#                   TRAP FUNCTIONS
#
# COMMON USAGE
#
#     source "/path_to/init_conf.sh"
#
#     for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
#     trap 'i_trap_i ${?}' INT
#     trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR
#
#       IMPORTANT: do use the 'single quotes' to get correct exit-status codes and NOT double quotes
#
# COMMON USAGE With CLEANUP Function
#
#     source "/path_to/init_conf.sh"
#
#     for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}" "own_cleanup_function_name"' "${_signal}"; done
#     trap 'i_trap_i ${?} "own_cleanup_function_name"' INT
#     trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO} "own_cleanup_function_name"' ERR
#=============================================================================================================================#

#******************************************************************************************************************************
# Prints information about the error and optionally executed an function before killing related processes.
#
#   ARGUMENTS
#       `_exc`: the 'exit code' used for the error message.
#       `_lines`: bash stack line number entries: BASH_LINENO[@]
#       `_src`: bash stack source entries: BASH_SOURCE[@]
#       `_func`: bash stack function name entries: FUNCNAME[@]
#       `_fname`: empty or a name of a function to run before the final exit: usful for cleanup etc..
#
#   USAGE: i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "cleanup_function"
#******************************************************************************************************************************
i_common_exit() {
    declare -i _exc=${1}
    local _lines=( ${!2} )
    local _src=( "${!3}" )
    local _func=( "${!4}" )
    local _fname=${5:-""}
    local _m1=$(_g "Exit Status: '%s'")
    local _m2=$(_g "Line:")
    local _m3=$(_g "File:")
    local _m4=$(_g "ERROR INFO STACK")
    local _m4=$(_g "CALL STACK INFO")
    local _m5=$(_g "called Function:")
    local _off=${_BF_OFF}           # shorten the var name: so we keep the line char limit
    local _b=${_BF_BOLD}            # shorten the var name: so we keep the line char limit
    local _ssize=${#FUNCNAME[@]}    # stack size
    declare  -i _pgid; i_get_pgid _pgid ${BASHPID}
    declare -i _n _line

    printf "${_BF_YELLOW}    ============== ${_m4} ==============${_off}\n\n" >&2
    printf "${_b}      -> ${_off}${_m2} '${_b}${BASH_LINENO[${_ssize}-1]}${_off}' ${_m3} <${BASH_SOURCE[${_ssize}-1]}>\n" >&2
    printf "         ${_m5} '${_b}${FUNCNAME[${_ssize}-1]}${_off}' ${_m3} <${BASH_SOURCE[${_ssize}-1]}>\n\n" >&2
    for (( _n=${_ssize}-2; _n > -1; _n-- )); do
        _line=${BASH_LINENO[${_n}]}
        printf "${_b}      -> ${_off}${_m2} '${_b}${BASH_LINENO[${_n}]}${_off}' ${_m3} <${BASH_SOURCE[${_n}+1]}>\n" >&2
        printf "         ${_m5} '${_b}${FUNCNAME[${_n}]}${_off}' ${_m3} <${BASH_SOURCE[${_n}]}>\n\n" >&2
    done
    printf "${_BF_YELLOW}    ============== =============== ==============${_off}\n\n\n\n" >&2

    if [[ -n ${_fname} ]]; then
        if (declare -f "${_fname}" >/dev/null); then
            printf "$(_g "      ${_b}-> Running function: <%s>${_off} before exit.${_off}")\n\n" "${_fname}"
            ${_fname}    # Run it
        else
            # Important to avoid infinit recursive loop do NOT give a _fname
            i_exit _exc ${LINENO} "$(_g "CODE-ERROR Could not find the specified function: '%s' to run before exiting.\n\n")" \
                "${_fname}"
        fi
    fi

    if (( ${_BF_ON_ERROR_KILL_PROCESS} > 0 )); then
        printf "$(_g "Going to kill all related processes in '%s' seconds.")\n\n" ${_BF_ON_ERROR_KILL_PROCESS} >&2
        sleep ${_BF_ON_ERROR_KILL_PROCESS}
        setsid kill  -s SIGKILL -${_pgid}
    fi
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_exc`: the exit signal code used for the error message.
#       `_signal`: exit signal type
#
#   OPTIONAL ARGUMENTS
#       `_fname`: a name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
i_trap_s() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    declare -i _exc=${1}
    local _signal=${2}
    local _fname=${3:-""}
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Exit Status:")
    local _m3=$(_g "File:")
    local _exc_filebasename=${BASH_SOURCE[1]}

    _exc_filebasename=${_exc_filebasename%%+(/)}
    _exc_filebasename=${_exc_filebasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]} (signal: '%s')> ${_BF_OFF}\n" \
        "${_signal}" >&2
    printf "${_BF_RED}    -> ${_m2} '${_exc}'${_BF_OFF} ${_m3} '${_BF_BOLD}${_exc_filebasename}${_BF_OFF}'\n\n" >&2

    i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "${_fname}"
    exit ${_exc}  # returnt he original error code
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_exc`: the exit signal code used for the error message.
#
#   OPTIONAL ARGUMENTS
#       `_fname`: a name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
i_trap_i() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    declare -i _exc=${1}
    local _fname=${2:-""}
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Interrupted by user! Exit Status:")
    local _m3=$(_g "File:")
    local _exc_filebasename=${BASH_SOURCE[1]}

    _exc_filebasename=${_exc_filebasename%%+(/)}
    _exc_filebasename=${_exc_filebasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]}> ${_BF_OFF}\n" >&2
    printf "${_BF_RED}    -> ${_m2} '${_exc}'${_BF_OFF} ${_m3} '${_BF_BOLD}${_exc_filebasename}${_BF_OFF}'\n\n" >&2

    i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "${_fname}"
    exit ${_exc}  # returnt he original error code
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_exc`: the exit signal code used for the error message.
#       `_cmd`: command: ${BASH_COMMAND}
#       `_lineno`: command: ${LINENO}
#
#   OPTIONAL ARGUMENTS
#       `_fname`: a name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
i_trap_err() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    declare -i _exc=${1}
    declare _cmd=${2}
    local _lineno=${3}
    local _fname=${4:-""}
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Exit Status:")
    local _m3=$(_g "Line:")
    local _m4=$(_g "File:")
    local _m5=$(_g "Command:")
    local _exc_filebasename=${BASH_SOURCE[1]}

    _exc_filebasename=${_exc_filebasename%%+(/)}
    _exc_filebasename=${_exc_filebasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]}> ${_BF_OFF}\n" >&2
    printf "${_BF_RED}    -> ${_m2} '${_exc}'${_BF_OFF} ${_m3} '${_BF_BOLD}${_lineno}${_BF_OFF}' " >&2
    printf "${_m4} '${_BF_BOLD}${_exc_filebasename}${_BF_OFF}' ${_m5} '${_BF_BOLD}${_cmd}${_BF_OFF}'\n\n" >&2

    i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "${_fname}"
    exit ${_exc}  # returnt he original error code
}



#=============================================================================================================================#
#
#                   pl_bash_functions RELATED FUNCTIONS - version, installed directory etc..
#
#=============================================================================================================================#

#=============================================================================================================================#
#
#                   MESSAGE FUNCTIONS - functions for outputting messages
#
#   Provides easy output formatting functions with different levels of indentation, colors etc..
#   The general message functions print to stdout and can be silenced by defining '_BF_OUT="no"'.
#   Any additional general info messages can be silenced by defining '_BF_OUT_I=no'.
#   Other message functions print to stderr.
#
#   * USAGE EXAMPLE - MESSAGE FORMAT: To support translation the messages format should be:
#
#       i_bold $(_g "Some Info...")
#       i_bold $(_g "The files path is: %s")  $FILEPATH
#       i_bold $(_g "Source file:  %s") $(get_filename "${1}")
#
#=============================================================================================================================#

#******************************************************************************************************************************
# ABORTING message: always enabled
#
#   ARGUMENTS
#       `_exc`: the exit signal code used for the error message.
#       `_lineno`: command: ${LINENO}
#       `_msg`: the info/error message
#
#   USAGE
#       local _example="no"
#       local _example_path="/home/examples"
#       [[ ${_example} == "yes" ]] || i_exit ${?} ${LINENO} "$(_g "Did not find any examples in: '%s'")" "${_example_path}"
#******************************************************************************************************************************
i_exit() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    (( ${#} < 3 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '3' arguments. Got '%s'")" "${#}"
    declare -i _exc=${1}
    local _lineno=${2}
    local _msg=${3}; shift
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Exit Status:")
    local _m3=$(_g "Line:")
    local _m4=$(_g "File:")
    local _m5=$(_g "MESSAGE")
    local _exc_filebasename=${BASH_SOURCE[1]}

    _exc_filebasename=${_exc_filebasename%%+(/)}
    _exc_filebasename=${_exc_filebasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]}> ${_BF_OFF}\n" >&2
    printf "${_BF_RED}    -> ${_m2} '${_exc}'${_BF_OFF} ${_m3} '${_BF_BOLD}${_lineno}${_BF_OFF}' " >&2
    printf "${_m4} '${_BF_BOLD}${_exc_filebasename}${_BF_OFF}'\n\n\n" >&2

    printf "${_BF_YELLOW}    -> MESSAGE !!${_BF_OFF}${_BF_BOLD} ${_msg}${_BF_OFF}\n\n\n" "${@:3}" >&2

    i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] ""
    exit ${_exc}  # returnt he original error code
}


#******************************************************************************************************************************
# ABORTING message: always enabled
#
#   ARGUMENTS
#       `_exc`: the exit signal code used for the error message.
#       `_lineno`: command: ${LINENO}
#       `_do_remove`: yes or no: if yes any existing path specified in `` will be removed before exiting.
#       `_path`: empty or absolute path
#       `_msg`: the info/error message
#
#   USAGE
#       local _example_path="/home/examples"
#       i_exit_remove_path ${?} ${LINENO} "yes" "${_example_path}" "$(_g "No examples")"
#******************************************************************************************************************************
i_exit_remove_path() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    (( ${#} < 5 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '5' arguments. Got '%s'")" "${#}"
    if [[ ${3} != "yes" && ${3} != "no" ]]; then
        i_exit 1 ${LINENO} "$(_g "FUNCTION Argument '3' (_do_remove) MUST be 'yes' or 'no'. Got '%s'")" "${3}"
    fi
    if [[ ${3} == "yes" && -z ${4} ]]; then
        i_exit 1 ${LINENO} \
            "$(_g "FUNCTION Argument '4' (_path) MUST NOT be empty if argument '3' (_do_remove) is 'yes'")"
    fi

    declare -i _exc=${1}
    local _lineno=${2}
    local _do_remove=${3}
    local _path=${4}
    local _msg=${5}; shift
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Exit Status:")
    local _m3=$(_g "Line:")
    local _m4=$(_g "File:")
    local _m5=$(_g "MESSAGE")
    local _exc_filebasename=${BASH_SOURCE[1]}

    _exc_filebasename=${_exc_filebasename%%+(/)}
    _exc_filebasename=${_exc_filebasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]}> ${_BF_OFF}\n" >&2
    printf "${_BF_RED}    -> ${_m2} '${_exc}'${_BF_OFF} ${_m3} '${_BF_BOLD}${_lineno}${_BF_OFF}' " >&2
    printf "${_m4} '${_BF_BOLD}${_exc_filebasename}${_BF_OFF}'\n\n\n" >&2

    printf "${_BF_YELLOW}    -> MESSAGE !!${_BF_OFF}${_BF_BOLD} ${_msg}${_BF_OFF}\n\n\n" "${@:5}" >&2

    if [[ ${_do_remove} == "yes" ]]; then
        i_more_i "$(_g "Removing path: <%s>")\n\n" "${_path}" >&2
        rm -rf "${_path}"
    fi

    i_common_exit ${_exc} BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] ""
    exit ${_exc}  # returnt he original error code
}


#******************************************************************************************************************************
# ERROR message: always enabled
#******************************************************************************************************************************
i_err() {
    local _m=${1}; shift
    printf "${_BF_RED}====> $(_g "ERROR:")${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ERROR message 2: always enabled
#******************************************************************************************************************************
i_err2() {
    local _m=${1}; shift
    printf "${_BF_RED}    ====> $(_g "ERROR:")${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# WARNING message: always enabled
#******************************************************************************************************************************
i_warn() {
    local _m=${1}; shift
    printf "${_BF_YELLOW}====> $(_g "WARNING:")${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# WARNING message 2: always enabled
#******************************************************************************************************************************
i_warn2() {
    local _m=${1}; shift
    printf "${_BF_YELLOW}    ====> $(_g "WARNING:")${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# Main-Bold message: enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_bold() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BOLD}====> ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main-Bold message (indented level): enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_bold_i() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BOLD}       ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message: enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_bold2() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BOLD}    ====> ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message (indented level): enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_bold2_i() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BOLD}           ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main message: enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_msg() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_GREEN}====>${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main message short blue arrow: enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_msg_b() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BLUE}-->${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Sub message (indented level): enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_msg_i() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BLUE}    ->${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Main message: enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_msg2() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_GREEN}    ====>${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Sub message (indented level): enabled by '_BF_OUT="yes"'
#******************************************************************************************************************************
i_msg2_i() {
    [[ ${_BF_OUT} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_BF_BLUE}        ->${_BF_OFF}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# More-Info message: enabled by '_BF_OUT_I="yes" '
#******************************************************************************************************************************
i_more() {
    [[ ${_BF_OUT_I} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "  INFO: ${_m}\n" "${@}" >&1
}


#******************************************************************************************************************************
# More-Info message (indented level): enabled by '_BF_OUT_I="yes" '
#******************************************************************************************************************************
i_more_i() {
    [[ ${_BF_OUT_I} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "         INFO: ${_m}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Color message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'i_format()'
#******************************************************************************************************************************
i_color() {
    local _format=${1}
    local _m=${2}; shift
    printf "${_format}${_m}${_BF_OFF}\n" "${@:2}" >&1
}


#******************************************************************************************************************************
# Formatted Header message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'i_format()'
#******************************************************************************************************************************
i_header() {
    local _format=${1}
    local _m=${2}; shift

    printf "${_format}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "# ${_m}\n" "${@:2}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_BF_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Header message (indented level): always enabled
#******************************************************************************************************************************
i_header_i() {
    local _format=${1}
    local _m=${2}; shift

    printf "${_format}\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "    #\n" >&1
    printf "    # ${_m}\n" "${@:2}" >&1
    printf "    #\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "${_BF_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Horizontal Line: always enabled: '_format' SHOULD BE one of the defined variables of function: 'i_format()'
#
#   USAGE:
#       i_format
#       i_hrl "${_BF_GREEN}" "#" "=" 25 "#"
#
#   OUTPUT: Green line '#=========================#'
#******************************************************************************************************************************
i_hrl() {
    (( ${#} != 5 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '5' arguments. Got '%s'")" "${#}"
    local _format=${1}
    local _start_txt=${2}
    local _repeated_text=${3}
    local _repeat=${4}
    local _end_text=${5}
    local _line=""

    while (( ${#_line} < ${_repeat} )); do
        _line+=${_repeated_text}
    done
    printf "${_format}%s%s%s${_BF_OFF}\n" "${_start_txt}" "${_line:0:_repeat}" "${_end_text}" >&1
}



#=============================================================================================================================#
#
#                   SETUP ENVIROMENT: source pl_bash_functions, set variables etc..
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Set General Settings
#******************************************************************************************************************************

# IMPORTANT: Remove all aliases: this should not be in the function: i_general_opt
unalias -a
# Set general options
i_general_opt

declare _BF_VERSION='0.9.4'

declare -i _BF_ON_ERROR_KILL_PROCESS=-1


#******************************************************************************************************************************
# Sets the message formatting Variables
#******************************************************************************************************************************
declare _BF_OUT="yes"
declare _BF_OUT_I="yes"
declare _BF_OFF=$(tput sgr0)
declare _BF_BOLD=$(tput bold)
declare _BF_RED="${_BF_BOLD}$(tput setaf 1)"
declare _BF_GREEN="${_BF_BOLD}$(tput setaf 2)"
declare _BF_YELLOW="${_BF_BOLD}$(tput setaf 3)"
declare _BF_BLUE="${_BF_BOLD}$(tput setaf 4)"
declare _BF_MAGENTA="${_BF_BOLD}$(tput setaf 5)"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
