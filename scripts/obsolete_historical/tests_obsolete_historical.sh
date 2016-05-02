#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

declare -r _THIS_SCRIPT_PATH_UTILITIES=$(readlink -f "${BASH_SOURCE[0]}")
declare -r _TEST_SCRIPT_DIR_UTILITIES=$(dirname "$_THIS_SCRIPT_PATH_UTILITIES")

source "${_TEST_SCRIPT_DIR_UTILITIES}/../msg.sh"
trap "ms_interrupted" SIGHUP SIGINT SIGQUIT SIGTERM
ms_format
ms_have_gettext_abort "$_THIS_SCRIPT_PATH_UTILITIES"

source "${_TEST_SCRIPT_DIR_UTILITIES}/obsolete_historical.sh"

ms_header "$_MS_GREEN" "$(gettext "EXAMPLES/TESTS for: obsolete_historical.sh")"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


#******************************************************************************************************************************
# TEST: ut_min_number_args_abort()
#******************************************************************************************************************************
ts_ut___ut_min_number_args_abort() {

    _example_func() {
        ut_min_number_args_abort "_example_func" 2 $#

        local _required_1=$1
        local _required_2=$2
        local _optional_3=$3
    }

    local _output
    declare -i _ret

    ms_msg 'TESTING: ut_min_number_args_abort()'

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test enough args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test enough args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi

    (_example_func "VALUE_1") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1") 2>&1)
    if [[ $_output == *"FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'"* ]]; then
        echo '    [  OK  ]: Test Requires AT LEAST 2 argument/s. Got 1: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test Requires AT LEAST 2 argument/s. Got 1: Find error message.'; ((_COUNT_FAILED++))
    fi
    echo
}
ts_ut___ut_min_number_args_abort


#******************************************************************************************************************************
# TEST: ut_min_number_args_not_empty_abort()
#******************************************************************************************************************************
ts_ut___ut_min_number_args_not_empty_abort() {

    _example_func() {
        ut_min_number_args_not_empty_abort "_example_func" 2 "$@"

        local _required_1=$1
        local _required_2=$2
        local _optional_3=$3
    }

    local _output
    declare -i _ret

    ms_msg 'TESTING: ut_min_number_args_not_empty_abort()'

    (_example_func "VALUE_1" "VALUE_2" "OPTIONAL_VALUE") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test enough args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test enough args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi

    (_example_func "VALUE_1") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1") 2>&1)
    if [[ $_output == *"FUNCTION '_example_func()': Requires AT LEAST '2' argument/s. Got '1'"* ]]; then
        echo '    [  OK  ]: Test not enough args: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Find error message.'; ((_COUNT_FAILED++))
    fi

    (_example_func "VALUE_1" "" "OPTIONAL_VALUE") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test enough args BUT ONE EMPTY: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test enough args BUT ONE EMPTY: Expected return value (1)' "GOT: $_ret"; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1" "" "OPTIONAL_VALUE") 2>&1)
    if [[ $_output == *"FUNCTION: '_example_func()' Argument '2': MUST NOT be empty"* ]]; then
        echo '    [  OK  ]: Test enough args BUT ONE EMPTY: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]:: Test enough args BUT ONE EMPTY: Find error message.'; ((_COUNT_FAILED++))
    fi
    echo
}
ts_ut___ut_min_number_args_not_empty_abort


#******************************************************************************************************************************
# TEST: ut_exact_number_args_abort()
#******************************************************************************************************************************
ts_ut___ut_exact_number_args_abort() {

    _example_func() {
        ut_exact_number_args_abort "_example_func" 2 $#

        local _required_1=$1
        local _required_2=$2
    }

    local _output
    declare -i _ret

    ms_msg 'TESTING: ut_exact_number_args_abort()'

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test exact number of args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test exact number of args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi

    (_example_func "VALUE_1") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1") 2>&1)
    if [[ $_output == *"FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'"* ]]; then
        echo '    [  OK  ]: Test not enough args: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Find error message.'; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    if [[ $_output == *"FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'"* ]]; then
        echo '    [  OK  ]: Test too many args: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test too many args: Find error message.'; ((_COUNT_FAILED++))
    fi
    echo
}
ts_ut___ut_exact_number_args_abort


#******************************************************************************************************************************
# TEST: ut_exact_number_args_not_empty_abort()
#******************************************************************************************************************************
ts_ut___ut_exact_number_args_not_empty_abort() {

    _example_func() {
        # call this first
        ut_exact_number_args_not_empty_abort "_example_func" 2 "$@"

        local _required_1=$1
        local _required_2=$2
    }

    local _output
    declare -i _ret

    ms_msg 'TESTING: ut_exact_number_args_not_empty_abort()'

    (_example_func "VALUE_1" "VALUE_2") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test exact args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test exact args: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi

    (_example_func "VALUE_1") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Expected return value (1)' "GOT: $_ret"; ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1") 2>&1)
    if [[ $_output == *" FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '1'"* ]]; then
        echo '    [  OK  ]: Test not enough args: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test not enough args: Find error message.'; ((_COUNT_FAILED++))
    fi

    (_example_func "VALUE_1" "") &> /dev/null
    _ret=$?
    if (( _ret )); then
        echo '    [  OK  ]: Test exact number of args BUT ONE EMPTY: Expected return value (1)' "GOT: $_ret"; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test exact number of args BUT ONE EMPTY: Expected return value (1)' "GOT: $_ret"
        ((_COUNT_FAILED++))
    fi

    _output=$((_example_func "VALUE_1" "VALUE_2" "VALUE_3") 2>&1)
    if [[ $_output == *"FUNCTION '_example_func()': Requires EXACT '2' argument/s. Got '3'"* ]]; then
        echo '    [  OK  ]: Test too many args: Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test too many args: Find error message.'; ((_COUNT_FAILED++))
    fi
    echo
}
ts_ut___ut_exact_number_args_not_empty_abort


#******************************************************************************************************************************
# TEST: ut_abort_sparse_array()
#******************************************************************************************************************************
ts_ut___ut_abort_sparse_array() {
    local _fn="ts_ut___ut_abort_sparse_array"
    local _sparse_array=([0]="a" [6]="VALID ITEM")
    declare -A _associative_array=(["key1"]="Item1" ["key2"]="Item2")
    declare -i _assigned_int=5
    declare -a -rl _options_arl_assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array
    local _output
    declare -i _ret

    ms_msg 'TESTING: ut_abort_sparse_array()'

    _output=$((ut_abort_sparse_array) 2>&1)
    if [[ $_output == *"FUNCTION: 'ut_abort_sparse_array()' Requires EXACT '2' arguments. Got '0'"* ]]; then
        echo '    [  OK  ]: Test FUNCTION Requires EXACT 2 arguments. Got '0'. Find error message'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test FUNCTION Requires EXACT 2 arguments. Got '0'. Find error message'; ((_COUNT_FAILED++))
    fi

    _output=$((ut_abort_sparse_array _sparse_array "$_fn") 2>&1)
    if [[ $_output == *"Not an index array"* ]]; then
        ms_warn2 "$_fn" 'Expected an input index array. Wrong test code.'
    fi
    if [[ $_output == *"Found a sparse array which is not allowd. Array-Name: 'a'"* ]]; then
        echo '    [  OK  ]: Test INPUT: <_sparse_array>. Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test INPUT: <_sparse_array>. Find error message.'; ((_COUNT_FAILED++))
    fi

    _output=$((ut_abort_sparse_array _associative_array "$_fn") 2>&1)
    if [[ $_output == *"Not an index array"* ]]; then
        echo '    [  OK  ]: Test Not an index array INPUT: <_associative_array>. Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test Not an index array INPUT: <_associative_array>. Find error message.'; ((_COUNT_FAILED++))
    fi

    _output=$((ut_abort_sparse_array _assigned_int "$_fn") 2>&1)
    if [[ $_output == *"Not an index array"* ]]; then
        echo '    [  OK  ]: Test Not an index array INPUT: <_assigned_int>. Find error message.'; ((_COUNT_OK++))
    else
        echo '    [FAILED]: Test Not an index array INPUT: <_assigned_int>. Find error message.'; ((_COUNT_FAILED++))
    fi

    _output=$((ut_abort_sparse_array _options_arl_assigned_array "$_fn") 2>&1)
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test <_options_arl_assigned_array>: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test <_options_arl_assigned_array>: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi

    _output=$((ut_abort_sparse_array _not_assigned_array "$_fn") 2>&1)
    _ret=$?
    if (( _ret )); then
        echo '    [FAILED]: Test <_not_assigned_array>: Expected return value (0)' "GOT: $_ret"; ((_COUNT_FAILED++))
    else
        echo '    [  OK  ]: Test <_not_assigned_array>: Expected return value (0)' "GOT: $_ret"; ((_COUNT_OK++))
    fi
    echo
}
ts_ut___ut_abort_sparse_array


#******************************************************************************************************************************

echo
echo
ms_header "$_MS_GREEN" "$(gettext "TESTS RESULTS: _COUNT_OK: '%s' _COUNT_FAILED: '%s'")" "$_COUNT_OK" "$_COUNT_FAILED"

if (( $_COUNT_FAILED > 0 ))  ; then
    ms_color "$_MS_YELLOW" "$(gettext "If _COUNT_FAILED is greater than '0': Reason could be also internet problems")"
fi


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
