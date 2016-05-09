#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/../scripts"

source "${_FUNCTIONS_DIR}/trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\"" "${_signal}"; done
trap "tr_trap_exit_interrupted" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "tr_trap_exit_unknown_error" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "testing.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: te_find_err_msg()
#******************************************************************************************************************************
ts_ms___te_find_err_msg() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_find_err_msg()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_find_err_msg()': Requires AT LEAST '4' argument. Got '2'"

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed "" "dummy") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Argument 3 MUST NOT be empty."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed "dummy" "") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Argument 4 MUST NOT be empty."

    _output="Other output: Find error message: Test expected to pass. other output"
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Find error message: Test expected to pass."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed "dummy" "Find error message: Test expected to fail.") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Find error message: Test expected to fail."

    # Optional extra info
    _output="Other output: Test expected to pass. Extra Info added. other output"
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Test expected to pass. Extra Info added." \
        "This is some optionl info."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_find_err_msg


#******************************************************************************************************************************
# TEST: te_find_info_msg()
#******************************************************************************************************************************
ts_ms___te_find_info_msg() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_find_info_msg()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_find_info_msg()': Requires AT LEAST '4' argument. Got '2'"

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_failed "" "dummy") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Argument 3 MUST NOT be empty."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_failed "dummy" "") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Argument 4 MUST NOT be empty."

    _output="Other output: Find info message: Test expected to pass. other output"
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Find info message: Test expected to pass."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_failed "dummy" "Find info message: Test expected to fail.") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Find info message: Test expected to fail."

    # Optional extra info
    _output="Other output: Test expected to pass. Extra Info added. other output"
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Test expected to pass. Extra Info added." \
        "This is some optionl info."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_find_info_msg


#******************************************************************************************************************************
# TEST: te_same_val()
#
# NOTE: a bit trick to test because of the formatted string
#******************************************************************************************************************************
ts_ms___te_same_val() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_same_val()"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _green="${_bold}$(tput setaf 2)"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0
    local _to_find

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_same_val _dummy_ok _dummy_failed) 2>&1)
    # NOTE: Use here the previously tested te_find_err_msg
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_same_val()': Requires AT LEAST '4' argument. Got '2'"

    _ref_val="/home/test"
    _output="Other output: Find error message: Test expected to pass: other output"
    te_same_val _COUNT_OK _COUNT_FAILED "/home/test" "${_ref_val}"

    _output=$((te_same_val _dummy_ok _dummy_failed "/home/wrong" "/home/test" "EXTRA INFO") 2>&1)
    # NOTE: Use here the previously tested te_find_err_msg
    _to_find="${_off}Expected value: <${_bold}/home/test${_off}> Got: <${_bold}/home/wrong${_off}> EXTRA INFO"
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "${_to_find}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_same_val


#******************************************************************************************************************************
# TEST: te_empty_val()
#******************************************************************************************************************************
ts_ms___te_empty_val() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_empty_val()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_empty_val _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_empty_val()': Requires EXACT '4' argument. Got '2'"

    te_empty_val _dummy_ok _dummy_failed "" "Testing empty string value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_empty_val _dummy_ok _dummy_failed "wrong" "Testing wrong string value: expected empty.") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Testing wrong string value: expected empty."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_empty_val


#******************************************************************************************************************************
# TEST: te_not_empty_val()
#******************************************************************************************************************************
ts_ms___te_not_empty_val() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_not_empty_val()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_not_empty_val _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_not_empty_val()': Requires EXACT '4' argument. Got '2'"

    te_not_empty_val _dummy_ok _dummy_failed "not empty" "Testing not empty string value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_not_empty_val _dummy_ok _dummy_failed "" "Testing wrong string value: expected not empty.") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Testing wrong string value: expected not empty."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_not_empty_val


#******************************************************************************************************************************
# TEST: te_retval_0()
#******************************************************************************************************************************
ts_ms___te_retval_0() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_retval_0()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retval_0 _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_retval_0()': Requires EXACT '4' argument. Got '2'"

    te_retval_0 _dummy_ok _dummy_failed 0 "Testing expected (0) return value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed 1 "Testing FAILED return value (1): expected (0).") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Testing FAILED return value (1): expected (0)."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_retval_0


#******************************************************************************************************************************
# TEST: te_retval_1()
#******************************************************************************************************************************
ts_ms___te_retval_1() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "te_retval_1()"
    declare -i _dummy_ok=0
    declare -i _dummy_failed=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retval_1 _dummy_ok _dummy_failed) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'te_retval_1()': Requires EXACT '4' argument. Got '2'"

    te_retval_1 _dummy_ok _dummy_failed 1 "Testing expected (1) return value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_failed 1 "Testing FAILED return value (0): expected (1).") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Testing FAILED return value (0): expected (1)."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_ms___te_retval_1



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
