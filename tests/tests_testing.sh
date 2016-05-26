#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************
_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="testing.sh"

source "${_FUNCTIONS_DIR}/init_conf.sh"
_BF_ON_ERROR_KILL_PROCESS=0     # Set the sleep seconds before killing all related processes or to less than 1 to skip it

for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
trap 'i_trap_i ${?}' INT
# For testing don't use error traps: as we expect failed tests - otherwise we would need to adjust all
#trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR

# do not use `i_source_safe_exit` in this case because it was not yet testet
source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: te_print_header                                                 SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_print_final_result                                           SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_print_function_msg                                           SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_abort                                                        SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_warn                                                         SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_ms_ok                                                        SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: te_ms_failed                                                    SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: te_find_err_msg()
#******************************************************************************************************************************
tste__te_find_err_msg() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_find_err_msg()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '4' arguments. Got '2'"

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail "" "dummy") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 3 MUST NOT be empty."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail "dummy" "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 4 MUST NOT be empty."

    _output="Other output: Find error message: Test expected to pass. other output"
    te_find_info_msg _COK _CFAIL "${_output}" "Find error message: Test expected to pass."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail "dummy" "Find error message: Test expected to fail.") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Find error message: Test expected to fail."

    # Optional extra info
    _output="Other output: Test expected to pass. Extra Info added. other output"
    te_find_info_msg _COK _CFAIL "${_output}" "Test expected to pass. Extra Info added." "This is some optionl info."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_find_err_msg


#******************************************************************************************************************************
# TEST: te_find_info_msg()
#******************************************************************************************************************************
tste__te_find_info_msg() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_find_info_msg()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '4' arguments. Got '2'"

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_fail "" "dummy") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 3 MUST NOT be empty."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_fail "dummy" "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 4 MUST NOT be empty."

    _output="Other output: Find info message: Test expected to pass. other output"
    te_find_info_msg _COK _CFAIL "${_output}" "Find info message: Test expected to pass."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_info_msg _dummy_ok _dummy_fail "dummy" "Find info message: Test expected to fail.") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Find info message: Test expected to fail."

    # Optional extra info
    _output="Other output: Test expected to pass. Extra Info added. other output"
    te_find_info_msg _COK _CFAIL "${_output}" "Test expected to pass. Extra Info added." "This is some optionl info."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_find_info_msg


#******************************************************************************************************************************
# TEST: te_same_val()
#
# NOTE: a bit trick to test because of the formatted string
#******************************************************************************************************************************
tste__te_same_val() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_same_val()"
    local _off=${_BF_OFF}
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0
    local _to_find

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_same_val _dummy_ok _dummy_fail) 2>&1)
    # NOTE: Use here the previously tested te_find_err_msg
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '4' arguments. Got '2'"

    _ref_val="/home/test"
    _output="Other output: Find error message: Test expected to pass: other output"
    te_same_val _COK _CFAIL "/home/test" "${_ref_val}"

    _output=$((te_same_val _dummy_ok _dummy_fail "/home/wrong" "/home/test" "EXTRA INFO") 2>&1)
    # NOTE: Use here the previously tested te_find_err_msg
    _to_find="${_BF_OFF}Expected value: <${_BF_BOLD}/home/test${_BF_OFF}> Got: <${_BF_BOLD}/home/wrong${_BF_OFF}> EXTRA INFO"
    te_find_err_msg _COK _CFAIL "${_output}" "${_to_find}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_same_val


#******************************************************************************************************************************
# TEST: te_empty_val()
#******************************************************************************************************************************
tste__te_empty_val() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_empty_val()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_empty_val _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '4' arguments. Got '2'"

    te_empty_val _COK _CFAIL "" "Testing empty string value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_empty_val _dummy_ok _dummy_fail "wrong" "Testing wrong string value: expected empty.") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Testing wrong string value: expected empty."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_empty_val


#******************************************************************************************************************************
# TEST: te_not_empty_val()
#******************************************************************************************************************************
tste__te_not_empty_val() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_not_empty_val()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_not_empty_val _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '4' arguments. Got '2'"

    te_not_empty_val _COK _CFAIL "not empty" "Testing not empty string value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_not_empty_val _dummy_ok _dummy_fail "" "Testing wrong string value: expected not empty.") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Testing wrong string value: expected not empty."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_not_empty_val


#******************************************************************************************************************************
# TEST: te_retcode_0()
#******************************************************************************************************************************
tste__te_retcode_0() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_retcode_0()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retcode_0 _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '4' arguments. Got '2'"

    te_retcode_0 _COK _CFAIL 0 "Testing expected (0) return value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail 1 "Testing FAILED return value (1): expected (0).") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Testing FAILED return value (1): expected (0)."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_retcode_0


#******************************************************************************************************************************
# TEST: te_retcode_1()
#******************************************************************************************************************************
tste__te_retcode_1() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_retcode_1()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retcode_1 _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '4' arguments. Got '2'"

    te_retcode_1 _COK _CFAIL 1 "Testing expected (1) return value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_find_err_msg _dummy_ok _dummy_fail 1 "Testing FAILED return value (0): expected (1).") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Testing FAILED return value (0): expected (1)."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_retcode_1


#******************************************************************************************************************************
# TEST: te_retcode_same()
#******************************************************************************************************************************
tste__te_retcode_same() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "te_retcode_same()"
    declare -i _dummy_ok=0
    declare -i _dummy_fail=0

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retcode_same _dummy_ok _dummy_fail) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '5' arguments. Got '2'"

    te_retcode_same _COK _CFAIL 18 18 "Testing expected (18) return value."

    # use the dummy counter to avoid counting the subshell as failed
    _output=$((te_retcode_same _dummy_ok _dummy_fail 2 5 "Testing FAILED return value (2): expected (5).") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Testing FAILED return value (2): expected (5)."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tste__te_retcode_same


#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
