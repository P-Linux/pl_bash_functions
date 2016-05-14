#******************************************************************************************************************************
#
#   <trap_opt.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

t_general_opt() {
    unset GREP_OPTIONS
    shopt -s extglob dotglob expand_aliases
    set +o noclobber

    if [[ ! $(type -p "gettext") || ! $(type -p "tput") ]]; then
        # REMEMBER: we can not use gettext for this messages
        printf "-> FUNCTION 't_general_opt()': MISSING COMMAND: 'gettext' and 'tput' are both required.\n\n" >&2
        exit 1
    fi

    # Set Aliases
    alias _g='gettext'
}
t_general_opt


#=============================================================================================================================#
#
#                   TRAP FUNCTIONS
#
# COMMON USAGE
#
#     source "/path_to/trap_opt.sh"
#
#     for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\"" "${_signal}"; done
#     trap "t_trap_i" INT
#     trap "t_trap_u" ERR
#
# COMMON USAGE With CLEANUP Function
#
#     source "/path_to/trap_opt.sh"
#
#     for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\" \"own_cleanup_function_name\"" "${_signal}"; done
#     trap "t_trap_i \"own_cleanup_function_name\"" INT
#     trap "t_trap_u \"own_cleanup_function_name\"" ERR
#=============================================================================================================================#

#******************************************************************************************************************************
# to enabled it set:
#
#   for _signal in TERM HUP QUIT; do
#       trap "t_trap_s \"${_signal}\"" "${_signal}"
#   done
#
#   ARGUMENTS
#       `$1 (_exit_signal)`: the exit signal used for the error message.
#
#   OPTIONAL ARGUMENTS
#       `_fname`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
t_trap_s() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    # skip assignment:  _exit_signal=${1}
    local _fname=${2:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _txt1=$(_g "ABORTING....from:")
    local _txt2=$(_g "signal caught. Exiting...")

    printf "${_bold}$(tput setaf 5)\n\n=======> ${_txt1}${_off}${_bold}$(tput setaf 4) <t_trap_s> ${_off}\n" >&2
    printf "${_bold}$(tput setaf 1)    -> ${_off}${_bold}ERROR: '${1}' ${_txt2}${_off}\n\n" >&2

    if [[ -n ${_fname} ]]; then
        if (declare -f "${_fname}" >/dev/null); then
            printf "$(_g "      ${_bold}-> Running function: <%s>${_off} before exit.${_off}")\n\n" "${_fname}"
            ${_fname}   # Run it
        else
            printf "$(_g "\nCODE-ERROR: FUNCTION: t_trap_s(): Could not find the specified function: <%s>")\n\n" "${_fname}" \
                >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# to enabled it set: 'trap "t_trap_i" INT'
#
#   OPTIONAL ARGUMENTS
#       `_fname`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
t_trap_i() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    local _fname=${1:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _txt1=$(_g "ABORTING....from:")
    local _txt2=$(_g "Aborted by user! Exiting...")

    printf "${_bold}$(tput setaf 5)\n\n=======> ${_txt1}${_off}${_bold}$(tput setaf 4) <t_trap_i> ${_off}\n" >&2
    printf "${_bold}$(tput setaf 1)    -> ${_off}${_bold}${_txt2}${_off}\n\n" >&2

    if [[ -n ${_fname} ]]; then
        if (declare -f "${_fname}" >/dev/null); then
            printf "$(_g "      ${_bold}-> Running function: <%s>${_off} before exit.${_off}")\n\n" \
                "${_fname}"
            ${_fname}  # Run it
        else
            printf "$(_g "\nCODE-ERROR: FUNCTION: %s(): Could not find the specified function: <%s>")\n\n" "t_trap_i" \
                "${_fname}" >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# to enabled it set: 'trap "t_trap_u" ERR'
#
#   OPTIONAL ARGUMENTS
#       `_fname`: an name of a function to run before the final exit: usful for cleanup etc..
#******************************************************************************************************************************
t_trap_u() {
    # unhook all traps to avoid race conditions
    trap '' EXIT TERM HUP QUIT INT ERR

    local _fname=${1:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _txt1=$(_g "ABORTING....from:")
    local _txt2=$(_g "An unknown error has occurred. Exiting...")

    printf "${_bold}$(tput setaf 5)\n\n=======> ${_txt1}${_off}${_bold}$(tput setaf 4) <t_trap_u> ${_off}\n" >&2
    printf "${_bold}$(tput setaf 1)    -> ${_off}${_bold}${_txt2}${_off}\n\n" >&2

    if [[ -n ${_fname} ]]; then
        if (declare -f "${_fname}" >/dev/null); then
            printf "$(_g "      ${_bold}-> Running function: <%s>${_off} before exit.${_off}")\n\n" "${_fname}"
            ${_fname}    # Run it
        else
            printf "$(_g "\nCODE-ERROR: FUNCTION: t_trap_u(): Could not find the specified function: <%s>")\n\n" "${_fname}" \
                >&2
        fi
    fi
    exit 1
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
