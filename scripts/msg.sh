#******************************************************************************************************************************
#
#   <msg.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

unset GREP_OPTIONS
shopt -s extglob dotglob
set +o noclobber



#=============================================================================================================================#
#
#                   pl_bash_functions RELATED FUNCTIONS - version, installed directory etc..
#
#=============================================================================================================================#

#******************************************************************************************************************************
#   USAGE: local _result; ms_get_pl_bash_functions_version _result
#******************************************************************************************************************************
ms_get_pl_bash_functions_version() {
    local _fn="ms_get_pl_bash_functions_version"
    local -n _ret_result=${1}
    local _this_script_dir_msg; ms_pl_bash_functions_installed_dir _this_script_dir_msg
    local _main_conf_file_path="${_this_script_dir_msg}/main_conf.sh"
    local _msg1=$(gettext "HINT:")
    local _msg2=$(gettext "MAYBE you forgot to run 'make install' or 'make generate'!")

    if ! source "${_main_conf_file_path}"; then
        echo
        echo
        printf "${_MS_YELLOW}   => ${_msg1}${_MS_ALL_OFF} ${_msg2}${_MS_ALL_OFF}\n"
        ms_abort "${_fn}" "$(gettext "Could not source: <%s>")" "${_main_conf_file_path}"
    fi
    _ret_result=${_PL_BASH_FUNCTIONS_VERSION}

}


#******************************************************************************************************************************
# Display a warning if the pl_bash_functions version is different than the one your script was tested with
#
#   USAGE: ms_has_tested_version "0.0.1"
#******************************************************************************************************************************
ms_has_tested_version() {
    local _tested_version=${1}
    local _version; ms_get_pl_bash_functions_version _version
    local _msg1=$(gettext "WARNING:")
    local _msg2=$(gettext "This script was %sTESTET%s with <pl_bash_functions>: '%s'")
    local _msg3=$(gettext "You've got <pl_bash_functions>: '%s'")
    local _installed_dir

    if [[ ${_version} != ${_tested_version} ]]; then
        printf "${_MS_YELLOW}====> ${_msg1}${_MS_ALL_OFF} ${_msg2}${_MS_ALL_OFF}\n" "${_MS_BOLD}" "${_MS_ALL_OFF}" \
            "${_tested_version}" >&2
        printf "               ${_msg3}\n" "${_version}" >&2
        ms_pl_bash_functions_installed_dir _installed_dir
        printf "                 ${_msg4}\n\n" "${_installed_dir}" >&2
    fi
}


#******************************************************************************************************************************
# Returns the installation directory of the used: pl_bash_functions
#
#   USAGE: local _result; ms_pl_bash_functions_installed_dir _result
#******************************************************************************************************************************
ms_pl_bash_functions_installed_dir() {
    local -n _ret_result=${1}
    _ret_result=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
}



#=============================================================================================================================#
#
#                   MESSAGE FUNCTIONS - functions for outputting messages
#
#   Provides easy output formatting functions with different levels of indentation, colors etc..
#   The general message functions print to stdout and can be silenced by defining '_MS_VERBOSE="no"'.
#   Any additional general info messages can be silenced by defining '_MS_VERBOSE_MORE=no'.
#   Other message functions print to stderr.
#
#   * USAGE EXAMPLE - MESSAGE FORMAT: To support translation the messages format should be:
#
#       ms_bold $(gettext "Some Info...")
#       ms_bold $(gettext "The files path is: %s")  $FILEPATH
#       ms_bold $(gettext "Source file:  %s") $(get_filename "${1}")
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Sets the message formatting and related command checks
#
#   ARGUMENTS
#       `_calling_script_path`: We pass the calling script PATH to the function in case of error messages.
#
#   USAGE
#
#       ms_format "${_THIS_SCRIPT_PATH}"
#******************************************************************************************************************************
ms_format() {
    local _fn="ms_format"
    if (( ${#} != 1 )); then
        # REMEMBER: we can not use gettext or ms_abort for this messages
        printf "-> FUNCTION '%s()': Requires EXACT '1' argument. Got '%s'\n\n" "${_fn}" "${#}" >&2
        exit 1
    fi
    local _calling_script_path=${1}
    _MS_VERBOSE="yes"
    _MS_VERBOSE_MORE="yes"

    if [[ ! $(type -p "gettext") || ! $(type -p "tput") ]]; then
        # REMEMBER: we can not use gettext or ms_abort for this messages
        printf "-> FUNCTION '%s()': MISSING COMMAND: 'gettext' and 'tput' are both required.\n\n" "${_fn}" >&2
        exit 1
    fi

    _MS_ALL_OFF=$(tput sgr0)
    _MS_BOLD=$(tput bold)
    _MS_RED="${_MS_BOLD}$(tput setaf 1)"
    _MS_GREEN="${_MS_BOLD}$(tput setaf 2)"
    _MS_YELLOW="${_MS_BOLD}$(tput setaf 3)"
    _MS_BLUE="${_MS_BOLD}$(tput setaf 4)"
    _MS_MAGENTA="${_MS_BOLD}$(tput setaf 5)"

    readonly _MS_ALL_OFF _MS_BOLD _MS_RED _MS_GREEN _MS_YELLOW _MS_BLUE _MS_MAGENTA
}


#******************************************************************************************************************************
# More-Info message: enabled by '_MS_VERBOSE_MORE="yes" '
#******************************************************************************************************************************
ms_more() {
    [[ ${_MS_VERBOSE_MORE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "  INFO: ${_msg}\n" "${@}" >&1
}


#******************************************************************************************************************************
# More-Info message (indented level): enabled by '_MS_VERBOSE_MORE="yes" '
#******************************************************************************************************************************
ms_more_i() {
    [[ ${_MS_VERBOSE_MORE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "         INFO: ${_msg}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main-Bold message: enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_bold() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BOLD}====> ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main-Bold message (indented level): enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_bold_i() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BOLD}       ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message: enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_bold2() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BOLD}    ====> ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message (indented level): enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_bold2_i() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BOLD}           ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main message: enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_GREEN}====>${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Sub message (indented level): enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg_i() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BLUE}    ->${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Main message: enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg2() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_GREEN}    ====>${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Sub message (indented level): enabled by '_MS_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg2_i() {
    [[ ${_MS_VERBOSE} == "yes" ]] || return 0
    local _msg=${1}; shift
    printf "${_MS_BLUE}        ->${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# WARNING message: always enabled
#******************************************************************************************************************************
ms_warn() {
    local _msg=${1}; shift
    printf "${_MS_YELLOW}====> $(gettext "WARNING:")${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# WARNING message 2: always enabled
#******************************************************************************************************************************
ms_warn2() {
    local _msg=${1}; shift
    printf "${_MS_YELLOW}    ====> $(gettext "WARNING:")${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ERROR message: always enabled
#******************************************************************************************************************************
ms_err() {
    local _msg=${1}; shift
    printf "${_MS_RED}====> $(gettext "ERROR:")${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ERROR message 2: always enabled
#******************************************************************************************************************************
ms_err2() {
    local _msg=${1}; shift
    printf "${_MS_RED}    ====> $(gettext "ERROR:")${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ABORTING message: always enabled: ms_abort "from_where_name" "$(gettext "Message did not find path: '%s'")" "$PATH"
#******************************************************************************************************************************
ms_abort() {
    if (( ${#} < 2 )); then
        ms_abort "ms_abort" "$(gettext "FUNCTION 'ms_abort()': Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    local _from_name=${1}
    local _msg=${2}; shift
    local _abort_text=$(gettext "ABORTING....from:")

    printf "${_MS_MAGENTA}\n\n=======> ${_abort_text}${_MS_ALL_OFF}${_MS_BLUE} <${_from_name}> ${_MS_ALL_OFF}\n" >&2
    printf "${_MS_RED}    ->${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n\n" "${@:2}" >&2
    exit 1
}


#******************************************************************************************************************************
# ABORTING message: always enabled: can optionally remove a path before aborting, useful to clean up before exit
#
#   USAGE:
#       ms_format
#       _remove_path="no"
#       CMK_BUILDS_DIR="/home/TEST DIR/builds"
#       ms_abort_remove_path "from_where_name" "${_remove_path}" "${CMK_BUILDS_DIR}/$pkname" "$(gettext "Failure while ...\n")"
#******************************************************************************************************************************
ms_abort_remove_path() {
    local _fn="ms_abort_remove_path"
    if (( ${#} < 4 )); then
        ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '4' arguments. Got '%s'")" "${_fn}" "${#}"
    fi
    if [[ $2 != "yes" && $2 != "no" ]]; then
        ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '2' MUST be 'yes' or 'no'. Got '%s'")" "${_fn}" "${2}"
    fi
    if [[ $2 == "yes" && -z $3 ]]; then
        ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '3' MUST NOT be empty if argument 2 is 'yes'")" "${_fn}"
    fi
    local _from_name=${1}
    local _remove_option=${2}
    local _path=${3}
    local _msg=${4}; shift
    local _abort_text=$(gettext "ABORTING....from:")

    printf "${_MS_MAGENTA}\n\n=======> ${_abort_text}${_MS_ALL_OFF}${_MS_BLUE} <${_from_name}> ${_MS_ALL_OFF}\n" >&2
    if [[ ${_remove_option} == "yes" ]]; then
        ms_more_i "$(gettext "Removing path: <%s>")\n" "${_path}" >&2
        rm -rf "${_path}"
    fi
    printf "${_MS_RED}    ->${_MS_ALL_OFF}${_MS_BOLD} ${_msg}${_MS_ALL_OFF}\n\n" "${@:4}" >&2
    exit 1
}


#******************************************************************************************************************************
# Color message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'ms_format()'
#******************************************************************************************************************************
ms_color() {
    local _format=${1}
    local _msg=${2}; shift
    printf "${_format}${_msg}${_MS_ALL_OFF}\n" "${@:2}" >&1
}


#******************************************************************************************************************************
# Formatted Header message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'ms_format()'
#******************************************************************************************************************************
ms_header() {
    local _format=${1}
    local _msg=${2}; shift

    printf "${_format}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "# ${_msg}\n" "${@:2}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_MS_ALL_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Header message (indented level): always enabled
#******************************************************************************************************************************
ms_header_i() {
    local _format=${1}
    local _msg=${2}; shift

    printf "${_format}\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "    #\n" >&1
    printf "    # ${_msg}\n" "${@:2}" >&1
    printf "    #\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "${_MS_ALL_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Horizontal Line: always enabled: '_format' SHOULD BE one of the defined variables of function: 'ms_format()'
#
#   USAGE:
#       ms_format
#       ms_hrl "${_MS_GREEN}" "#" "=" 25 "#"
#
#   OUTPUT: Green line '#=========================#'
#******************************************************************************************************************************
ms_hrl() {
    (( ${#} != 5 )) && ms_abort "ms_hrl" "$(gettext "FUNCTION 'ms_hrl()': Requires EXACT '5' arguments. Got '%s'")" "${#}"
    local _format=${1}
    local _start_txt=${2}
    local _repeated_text=${3}
    local _repeat_number=${4}
    local _end_text=${5}
    local _complete_line=""

    while (( ${#_complete_line} < ${_repeat_number} )); do
        _complete_line+=${_repeated_text}
    done
    printf "${_format}%s%s%s${_MS_ALL_OFF}\n" "${_start_txt}" "${_complete_line:0:_repeat_number}" "${_end_text}" >&1
}



#=============================================================================================================================#
#
#                   DIVERSE FUNCTION
#
#=============================================================================================================================#

#******************************************************************************************************************************
# General request for a manual input of the user to continue execution.
#       '_check_user' optional set under which user the script must run
#
#   USAGE:
#       trap "ms_interrupted" SIGHUP SIGINT SIGQUIT SIGTERM
#       ms_format
#       ms_request_continue "root"
#******************************************************************************************************************************
ms_request_continue() {
    local _check_user=${1}
    local _msg1=$(gettext "This script MUST run under User-Account: '%s'")
    local _msg2=$(gettext "INFO: Please run this script in %sMAXIMIZED%s terminal.")
    local _msg3=$(gettext "To %sINTERRUPT%s at any time press [%sctrl+c%s].")
    local _msg4=$(gettext "To %sCONTINUE%s type: [%sYES%s]: ")
    local _user_input

    printf "\n"
    if [[ -n ${_check_user} ]]; then
        if [[ $(whoami) != ${_check_user} ]]; then
            printf "${_MS_BLUE}        ${_msg1}${_MS_ALL_OFF}\n" "${_check_user}" >&1
            ms_abort "ms_request_continue" "$(gettext "Got EUID: '%s' USER: '%s'")" "$EUID" "$(whoami)"
        fi
    fi
    printf "${_MS_GREEN}====> ${_MS_ALL_OFF}${_msg2}\n" "${_MS_BOLD}" "${_MS_ALL_OFF}" >&1
    printf "        ${_msg3}\n\n" "${_MS_BOLD}" "${_MS_ALL_OFF}" "${_MS_GREEN}" "${_MS_ALL_OFF}" >&1
    printf "                ${_msg4}" "${_MS_BOLD}" "${_MS_ALL_OFF}" "${_MS_GREEN}" "${_MS_ALL_OFF}" >&1
    read _user_input
    [[ ${_user_input} == "YES" ]] || exit 1
    printf "\n"
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
