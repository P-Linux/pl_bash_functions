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
shopt -s extglob
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
#       `_file_name`: filename / or path of the file we test
#
#   USAGE
#       te_print_header "testing.sh"
#******************************************************************************************************************************
te_print_header() {
    local _file_name=${1}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_green="${_ms_bold}$(tput setaf 2)"

    printf "${_ms_green}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(gettext "# EXAMPLES/TESTS for: '%s'\n")" "${_file_name}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_ms_all_off}\n" >&1
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `_count_ok`: Counter of OK Tests
#       `_count_failed`: Counter of FAILED Tests
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
    local _fn="te_print_final_result"
    if (( ${#} < 2 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local _count_ok=${1}
    local _count_failed=${2}
    local _ok_name=${3:-"_COUNT_OK"}
    local _failed_name=${4:-"_COUNT_FAILED"}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_green="${_ms_bold}$(tput setaf 2)"
    local _ms_yellow="${_ms_bold}$(tput setaf 3)"

    echo
    echo
    printf "${_ms_green}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(gettext "# TESTS RESULTS: %s: '%s' %s: '%s'\n")" "${_ok_name}" "${_count_ok}" "${_failed_name}" \
        "${_count_failed}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_ms_all_off}\n" >&1

    if (( ${_count_failed} > 0 ))  ; then
        printf "${_ms_yellow}\n" >&1
        printf "$(gettext "    There are FAILED TEST RESULTS (%s): Check the terminal output.")" "${_count_failed}" >&1
        printf "${_ms_all_off}\n" >&1
    fi
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `_func_info`: e.g. info which function is tested
#
#   USAGE
#       te_print_function_msg "te_find_err_msg() very limited tests"
#******************************************************************************************************************************
te_print_function_msg() {
    local _func_info=${1}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_blue="${_ms_bold}$(tput setaf 4)"
    local _ms_magenta="${_ms_bold}$(tput setaf 5)"
    local _abort_text=$(gettext "TESTING:")

    printf "${_ms_magenta}\n=======> ${_abort_text}${_ms_all_off}${_ms_blue} ${_func_info}${_ms_all_off}\n" >&1
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
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_blue="${_ms_bold}$(tput setaf 4)"
    local _ms_magenta="${_ms_bold}$(tput setaf 5)"
    local _abort_text=$(gettext "ABORTING....from:")

    printf "${_ms_magenta}\n\n=======> ${_abort_text}${_ms_all_off}${_ms_blue} <${_from_name}> ${_ms_all_off}\n" >&2
    printf "${_ms_red}    ->${_ms_all_off}${_ms_bold} ${_msg}${_ms_all_off}\n\n" "${@:2}" >&2
    exit 1
}


#******************************************************************************************************************************
#   USAGE: te_warn "from_where_name" "This Test needs working internet."
#******************************************************************************************************************************
te_warn() {
    if (( ${#} < 2 )); then
        ms_abort "te_abort" "$(gettext "FUNCTION 'ms_abort()': Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    local _from_name=${1}
    local _msg=${2}; shift
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"

    printf "${_red}  >>> WARNING: <${_from_name}>  ${_msg}${_off}\n" "${@:2}" >&2
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
    local _fn="te_ms_ok"
    if (( ${#} < 2 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local _msg=${2}; shift
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_green="${_ms_bold}$(tput setaf 2)"
    local _msg_prefix=$(gettext "Testing:")

    printf "${_ms_green}    [  OK  ] ${_ms_all_off}${_msg_prefix}${_ms_bold} ${_msg}${_ms_all_off}\n" "${@:2}" >&1
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
    local _fn="te_ms_failed"
    if (( ${#} < 2 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '2' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local _msg=${2}; shift
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _msg_prefix=$(gettext "Testing:")

    printf "${_ms_red}    [FAILED] ${_ms_all_off}${_msg_prefix}${_ms_bold} ${_msg}${_ms_all_off}\n" "${@:2}" >&1
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
#       `_func_output`: output message of an function to check
#       `_find_error_message`: error message to search for
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
    local _func_output=${3}
    local _find_error_message=${4}
    local _info=${5:-""}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_green="${_ms_bold}$(tput setaf 2)"
    local _msg=$(gettext "Find err-msg:")

    [[ -n ${_info} ]] && _info=" ${_info}"
    if [[ ${_func_output} == *${_find_error_message}* ]]; then
        printf "${_ms_green}    [  OK  ] ${_ms_all_off}${_msg}${_ms_bold} ${_find_error_message}${_ms_all_off}${_info}\n" >&1
        ((_ret_count_ok++))
    else
        printf "${_ms_red}    [FAILED] ${_ms_all_off}${_msg}${_ms_bold} ${_find_error_message}${_ms_all_off}${_info}\n" >&1
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
#       `_func_output`: output message of an function to check
#       `_find_info_message`: info message to search for
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
    local _func_output=${3}
    local _find_info_message=${4}
    local _info=${5:-""}
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_red="${_ms_bold}$(tput setaf 1)"
    local _ms_green="${_ms_bold}$(tput setaf 2)"
    local _msg=$(gettext "Find info-msg:")

    [[ -n ${_info} ]] && _info=" ${_info}"
    if [[ ${_func_output} == *${_find_info_message}* ]]; then
        printf "${_ms_green}    [  OK  ] ${_ms_all_off}${_msg}${_ms_bold} ${_find_info_message}${_ms_all_off}${_info}\n" >&1
        ((_ret_count_ok++))
    else
        printf "${_ms_red}    [FAILED] ${_ms_all_off}${_msg}${_ms_bold} ${_find_info_message}${_ms_all_off}${_info}\n" >&1
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
#       `_in_str`: string value to compare `_func_output` to: could also be empty
#       `_ref_str`: string expected function output: could also be empty
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
    local _fn="te_same_val"
    if (( ${#} < 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    local _ref_str=${3}
    local _in_str=${4}
    local _info=${5:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected value: <")
    local _msg1=$(gettext "> Got:")

    [[ -n ${_info} ]] && _info=" ${_info}"
    if [[ ${_in_str} == ${_ref_str} ]]; then
        printf "${_green}    [  OK  ] ${_off}${_msg}${_bold}${_in_str}${_off}${_msg1} <${_bold}${_ref_str}${_off}>${_info}\n" \
            >&1
        ((_ret_count_ok++))
    else
        printf "${_red}    [FAILED] ${_off}${_msg}${_bold}${_in_str}${_off}${_msg1} <${_bold}${_ref_str}${_off}>${_info}\n" >&1
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
#       `_in_string`: value to check
#       `_info`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       te_empty_val _COUNT_OK _COUNT_FAILED "" "Testing something - expected an empty string"
#       te_empty_val _COUNT_OK _COUNT_FAILED "none_empty" "Testing something - expected an empty string"
#******************************************************************************************************************************
te_empty_val() {
    local _fn="te_empty_val"
    if (( ${#} != 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires EXACT '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    local _in_string=${3}
    local _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected empty <>. Got:")

    if [[ -z ${_in_string} ]]; then
        printf "${_green}    [  OK  ] ${_off}${_msg} <${_bold}${_in_string}${_off}>${_bold} ${_info}${_off}\n" >&1
        ((_ret_count_ok++))
    else
        printf "${_red}    [FAILED] ${_off}${_msg} <${_bold}${_in_string}${_off}>${_bold} ${_info}${_off}\n" >&1
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
#       `_in_string`: value to check
#       `_info`: info message
#
#   USAGE
#       declare -i _COUNT_OK=0
#       declare -i _COUNT_FAILED=0
#       te_not_empty_val _COUNT_OK _COUNT_FAILED "not_empty" "Testing something - expected an none empty string"
#       te_not_empty_val _COUNT_OK _COUNT_FAILED "" "Testing something - expected an none empty string"
#******************************************************************************************************************************
te_not_empty_val() {
    local _fn="te_not_empty_val"
    if (( ${#} != 4 )); then
        te_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires EXACT '4' argument. Got '%s'\n\n")" "${_fn}" "${#}"
    fi
    local -n _ret_count_ok=${1}
    local -n _ret_count_failed=${2}
    local _in_string=${3}
    local _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected not empty. Got:")

    if [[ -n ${_in_string} ]]; then
        printf "${_green}    [  OK  ] ${_off}${_msg} <${_bold}${_in_string}${_off}>${_bold} ${_info}${_off}\n" >&1
        ((_ret_count_ok++))
    else
        printf "${_red}    [FAILED] ${_off}${_msg} <${_bold}${_in_string}${_off}>${_bold} ${_info}${_off}\n" >&1
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
#       `_info`: info message
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
    local _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected ret-val (")
    local _msg1=$(gettext ") GOT:")

    if (( _func_ret )); then
        printf "${_red}    [FAILED] ${_off}${_msg}${_bold}0${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${_info}\n" >&1
        ((_ret_count_failed++))
    else
        printf "${_green}    [  OK  ] ${_off}${_msg}${_bold}0${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${_info}\n" >&1
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
#       `_info`: info message
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
    local _info=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _msg=$(gettext "Expected ret-val (")
    local _msg1=$(gettext ") GOT:")

    if (( ${_func_ret} )); then
        printf "${_green}    [  OK  ] ${_off}${_msg}${_bold}1${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${_info}\n" >&1
        ((_COUNT_OK++))
    else
        printf "${_red}    [FAILED] ${_off}${_msg}${_bold}1${_off}${_msg1} (${_bold}${_func_ret}${_off}) ${_info}\n" >&1
        ((_ret_count_failed++))
    fi

    # Avoid: ABORTING....from: <ts_trap_exit_unknown_error>
    return 0
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
