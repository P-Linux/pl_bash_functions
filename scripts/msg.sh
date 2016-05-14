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

t_general_opt



#=============================================================================================================================#
#
#                   pl_bash_functions RELATED FUNCTIONS - version, installed directory etc..
#
#=============================================================================================================================#

#******************************************************************************************************************************
#   USAGE: local _result; m_get_pl_bash_functions_version _result
#******************************************************************************************************************************
m_get_pl_bash_functions_version() {
    local -n _ret_r=${1}
    local _plfunc_dir; m_pl_bash_functions_dir _plfunc_dir
    local _m1=$(_g "HINT:")
    local _m2=$(_g "MAYBE you forgot to run 'make install' or 'make generate'!")

    if ! source "${_plfunc_dir}/main_conf.sh"; then
        echo
        echo
        printf "${_M_YELLOW}   => ${_m1}${_M_OFF} ${_m2}${_M_OFF}\n"
        m_exit "m_get_pl_bash_functions_version" "$(_g "Could not source: <%s>")" "${_plfunc_dir}/main_conf.sh"
    fi
    _ret_r=${_PL_BASH_FUNCTIONS_VERSION}

}


#******************************************************************************************************************************
# Display a warning if the pl_bash_functions version is different than the one your script was tested with
#
#   USAGE: m_has_tested_version "0.0.1"
#******************************************************************************************************************************
m_has_tested_version() {
    local __tested_vers=${1}
    local _vers; m_get_pl_bash_functions_version _vers
    local _m1=$(_g "WARNING:")
    local _m2=$(_g "This script was %sTESTET%s with <pl_bash_functions>: '%s'")
    local _m3=$(_g "You've got <pl_bash_functions>: '%s'")
    local _plfunc_dir

    if [[ ${_vers} != ${__tested_vers} ]]; then
        printf "${_M_YELLOW}====> ${_m1}${_M_OFF} ${_m2}${_M_OFF}\n" "${_M_BOLD}" "${_M_OFF}" "${__tested_vers}" >&2
        printf "               ${_m3}\n" "${_vers}" >&2
        m_pl_bash_functions_dir _plfunc_dir
        printf "                 ${_m4}\n\n" "${_plfunc_dir}" >&2
    fi
}


#******************************************************************************************************************************
# Returns the installation directory of the used: pl_bash_functions
#
#   USAGE: local _result; m_pl_bash_functions_dir _result
#******************************************************************************************************************************
m_pl_bash_functions_dir() {
    local -n _ret_r=${1}
    _ret_r=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
}



#=============================================================================================================================#
#
#                   MESSAGE FUNCTIONS - functions for outputting messages
#
#   Provides easy output formatting functions with different levels of indentation, colors etc..
#   The general message functions print to stdout and can be silenced by defining '_M_VERBOSE="no"'.
#   Any additional general info messages can be silenced by defining '_M_VERBOSE_I=no'.
#   Other message functions print to stderr.
#
#   * USAGE EXAMPLE - MESSAGE FORMAT: To support translation the messages format should be:
#
#       m_bold $(_g "Some Info...")
#       m_bold $(_g "The files path is: %s")  $FILEPATH
#       m_bold $(_g "Source file:  %s") $(get_filename "${1}")
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Sets the message formatting and related command checks.     USAGE: m_format
#******************************************************************************************************************************
m_format() {
    _M_VERBOSE="yes"
    _M_VERBOSE_I="yes"

    _M_OFF=$(tput sgr0)
    _M_BOLD=$(tput bold)
    _M_RED="${_M_BOLD}$(tput setaf 1)"
    _M_GREEN="${_M_BOLD}$(tput setaf 2)"
    _M_YELLOW="${_M_BOLD}$(tput setaf 3)"
    _M_BLUE="${_M_BOLD}$(tput setaf 4)"
    _M_MAGENTA="${_M_BOLD}$(tput setaf 5)"

    readonly _M_OFF _M_BOLD _M_RED _M_GREEN _M_YELLOW _M_BLUE _M_MAGENTA
}


#******************************************************************************************************************************
# More-Info message: enabled by '_M_VERBOSE_I="yes" '
#******************************************************************************************************************************
m_more() {
    [[ ${_M_VERBOSE_I} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "  INFO: ${_m}\n" "${@}" >&1
}


#******************************************************************************************************************************
# More-Info message (indented level): enabled by '_M_VERBOSE_I="yes" '
#******************************************************************************************************************************
m_more_i() {
    [[ ${_M_VERBOSE_I} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "         INFO: ${_m}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main-Bold message: enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_bold() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BOLD}====> ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main-Bold message (indented level): enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_bold_i() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BOLD}       ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message: enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_bold2() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BOLD}    ====> ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Bold message (indented level): enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_bold2_i() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BOLD}           ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Main message: enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_msg() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_GREEN}====>${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Sub message (indented level): enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
m_msg_i() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BLUE}    ->${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Main message: enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg2() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_GREEN}    ====>${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# Level-2 Sub message (indented level): enabled by '_M_VERBOSE="yes"'
#******************************************************************************************************************************
ms_msg2_i() {
    [[ ${_M_VERBOSE} == "yes" ]] || return 0
    local _m=${1}; shift
    printf "${_M_BLUE}        ->${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&1
}


#******************************************************************************************************************************
# WARNING message: always enabled
#******************************************************************************************************************************
m_warn() {
    local _m=${1}; shift
    printf "${_M_YELLOW}====> $(_g "WARNING:")${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# WARNING message 2: always enabled
#******************************************************************************************************************************
m_warn2() {
    local _m=${1}; shift
    printf "${_M_YELLOW}    ====> $(_g "WARNING:")${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ERROR message: always enabled
#******************************************************************************************************************************
m_err() {
    local _m=${1}; shift
    printf "${_M_RED}====> $(_g "ERROR:")${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ERROR message 2: always enabled
#******************************************************************************************************************************
m_err2() {
    local _m=${1}; shift
    printf "${_M_RED}    ====> $(_g "ERROR:")${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n" "${@}" >&2
}


#******************************************************************************************************************************
# ABORTING message: always enabled: m_exit "from_where_name" "$(_g "Message did not find path: '%s'")" "$PATH"
#******************************************************************************************************************************
m_exit() {
    (( ${#} < 2 )) &&  m_exit "m_exit" "$(_g "FUNCTION Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    local _from=${1}
    local _m=${2}; shift
    local _txt=$(_g "ABORTING....from:")

    printf "${_M_MAGENTA}\n\n=======> ${_txt}${_M_OFF}${_M_BLUE} <${_from}> ${_M_OFF}\n" >&2
    printf "${_M_RED}    ->${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n\n" "${@:2}" >&2
    exit 1
}


#******************************************************************************************************************************
# ABORTING message: always enabled: can optionally remove a path before aborting, useful to clean up before exit
#
#   USAGE:
#       m_format
#       _remove_path="no"
#       CMK_BUILDS_DIR="/home/TEST DIR/builds"
#       m_exit_remove_path "from_where_name" "${_remove_path}" "${CMK_BUILDS_DIR}/$pkname" "$(_g "Failure while ...\n")"
#******************************************************************************************************************************
m_exit_remove_path() {
    local _fn="m_exit_remove_path"
    (( ${#} < 4 )) && m_exit "${_fn}" "$(_g "FUNCTION Requires AT LEAST '4' arguments. Got '%s'")" "${#}"
    if [[ $2 != "yes" && $2 != "no" ]]; then
        m_exit "${_fn}" "$(_g "FUNCTION Argument '2' MUST be 'yes' or 'no'. Got '%s'")" "${2}"
    fi
    if [[ $2 == "yes" && -z $3 ]]; then
        m_exit "${_fn}" "$(_g "FUNCTION Argument '3' MUST NOT be empty if argument 2 is 'yes'")"
    fi
    local _from=${1}
    local _do_remove=${2}
    local _path=${3}
    local _m=${4}; shift
    local _txt=$(_g "ABORTING....from:")

    printf "${_M_MAGENTA}\n\n=======> ${_txt}${_M_OFF}${_M_BLUE} <${_from}> ${_M_OFF}\n" >&2
    if [[ ${_do_remove} == "yes" ]]; then
        m_more_i "$(_g "Removing path: <%s>")\n" "${_path}" >&2
        rm -rf "${_path}"
    fi
    printf "${_M_RED}    ->${_M_OFF}${_M_BOLD} ${_m}${_M_OFF}\n\n" "${@:4}" >&2
    exit 1
}


#******************************************************************************************************************************
# Color message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'm_format()'
#******************************************************************************************************************************
m_color() {
    local _format=${1}
    local _m=${2}; shift
    printf "${_format}${_m}${_M_OFF}\n" "${@:2}" >&1
}


#******************************************************************************************************************************
# Formatted Header message: always enabled: '_format' SHOULD BE one of the defined variables of function: 'm_format()'
#******************************************************************************************************************************
m_header() {
    local _format=${1}
    local _m=${2}; shift

    printf "${_format}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "# ${_m}\n" "${@:2}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_M_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Header message (indented level): always enabled
#******************************************************************************************************************************
m_header_i() {
    local _format=${1}
    local _m=${2}; shift

    printf "${_format}\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "    #\n" >&1
    printf "    # ${_m}\n" "${@:2}" >&1
    printf "    #\n" >&1
    printf "    #=======================================================================#\n" >&1
    printf "${_M_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted Horizontal Line: always enabled: '_format' SHOULD BE one of the defined variables of function: 'm_format()'
#
#   USAGE:
#       m_format
#       m_hrl "${_M_GREEN}" "#" "=" 25 "#"
#
#   OUTPUT: Green line '#=========================#'
#******************************************************************************************************************************
m_hrl() {
    (( ${#} != 5 )) && m_exit "m_hrl" "$(_g "FUNCTION Requires EXACT '5' arguments. Got '%s'")" "${#}"
    # skip assignment:  _format=${1}
    # skip assignment:  _start_txt=${2}
    # skip assignment:  _repeated_text=${3}
    local _repeat=${4}
    # skip assignment:  _end_text=${5}
    local _line=""

    while (( ${#_line} < ${_repeat} )); do
        _line+=${3}
    done
    printf "${1}%s%s%s${_M_OFF}\n" "${2}" "${_line:0:_repeat}" "${5}" >&1
}



#=============================================================================================================================#
#
#                   DIVERSE FUNCTION
#
#=============================================================================================================================#

#******************************************************************************************************************************
# General request for a manual input of the user to continue execution.
#       '_user' optional set under which user the script must run
#
#   USAGE:
#       m_ask_continue
#       m_ask_continue "root"
#******************************************************************************************************************************
m_ask_continue() {
    local _user=${1}
    local _m1=$(_g "This script MUST run under User-Account: '%s'")
    local _m2=$(_g "INFO: Please run this script in %sMAXIMIZED%s terminal.")
    local _m3=$(_g "To %sINTERRUPT%s at any time press [%sctrl+c%s].")
    local _m4=$(_g "To %sCONTINUE%s type: [%sYES%s]: ")
    local _input

    printf "\n"
    if [[ -n ${_user} ]]; then
        if [[ $(whoami) != ${_user} ]]; then
            printf "${_M_BLUE}        ${_m1}${_M_OFF}\n" "${_user}" >&1
            m_exit "m_ask_continue" "$(_g "Got EUID: '%s' USER: '%s'")" "$EUID" "$(whoami)"
        fi
    fi
    printf "${_M_GREEN}====> ${_M_OFF}${_m2}\n" "${_M_BOLD}" "${_M_OFF}" >&1
    printf "        ${_m3}\n\n" "${_M_BOLD}" "${_M_OFF}" "${_M_GREEN}" "${_M_OFF}" >&1
    printf "                ${_m4}" "${_M_BOLD}" "${_M_OFF}" "${_M_GREEN}" "${_M_OFF}" >&1
    read _input
    [[ ${_input} == "YES" ]] || exit 1
    printf "\n"
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
