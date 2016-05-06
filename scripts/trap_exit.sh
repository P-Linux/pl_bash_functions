#******************************************************************************************************************************
#
#   <trap_exit.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
shopt -s extglob
set +o noclobber



#=============================================================================================================================#
#
#                   TRAP FUNCTIONS
#
# COMMON USAGE
#
#     source "/path_to/trap_exit.sh"
#
#     for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\"" "${_signal}"; done
#     trap "tr_trap_exit_interrupted" INT
#     trap "tr_trap_exit_unknown_error" ERR
#
# COMMON USAGE With CLEANUP Function
#
#     source "/path_to/trap_exit.sh"
#
#     for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\" \"own_cleanup_function_name\"" "${_signal}"; done
#     trap "tr_trap_exit_interrupted \"own_cleanup_function_name\"" INT
#     trap "tr_trap_exit_unknown_error \"own_cleanup_function_name\"" ERR
#=============================================================================================================================#

#******************************************************************************************************************************
# to enabled it set:
#
#   for _signal in TERM HUP QUIT; do
#       trap "tr_trap_exit \"${_signal}\"" "${_signal}"
#   done
#
#   ARGUMENTS
#       `_exit_signal`: the exit signal used for the error message.
#
#   OPTIONAL ARGUMENTS
#       `_func_name`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
tr_trap_exit() {
    local _fn="tr_trap_exit"
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    local _exit_signal=${1}
    local _func_name=${2:-""}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_blue="${_ms_bold}$(tput setaf 4)"
    local _ms_magenta="${_ms_bold}$(tput setaf 5)"
    local _abort_text=$(gettext "ABORTING....from:")
    local _abort_msg=$(gettext "signal caught. Exiting...")

    printf "${_ms_magenta}\n\n=======> ${_abort_text}${_ms_all_off}${_ms_blue} <${_fn}> ${_ms_all_off}\n" >&2
    printf "${_ms_red}    -> ${_ms_all_off}${_ms_bold}ERROR: '${_exit_signal}' ${_abort_msg}${_ms_all_off}\n\n" >&2

    if [[ -n ${_func_name} ]]; then
        if (declare -f "${_func_name}" >/dev/null); then
            printf "$(gettext "      ${_ms_bold}-> Running function: <%s>${_ms_all_off} before exit.${_ms_all_off}")\n\n" \
                "${_func_name}"
            ${_func_name}   # Run it
        else
            printf "$(gettext "\nCODE-ERROR: FUNCTION: %s(): Could not find the specified function: <%s>")\n\n" "${_fn}" \
                "${_func_name}" >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# to enabled it set: 'trap "tr_trap_exit_interrupted" INT'
#
#   OPTIONAL ARGUMENTS
#       `_func_name`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
tr_trap_exit_interrupted() {
    local _fn="tr_trap_exit_interrupted"
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    local _func_name=${1:-""}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_blue="${_ms_bold}$(tput setaf 4)"
    local _ms_magenta="${_ms_bold}$(tput setaf 5)"
    local _abort_text=$(gettext "ABORTING....from:")
    local _abort_msg=$(gettext "Aborted by user! Exiting...")

    printf "${_ms_magenta}\n\n=======> ${_abort_text}${_ms_all_off}${_ms_blue} <${_fn}> ${_ms_all_off}\n" >&2
    printf "${_ms_red}    -> ${_ms_all_off}${_ms_bold}${_abort_msg}${_ms_all_off}\n\n" >&2

    if [[ -n ${_func_name} ]]; then
        if (declare -f "${_func_name}" >/dev/null); then
            printf "$(gettext "      ${_ms_bold}-> Running function: <%s>${_ms_all_off} before exit.${_ms_all_off}")\n\n" \
                "${_func_name}"
            ${_func_name}  # Run it
        else
            printf "$(gettext "\nCODE-ERROR: FUNCTION: %s(): Could not find the specified function: <%s>")\n\n" "${_fn}" \
                "${_func_name}" >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# to enabled it set: 'trap "tr_trap_exit_unknown_error" ERR'
#
#   OPTIONAL ARGUMENTS
#       `_func_name`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
tr_trap_exit_unknown_error() {
    local _fn="tr_trap_exit_unknown_error"
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    local _func_name=${1:-""}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_blue="${_ms_bold}$(tput setaf 4)"
    local _ms_magenta="${_ms_bold}$(tput setaf 5)"
    local _abort_text=$(gettext "ABORTING....from:")
    local _abort_msg=$(gettext "An unknown error has occurred. Exiting...")

    printf "${_ms_magenta}\n\n=======> ${_abort_text}${_ms_all_off}${_ms_blue} <${_fn}> ${_ms_all_off}\n" >&2
    printf "${_ms_red}    -> ${_ms_all_off}${_ms_bold}${_abort_msg}${_ms_all_off}\n\n" >&2

    if [[ -n ${_func_name} ]]; then
        if (declare -f "${_func_name}" >/dev/null); then
            printf "$(gettext "      ${_ms_bold}-> Running function: <%s>${_ms_all_off} before exit.${_ms_all_off}")\n\n" \
                "${_func_name}"
            ${_func_name}    # Run it
        else
            printf "$(gettext "\nCODE-ERROR: FUNCTION: %s(): Could not find the specified function: <%s>")\n\n" "${_fn}" \
                "${_func_name}" >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
