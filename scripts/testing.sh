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

t_general_opt



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
    printf "$(_g "# EXAMPLES/TESTS for: '%s'\n")" "${1}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "$(tput sgr0)\n" >&1
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `$1 (_filename)`: name of the file/testscript
#       `$2 (_cok)`: Counter of OK Tests
#       `$3 (_cfail)`: Counter of FAILED Tests
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_print_final_result _COK _CFAIL "_COK" "_CFAIL"
#******************************************************************************************************************************
te_print_final_result() {
    (( ${#} < 3 )) && te_abort "te_print_final_result" "$(_g "FUNCTION Requires AT LEAST '3' argument. Got '%s'\n\n")" "${#}"
    # skip assignment:  _filename=${1}
    # skip assignment:  _cok=${2}
    # skip assignment:  _cfail=${3}

    echo
    echo
    printf "$(tput bold)$(tput setaf 2)\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(_g "# TESTS RESULTS <%s>: OK: '%s' FAILED: '%s'\n")" "${1}" "${2}" "${3}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "$(tput sgr0)\n" >&1

    if (( ${3} > 0 )); then
        printf "$(tput bold)$(tput setaf 3)\n" >&1
        printf "$(_g "    There are FAILED TEST RESULTS (%s): Check the terminal output.")" "${3}" >&1
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
    local _text=$(_g "TESTING:")
    printf "$(tput bold)$(tput setaf 5)\n=======> ${_text}$(tput sgr0)$(tput bold)$(tput setaf 4) ${1}$(tput sgr0)\n" >&1
}


#******************************************************************************************************************************
#   USAGE: te_abort "from_where_name" "$(_g "Message did not find path: '%s'")" "$PATH"
#******************************************************************************************************************************
te_abort() {
    if (( ${#} < 2 )); then
        m_exit "te_abort" "$(_g "FUNCTION 'm_exit()': Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    local _from=${1}
    local _m=${2}; shift
    local _blue="$(tput bold)$(tput setaf 4)"
    local _m2=$(_g "ABORTING....from:")

    printf "$(tput bold)$(tput setaf 5)\n\n=======> ${_m2}$(tput sgr0)${_blue} <${_from}> $(tput sgr0)\n" >&2
    printf "$(tput bold)$(tput setaf 1)    ->$(tput sgr0)$$(tput bold) ${_m}$(tput sgr0)\n\n" "${@:2}" >&2
    exit 1
}


#******************************************************************************************************************************
#   USAGE: te_warn "from_where_name" "This Test needs working internet."
#******************************************************************************************************************************
te_warn() {
    (( ${#} < 2 )) && m_exit "te_abort" "$(_g "FUNCTION Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    # skip assignment:  _from=${1}
    local _m=${2}; shift

    printf "$(tput bold)$(tput setaf 1)  >>> WARNING: <${1}>  ${_m}$(tput sgr0)\n" "${@:2}" >&2
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       if [[ -f $PATH ]]; then
#           te_ms_ok _COK "$(_g "Found path: '%s'")" "$PATH"
#       else
#           te_ms_failed _CFAIL "$(_g "Found path: '%s'")" "$PATH"
#       fi
#******************************************************************************************************************************
te_ms_ok() {
    (( ${#} < 2 )) && te_abort "te_ms_ok" "$(_g "FUNCTION Requires AT LEAST '2' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local _m=${2}; shift
    local _m_prefix=$(_g "Testing:")

    printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_m_prefix}$(tput bold) ${_m}$(tput sgr0)\n" "${@:2}" >&1
    ((_ret_cok++))
}


#******************************************************************************************************************************
#   ARGUMENTS
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       if [[ -f $PATH ]]; then
#           te_ms_ok _COK "$(_g "Found path: '%s'")" "$PATH"
#       else
#           te_ms_failed _CFAIL "$(_g "Found path: '%s'")" "$PATH"
#       fi
#******************************************************************************************************************************
te_ms_failed() {
    (( ${#} < 2 )) && te_abort "te_ms_failed" "$(_g "FUNCTION Requires AT LEAST '2' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local _m=${2}; shift
    local _m_prefix=$(_g "Testing:")

    printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_m_prefix}$(tput bold) ${_m}$(tput sgr0)\n" "${@:2}" >&1
    ((_ret_cok++))
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
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_func_output)`: output message of an function to check
#       `$4 (_find_error_message)`: error message to search for
#
#   OPTIONAL ARGUMETNTS
#       `_inf`: extra info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _output="Some info FUNCTION: Requires AT LEAST '2' arguments. Got '1' some more text"
#       te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: Requires AT LEAST '2' arguments. Got '1'"
#       te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: Requires AT LEAST '7' arguments. Got '8'" "EXTRA"
#******************************************************************************************************************************
te_find_err_msg() {
    local _fn="te_find_err_msg"
    (( ${#} < 4 )) && te_abort "${_fn}" "$(_g "FUNCTION Requires AT LEAST '4' argument. Got '%s'\n\n")" "${#}"
    [[ -n $3 ]] || te_abort "${_fn}" "$(_g "FUNCTION Argument 3 MUST NOT be empty.\n\n")"
    [[ -n $4 ]] || te_abort "${_fn}" "$(_g "FUNCTION Argument 4 MUST NOT be empty.\n\n")"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    # skip assignment:  _func_output=${3}
    # skip assignment:  _find_error_message=${4}
    local _inf=${5:-""}
    local _m=$(_g "Find err-msg:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${3} == *${4}* ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_m}$(tput bold) ${4}$(tput sgr0)${_inf}\n" >&1
        ((_ret_cok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_m}$(tput bold) ${4}$(tput sgr0)${_inf}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_func_output` contains the `_find_info_message`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_func_output)`: output message of an function to check
#       `$4 (_find_info_message)`: info message to search for
#
#   OPTIONAL ARGUMETNTS
#       `_inf`: extra info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _output="Some info FUNCTION 'xxx()': Download success. some more text"
#       te_find_info_msg _COK _CFAIL "${_output}" "FUNCTION 'xxx()': Download success."
#       te_find_info_msg _COK _CFAIL "${_output}" "FUNCTION 'xxx()': Download success but." "EXTRA Optional Info"
#******************************************************************************************************************************
te_find_info_msg() {
    local _fn="te_find_info_msg"
    (( ${#} < 4 )) && te_abort "${_fn}" "$(_g "FUNCTION Requires AT LEAST '4' argument. Got '%s'\n\n")" "${#}"
    [[ -n $3 ]] || te_abort "${_fn}" "$(_g "FUNCTION Argument 3 MUST NOT be empty.\n\n")"
    [[ -n $4 ]] || te_abort "${_fn}" "$(_g "FUNCTION Argument 4 MUST NOT be empty.\n\n")"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    # skip assignment:  _func_output=${3}
    # skip assignment:  _find_info_message=${4}
    local _inf=${5:-""}
    local _m=$(_g "Find info-msg:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${3} == *${4}* ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] $(tput sgr0)${_m}$(tput bold) ${4}$(tput sgr0)${_inf}\n" >&1
        ((_ret_cok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] $(tput sgr0)${_m}$(tput bold) ${4}$(tput sgr0)${_inf}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_str` is the same as `_ref_str`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_str)`: string value to compare `_func_output` to: could also be empty
#       `$4 (_ref_str)`: string expected function output: could also be empty
#
#   OPTIONAL ARGUMETNTS
#       `_inf`: extra info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _ref_str="/home/test"
#       te_same_val _COK _CFAIL "${_ref_str}" "/home/test"
#       te_same_val _COK _CFAIL "${_ref_str}" "/home/testing" "EXTRA"
#
#   NOTES FOR INTEGERS: pass it as a string
#       declare -i _n=10
#       te_same_val _COK _CFAIL "${_n}" "10"
#
#   NOTES FOR ARRAYS: pass it as a string
#       local _result=(value1 value2 value3)
#       Need to convert it first to a string
#       _tmp_str=${_result[@]}
#       te_same_val _COK _CFAIL "${_tmp_str}" "value1 value2 value3"
#******************************************************************************************************************************
te_same_val() {
    (( ${#} < 4 )) && te_abort "te_same_val" "$(_g "FUNCTION Requires AT LEAST '4' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    # skip assignment:  _in_str=${3}
    # skip assignment:  _ref_str=${4}
    local _inf=${5:-""}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _m=$(_g "Expected value: <")
    local _m1=$(_g "> Got:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${3} == ${4} ]]; then
        printf "${_bold}$(tput setaf 2)    [  OK  ] ${_off}${_m}${_bold}${4}${_off}${_m1} <${_bold}${3}${_off}>${_inf}\n" >&1
        ((_ret_cok++))
    else
        printf "${_bold}$(tput setaf 1)    [FAILED] ${_off}${_m}${_bold}${4}${_off}${_m1} <${_bold}${3}${_off}>${_inf}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_string` is empty. [[ -z _in_string ]]
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_string)`: value to check
#       `$4 (_inf)`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_empty_val _COK _CFAIL "" "Testing something - expected an empty string"
#       te_empty_val _COK _CFAIL "none_empty" "Testing something - expected an empty string"
#******************************************************************************************************************************
te_empty_val() {
    (( ${#} != 4 )) && te_abort "te_empty_val" "$(_g "FUNCTION Requires EXACT '4' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    # skip assignment:  _in_string=${3}
    # skip assignment:  _inf=${4}
    local _off=$(tput sgr0)
    local _m=$(_g "Expected empty <>. Got:")

    if [[ -z ${3} ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] ${_off}${_m} <$(tput bold)}${3}${_off}>${_bold} ${4}${_off}\n" >&1
        ((_ret_cok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] ${_off}${_m} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_string` is not empty. [[ -n _in_string ]]
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `$3 (_in_string)`: value to check
#       `$4 (_inf)`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_not_empty_val _COK _CFAIL "not_empty" "Testing something - expected an none empty string"
#       te_not_empty_val _COK _CFAIL "" "Testing something - expected an none empty string"
#******************************************************************************************************************************
te_not_empty_val() {
    (( ${#} != 4 )) && te_abort "te_not_empty_val" "$(_g "FUNCTION Requires EXACT '4' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    # skip assignment:  _in_string=${3}
    # skip assignment:  _inf=${4}
    local _off=$(tput sgr0)
    local _m=$(_g "Expected not empty. Got:")

    if [[ -n ${3} ]]; then
        printf "$(tput bold)$(tput setaf 2)    [  OK  ] ${_off}${_m} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" >&1
        ((_ret_cok++))
    else
        printf "$(tput bold)$(tput setaf 1)    [FAILED] ${_off}${_m} <$(tput bold)${3}${_off}>${_bold} ${4}${_off}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 0
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `$4 (_inf)`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retval_0 _COK _CFAIL 0 "${_info_msg}"
#       te_retval_0 _COK _CFAIL 1 "${_info_msg}"
#       te_retval_0 _COK _CFAIL ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retval_0() {
    local _fn="te_retval_0"
    (( ${#} != 4 )) && te_abort "${_fn}" "$(_g "FUNCTION Requires EXACT '4' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    declare -i _func_ret=${3}
    # skip assignment:  _inf=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _m=$(_g "Expected ret-val (")
    local _m1=$(_g ") GOT:")

    if (( _func_ret )); then
        printf "${_red}    [FAILED] ${_off}${_m}${_bold}0${_off}${_m1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_ret_cfail++))
    else
        printf "${_green}    [  OK  ] ${_off}${_m}${_bold}0${_off}${_m1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_COK++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 1
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `$4 (_inf)`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retval_1 _COK _CFAIL 1 "${_info_msg}"
#       te_retval_1 _COK _CFAIL 0 "${_info_msg}"
#       te_retval_1 _COK _CFAIL ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retval_1() {
    local _fn="te_retval_1"
    (( ${#} != 4 )) && te_abort "${_fn}" "$(_g "FUNCTION Requires EXACT '4' argument. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    declare -i _func_ret=${3}
    # skip assignment:  _inf=${4}
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    local _m=$(_g "Expected ret-val (")
    local _m1=$(_g ") GOT:")

    if (( ${_func_ret} )); then
        printf "${_green}    [  OK  ] ${_off}${_m}${_bold}1${_off}${_m1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_COK++))
    else
        printf "${_red}    [FAILED] ${_off}${_m}${_bold}1${_off}${_m1} (${_bold}${_func_ret}${_off}) ${4}\n" >&1
        ((_ret_cfail++))
    fi

    # Avoid: ABORTING....from: <ts_trap_opt_unknown_error>
    return 0
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
