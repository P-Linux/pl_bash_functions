#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/.."
_TESTFILE="obsolete_historical.sh"

source "${_FUNCTIONS_DIR}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\"" "${_signal}"; done
trap "t_trap_i" INT
trap "t_trap_u" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

source "${_FUNCTIONS_DIR}/msg.sh"
m_format

source "${_TEST_SCRIPT_DIR}/obsolete_historical.sh"

declare -i _COK=0
declare -i _CFAIL=0


#******************************************************************************************************************************
# TEST: u_min_number_args_exit()
#******************************************************************************************************************************
tsu__u_min_number_args_exit() {
    te_print_function_msg "tsu__u_min_number_args_exit()"

    _example_func() {
        u_min_number_args_exit "_example_func" 2 $#

        local _required_1=${1}
        local _required_2=${2}
        local _optional_3=${3}
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test enough args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test not enough args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'" "Test not enough args."
}
tsu__u_min_number_args_exit


#******************************************************************************************************************************
# TEST: u_min_number_args_not_empty_abort()
#******************************************************************************************************************************
tsu__u_min_number_args_not_empty_abort() {
    te_print_function_msg "u_min_number_args_not_empty_abort()"

    _example_func() {
        u_min_number_args_not_empty_abort "_example_func" 2 "$@"

        local _required_1=${1}
        local _required_2=${2}
        local _optional_3=${3}
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test enough args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test not enough args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'" "Test not enough args."



    _output=$((_example_func "VALUE_1" "" "OPTIONAL_VALUE") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test enough args BUT ONE EMPTY."
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: '_example_func()' Argument '2': MUST NOT be empty" \
        "Test enough args BUT ONE EMPTY."
}
tsu__u_min_number_args_not_empty_abort


#******************************************************************************************************************************
# TEST: u_exact_number_args_exit()
#******************************************************************************************************************************
tsu__u_exact_number_args_exit() {
    te_print_function_msg "u_exact_number_args_exit()"
    _example_func() {
        u_exact_number_args_exit "_example_func" 2 $#

        local _required_1=${1}
        local _required_2=${2}
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test exact number of args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test not enough args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'" "Test not enough args."

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test too many args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'" "Test too many args."
}
tsu__u_exact_number_args_exit


#******************************************************************************************************************************
# TEST: u_exact_number_args_not_empty_exit()
#******************************************************************************************************************************
tsu__u_exact_number_args_not_empty_exit() {
    te_print_function_msg "u_exact_number_args_not_empty_exit()"
    _example_func() {
        # call this first
        u_exact_number_args_not_empty_exit "_example_func" 2 "$@"

        local _required_1=${1}
        local _required_2=${2}
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test exact args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test not enough args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'" "Test not enough args."

    (_example_func "VALUE_1" "") &> /dev/null
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test exact number of args BUT ONE EMPTY."

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed ${?} "Test not enough args."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'" "Test too many args."
}
tsu__u_exact_number_args_not_empty_exit


#******************************************************************************************************************************
# TEST: u_exit_sparse_array()
#******************************************************************************************************************************
tsu__u_exit_sparse_array() {
    te_print_function_msg "u_exit_sparse_array()"
    local _fn="tsu__u_exit_sparse_array"
    local _sparse_array=([0]="a" [6]="VALID ITEM")
    declare -A _associative_array=(["key1"]="Item1" ["key2"]="Item2")
    declare -i _assigned_int=5
    declare -a -rl _options_arl_assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array
    local _output

    _output=$((u_exit_sparse_array) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION Requires EXACT '2' arguments. Got '0'" "Test FUNCTION Requires EXACT 2 arguments"

    _output=$((u_exit_sparse_array _sparse_array "${_fn}") 2>&1)
    if [[ ${_output} == *"Not an index array"* ]]; then
        te_warn "${_fn}" "Expected an input index array. Wrong test code."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: 'tsu__u_exit_sparse_array()' Found a sparse array which is not allowd. Array-Name: 'a'"

    _output=$((u_exit_sparse_array _associative_array "${_fn}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not an index array" "Test Not an index array INPUT: <_associative_array>."

    _output=$((u_exit_sparse_array _assigned_int "${_fn}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not an index array" "Test Not an index array INPUT: <_assigned_int>."

    _output=$((u_exit_sparse_array _options_arl_assigned_array "${_fn}") 2>&1)
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test <_options_arl_assigned_array>."

    _output=$((u_exit_sparse_array _not_assigned_array "${_fn}") 2>&1)
    te_retval_0 _dummy_ok _dummy_failed ${?} "Test <_not_assigned_array>."
}
tsu__u_exit_sparse_array



#******************************************************************************************************************************

te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
