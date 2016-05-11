#******************************************************************************************************************************
#
#   <testing.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
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
#                   GENERAL TESTING HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Formatted HEADER message
#
#   ARGUMENTS
#       `$1 (_file_name)`: filename / or path of the file we test
#
#   USAGE
#       te_print_header "testing.sh"
#******************************************************************************************************************************
te_print_header() {
    # skip assignment:  _file_name=${1}

    printf "$(tput bold)$(tput setaf 2)\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(gettext "# EXAMPLES/TESTS for: '%s'\n")" "${1}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "$(tput sgr0)\n" >&1
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `$1 (_count_ok)`: Counter of OK Tests
#       `$2 (_count_failed)`: Counter of FAILED Tests
#
#   OPTIONAL ARGUMETNTS
#       `_ok_name`: output name for _count_ok: Default: _COUNT_OK
#       `_failed_name`: output name for _count_failed: Default: _COUNT_FAILED
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       te_print_final_result _COUNT_OK _COUNT_FAILED "_COUNT_OK" "_COUNT_FAILED"
#******************************************************************************************************************************
te_print_final_result() {
    if (( ${#} < 2 )); then
        te_abort "te_print_final_result" \
            "$(gettext "FUNCTION 'te_print_final_result()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${#}"
    fi
    # skip assignment:  _count_ok=${1}
    # skip assignment:  _count_failed=${2}
    local _ok_name=${3:-"_COUNT_OK"}
    local _failed_name=${4:-"_COUNT_FAILED"}

    echo
    echo
    printf "$(tput bold)$(tput setaf 2)\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(gettext "# TESTS RESULTS: %s: '%s' %s: '%s'\n")" "${_ok_name}" "${1}" "${_failed_name}" \
        "${2}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "$(tput sgr0)\n" >&1

    if (( ${2} > 0 ))  ; then
        printf "$(tput bold)$(tput setaf 3)\n" >&1
        printf "$(gettext "    There are FAILED TEST RESULTS (%s): Check the terminal output.")" "${2}" >&1
        printf "$(tput sgr0)\n" >&1
    fi
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `$1 (_func_info)`: e.g. info which function is tested
#
#   USAGE
#       te_print_function_msg "te_find_err_msg() very limited tests"
#******************************************************************************************************************************
te_print_function_msg() {
    # skip assignment:  _func_info=${1}
    local _text=$(gettext "TESTING:")
    printf "$(tput bold)$(tput setaf 5)\n=======> ${_text}$(tput sgr0)$(tput bold)$(tput setaf 4) ${1}$(tput sgr0)\n" >&1
}


#******************************************************************************************************************************
#   USAGE: te_abort "from_where_name" "$(gettext "Message did not find path: '%s'")" "$PATH"
#******************************************************************************************************************************
te_abort() {
    if (( ${#} < 2 )); then
        ms_abort "te_abort" "$(gettext "FUNCTION 'ms_abort()': Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    local _from_name=${1}
    local _msg=${2}; shift
    local _ms_blue="$(tput bold)$(tput setaf 4)"
    local _abort_text=$(gettext "ABORTING....from:")

    printf "$(tput bold)$(tput setaf 5)\n\n=======> ${_abort_text}$(tput sgr0)${_ms_blue} <${_from_name}> $(tput sgr0)\n" >&2
    printf "$(tput bold)$(tput setaf 1)    ->$(tput sgr0)$$(tput bold) ${_msg}$(tput sgr0)\n\n" "${@:2}" >&2
    exit 1
}


#******************************************************************************************************************************
#   USAGE: te_warn "from_where_name" "This Test needs working internet."
#******************************************************************************************************************************
te_warn() {
    if (( ${#} < 2 )); then
        ms_abort "te_abort" "$(gettext "FUNCTION 'ms_abort()': Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    # skip assignment:  _from_name=${1}
    local _msg=${2}; shift

    printf "$(tput bold)$(tput setaf 1)  >>> WARNING: <${1}>  ${_msg}$(tput sgr0)\n" "${@:2}" >&2
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       if [[ -f $PATH ]]; then
#           te_ms_ok _COUNT_OK "$(gettext "Found path: '%s'")" "$PATH"
#       else
#           te_ms_failed _COUNT_FAILED "$(gettext "Found path: '%s'")" "$PATH"
#       fi
#******************************************************************************************************************************
te_ms_ok() {
    if (( ${#} < 2 )); then
        te_abort "te_ms_ok" "$(gettext "FUNCTION 'te_ms_ok()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local _msg=${2}; shift
    local _msg_prefix=$(gettext "Testing:")

    printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_msg_prefix}$(tput bold) ${_msg}$(tput sgr0)\n" "${@:2}" >&1
    ((_ret_count_ok++))
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       if [[ -f $PATH ]]; then
#           te_ms_ok _COUNT_OK "$(gettext "Found path: '%s'")" "$PATH"
#       else
#           te_ms_failed _COUNT_FAILED "$(gettext "Found path: '%s'")" "$PATH"
#       fi
#******************************************************************************************************************************
te_ms_failed() {
    if (( ${#} < 2 )); then
        te_abort "te_ms_failed" "$(gettext "FUNCTION 'te_ms_failed()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local _msg=${2}; shift
    local _msg_prefix=$(gettext "Testing:")

    printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_msg_prefix}$(tput bold) ${_msg}$(tput sgr0)\n" "${@:2}" >&1
    ((_ret_count_ok++))
}


#=============================================================================================================================#
#
#                   TESTING FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Reports OK: if the `_func_output` contains the `_find_error_message`
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_func_output)`: output message of an function to check
#       `$4 (_find_error_message)`: error message to search for
#
#   OPTIONAL ARGUMETNTS
#       `_info`: extra info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       _output="Some info FUNCTION: Requires AT LEAST '2' arguments. Got '1' some more text"
#       te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION: Requires AT LEAST '2' arguments. Got '1'"
#       te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION: Requires AT LEAST '7' arguments. Got '8'" "EXTRA"
#******************************************************************************************************************************
te_find_err_msg() {
    local _fn="te_find_err_msg"
    if (( ${#} < 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    [[ -n $3 ]] || te_abort "${_fn}" "$(gettext "FUNCTION '%s()': FUNCTION Argument 3 MUST NOT be empty.\n\n")" "${_fn}"
    [[ -n $4 ]] || te_abort "${_fn}" "$(gettext "FUNCTION '%s()': FUNCTION Argument 4 MUST NOT be empty.\n\n")" "${_fn}"
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    # skip assignment:  _func_output=${3}
    # skip assignment:  _find_error_message=${4}
    local _info=${5:-""}
    local _msg=$(gettext "Find err-msg:")

    [[ -n ${_info} ]] && _info=" ${_info}"
    if [[ ${3} == *${4}* ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_msg}$(tput bold) ${4}$(tput sgr0)${_info}\n" >&1
        ((_ret_count_ok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_msg}$(tput bold) ${4}$(tput sgr0)${_info}\n" >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_func_output` contains the `_find_info_message`
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_func_output)`: output message of an function to check
#       `$4 (_find_info_message)`: info message to search for
#
#   OPTIONAL ARGUMETNTS
#       `_info`: extra info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       _output="Some info FUNCTION 'xxx()': Download success. some more text"
#       te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'xxx()': Download success."
#       te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'xxx()': Download success but." "EXTRA Optional Info"
#******************************************************************************************************************************
te_find_info_msg() {
    local _fn="te_find_info_msg"
    if (( ${#} < 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    [[ -n $3 ]] || te_abort "${_fn}" "$(gettext "FUNCTION '%s()': FUNCTION Argument 3 MUST NOT be empty.\n\n")" "${_fn}"
    [[ -n $4 ]] || te_abort "${_fn}" "$(gettext "FUNCTION '%s()': FUNCTION Argument 4 MUST NOT be empty.\n\n")" "${_fn}"
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    # skip assignment:  _func_output=${3}
    # skip assignment:  _find_info_message=${4}
    local _info=${5:-""}
    local _msg=$(gettext "Find info-msg:")

    [[ -n ${_info} ]] && _info=" ${_info}"
    if [[ ${3} == *${4}* ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_msg}$(tput bold) ${4}$(tput sgr0)${_info}\n" >&1
        ((_ret_count_ok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_msg}$(tput bold) ${4}$(tput sgr0)${_info}\n" >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_str` is the same as `_ref_str`
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_str)`: string value to compare `_func_output` to: could also be empty
#       `$4 (_ref_str)`: string expected function output: could also be empty
#
#   OPTIONAL ARGUMETNTS
#       `_info`: extra info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       _ref_str="/home/test"
#       te_same_val _COUNT_OK _COUNT_FAILED "${_ref_str}" "/home/test"
#       te_same_val _COUNT_OK _COUNT_FAILED "${_ref_str}" "/home/testing" "EXTRA"
#
#   NOTES FOR INTEGERS: pass it as a string
#       declare -i _n=10
#       te_same_val _COUNT_OK _COUNT_FAILED "${_n}" "10"
#
#   NOTES FOR ARRAYS: pass it as a string
#       local _result=(value1 value2 value3)
#       Need to convert it first to a string
#       _tmp_str=${_result[@]}
#       te_same_val _COUNT_OK _COUNT_FAILED "${_tmp_str}" "value1 value2 value3"
#******************************************************************************************************************************
te_same_val() {
    if (( ${#} < 4 )); then
        te_abort "te_same_val" "$(gettext "FUNCTION 'te_same_val()': Requires AT LEAST '4' argument. Got '%s'\n\n")" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    # skip assignment:  _in_str=${3}
    # skip assignment:  _ref_str=${4}
    local _inf=${5:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _msg=$(gettext "Expected value: <")
    local _msg1=$(gettext "> Got:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${3} == ${4} ]]; then
        printf "${_bold}$(tput setaf 2)    [  OK  ] ${_off}${_msg}${_bold}${4}${_off}${_msg1} <${_bold}${3}${_off}>${_inf}\n" \
            >&1
        ((_ret_count_ok++))
    else
        printf "${_bold}$(tput setaf 1)    [FAILED] ${_off}${_msg}${_bold}${4}${_off}${_msg1} <${_bold}${3}${_off}>${_inf}\n" \
            >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_string` is empty. [[ -z _in_string ]]
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_string)`: value to check
#       `$4 (_info)`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       te_empty_val _COUNT_OK _COUNT_FAILED "" "Testing something - expected an empty string"
#       te_empty_val _COUNT_OK _COUNT_FAILED "none_empty" "Testing something - expected an empty string"
#******************************************************************************************************************************
te_empty_val() {
    if (( ${#} != 4 )); then
        te_abort "te_empty_val" "$(gettext "FUNCTION 'te_empty_val()': Requires EXACT '4' argument. Got '%s'\n\n")" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    # skip assignment:  _in_string=${3}
    # skip assignment:  _info=${4}
    local _off=$(tput sgr0)
    local _msg=$(gettext "Expected empty <>. Got:")

    if [[ -z ${3} ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] ${_off}${_msg} <$(tput bold)}${3}${_off}>${_bold} ${4}${_off}\n" \
            >&1
        ((_ret_count_ok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] ${_off}${_msg} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" \
            >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_string` is not empty. [[ -n _in_string ]]
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_string)`: value to check
#       `$4 (_info)`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       te_not_empty_val _COUNT_OK _COUNT_FAILED "not_empty" "Testing something - expected an none empty string"
#       te_not_empty_val _COUNT_OK _COUNT_FAILED "" "Testing something - expected an none empty string"
#******************************************************************************************************************************
te_not_empty_val() {
    if (( ${#} != 4 )); then
        te_abort "te_not_empty_val" "$(gettext "FUNCTION 'te_not_empty_val()': Requires EXACT '4' argument. Got '%s'\n\n")" \
            "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    # skip assignment:  _in_string=${3}
    # skip assignment:  _info=${4}
    local _off=$(tput sgr0)
    local _msg=$(gettext "Expected not empty. Got:")

    if [[ -n ${3} ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] ${_off}${_msg} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" \
            >&1
        ((_ret_count_ok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] ${_off}${_msg} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" \
            >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 0
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `$4 (_info)`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retval_0 _COUNT_OK _COUNT_FAILED 0 "${_info_msg}"
#       te_retval_0 _COUNT_OK _COUNT_FAILED 1 "${_info_msg}"
#       te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retval_0() {
    local _fn="te_retval_0"
    if (( ${#} != 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires EXACT '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    declare -i _func_ret=${3}
    # skip assignment:  _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected ret-val (")
    local _msg1=$(gettext ") GOT:")

    if (( _func_ret )); then
        printf "${_red}    [FAILED] ${_off}${_msg}${_bold}0${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_ret_count_failed++))
    else
        printf "${_green}    [  OK  ] ${_off}${_msg}${_bold}0${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_COUNT_OK++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 1
#
#   ARGUMENTS
#       `_ret_count_ok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_count_failed`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `$4 (_info)`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retval_1 _COUNT_OK _COUNT_FAILED 1 "${_info_msg}"
#       te_retval_1 _COUNT_OK _COUNT_FAILED 0 "${_info_msg}"
#       te_retval_1 _COUNT_OK _COUNT_FAILED ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retval_1() {
    local _fn="te_retval_1"
    if (( ${#} != 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires EXACT '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    declare -i _func_ret=${3}
    # skip assignment:  _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected ret-val (")
    local _msg1=$(gettext ") GOT:")

    if (( ${_func_ret} )); then
        printf "${_green}    [  OK  ] ${_off}${_msg}${_bold}1${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_COUNT_OK++))
    else
        printf "${_red}    [FAILED] ${_off}${_msg}${_bold}1${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
