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

i_general_opt



#=============================================================================================================================#
#
#                   GENERAL TESTING HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Formatted HEADER message
#
#   ARGUMENTS
#       `_file`: filename / or path of the file we test
#
#   USAGE
#       te_print_header "testing.sh"
#******************************************************************************************************************************
te_print_header() {
    local _file=${1}

    printf "${_BF_GREEN}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(_g "# EXAMPLES/TESTS for: '%s'\n")" "${_file}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_BF_OFF}\n" >&1
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `_filename`: name of the file/testscript
#       `_cok`: Counter of OK Tests
#       `_cfail`: Counter of FAILED Tests
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_print_final_result _COK _CFAIL
#******************************************************************************************************************************
te_print_final_result() {
    (( ${#} != 3 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '3' arguments. Got '%s'\n\n")" "${#}"
    local _filename=${1}
    local _cok=${2}
    local _cfail=${3}

    echo
    echo
    printf "${_BF_GREEN}\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "#\n" >&1
    printf "$(_g "# TESTS RESULTS <%s>: OK: '%s' FAILED: '%s'\n")" "${_filename}" "${_cok}" "${_cfail}" >&1
    printf "#\n" >&1
    printf "#===========================================================================#\n" >&1
    printf "${_BF_OFF}\n" >&1

    if (( ${_cfail} > 0 )); then
        printf "${_BF_BOLD}${_BF_YELLOW}\n" >&1
        printf "$(_g "    There are FAILED TEST RESULTS (%s): Check the terminal output.")" "${_cfail}" >&1
        printf "${_BF_OFF}\n" >&1
    fi
}


#******************************************************************************************************************************
# Formatted FINAL RESULT message
#
#   ARGUMENTS
#       `_func_inf`: e.g. info which function is tested
#
#   USAGE
#       te_print_function_msg "te_find_err_msg() very limited tests"
#******************************************************************************************************************************
te_print_function_msg() {
    local _func_inf=${1}
    local _text=$(_g "TESTING:")
    printf "${_BF_MAGENTA}\n=======> ${_text}${_BF_OFF}${_BF_BLUE} ${_func_inf}${_BF_OFF}\n" >&1
}


#******************************************************************************************************************************
#   USAGE: te_abort ${LINENO} "ERROR IN TEST-case: Keeping build_dir: <${_builds_dir}> should still exist."
#******************************************************************************************************************************
te_abort() {
    if (( ${#} < 2 )); then
        te_abort ${LINENO} "$(_g "FUNCTION  Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    fi
    local _lineno=${1}
    local _msg=${2}; shift
    local _m1=$(_g "ABORTING....from:")
    local _m2=$(_g "Line:")
    local _m3=$(_g "Function:")
    local _m4=$(_g "File:")
    local _m5=$(_g "CAN NOT CONINUE TESTING.")
    local _fbasename=${BASH_SOURCE[1]}

    _fbasename=${_fbasename%%+(/)}
    _fbasename=${_fbasename##*/}

    printf "${_BF_MAGENTA}\n\n=======> ${_m1}${_BF_OFF}${_BF_BLUE} <${FUNCNAME[0]}> ${_BF_OFF}\n" >&2
    printf "${_BF_RED}    -> ${_m2} '${_BF_BOLD}${_lineno}${_BF_OFF}' ${_m3} '${_BF_BOLD}${FUNCNAME[1]}${_BF_OFF}' "
    printf "${_m4} '${_BF_BOLD}${_fbasename}${_BF_OFF}'\n\n\n" >&2

    printf "${_BF_YELLOW}    -> MESSAGE !!${_BF_OFF}${_BF_BOLD} ${_msg}${_BF_OFF}\n\n\n" "${@:2}" >&2

    printf "\n\n${_BF_YELLOW}    ${_m5}${_BF_OFF}\n\n" >&2

    # do not use exit 1 otherwise we get an additional trap call
    exit 0
}


#******************************************************************************************************************************
#   USAGE: te_warn "${FUNCNAME[0]}" "This Test needs working internet."
#******************************************************************************************************************************
te_warn() {
    (( ${#} < 2 )) && te_abort ${LINENO} "${FUNCNAME[0]}" "$(_g "FUNCTION Requires AT LEAST '2' arguments. Got '%s'")" "${#}"
    local _from=${1}
    local _m=${2}; shift
    printf "${_BF_RED}  >>> WARNING: <${_from}>  ${_m}${_BF_OFF}\n" "${@:2}" >&2
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
    (( ${#} < 2 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires AT LEAST '2' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local _m=${2}; shift
    local _m_prefix=$(_g "Testing:")
    printf "${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m_prefix}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@:2}" >&1
    _ret_cok+=1
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
    (( ${#} < 2 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires AT LEAST '2' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cfail=${1}
    local _m=${2}; shift
    local _m_prefix=$(_g "Testing:")
    printf "${_BF_BOLD}${_BF_RED}    [FAILED] ${_BF_OFF}${_m_prefix}${_BF_BOLD} ${_m}${_BF_OFF}\n" "${@:2}" >&1
    _ret_cfail+=1
}


#=============================================================================================================================#
#
#                   TESTING FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Reports OK: if the `_func_output` contains the `_find_err_msg`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_output`: output message of an function to check
#       `_find_err_msg`: error message to search for
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
    (( ${#} < 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires AT LEAST '4' arguments. Got '%s'\n\n")" "${#}"
    [[ -n $3 ]] || te_abort ${LINENO} "$(_g "FUNCTION Argument 3 MUST NOT be empty.\n\n")"
    [[ -n $4 ]] || te_abort ${LINENO} "$(_g "FUNCTION Argument 4 MUST NOT be empty.\n\n")"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    local _func_output=${3}
    local _find_err_msg=${4}
    local _inf=${5:-""}
    local _m=$(_g "Find err-msg:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${_func_output} == *${_find_err_msg}* ]]; then
        printf "${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m}${_BF_BOLD} ${_find_err_msg}${_BF_OFF}${_inf}\n" >&1
        _ret_cok+=1
    else
        printf "${_BF_BOLD}${_BF_RED}    [FAILED] ${_BF_OFF}${_m}${_BF_BOLD} ${_find_err_msg}${_BF_OFF}${_inf}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_func_output` contains the `_find_info_message`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_output`: output message of an function to check
#       `_find_inf_msg`: info message to search for
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
    (( ${#} < 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires AT LEAST '4' arguments. Got '%s'\n\n")" "${#}"
    [[ -n $3 ]] || te_abort ${LINENO} "$(_g "FUNCTION Argument 3 MUST NOT be empty.\n\n")"
    [[ -n $4 ]] || te_abort ${LINENO} "$(_g "FUNCTION Argument 4 MUST NOT be empty.\n\n")"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    local _func_output=${3}
    local _find_inf_msg=${4}
    local _inf=${5:-""}
    local _m=$(_g "Find info-msg:")

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${_func_output} == *${_find_inf_msg}* ]]; then
        printf "${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m}${_BF_BOLD} ${_find_inf_msg}${_BF_OFF}${_inf}\n" >&1
        _ret_cok+=1
    else
        printf "${_BF_BOLD}${_BF_RED}    [FAILED] ${_BF_OFF}${_m}${_BF_BOLD} ${_find_inf_msg}${_BF_OFF}${_inf}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_str` is the same as `_ref_str`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_in_str`: string value to compare `_func_output` to: could also be empty
#       `_ref_str`: string expected function output: could also be empty
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
    (( ${#} < 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires AT LEAST '4' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    local _in_str=${3}
    local _ref_str=${4}
    local _inf=${5:-""}
    local _m=$(_g "Expected value: <")
    local _m1=$(_g "> Got:")
    local _off=${_BF_OFF}  # shorten the var name: so we keep the line char limit
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    [[ -n ${_inf} ]] && _inf=" ${_inf}"
    if [[ ${_in_str} == ${_ref_str} ]]; then
        printf "${_b}${_BF_GREEN}    [  OK  ] ${_off}${_m}${_b}${_ref_str}${_off}${_m1} <${_b}${_in_str}${_off}>${_inf}\n" >&1
        _ret_cok+=1
    else
        printf "${_b}${_BF_RED}    [FAILED] ${_off}${_m}${_b}${_ref_str}${_off}${_m1} <${_b}${_in_str}${_off}>${_inf}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_str` is empty. [[ -z _in_str ]]
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_in_str`: value to check
#       `_inf`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_empty_val _COK _CFAIL "" "Testing something - expected an empty string"
#       te_empty_val _COK _CFAIL "none_empty" "Testing something - expected an empty string"
#******************************************************************************************************************************
te_empty_val() {
    (( ${#} != 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '4' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    local _in_str=${3}
    local _inf=${4}
    local _m=$(_g "Expected empty <>. Got:")
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    if [[ -z ${_in_str} ]]; then
        printf "${_b}${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m} <${_b}${_in_str}${_BF_OFF}>${_b} ${_inf}${_BF_OFF}\n" >&1
        _ret_cok+=1
    else
        printf "${_b}${_BF_RED}    [FAILED] ${_BF_OFF}${_m} <${_b}${_in_str}${_BF_OFF}>${_b} ${_inf}${_BF_OFF}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if the `_in_str` is not empty. [[ -n _in_str ]]
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_in_str`: value to check
#       `_inf`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       te_not_empty_val _COK _CFAIL "not_empty" "Testing something - expected an none empty string"
#       te_not_empty_val _COK _CFAIL "" "Testing something - expected an none empty string"
#******************************************************************************************************************************
te_not_empty_val() {
    (( ${#} != 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '4' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    local _in_str=${3}
    local _inf=${4}
    local _m=$(_g "Expected not empty. Got:")
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    if [[ -n ${_in_str} ]]; then
        printf "${_b}${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m} <${_b}${_in_str}${_BF_OFF}>${_b} ${_inf}${_BF_OFF}\n" >&1
        _ret_cok+=1
    else
        printf "${_b}${_BF_RED}    [FAILED] ${_BF_OFF}${_m} <${_b}${_in_str}${_BF_OFF}>${_b} ${_inf}${_BF_OFF}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 1
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `_inf`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retcode_0 _COK _CFAIL 1 "${_info_msg}"
#       te_retcode_0 _COK _CFAIL 0 "${_info_msg}"
#       te_retcode_0 _COK _CFAIL ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retcode_0() {
    (( ${#} != 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '4' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    declare -i _func_ret=${3}
    local _inf=${4}
    local _m=$(_g "Expected ret-val (")
    local _m1=$(_g ") GOT:")
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    if (( ${_func_ret} )); then
        printf "${_BF_RED}    [FAILED] ${_BF_OFF}${_m}${_b}0${_BF_OFF}${_m1} (${_b}${_func_ret}${_BF_OFF}) ${_inf}\n" >&1
        _ret_cfail+=1
    else
        printf "${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m}${_b}0${_BF_OFF}${_m1} (${_b}${_func_ret}${_BF_OFF}) ${_inf}\n" >&1
        _ret_cok+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is 1
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `_inf`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retcode_1 _COK _CFAIL 1 "${_info_msg}"
#       te_retcode_1 _COK _CFAIL 0 "${_info_msg}"
#       te_retcode_1 _COK _CFAIL ${?} "${_info_msg}"
#******************************************************************************************************************************
te_retcode_1() {
    (( ${#} != 4 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '4' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    declare -i _func_ret=${3}
    local _inf=${4}
    local _m=$(_g "Expected ret-val (")
    local _m1=$(_g ") GOT:")
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    if (( ${_func_ret} )); then
        printf "${_BF_GREEN}    [  OK  ] ${_BF_OFF}${_m}${_b}1${_BF_OFF}${_m1} (${_b}${_func_ret}${_BF_OFF}) ${_inf}\n" >&1
        _ret_cok+=1
    else
        printf "${_BF_RED}    [FAILED] ${_BF_OFF}${_m}${_b}1${_BF_OFF}${_m1} (${_b}${_func_ret}${_BF_OFF}) ${_inf}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: ABORTING....from: <ERR Trap>
    return 0
}


#******************************************************************************************************************************
# Reports OK: if `_func_ret` is the same as the expected `_ref_code`
#
#   ARGUMENTS
#       `_ret_cok`: a reference var: Counter for OK Tests - will be updated
#       `_ret_cfail`: a reference var: Counter for FAILED Tests - will be updated
#       `_func_ret`: return value of an function to check
#       `_ref_code`: integer expected function return code
#       `_inf`: info message
#
#   USAGE
#       declare -i _COK=0
#       declare -i _CFAIL=0
#       _info_msg="Checksum verification but no download_mirror defined."
#       te_retcode_same _COK _CFAIL ${?} 18 "${_info_msg}"
#******************************************************************************************************************************
te_retcode_same() {
    (( ${#} != 5 )) && te_abort ${LINENO} "$(_g "FUNCTION Requires EXACT '5' arguments. Got '%s'\n\n")" "${#}"
    local -n _ret_cok=${1}
    local -n _ret_cfail=${2}
    declare -i _func_ret=${3}
    declare -i _ref_code=${4}
    local _inf=${5}
    local _m=$(_g "Expected ret-val (")
    local _m1=$(_g ") GOT:")
    local _o=${_BF_OFF}  # shorten the var name: so we keep the line char limit
    local _b=${_BF_BOLD}  # shorten the var name: so we keep the line char limit

    if (( ${_func_ret} == ${_ref_code} )); then
        printf "${_BF_GREEN}    [  OK  ] ${_o}${_m}${_b}${_ref_code}${_o}${_m1} (${_b}${_func_ret}${_o}) ${_inf}\n" >&1
        _ret_cok+=1
    else
        printf "${_BF_RED}    [FAILED] ${_o}${_m}${_b}${_ref_code}${_o}${_m1} (${_b}${_func_ret}${_o}) ${_inf}\n" >&1
        _ret_cfail+=1
    fi

    # Avoid: catched by a trap
    return 0
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
