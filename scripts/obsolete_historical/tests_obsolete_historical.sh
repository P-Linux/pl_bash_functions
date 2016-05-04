#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/.."

source "${_FUNCTIONS_DIR}/trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\"" "${_signal}"; done
trap "tr_trap_exit_interrupted" INT
trap "tr_trap_exit_unknown_error" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "obsolete_historical.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

source "${_TEST_SCRIPT_DIR}/obsolete_historical.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


#******************************************************************************************************************************
# TEST: ut_min_number_args_abort()
#******************************************************************************************************************************
ts_ut___ut_min_number_args_abort() {
    te_print_function_msg "ts_ut___ut_min_number_args_abort()"

    _example_func() {
        ut_min_number_args_abort "_example_func" 2 $#

        local _required_1=$1
        local _required_2=$2
        local _optional_3=$3
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed $? "Test enough args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test not enough args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'" "Test not enough args."
}
ts_ut___ut_min_number_args_abort


#******************************************************************************************************************************
# TEST: ut_min_number_args_not_empty_abort()
#******************************************************************************************************************************
ts_ut___ut_min_number_args_not_empty_abort() {
    te_print_function_msg "ut_min_number_args_not_empty_abort()"

    _example_func() {
        ut_min_number_args_not_empty_abort "_example_func" 2 "$@"

        local _required_1=$1
        local _required_2=$2
        local _optional_3=$3
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed $? "Test enough args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test not enough args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'" "Test not enough args."



    _output=$((_example_func "VALUE_1" "" "OPTIONAL_VALUE") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test enough args BUT ONE EMPTY."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}"  "FUNCTION: '_example_func()' Argument '2': MUST NOT be empty" \
        "Test enough args BUT ONE EMPTY."
}
ts_ut___ut_min_number_args_not_empty_abort


#******************************************************************************************************************************
# TEST: ut_exact_number_args_abort()
#******************************************************************************************************************************
ts_ut___ut_exact_number_args_abort() {
    te_print_function_msg "ut_exact_number_args_abort()"
    _example_func() {
        ut_exact_number_args_abort "_example_func" 2 $#

        local _required_1=$1
        local _required_2=$2
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed $? "Test exact number of args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test not enough args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'" "Test not enough args."

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test too many args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'" "Test too many args."
}
ts_ut___ut_exact_number_args_abort


#******************************************************************************************************************************
# TEST: ut_exact_number_args_not_empty_abort()
#******************************************************************************************************************************
ts_ut___ut_exact_number_args_not_empty_abort() {
    te_print_function_msg "ut_exact_number_args_not_empty_abort()"
    _example_func() {
        # call this first
        ut_exact_number_args_not_empty_abort "_example_func" 2 "$@"

        local _required_1=$1
        local _required_2=$2
    }

    local _output

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    te_retval_0 _dummy_ok _dummy_failed $? "Test exact args."

    _output=$((_example_func "VALUE_1") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test not enough args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'" "Test not enough args."

    (_example_func "VALUE_1" "") &> /dev/null
    te_retval_1 _dummy_ok _dummy_failed $? "Test exact number of args BUT ONE EMPTY."

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    te_retval_1 _dummy_ok _dummy_failed $? "Test not enough args."
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'" "Test too many args."
}
ts_ut___ut_exact_number_args_not_empty_abort


#******************************************************************************************************************************
# TEST: ut_abort_sparse_array()
#******************************************************************************************************************************
ts_ut___ut_abort_sparse_array() {
    te_print_function_msg "ut_abort_sparse_array()"
    local _fn="ts_ut___ut_abort_sparse_array"
    local _sparse_array=([0]="a" [6]="VALID ITEM")
    declare -A _associative_array=(["key1"]="Item1" ["key2"]="Item2")
    declare -i _assigned_int=5
    declare -a -rl _options_arl_assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array
    local _output

    _output=$((ut_abort_sparse_array) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION: 'ut_abort_sparse_array()' Requires EXACT '2' arguments. Got '0'" "Test FUNCTION Requires EXACT 2 arguments"

    _output=$((ut_abort_sparse_array _sparse_array "$_fn") 2>&1)
    if [[ $_output == *"Not an index array"* ]]; then
        te_warn "$_fn" "Expected an input index array. Wrong test code."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION: 'ts_ut___ut_abort_sparse_array()' Found a sparse array which is not allowd. Array-Name: 'a'"

    _output=$((ut_abort_sparse_array _associative_array "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Not an index array" "Test Not an index array INPUT: <_associative_array>."

    _output=$((ut_abort_sparse_array _assigned_int "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Not an index array" "Test Not an index array INPUT: <_assigned_int>."

    _output=$((ut_abort_sparse_array _options_arl_assigned_array "$_fn") 2>&1)
    te_retval_0 _dummy_ok _dummy_failed $? "Test <_options_arl_assigned_array>."

    _output=$((ut_abort_sparse_array _not_assigned_array "$_fn") 2>&1)
    te_retval_0 _dummy_ok _dummy_failed $? "Test <_not_assigned_array>."
}
ts_ut___ut_abort_sparse_array



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
