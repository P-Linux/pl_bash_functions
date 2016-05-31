#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************
_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="util.sh"

_BF_EXPORT_ALL="yes"
source "${_FUNCTIONS_DIR}/init_conf.sh"
_BF_ON_ERROR_KILL_PROCESS=0     # Set the sleep seconds before killing all related processes or to less than 1 to skip it

for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
trap 'i_trap_i ${?}' INT
# For testing don't use error traps: as we expect failed tests - otherwise we would need to adjust all
#trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR
trap 'i_trap_exit ${?} "${BASH_COMMAND}"' EXIT

i_source_safe_exit "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

i_source_safe_exit "${_FUNCTIONS_DIR}/util.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: u_is_yes_no_var_exit()
#******************************************************************************************************************************
tsu__u_is_yes_no_var_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_yes_no_var_exit()"
    local _test_var _output

    _output=$((u_is_yes_no_var_exit) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_is_yes_no_var_exit()' Requires AT LEAST '1' argument. Got '0'"

    _test_var=""
    _output=$((u_is_yes_no_var_exit "_test_var") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_test_var' MUST be: 'yes/no'. Got: '' Called From"

    _test_var="wrong"
    _output=$((u_is_yes_no_var_exit "_test_var") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_test_var' MUST be: 'yes/no'. Got: 'wrong' Called From"

    _test_var="yes"
    (u_is_yes_no_var_exit "_test_var")
    te_retcode_0 _COK _CFAIL ${?} "Test Variable yes."

    _test_var="no"
    (u_is_yes_no_var_exit "_test_var")
    te_retcode_0 _COK _CFAIL ${?} "Test Variable no."

    _test_var="false"
    _output=$((u_is_yes_no_var_exit "_test_var" "Some info") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Variable '_test_var' MUST be: 'yes/no'. Got: 'false' Called From: 'tsu__u_is_yes_no_var_exit()' INFO: Some info"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_yes_no_var_exit


#******************************************************************************************************************************
# TEST: u_is_str_var()
#******************************************************************************************************************************
tsu__u_is_str_var() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_str_var()"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    declare -ru zzz_option_ru_assigned_should_be_last="Should be last in declare string"
    declare -tux _option_tux_assigned="dummy example"
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    declare -i _assigned_int=5

    (u_is_str_var "_not_declared") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_not_declared>."

    (u_is_str_var "_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_not_assigned>."

    (u_is_str_var "_assigned_empty") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_assigned_empty>."

    (u_is_str_var "_assigned_none_empty") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_assigned_none_empty>."

    (u_is_str_var "_option_rl_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_option_rl_not_assigned>."

    (u_is_str_var "zzz_option_ru_assigned_should_be_last") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <zzz_option_ru_assigned_should_be_last>."

    (u_is_str_var "_option_tux_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_option_tux_assigned>."

    (u_is_str_var "_options_al_not_assigned_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_options_al_not_assigned_array>."

    (u_is_str_var "_associative_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_associative_array>."

    (u_is_str_var "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_assigned_int>."

    # CLEAN UP
    unset _option_tux_assigned

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_str_var


#******************************************************************************************************************************
# TEST: u_is_empty_str_var()
#******************************************************************************************************************************
tsu__u_is_empty_str_var() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_empty_str_var()"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    declare -ru zzz_option_ru_assigned_should_be_last="Should be last in declare string"
    declare -tux _option_tux_assigned="dummy example"
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    declare -i _assigned_int=5

    (u_is_empty_str_var "_not_declared") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_not_declared>."

    (u_is_empty_str_var "_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_not_assigned>."

    (u_is_empty_str_var "_assigned_empty") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_assigned_empty>."

    (u_is_empty_str_var "_assigned_none_empty") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_assigned_none_empty>."

    (u_is_empty_str_var "_option_rl_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test Variable <_option_rl_not_assigned>."

    (u_is_empty_str_var "zzz_option_ru_assigned_should_be_last") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <zzz_option_ru_assigned_should_be_last>."

    (u_is_empty_str_var "_option_tux_assigned") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_option_tux_assigned>."

    (u_is_empty_str_var "_options_al_not_assigned_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_options_al_not_assigned_array>."

    (u_is_empty_str_var "_associative_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_associative_array>."

    (u_is_empty_str_var "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Variable <_assigned_int>."

    # CLEAN UP
    unset _option_tux_assigned

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_empty_str_var


#******************************************************************************************************************************
# TEST: u_is_str_var_exit()
#******************************************************************************************************************************
tsu__u_is_str_var_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_str_var_exit()"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    declare -i _assigned_int=5
    local _array=(a b)
    local _output

    _output=$((u_is_str_var_exit) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_is_str_var_exit()' Requires AT LEAST '1' argument. Got '0'"

    _output=$((u_is_str_var_exit "not_a_declared__variable") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a declared string variable: 'not_a_declared__variable' Called From"

    (u_is_str_var_exit "_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_not_assigned>."

    (u_is_str_var_exit "_assigned_empty") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_assigned_empty>."

    (u_is_str_var_exit "_assigned_none_empty") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_assigned_none_empty>."

    (u_is_str_var_exit "_option_rl_not_assigned") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_option_rl_not_assigned>."

    (u_is_str_var_exit "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_int>."

    _output=$((u_is_str_var_exit "_array") 2>&1)
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_array>."
    te_find_err_msg _COK _CFAIL "${_output}" "Not a declared string variable: '_array' Called From: 'tsu__u_is_str_var_exit()'"

    _output=$((u_is_str_var_exit "_assigned_int"  "JUST Some INFO") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared string variable: '_assigned_int' Called From: 'tsu__u_is_str_var_exit()' INFO: JUST Some INFO" \
        "Test <_assigned_int> with optional arg"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_str_var_exit


#******************************************************************************************************************************
# TEST: u_is_idx_array_var()
#******************************************************************************************************************************
tsu__u_is_idx_array_var() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_idx_array_var()"
    local _assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array
    declare -ar _readonly_assigned_array=( 1 item)
    declare -arl _options_arl_assigned_array=( 1 "Item1")
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5

    (u_is_idx_array_var "_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_assigned_array>."

    (u_is_idx_array_var "_not_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_not_assigned_array>."

    (u_is_idx_array_var "_readonly_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_readonly_assigned_array>."

    (u_is_idx_array_var "_options_arl_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_options_arl_assigned_array>."

    (u_is_idx_array_var "_options_al_not_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_options_al_not_assigned_array>."

    (u_is_idx_array_var "_associative_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_associative_array>."

    (u_is_idx_array_var "_assigned_string") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_string>."

    (u_is_idx_array_var "_not_assigned_anything") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_not_assigned_anything>."

    (u_is_idx_array_var "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_int>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_idx_array_var


#******************************************************************************************************************************
# TEST: u_is_idx_array_exit()
#******************************************************************************************************************************
tsu__u_is_idx_array_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_idx_array_exit()"
    local _assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array

    declare -A _associative_array=(["key1"]="Item")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5
    local _output

    _output=$((u_is_idx_array_exit "_assigned_int" "JUST Some INFO") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared index array variable: '_assigned_int' Called From: 'tsu__u_is_idx_array_exit()' INFO: JUST Some INFO"

    _output=$((u_is_idx_array_exit) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_is_idx_array_exit()' Requires AT LEAST '1' argument. Got '0'"

    _output=$((u_is_idx_array_exit "_not_assigned_anything") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a declared index array variable: '_not_assigned_anything'"

    _output=$((u_is_idx_array_exit "_assigned_int") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a declared index array variable: '_assigned_int'"

    _output=$((u_is_idx_array_exit "no_variable") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a declared index array variable: 'no_variable'"

    (u_is_idx_array_exit "_assigned_array")
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_assigned_array>."

    (u_is_idx_array_exit "_not_assigned_array")
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_not_assigned_array>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_idx_array_exit


#******************************************************************************************************************************
# TEST: u_is_associative_array_var()
#******************************************************************************************************************************
tsu__u_is_associative_array_var() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_associative_array_var()"
    declare -A _assigned_array=(["a"]="a" ["VALID ITEM2"]="VALID ITEM2" ["e f"]="e f" ["3"]=3 ["VALID ITEM"]="VALID ITEM")
    declare -A _not_assigned_array
    declare -A -r _readonly_assigned_array=(["1"]=1 ["item"]=item)
    declare -A -rl _options_arl_assigned_array=(["1"]=1 ["Item1"]=Item1)
    declare -Al _options_al_not_assigned_array

    local _index_array=(a b "c")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5

    (u_is_associative_array_var "_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_assigned_array>."

    (u_is_associative_array_var "_not_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_not_assigned_array>."

    (u_is_associative_array_var "_readonly_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_readonly_assigned_array>."

    (u_is_associative_array_var "_options_arl_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_options_arl_assigned_array>."

    (u_is_associative_array_var "_options_al_not_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_options_al_not_assigned_array>."

    (u_is_associative_array_var "_index_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_index_array>."

    (u_is_associative_array_var "_assigned_string") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_string>."

    (u_is_associative_array_var "_not_assigned_anything") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_not_assigned_anything>."

    (u_is_associative_array_var "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_int>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_associative_array_var


#******************************************************************************************************************************
# TEST: u_ref_associative_array_exit()
#******************************************************************************************************************************
tsu__u_ref_associative_array_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_ref_associative_array_exit()"
    declare -A _assigned_array=(["a"]="a" ["VALID ITEM2"]="VALID ITEM2" ["e f"]="e f" ["3"]=3 ["VALID ITEM"]="VALID ITEM")
    declare -A _not_assigned_array
    declare -A -r _readonly_assigned_array=(["1"]=1 ["item"]=item)
    declare -A -rl _options_arl_assigned_array=(["1"]=1 ["Item1"]=Item1)

    declare -n _ref_assigned_array=_assigned_array
    declare -n _ref_not_assigned_array=_not_assigned_array
    declare -n _ref_readonly_assigned_array=_readonly_assigned_array
    declare -n _ref_options_arl_assigned_array=_options_arl_assigned_array

    local _index_array=(a b "c")
    declare -i _assigned_int=5

    declare -n _ref_not_assigned_to_nothing
    declare -n _ref_index_array=_index_array
    declare -A _empty_array=()
    declare -nr _ref__empty_array_set_ref_to_readonly=_empty_array
    declare _output

    _output=$((u_ref_associative_array_exit) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Requires AT LEAST '1' argument. Got '0'"

    _output=$((u_ref_associative_array_exit "_ref_index_array") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a referenced associative array: '_ref_index_array' Called From"

    (u_ref_associative_array_exit "_ref_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_ref_assigned_array>."

    (u_ref_associative_array_exit "_ref_not_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_ref_not_assigned_array>."

    (u_ref_associative_array_exit "_ref_readonly_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_ref_readonly_assigned_array>."

    (u_ref_associative_array_exit "_ref_options_arl_assigned_array") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_ref_options_arl_assigned_array>."

    (u_ref_associative_array_exit "_ref_not_assigned_to_nothing") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_ref_not_assigned_to_nothing>."

    (u_ref_associative_array_exit "_ref_index_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_ref_index_array>."

    (u_ref_associative_array_exit "_index_array") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_index_array>."

    (u_ref_associative_array_exit "_assigned_int") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test variable <_assigned_int>."

    (u_ref_associative_array_exit "_ref__empty_array_set_ref_to_readonly") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test variable <_ref__empty_array_set_ref_to_readonly>."

    _output=$((u_ref_associative_array_exit "_ref_index_array" "Info") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a referenced associative array: '_ref_index_array' Called From: 'tsu__u_ref_associative_array_exit()' INFO: Info"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_ref_associative_array_exit


#******************************************************************************************************************************
# TEST: u_count_substr()
#******************************************************************************************************************************
tsu__u_count_substr() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_count_substr()"
    local _input="text::text::|text::text"

    te_same_val _COK _CFAIL  "$(u_count_substr "::" "${_input}")" "3" "Test substr: :: INPUT: <${_input}>"

    te_same_val _COK _CFAIL "$(u_count_substr "|" "${_input}")" "1" "Test substr: | INPUT: <${_input}>"

    te_same_val _COK _CFAIL "$(u_count_substr "X" "${_input}")" "0" "Test substr: X INPUT: <${_input}>"

    te_same_val _COK _CFAIL "$(u_count_substr "|" "")" "0" "Test substr: | EMPTY INPUT: <>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_count_substr


#******************************************************************************************************************************
# TEST: u_strip_end_slahes()
#******************************************************************************************************************************
tsu__u_strip_end_slahes() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_strip_end_slahes()"
    local _input_no_trailing_slash_extension="/home/testfile.txt"
    local _input_no_trailing_slash="/home/testdir"
    local _input_one_trailing_slash="/home/testdir/"
    local _input_multiple_trailing_slashes="/home/testdir///"
    local _input_no_slashes="home_test_dir"
    local _result

    u_strip_end_slahes _result "${_input_no_trailing_slash_extension}"
    te_same_val _COK _CFAIL "${_result}" "/home/testfile.txt" "Test INPUT: <${_input_no_trailing_slash_extension}>"

    u_strip_end_slahes _result "${_input_no_trailing_slash}"
    te_same_val _COK _CFAIL "${_result}" "/home/testdir" "Test INPUT: <${_input_no_trailing_slash}>"

    u_strip_end_slahes _result "${_input_one_trailing_slash}"
    te_same_val _COK _CFAIL "${_result}" "/home/testdir" "Test INPUT: <${_input_one_trailing_slash}>"

    u_strip_end_slahes _result "${_input_multiple_trailing_slashes}"
    te_same_val _COK _CFAIL "${_result}" "/home/testdir" "Test INPUT: <${_input_multiple_trailing_slashes}>"

    u_strip_end_slahes _result "${_input_no_slashes}"
    te_same_val _COK _CFAIL "${_result}" "home_test_dir" "Test INPUT: <${_input_no_slashes}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_strip_end_slahes



#******************************************************************************************************************************
# TEST: u_strip_whitespace()
#******************************************************************************************************************************
tsu__u_strip_whitespace() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_strip_whitespace()"
    local _input_no_whitespace="Just a dummy text"
    local _input_leading_whitespace="       Just a dummy text"
    local _input_trailing_whitespace="Just a dummy text       "
    local _input_leading_trailing_whitespace="     Just a dummy text      "
    local _result

    u_strip_whitespace _result "${_input_no_whitespace}"
    te_same_val _COK _CFAIL "${_result}" "Just a dummy text" "Test INPUT: <${_input_no_whitespace}>"

    u_strip_whitespace _result "${_input_leading_whitespace}"
    te_same_val _COK _CFAIL "${_result}" "Just a dummy text" "Test INPUT: <${_input_leading_whitespace}>"

    u_strip_whitespace _result "${_input_trailing_whitespace}"
    te_same_val _COK _CFAIL "${_result}" "Just a dummy text" "Test INPUT: <${_input_trailing_whitespace}>"

    u_strip_whitespace _result "${_input_leading_trailing_whitespace}"
    te_same_val _COK _CFAIL "${_result}" "Just a dummy text" "Test INPUT: <${_input_leading_trailing_whitespace}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_strip_whitespace


#******************************************************************************************************************************
# TEST: u_prefix_shortest_empty()
#******************************************************************************************************************************
tsu__u_prefix_shortest_empty() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_prefix_shortest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_prefix_shortest_empty _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "NOEXTRACT" "Test INPUT: <${_entry}>"

    u_prefix_shortest_empty _result "${_entry_no_delim}" "::"
    te_empty_val _COK _CFAIL "${_result}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_prefix_shortest_empty


#******************************************************************************************************************************
# TEST: u_prefix_longest_empty()
#******************************************************************************************************************************
tsu__u_prefix_longest_empty() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_prefix_longest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_prefix_longest_empty _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "NOEXTRACT::helper_scripts" "Test INPUT: <${_entry}>"

    u_prefix_longest_empty _result "${_entry_no_delim}" "::"
    te_empty_val _COK _CFAIL "${_result}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_prefix_longest_empty


#******************************************************************************************************************************
# TEST: u_prefix_shortest_all()
#******************************************************************************************************************************
tsu__u_prefix_shortest_all() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_prefix_shortest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_prefix_shortest_all _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "NOEXTRACT" "Test INPUT: <${_entry}>"

    u_prefix_shortest_all _result "${_entry_no_delim}" "::"
    te_same_val _COK _CFAIL "${_result}" "${_entry_no_delim}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_prefix_shortest_all


#******************************************************************************************************************************
# TEST: u_prefix_longest_all()
#******************************************************************************************************************************
tsu__u_prefix_longest_all() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_prefix_longest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_prefix_longest_all _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "NOEXTRACT::helper_scripts" "Test INPUT: <${_entry}>"

    u_prefix_longest_all _result "${_entry_no_delim}" "::"
    te_same_val _COK _CFAIL "${_result}" "${_entry_no_delim}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_prefix_longest_all


#******************************************************************************************************************************
# TEST: u_postfix_shortest_empty()
#******************************************************************************************************************************
tsu__u_postfix_shortest_empty() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_postfix_shortest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_postfix_shortest_empty _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}"  "https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" \
        "Test INPUT: <${_entry}>"

    u_postfix_shortest_empty _result "${_entry_no_delim}" "::"
    te_empty_val _COK _CFAIL "${_result}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_postfix_shortest_empty


#******************************************************************************************************************************
# TEST: u_postfix_longest_empty()
#******************************************************************************************************************************
tsu__u_postfix_longest_empty() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_postfix_longest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_postfix_longest_empty _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" \
        "Test INPUT: <${_entry}>"

    u_postfix_longest_empty _result "${_entry_no_delim}" "::"
    te_empty_val _COK _CFAIL "${_result}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_postfix_longest_empty


#******************************************************************************************************************************
# TEST: u_postfix_shortest_all()
#******************************************************************************************************************************
tsu__u_postfix_shortest_all() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_postfix_shortest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_postfix_shortest_all _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" \
        "Test INPUT: <${_entry}>"

    u_postfix_shortest_all _result "${_entry_no_delim}" "::"
    te_same_val _COK _CFAIL "${_result}" "${_entry_no_delim}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_postfix_shortest_all


#******************************************************************************************************************************
# TEST: u_postfix_longest_all()
#******************************************************************************************************************************
tsu__u_postfix_longest_all() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_postfix_longest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    u_postfix_longest_all _result "${_entry}" "::"
    te_same_val _COK _CFAIL "${_result}" "helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" \
        "Test INPUT: <${_entry}>"

    u_postfix_longest_all _result "${_entry_no_delim}" "::"
    te_same_val _COK _CFAIL "${_result}" "${_entry_no_delim}" "Test No Delimiter INPUT: <${_entry_no_delim}>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_postfix_longest_all


#******************************************************************************************************************************
# TEST: u_get_cmd_arg_values_array()
#******************************************************************************************************************************
tsu__u_get_cmd_arg_values_array() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_get_cmd_arg_values_array()"
    local _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
    local _array_with_long_option=(-v --version -i --install --config-file /home/long_option/cmk.conf -h --help)
    local _array_with_short_option_no_value=(-v --version -i --install -cf)
    local _array_with_short_option_empty_value=(-v --version -i --install -cf "" -h --help)
    local _array_with_long_option_wrong_startchar=(-v --version -i --install --config-file -/home/long_option/cmk.conf -h)
    local _array_with_short_3_values=(-v --version -i --install -cf value1 value2 value3 -h --help)
    local _array_with_long_3_values_at_end=(-v --version -i --install --config-file value1 value2 value3)
    local _output _tmp_str
    declare -a _result
    declare -i _n

    _result=()
    _output=$((u_get_cmd_arg_values_array _result) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: 'u_get_cmd_arg_values_array()' Requires AT LEAST '3' arguments. Got '1'"

    _result=()
    _output=$((u_get_cmd_arg_values_array _result "" _array_with_short_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: u_get_cmd_arg_values_array()' Argument '2' MUST be as integer declared and greater than '-1'."

    _result=()
    _n=4
    _output=$((u_get_cmd_arg_values_array _result _n _array_with_long_option_wrong_startchar) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '--config-file' value: '-/home/long_option/cmk.conf' MUST NOT start with a hyphen-minus" \
        "Test INPUT: <_array_with_long_option_wrong_startchar>"

    _result=()
    _n=4
    _output=$((u_get_cmd_arg_values_array _result _n _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-cf' requires an value. All Arguments: <-v --v" \
        "Test INPUT: <_array_with_short_option_no_value>."

    _result=()
    _n=4
    _output=$((u_get_cmd_arg_values_array _result _n _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-cf' value: '' MUST NOT be empty: All Argument" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    _result=()
    _n=4
    _output=$((u_get_cmd_arg_values_array _result _n _array_with_short_3_values 0) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Argument '_max_exp_val' MUST NOT be 0" \
        "Test Argument _max_exp_val MUST NOT be 0"

    _result=()
    _n=4
    _output=$((u_get_cmd_arg_values_array _result _n _array_with_long_3_values_at_end 2) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "option: '--config-file' maximum expected values: '2'. Found '3'"

    _result=()
    _n=4
    u_get_cmd_arg_values_array _result _n _array_with_short_option
    te_same_val _COK _CFAIL "${_result[@]}" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    _result=()
    _n=4
    u_get_cmd_arg_values_array _result _n _array_with_long_option
    te_same_val _COK _CFAIL "${_result[@]}" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    _result=()
    _n=4
    u_get_cmd_arg_values_array _result _n _array_with_short_3_values 3
    # Need to convert it first to a string
    _tmp_str=${_result[@]}
    te_same_val _COK _CFAIL "${_tmp_str}" "value1 value2 value3" \
        "Test maximum expected values: 3. Found 3. INPUT: <_array_with_short_3_values>"

    _result=()
    _n=4
    u_get_cmd_arg_values_array _result _n _array_with_long_3_values_at_end 5
    _tmp_str=${_result[@]}
    te_same_val _COK _CFAIL "${_tmp_str}" "value1 value2 value3" \
        "Test maximum expected values: 5. Found 3. INPUT: <_array_with_long_3_values_at_end>"
    te_same_val _COK _CFAIL "${_n}" "7" "Test index value was incremented. Found 3. INPUT: <_array_with_long_3_values_at_end>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_get_cmd_arg_values_array


#******************************************************************************************************************************
# TEST: u_get_cmd_arg_single_value_string()
#******************************************************************************************************************************
tsu__u_get_cmd_arg_single_value_string() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_get_cmd_arg_single_value_string()"
    local _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
    local _array_with_long_option=(-v --version -i --install --config-file /home/long_option/cmk.conf -h --help)
    local _array_with_short_option_no_value=(-v --version -i --install -cf)
    local _array_with_short_option_empty_value=(-v --version -i --install -cf "" -h --help)
    local _array_with_long_option_in_middle_no_value=(-v --version -i --install --config-file -h --help)
    local _output _result

    _output=$((u_get_cmd_arg_single_value_string _result 4 _array_with_short_option "wrong") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "4. VARIBLE: '_exit_if_no_val' MUST be set to: 'yes/no'. Got: 'wrong'"

    u_get_cmd_arg_single_value_string _result 4 _array_with_short_option
    te_same_val _COK _CFAIL "${_result}" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    u_get_cmd_arg_single_value_string _result 4 _array_with_long_option
    te_same_val _COK _CFAIL "${_result}" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    _output=$((u_get_cmd_arg_single_value_string _result 4 _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Cmd option: '-cf' requires an value. All Arguments" \
        "Test INPUT: <_array_with_short_option_no_value>."

    _output=$((u_get_cmd_arg_single_value_string _result 4 _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-cf' argument value MUST NOT be empty: All Arg" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    _output=$((u_get_cmd_arg_single_value_string _result 4 _array_with_long_option_in_middle_no_value "yes") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '--config-file' requires an value. All Argument" \
        "Test _abort_if_no_value=yes: <_array_with_long_option_in_middle_no_value>. "

    u_get_cmd_arg_single_value_string _result 4 _array_with_long_option_in_middle_no_value "no"
    te_empty_val _COK _CFAIL "${_result}" \
        "Test _abort_if_no_value=no: <_array_with_long_option_in_middle_no_value>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_get_cmd_arg_single_value_string


#******************************************************************************************************************************
# TEST: u_search_cmd_arg_values_string()
#******************************************************************************************************************************
tsu__u_search_cmd_arg_values_string() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_search_cmd_arg_values_string()"
    local _array_without_search_option=(-v --version -i --install -h --help)
    local _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
    local _array_with_long_option=(-v --version -i --install --config-file /home/long_option/cmk.conf -h --help)
    local _array_with_short_option_no_value=(-v --version -i --install -cf)
    local _array_with_short_option_empty_value=(-v --version -i --install -cf "" -h --help)
    local _array_with_long_option_wrong_startchar=(-v --version -i --install --config-file -/home/long_option/cmk.conf -h)
    local _array_with_short_3_values=(-v --version -i --install -cf value1 value2 value3 -h --help)
    local _array_with_long_3_values_at_end=(-v --version -i --install --config-file value1 value2 value3)
    local _array_empty=()
    local _output _result

    _output=$((u_search_cmd_arg_values_string _result "" "" _array_without_search_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "WRONG CODE: Argument 1: '' Argument 2: ''. Only one MAY be empty." \
        "Test Both option to check are empty. <_array_without_search_option>."

    _output=$((u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_long_option_wrong_startchar) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-"*"'-/home/long_option/cmk.conf' MUST NOT start with a hyphen-minus" \
        "Test INPUT: <_array_with_long_option_wrong_startchar>."

    _output=$((u_search_cmd_arg_values_string _result "-" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Short option to check: '-' MUST be at least 2 character long or empty."

    _output=$((u_search_cmd_arg_values_string _result "+c" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Short option to check: '+c' MUST start with EXACT ONE hyphen-minus."

    _output=$((u_search_cmd_arg_values_string _result "--d" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Short option to check: '--d' MUST start with EXACT ONE hyphen-minus."

    _output=$((u_search_cmd_arg_values_string _result "-cf" "-" _array_with_long_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Long option to check: '-' MUST be at least 3 character long or empty."

    _output=$((u_search_cmd_arg_values_string _result "-cf" "+config-file" _array_with_long_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Long option to check: '+config-file' MUST start with EXACT TWO hyphen-minus."

    _output=$((u_search_cmd_arg_values_string _result "-cf" "---d" _array_with_long_option) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Long option to check: '---d' MUST start with EXACT TWO hyphen-minus."

    _output=$(u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_without_search_option)
    te_empty_val _COK _CFAIL "${_output}" "Test INPUT: <_array_without_search_option> Check info message."

    u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_short_option
    te_same_val _COK _CFAIL "${_result}" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_long_option
    te_same_val _COK _CFAIL "${_result}" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    u_search_cmd_arg_values_string _result "" "--config-file" _array_without_search_option
    te_empty_val _COK _CFAIL "${_result}" "Test Short option empty. INPUT: <_array_without_search_option>"

    u_search_cmd_arg_values_string _result "-cf" "" _array_without_search_option
    te_empty_val _COK _CFAIL "${_result}" "Test Long option empty. INPUT: <_array_without_search_option>"

    _output=$((u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-cf' requires at least 1 value. All ARGS: <-v --version -i --install" \
        "Test INPUT: <_array_with_short_option_no_value>"

    _output=$((u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '-cf' value: '' MUST NOT be empty: All Arguments: <-v --version -i --i" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    u_search_cmd_arg_values_string _result "-v" "--version" _array_empty 1
    te_empty_val _COK _CFAIL "${_result}" "Test INPUT: <_array_empty>."

    _output=$((u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_short_3_values 0) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Argument '_max_exp_val' MUST NOT be 0"

    _output=$((u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_long_3_values_at_end 2) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Cmd option: '--config-file' maximum expected values: '2'. Found '3' All ARGS: <-v" \
        "Test maximum expected values: 2"

    u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_short_3_values 3
    te_same_val _COK _CFAIL "${_result}" "value1 value2 value3" \
        "Test maximum expected values: 3.  Found 3. INPUT: <_array_with_short_3_values>"

    u_search_cmd_arg_values_string _result "-cf" "--config-file" _array_with_long_3_values_at_end 5
    te_same_val _COK _CFAIL "${_result}" "value1 value2 value3" \
        "Test maximum expected values: 5.  Found 3. INPUT: <_array_with_long_3_values_at_end>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_search_cmd_arg_values_string


#******************************************************************************************************************************
# TEST: u_basename()
#******************************************************************************************************************************
tsu__u_basename() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "tsu__u_basename()"
    local _output _result

    u_basename _result "/home/test_dir//"
    te_same_val _COK _CFAIL "${_result}" "test_dir" "Test </home/test_dir//>"

    u_basename _result "home"
    te_same_val _COK _CFAIL "${_result}" "home"

    u_basename _result ""
    te_empty_val _COK _CFAIL "${_result}" "Test empty INPUT: <>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_basename


#******************************************************************************************************************************
# TEST: u_dirname()
#******************************************************************************************************************************
tsu__u_dirname() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_dirname()"
    local _output _result

    u_dirname _result "/home/test/Pkgfile.txt"
    te_same_val _COK _CFAIL "${_result}" "/home/test" "Test </home/test/Pkgfile.txt>"

    u_dirname _result "/home////"
    te_same_val _COK _CFAIL "${_result}" "/" "Test </home////>"

    u_dirname _result "home/test/Pkgfile.txt"
    te_same_val _COK _CFAIL "${_result}" "home/test" "Test <home/test/Pkgfile.txt>"

    u_dirname _result "Pkgfile.txt"
    te_same_val _COK _CFAIL "${_result}" "." "Test <Pkgfile.txt>"

    u_dirname _result ""
    te_same_val _COK _CFAIL "${_result}" "." "Test empty input <>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_dirname


#******************************************************************************************************************************
# TEST: u_is_abspath()
#******************************************************************************************************************************
tsu__u_is_abspath() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_abspath()"

    (u_is_abspath "test/Pkgfile")
    te_retcode_1 _COK _CFAIL ${?} "Test relative path <test/Pkgfile>."

    (u_is_abspath "")
    te_retcode_1 _COK _CFAIL ${?} "Test empty path <>."

    (u_is_abspath "/home/Pkgfile")
    te_retcode_0 _COK _CFAIL ${?} "Test absolute path </home/Pkgfile>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_abspath


#******************************************************************************************************************************
# TEST: u_is_abspath_exit()
#******************************************************************************************************************************
tsu__u_is_abspath_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_abspath_exit()"
    local _output

    _output=$((u_is_abspath_exit "test/Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Path MUST be an absolute path and MUST start with a slash: <test/Pkgfile>" "Test relative path <test/Pkgfile>"

    _output=$((u_is_abspath_exit "" "TEST_PATH") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "TEST_PATH MUST be an absolute path and MUST start with a slash: <>" \
        "Test empty path <>"

    (u_is_abspath_exit "/home/Pkgfile")
    te_retcode_0 _COK _CFAIL ${?} "Test absolute path </home/Pkgfile>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_abspath_exit


#******************************************************************************************************************************
# TEST: u_dir_has_content_exit()
#******************************************************************************************************************************
tsu__u_dir_has_content_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_dir_has_content_exit()"
    local _tmp_dir_empty=$(mktemp -d)
    local _tmp_dir_with_dir=$(mktemp -d)
    local _tmp_dir_with_file=$(mktemp -d)
    local _tmp_dir_with_link=$(mktemp -d)
    local _tmp_dir_with_hiddenfile=$(mktemp -d)
    local _tmp_dummy_file=$(mktemp)
    local _none_existing_dir=${_tmp_dir_empty}/_none_existing_dir

    mkdir "${_tmp_dir_with_dir}/subfolder"
    touch "${_tmp_dir_with_file}/simple_file.txt"
    touch "${_tmp_dir_with_hiddenfile}/.hidden.txt"
    ln -s "${_tmp_dummy_file}" "${_tmp_dir_with_link}/_dummy_file_link"

    (u_dir_has_content_exit "${_tmp_dir_empty}")
    te_retcode_1 _COK _CFAIL ${?} "Test has no content <_tmp_dir_empty>."

    (u_dir_has_content_exit "${_tmp_dir_with_dir}")
    te_retcode_0 _COK _CFAIL ${?} "Test has content <_tmp_dir_with_dir>."

    if u_dir_has_content_exit "${_none_existing_dir}"; then
        te_ms_failed _CFAIL "Common usage example: Test has no content <_none_existing_dir>"
    else
        te_ms_ok _COK "Common usage example: Test has no content <_none_existing_dir>"
    fi

    (u_dir_has_content_exit "${_tmp_dir_with_file}")
    te_retcode_0 _COK _CFAIL ${?} "Test has content <_tmp_dir_with_file>."

    (u_dir_has_content_exit "${_tmp_dir_with_hiddenfile}")
    te_retcode_0 _COK _CFAIL ${?} "Test has hidden content <_tmp_dir_with_hiddenfile>."

    (u_dir_has_content_exit "${_tmp_dir_with_link}")
    te_retcode_0 _COK _CFAIL ${?} "Test has content <_tmp_dir_with_link>."


    # CLEAN UP
    rm -rf "${_tmp_dir_empty}"
    rm -rf "${_tmp_dir_with_dir}"
    rm -rf "${_tmp_dir_with_file}"
    rm -rf "${_tmp_dir_with_link}"
    rm -rf "${_tmp_dir_with_hiddenfile}"
    rm -f "${_tmp_dummy_file}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_dir_has_content_exit


#******************************************************************************************************************************
# TEST: u_cd_safe_exit()
#******************************************************************************************************************************
tsu__u_cd_safe_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_cd_safe_exitt()"
    local _tmp_dir=$(mktemp -d)
    local _output

    _output=$((u_cd_safe_exit "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_cd_safe_exit()' Argument '1' MUST NOT be empty."

    ((u_cd_safe_exit "${_tmp_dir}") &> /dev/null)
    te_retcode_0 _COK _CFAIL ${?} "Test CD to existing dir."
    cd "${_TEST_SCRIPT_DIR}"     # Get back

    ((u_cd_safe_exit "${_script_dir}/NONE_EXISTING_DIR") &> /dev/null)
    te_retcode_1 _COK _CFAIL ${?} "Test CD to NONE existing dir."
    cd "${_TEST_SCRIPT_DIR}"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_cd_safe_exit


#******************************************************************************************************************************
# TEST: u_dir_is_rwx_exit                                               SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: u_file_is_r_exit                                                SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: u_file_is_rw_exit                                               SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: ut_utc_date                                                     SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: u_get_unix_timestamp                                            SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: u_is_integer_greater()
#******************************************************************************************************************************
tsu__u_is_integer_greater() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_integer_greater()"

    (u_is_integer_greater 266)
    te_retcode_0 _COK _CFAIL ${?} "Test INPUT: <u_is_integer_greater 266>  NOTE: Default CHECK VALUE is: 0."

    (u_is_integer_greater 266 500)
    te_retcode_1 _COK _CFAIL ${?} "Test INPUT: <u_is_integer_greater 266 500>."

    (u_is_integer_greater -1 -15)
    te_retcode_0 _COK _CFAIL ${?} "Test INPUT: <u_is_integer_greater -1 -15>."

    (u_is_integer_greater -199 -89)
    te_retcode_1 _COK _CFAIL ${?} "Test INPUT: <u_is_integer_greater -199 -89>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_integer_greater


#******************************************************************************************************************************
# TEST: u_repeat_failed_command()
#******************************************************************************************************************************
tsu__u_repeat_failed_command() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_repeat_failed_command()"
    local _output _command
    declare -i _ret

    _output=$((u_repeat_failed_command _ret) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: 'u_repeat_failed_command()' Requires AT LEAST '4' arguments. Got '1'"

    _output=$((u_repeat_failed_command _ret 0 1 true) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'_max_tries': must be greater than 0. Got: '0'" \
        "Test INPUT: <u_repeat_failed_command _ret 0 1 true>"

    _output=$((u_repeat_failed_command _ret 1 -1 true) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'_delay_sec': must be greater than -1. Got: '-1'" \
        "Test INPUT: <u_repeat_failed_command _ret 1 -1 true> _DELAY_SEC: must be greater than -1."

    _output=$((u_repeat_failed_command _ret 1 1 true) 2>&1)
    te_retcode_0 _COK _CFAIL ${?} \
        "Test INPUT: <u_repeat_failed_command 1 1 true>. Return code should always be 0 for this function"
    te_empty_val _COK _CFAIL "${_output}" "Test INPUT: <u_repeat_failed_command _ret 1 1 true> Check no warn message."

    _output=$((u_repeat_failed_command _ret 2 1 false) 2>&1)
    te_retcode_0 _COK _CFAIL ${?} \
        "Test INPUT: <u_repeat_failed_command _ret 2 1 false>. Return code should always be 0 for this function"
    te_find_info_msg _COK _CFAIL "${_output}" "WARNING: Command failed: '2' times" \
        "Test INPUT: <u_repeat_failed_command 2 1 false> Find failed: 2 times WARNING message."

    (
        _ret=-1
        u_repeat_failed_command _ret 2 1 false &> /dev/null
        te_same_val _COK _CFAIL  "${_ret}" "1" \
            "Test actual comman status code: _ret INPUT: <u_repeat_failed_command _ret 2 1 false>."

        _ret=-1
        _command="wget"
        [[ $(type -p "${_command}") ]] || te_warn "${FUNCNAME[0]}" "Command '%s' is REQUIRED for this test." "${_command}"
        u_repeat_failed_command _ret 2 1 ${_command} "wrong_uri" &> /dev/null
        te_same_val _COK _CFAIL  "${_ret}" "4" \
            "Test actual comman status code: _ret INPUT: <u_repeat_failed_command _ret 2 1 false>."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"

    ####
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_repeat_failed_command


#******************************************************************************************************************************
# TEST: u_in_array()
#******************************************************************************************************************************
tsu__u_in_array() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_in_array()"
    local _test_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    local _output

    _output=$((u_in_array _test_array) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_in_array()' Requires EXACT '2' arguments. Got '1'"

    (u_in_array "NOT VALID ITEM" _test_array) &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test NOT VALID item in array."

    (u_in_array "VALID ITEM2" _test_array) &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test VALID ITEM2 item in array."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_in_array


#******************************************************************************************************************************
# TEST: u_got_function()
#******************************************************************************************************************************
tsu__u_got_function() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_got_function()"

    _valid_function() {
        _a="DUMMY"
    }

    (u_got_function "_valid_function")
    te_retcode_0 _COK _CFAIL ${?} "Test Find <_valid_function>."

    (u_got_function "_not_valid_function") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test Find <_not_valid_function>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_got_function


#******************************************************************************************************************************
# TEST: u_get_file_md5sum()
#******************************************************************************************************************************
tsu__u_get_file_md5sum() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_get_file_md5sum()"
    local _orig_chksum="251aadc2351abf85b3dbfe7261f06218"
    local _text_file="$(dirname _THIS_SCRIPT_PATH)/files/md5sum_testfile.txt"
    local _none_existing_file="$(dirname _THIS_SCRIPT_PATH)/none_existing_file_path.no"
    local _chksum

    u_get_file_md5sum _chksum "${_text_file}"
    te_same_val _COK _CFAIL "${_chksum}" "${_orig_chksum}"

    u_get_file_md5sum _chksum "${_none_existing_file}"
    te_empty_val _COK _CFAIL "${_chksum}" "Test chksum none existing file path. Expected empty.'"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_get_file_md5sum


#******************************************************************************************************************************
# TEST: u_get_file_md5sum_exit()
#******************************************************************************************************************************
tsu__u_get_file_md5sum_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_get_file_md5sum_exit()"
    local _orig_chksum="251aadc2351abf85b3dbfe7261f06218"
    local _text_file="$(dirname _THIS_SCRIPT_PATH)/files/md5sum_testfile.txt"
    local _none_existing_file="$(dirname _THIS_SCRIPT_PATH)/none_existing_file_path.no"
    local _chksum _output

    u_get_file_md5sum_exit _chksum "${_text_file}"
    te_same_val _COK _CFAIL "${_chksum}" "${_orig_chksum}"

    _output=$((u_get_file_md5sum_exit _chksum "${_none_existing_file}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a readable file path: <./none_existing_file_path.no>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_get_file_md5sum_exit


#******************************************************************************************************************************
# TEST: u_no_command_exit()
#******************************************************************************************************************************
tsu__u_no_command_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_no_command_exit()"
    local _output

    _output=$((u_no_command_exit) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'u_no_command_exit()' Requires EXACT '1' argument. Got '0'"

    _output=$((u_no_command_exit "missing_command") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Missing command: 'missing_command'" "Test got command <missing_command>."

    (u_no_command_exit "bash")
    te_retcode_0 _COK _CFAIL ${?} "Test got command <bash>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_no_command_exit


#******************************************************************************************************************************
# TEST: u_got_internet()
#******************************************************************************************************************************
tsu__u_got_internet() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_got_internet()"
    local _output
    declare -i _ret

    _output=$((u_got_internet) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_retcode_0 _COK _CFAIL ${_ret} "Test got internet."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_got_internet


#******************************************************************************************************************************
# TEST: u_is_git_uri_accessible()
#******************************************************************************************************************************
tsu__u_is_git_uri_accessible() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_git_uri_accessible()"
    local _git_uri="https://github.com/P-Linux/pl_bash_functions.git"
    local _git_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri.git"
    local _output
    declare -i _ret

    _output=$((u_is_git_uri_accessible "${_git_uri}") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_retcode_0 _COK _CFAIL ${_ret} "Test got internet."

    _output=$((u_is_git_uri_accessible "${_git_wrong_uri}") 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" "Couldn't verify that the git uri is accessible:" "Test wrong git uri."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_git_uri_accessible


#******************************************************************************************************************************
# TEST: u_is_svn_uri_accessible()
#******************************************************************************************************************************
tsu__u_is_svn_uri_accessible() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_svn_uri_accessible()"
    local _svn_uri="https://svn.code.sf.net/p/portmedia/code/portsmf/trunk"
    local _svn_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri"
    local _output
    declare -i _ret

    _output=$((u_is_svn_uri_accessible "${_svn_uri}") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_retcode_0 _COK _CFAIL ${_ret} "Test got internet."

    _output=$((u_is_svn_uri_accessible "${_svn_wrong_uri}") 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" "Couldn't verify that the svn uri is accessible:" "Test wrong git uri."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_svn_uri_accessible


#******************************************************************************************************************************
# TEST: u_is_hg_uri_accessible()
#******************************************************************************************************************************
tsu__u_is_hg_uri_accessible() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_is_hg_uri_accessible()"
    local _hg_uri="https://bitbucket.org/bos/hg-tutorial-hello"
    local _hg_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri"
    local _output
    declare -i _ret

    _output=$((u_is_hg_uri_accessible "${_hg_uri}") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_retcode_0 _COK _CFAIL ${_ret} "Test got internet."

    _output=$((u_is_hg_uri_accessible "${_hg_wrong_uri}") 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${FUNCNAME[0]}" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" "Couldn't verify that the hg uri is accessible:" "Test wrong git uri."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsu__u_is_hg_uri_accessible


#******************************************************************************************************************************
# TEST: u_export()
#******************************************************************************************************************************
tsi__u_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "u_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((u_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((u_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        u_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx u_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx u_export'."

        _BF_EXPORT_ALL="no"
        u_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f u_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f u_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__u_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 202
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
