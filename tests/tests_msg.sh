#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/../scripts"
_TESTFILE="msg.sh"

source "${_FUNCTIONS_DIR}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\"" "${_signal}"; done
trap "t_trap_i" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "t_trap_u" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

source "${_FUNCTIONS_DIR}/msg.sh"
m_format

declare -i _COK=0
declare -i _CFAIL=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: m_get_pl_bash_functions_version()
#******************************************************************************************************************************
tsm__m_get_pl_bash_functions_version() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_get_pl_bash_functions_version()"
    local _vers; m_get_pl_bash_functions_version _vers

    te_not_empty_val _COK _CFAIL "${_vers}" "Testing get pl_bash_functions package version."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_get_pl_bash_functions_version


#******************************************************************************************************************************
# TEST: m_has_tested_version()
#******************************************************************************************************************************
tsm__m_has_tested_version() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_has_tested_version()"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _yellow="${_bold}$(tput setaf 3)"
    local _msg1="${_yellow}====> WARNING:"
    local _pl_bash_functions_version; m_get_pl_bash_functions_version _pl_bash_functions_version
    local _output

    _output=$((m_has_tested_version "different_version") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" \
        "${_msg1}${_off} This script was ${_bold}TESTET${_off} with <pl_bash_functions>: 'different_version'"

    _output=$((m_has_tested_version "${_pl_bash_functions_version}") 2>&1)
    te_empty_val _COK _CFAIL "${_output}" "Testing same pl_bash_functions version."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_has_tested_version


#******************************************************************************************************************************
# TEST: m_pl_bash_functions_dir()
#******************************************************************************************************************************
tsm__m_pl_bash_functions_dir() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_pl_bash_functions_dir() very limited test"
    local _installed_dir; m_pl_bash_functions_dir _installed_dir
    local _ref_script_dir=$(readlink -f "${_FUNCTIONS_DIR}")

    te_same_val _COK _CFAIL "${_installed_dir}" "${_ref_script_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_pl_bash_functions_dir


#******************************************************************************************************************************
# TEST: m_more()
#******************************************************************************************************************************
tsm__m_more() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "tsm__m_more()"
    local _filename="/home/testfile.txt"
    local _output

    _M_VERBOSE_I="no"
    _output=$(m_more "$(_g "Source file: <%s>")" "${_filename}")
    te_empty_val _COK _CFAIL "${_output}" "Testing _M_VERBOSE_I=no skip output."

    _M_VERBOSE_I="yes"
    _output=$(m_more "$(_g "Source file: <%s>")" "${_filename}")
    te_not_empty_val _COK _CFAIL "${_output}" "Testing _M_VERBOSE_I=yes expect output."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_more


#******************************************************************************************************************************
# TEST: m_bold()
#******************************************************************************************************************************
tsm__bold() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "tsm__bold()"
    local _filename="/home/testfile.txt"
    local _output

    _M_VERBOSE="no"
    _output=$(m_bold "$(_g "Source file: <%s>")" "${_filename}")
    te_empty_val _COK _CFAIL "${_output}" "Testing _M_VERBOSE=no skip output."

    _M_VERBOSE="yes"
    _output=$(m_bold "$(_g "Source file: <%s>")" "${_filename}")
    te_not_empty_val _COK _CFAIL "${_output}" "Testing _M_VERBOSE=yes expect output."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__bold


#******************************************************************************************************************************
# TEST: m_exit()
#******************************************************************************************************************************
tsm__m_exit() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_exit()"
    local _fn="tsm__m_exit"
    local _filename="/home/testfile.txt"
    local _info="Find passed info message: Just some extra info."
    local _output

    _output=$((m_exit "${_fn}" "$(_g "Did Not find file: <%s> _info: '%s'")" "${_filename}" "${_info}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Find passed info message: Just some extra info."

    (m_exit "${_fn}" "$(_g "Did Not find file: <%s> _info: '%s'")" "${_filename}" "${_info}") &> /dev/null
    te_retval_1 _COK _CFAIL $? "Just normal abort."

    _output=$((m_exit "${_fn}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '2' arguments. Got '1'"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_exit


#******************************************************************************************************************************
# TEST: m_exit_remove_path()
#******************************************************************************************************************************
tsm__m_exit_remove_path() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_exit_remove_path()"
    local _fn="tsm__m_exit_remove_path"
    local _tmp_dir=$(mktemp -d)
    local _builds_dir="${_tmp_dir}/builds"
    local _output

    _output=$((m_exit_remove_path "${_fn}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Requires AT LEAST '4' arguments. Got '1'"

    _output=$((m_exit_remove_path "${_fn}" "yes" "${_builds_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Requires AT LEAST '4' arguments. Got '3'"

    _output=$((m_exit_remove_path "${_fn}" "wrong" "${_builds_dir}" "$(_g "this is a failure: <%s>")" "ERROR") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Argument '2' MUST be 'yes' or 'no'. Got 'wrong'"

    _output=$((m_exit_remove_path "${_fn}" "no" "" "Path is: ${_tmp_dir}/none_existing") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Path is: ${_tmp_dir}/none_existing" \
        "ARGUMENT 3 empty but ARGUMENT 2 is not."

    _output=$((m_exit_remove_path "${_fn}" "yes" "" "${_tmp_dir}/none_existing") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Argument '3' MUST NOT be empty if argument 2 is 'yes'"

    # create the dir
    mkdir -p "${_builds_dir}"

    _output=$((m_exit_remove_path "${_fn}" "no" "" "Keeping build_dir: <%s>" "${_builds_dir}") 2>&1)
    if [[ ! -d ${_builds_dir} ]]; then
        te_warn "${_fn}" "!! ERROR IN TEST-case: Keeping build_dir: <${_builds_dir}> should still exist."
        exit 1
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Keeping build_dir:"

    _output=$((m_exit_remove_path "${_fn}" "yes" "${_builds_dir}" "Removing build_dir: <%s>" "${_builds_dir}") 2>&1)
    if [[ -d ${_builds_dir} ]]; then
        te_warn "${_fn}" "!! ERROR IN TEST-case: Keeping build_dir: <${_builds_dir}> should not exist."
        exit 1
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Removing build_dir:"

    (m_exit_remove_path "${_fn}" "yes" "${_builds_dir}" "Removing build_dir: <%s>" "${_builds_dir}") &> /dev/null
    te_retval_1 _COK _CFAIL $? "Remove Path is: 'yes' BUT none existing."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_exit_remove_path


#******************************************************************************************************************************
# TEST: m_hrl()
#******************************************************************************************************************************
tsm__m_hrl() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "m_hrl()"
    local _expected_output="${_M_GREEN}#=========================#${_M_OFF}"
    local _output=$(m_hrl "${_M_GREEN}" "#" "=" 25 "#")

    te_same_val _COK _CFAIL "${_output}" "${_expected_output}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsm__m_hrl



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
