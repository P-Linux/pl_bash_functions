#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "$_THIS_SCRIPT_PATH")

source "${_TEST_SCRIPT_DIR}/../trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"$_signal\"" "$_signal"; done
trap "tr_trap_exit_interrupted" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "tr_trap_exit_unknown_error" ERR

source "${_TEST_SCRIPT_DIR}/../testing.sh"
te_print_header "utilities.sh"

source "${_TEST_SCRIPT_DIR}/../msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

source "${_TEST_SCRIPT_DIR}/../utilities.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


#******************************************************************************************************************************
# TEST: ut_is_yes_no_var_abort()
#******************************************************************************************************************************
ts_ut___ut_is_yes_no_var_abort() {
    te_print_function_msg "ut_is_yes_no_var_abort()"
    local _fn="ts_ut___ut_is_yes_no_var_abort"
    local _test_var _output

    _test_var=""
    _output=$((ut_is_yes_no_var_abort "$_test_var" "_test_var") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'ut_is_yes_no_var_abort()' Requires AT LEAST '3' arguments. Got '2'"

    _test_var="yes"
    _output=$((ut_is_yes_no_var_abort "$_test_var" "" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION Argument 2 MUST NOT be empty."

    _test_var="wrong"
    _output=$((ut_is_yes_no_var_abort "$_test_var" "_test_var" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "VARIBLE: '_test_var' MUST be set to: 'yes' or 'no'. Got: 'wrong'"

    _test_var="wrong"
    _output=$((ut_is_yes_no_var_abort "$_test_var" "_test_var" "$_fn" "Some info") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "VARIBLE:"*"MUST be set to: 'yes' or 'no'. Got: 'wrong' INFO: Some info"

    _test_var="yes"
    (ut_is_yes_no_var_abort "$_test_var" "_test_var" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable yes."

    _test_var="no"
    (ut_is_yes_no_var_abort "$_test_var" "_test_var" "$_fn" "Some Extra error info")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable no."
}
ts_ut___ut_is_yes_no_var_abort


#******************************************************************************************************************************
# TEST: ut_is_str_var()
#******************************************************************************************************************************
ts_ut___ut_is_str_var() {
    te_print_function_msg "ut_is_str_var()"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    declare -ru zzz_option_ru_assigned_should_be_last="Should be last in declare string"
    declare -tux _option_tux_assigned="dummy example"
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    declare -i _assigned_int=5

    (ut_is_str_var "_not_declared") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_not_declared>."

    (ut_is_str_var "_not_assigned") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_not_assigned>."

    (ut_is_str_var "_assigned_empty") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_empty>."

    (ut_is_str_var "_assigned_none_empty") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_none_empty>."

    (ut_is_str_var "_option_rl_not_assigned") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_option_rl_not_assigned>."

    (ut_is_str_var "zzz_option_ru_assigned_should_be_last") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <zzz_option_ru_assigned_should_be_last>."

    (ut_is_str_var "_option_tux_assigned") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_option_tux_assigned>."

    (ut_is_str_var "_options_al_not_assigned_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_options_al_not_assigned_array>."

    (ut_is_str_var "_associative_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_associative_array>."

    (ut_is_str_var "_assigned_int") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_int>."

    # CLEAN UP
    unset _option_tux_assigned
}
ts_ut___ut_is_str_var


#******************************************************************************************************************************
# TEST: ut_is_empty_str_var()
#******************************************************************************************************************************
ts_ut___ut_is_empty_str_var() {
    te_print_function_msg "ut_is_empty_str_var()"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    declare -ru zzz_option_ru_assigned_should_be_last="Should be last in declare string"
    declare -tux _option_tux_assigned="dummy example"
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    declare -i _assigned_int=5

    (ut_is_empty_str_var "_not_declared") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_not_declared>."

    (ut_is_empty_str_var "_not_assigned") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_not_assigned>."

    (ut_is_empty_str_var "_assigned_empty") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_empty>."

    (ut_is_empty_str_var "_assigned_none_empty") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_none_empty>."

    (ut_is_empty_str_var "_option_tux_assigned") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_option_tux_assigned>."

    (ut_is_empty_str_var "zzz_option_ru_assigned_should_be_last") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <zzz_option_ru_assigned_should_be_last>."

    (ut_is_empty_str_var "_options_al_not_assigned_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_options_al_not_assigned_array>."

    (ut_is_empty_str_var "_associative_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_associative_array>."

    (ut_is_empty_str_var "_assigned_int") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Variable <_assigned_int>."

    # CLEAN UP
    unset _option_tux_assigned
}
ts_ut___ut_is_empty_str_var


#******************************************************************************************************************************
# TEST: ut_is_str_var_abort()
#******************************************************************************************************************************
ts_ut___ut_is_str_var_abort() {
    te_print_function_msg "ut_is_str_var_abort()"
    local _fn="ts_ut___ut_is_str_var_abort"
    local _not_assigned
    local _assigned_empty=""
    local _assigned_none_empty="dummy example"
    declare -rl _option_rl_not_assigned
    local _array=(a b)
    local _output

    _output=$((ut_is_str_var_abort "_ret" "$_fn" "JUST Some INFO") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared string variable: '_ret' INFO: JUST Some INFO" \
        "Test optional arg: <_extra_info>"

    _output=$((ut_is_str_var_abort "_not_assigned") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'ut_is_str_var_abort()' Requires AT LEAST '2' arguments. Got '1'"

    _output=$((ut_is_str_var_abort "not_a_declared__variable" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared string variable: 'not_a_declared__variable'"

    _output=$((ut_is_str_var_abort "_array" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared string variable: '_array'"

    (ut_is_str_var_abort "_not_assigned" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned>."

    (ut_is_str_var_abort "_assigned_empty" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_empty>."

    (ut_is_str_var_abort "_assigned_none_empty" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_none_empty>."

    (ut_is_str_var_abort "_option_rl_not_assigned" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_option_rl_not_assigned>."
}
ts_ut___ut_is_str_var_abort


#******************************************************************************************************************************
# TEST: ut_is_idx_array_var()
#******************************************************************************************************************************
ts_ut___ut_is_idx_array_var() {
    te_print_function_msg "ut_is_idx_array_var()"
    local _assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array
    declare -ar _readonly_assigned_array=( 1 item)
    declare -arl _options_arl_assigned_array=( 1 "Item1")
    local -al _options_al_not_assigned_array
    declare -A _associative_array=(["key1"]="Item")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5

    (ut_is_idx_array_var "_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_array>."

    (ut_is_idx_array_var "_not_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned_array>."

    (ut_is_idx_array_var "_readonly_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_readonly_assigned_array>."

    (ut_is_idx_array_var "_options_arl_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_options_arl_assigned_array>."

    (ut_is_idx_array_var "_options_al_not_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_options_al_not_assigned_array>."

    (ut_is_idx_array_var "_associative_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_associative_array>."

    (ut_is_idx_array_var "_assigned_string") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_string>."

    (ut_is_idx_array_var "_not_assigned_anything") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned_anything>."

    (ut_is_idx_array_var "_assigned_int") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_int>."
}
ts_ut___ut_is_idx_array_var


#******************************************************************************************************************************
# TEST: ut_is_idx_array_abort()
#******************************************************************************************************************************
ts_ut___ut_is_idx_array_abort() {
    te_print_function_msg "ut_is_idx_array_abort()"
    local _fn="ts_ut___ut_is_idx_array_abort"
    local _assigned_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    declare -a _not_assigned_array

    declare -A _associative_array=(["key1"]="Item")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5
    local _output

    _output=$((ut_is_idx_array_abort "_ret" "$_fn" "JUST Some INFO") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: '_ret' INFO: JUST Some INFO"

    _output=$((ut_is_idx_array_abort "_assigned_array") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'ut_is_str_var_abort()' Requires AT LEAST '2' arguments. Got '1'"

    _output=$((ut_is_idx_array_abort "_not_assigned_anything" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: '_not_assigned_anything'"

    _output=$((ut_is_idx_array_abort "_assigned_int" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: '_assigned_int'"

    _output=$((ut_is_idx_array_abort "no_variable" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: 'no_variable'"

    (ut_is_idx_array_abort "_assigned_array" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_array>."

    (ut_is_idx_array_abort "_not_assigned_array" "$_fn")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned_array>."
}
ts_ut___ut_is_idx_array_abort


#******************************************************************************************************************************
# TEST: ut_is_associative_array_var()
#******************************************************************************************************************************
ts_ut___ut_is_associative_array_var() {
    te_print_function_msg "ut_is_associative_array_var()"
    declare -A _assigned_array=(["a"]="a" ["VALID ITEM2"]="VALID ITEM2" ["e f"]="e f" ["3"]=3 ["VALID ITEM"]="VALID ITEM")
    declare -A _not_assigned_array
    declare -A -r _readonly_assigned_array=(["1"]=1 ["item"]=item)
    declare -A -rl _options_arl_assigned_array=(["1"]=1 ["Item1"]=Item1)
    declare -Al _options_al_not_assigned_array

    local _index_array=(a b "c")
    local _assigned_string="anything"
    local _not_assigned_anything
    declare -i _assigned_int=5

    (ut_is_associative_array_var "_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_array>."

    (ut_is_associative_array_var "_not_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned_array>."

    (ut_is_associative_array_var "_readonly_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_readonly_assigned_array>."

    (ut_is_associative_array_var "_options_arl_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_options_arl_assigned_array>."

    (ut_is_associative_array_var "_options_al_not_assigned_array") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_options_al_not_assigned_array>."

    (ut_is_associative_array_var "_index_array") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_index_array>."

    (ut_is_associative_array_var "_assigned_string") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_string>."

    (ut_is_associative_array_var "_not_assigned_anything") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_not_assigned_anything>."

    (ut_is_associative_array_var "_assigned_int") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_int>."
}
ts_ut___ut_is_associative_array_var


#******************************************************************************************************************************
# TEST: ut_ref_associative_array_abort()
#******************************************************************************************************************************
ts_ut___ut_ref_associative_array_abort() {
    te_print_function_msg "ut_ref_associative_array_abort()"
    local _fn="ut_ref_associative_array_abort"
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

    _output=$((ut_ref_associative_array_abort) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Requires EXACT '2' arguments. Got '0'"

    _output=$((ut_ref_associative_array_abort "_ref_index_array" "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a referenced associative array: '_ref_ind"

    (ut_ref_associative_array_abort "_ref_assigned_array" "$_fn") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_assigned_array>."

    (ut_ref_associative_array_abort "_ref_not_assigned_array" "$_fn") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_not_assigned_array>."

    (ut_ref_associative_array_abort "_ref_readonly_assigned_array" "$_fn") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_readonly_assigned_array>."

    (ut_ref_associative_array_abort "_ref_options_arl_assigned_array" "$_fn") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_options_arl_assigned_array>."

    (ut_ref_associative_array_abort "_ref_not_assigned_to_nothing" "$_fn") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_not_assigned_to_nothing>."

    (ut_ref_associative_array_abort "_ref_index_array" "$_fn") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref_index_array>."

    (ut_ref_associative_array_abort "_index_array" "$_fn") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_index_array>."

    (ut_ref_associative_array_abort "_assigned_int" "$_fn") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test variable <_assigned_int>."

    (ut_ref_associative_array_abort "_ref__empty_array_set_ref_to_readonly" "$_fn") &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test variable <_ref__empty_array_set_ref_to_readonly>."
}
ts_ut___ut_ref_associative_array_abort


#******************************************************************************************************************************
# TEST: ut_count_substr()
#******************************************************************************************************************************
ts_ut___ut_count_substr() {
    te_print_function_msg "ut_count_substr()"
    local _input="text::text::|text::text"

    te_same_val _COUNT_OK _COUNT_FAILED  "$(ut_count_substr "::" "$_input")" "3" "Test substr: :: INPUT: <$_input>"

    te_same_val _COUNT_OK _COUNT_FAILED "$(ut_count_substr "|" "$_input")" "1"  "Test substr: | INPUT: <$_input>"

    te_same_val _COUNT_OK _COUNT_FAILED "$(ut_count_substr "X" "$_input")" "0" "Test substr: X INPUT: <$_input>"

    te_same_val _COUNT_OK _COUNT_FAILED "$(ut_count_substr "|" "")" "0" "Test substr: | EMPTY INPUT: <>"
}
ts_ut___ut_count_substr


#******************************************************************************************************************************
# TEST: ut_strip_trailing_slahes()
#******************************************************************************************************************************
ts_ut___ut_strip_trailing_slahes() {
    te_print_function_msg "ut_strip_trailing_slahes()"
    local _input_no_trailing_slash_extension="/home/testfile.txt"
    local _input_no_trailing_slash="/home/testdir"
    local _input_one_trailing_slash="/home/testdir/"
    local _input_multiple_trailing_slashes="/home/testdir///"
    local _input_no_slashes="home_test_dir"
    local _result

    ut_strip_trailing_slahes _result "$_input_no_trailing_slash_extension"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/testfile.txt" "Test INPUT: <$_input_no_trailing_slash_extension>"

    ut_strip_trailing_slahes _result "$_input_no_trailing_slash"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/testdir" "Test INPUT: <$_input_no_trailing_slash>"

    ut_strip_trailing_slahes _result "$_input_one_trailing_slash"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/testdir" "Test INPUT: <$_input_one_trailing_slash>"

    ut_strip_trailing_slahes _result "$_input_multiple_trailing_slashes"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/testdir" "Test INPUT: <$_input_multiple_trailing_slashes>"

    ut_strip_trailing_slahes _result "$_input_no_slashes"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "home_test_dir" "Test INPUT: <$_input_no_slashes>"
}
ts_ut___ut_strip_trailing_slahes


#******************************************************************************************************************************
# TEST: ut_strip_whitespace()
#******************************************************************************************************************************
ts_ut___ut_strip_whitespace() {
    te_print_function_msg "ut_strip_whitespace()"
    local _input_no_whitespace="Just a dummy text"
    local _input_leading_whitespace="       Just a dummy text"
    local _input_trailing_whitespace="Just a dummy text       "
    local _input_leading_trailing_whitespace="     Just a dummy text      "
    local _result

    ut_strip_whitespace _result "$_input_no_whitespace"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "Just a dummy text" "Test INPUT: <$_input_no_whitespace>"

    ut_strip_whitespace _result "$_input_leading_whitespace"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "Just a dummy text" "Test INPUT: <$_input_leading_whitespace>"

    ut_strip_whitespace _result "$_input_trailing_whitespace"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "Just a dummy text" "Test INPUT: <$_input_trailing_whitespace>"

    ut_strip_whitespace _result "$_input_leading_trailing_whitespace"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "Just a dummy text" "Test INPUT: <$_input_leading_trailing_whitespace>"
}
ts_ut___ut_strip_whitespace


#******************************************************************************************************************************
# TEST: ut_get_prefix_shortest_empty()
#******************************************************************************************************************************
ts_ut___ut_get_prefix_shortest_empty() {
    te_print_function_msg "ut_get_prefix_shortest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_prefix_shortest_empty _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "NOEXTRACT" "Test INPUT: <$_entry>"

    ut_get_prefix_shortest_empty _result "$_entry_no_delim" "::"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_prefix_shortest_empty


#******************************************************************************************************************************
# TEST: ut_get_prefix_longest_empty()
#******************************************************************************************************************************
ts_ut___ut_get_prefix_longest_empty() {
    te_print_function_msg "ut_get_prefix_longest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_prefix_longest_empty _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "NOEXTRACT::helper_scripts" "Test INPUT: <$_entry>"

    ut_get_prefix_longest_empty _result "$_entry_no_delim" "::"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_prefix_longest_empty


#******************************************************************************************************************************
# TEST: ut_get_prefix_shortest_all()
#******************************************************************************************************************************
ts_ut___ut_get_prefix_shortest_all() {
    te_print_function_msg "ut_get_prefix_shortest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_prefix_shortest_all _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "NOEXTRACT" "Test INPUT: <$_entry>"

    ut_get_prefix_shortest_all _result "$_entry_no_delim" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "$_entry_no_delim" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_prefix_shortest_all


#******************************************************************************************************************************
# TEST: ut_get_prefix_longest_all()
#******************************************************************************************************************************
ts_ut___ut_get_prefix_longest_all() {
    te_print_function_msg "ut_get_prefix_longest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_prefix_longest_all _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "NOEXTRACT::helper_scripts" "Test INPUT: <$_entry>"

    ut_get_prefix_longest_all _result "$_entry_no_delim" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "$_entry_no_delim" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_prefix_longest_all


#******************************************************************************************************************************
# TEST: ut_get_postfix_shortest_empty()
#******************************************************************************************************************************
ts_ut___ut_get_postfix_shortest_empty() {
    te_print_function_msg "ut_get_postfix_shortest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_postfix_shortest_empty _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" \
        "https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" "Test INPUT: <$_entry>"

    ut_get_postfix_shortest_empty _result "$_entry_no_delim" "::"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_postfix_shortest_empty


#******************************************************************************************************************************
# TEST: ut_get_postfix_longest_empty()
#******************************************************************************************************************************
ts_ut___ut_get_postfix_longest_empty() {
    te_print_function_msg "ut_get_postfix_longest_empty()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_postfix_longest_empty _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" \
        "helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" "Test INPUT: <$_entry>"

    ut_get_postfix_longest_empty _result "$_entry_no_delim" "::"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_postfix_longest_empty


#******************************************************************************************************************************
# TEST: ut_get_postfix_shortest_all()
#******************************************************************************************************************************
ts_ut___ut_get_postfix_shortest_all() {
    te_print_function_msg "ut_get_postfix_shortest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_postfix_shortest_all _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" \
        "https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" "Test INPUT: <$_entry>"

    ut_get_postfix_shortest_all _result "$_entry_no_delim" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "$_entry_no_delim" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_postfix_shortest_all


#******************************************************************************************************************************
# TEST: ut_get_postfix_longest_all()
#******************************************************************************************************************************
ts_ut___ut_get_postfix_longest_all() {
    te_print_function_msg "ut_get_postfix_longest_all()"
    local _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _entry_no_delim="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
    local _result

    ut_get_postfix_longest_all _result "$_entry" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" \
        "helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a" "Test INPUT: <$_entry>"

    ut_get_postfix_longest_all _result "$_entry_no_delim" "::"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "$_entry_no_delim" "Test No Delimiter INPUT: <$_entry_no_delim>"
}
ts_ut___ut_get_postfix_longest_all


#******************************************************************************************************************************
# TEST: ut_get_cmd_option_values_array()
#******************************************************************************************************************************
ts_ut___ut_get_cmd_option_values_array() {
    te_print_function_msg "ut_get_cmd_option_values_array()"
    local _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
    local _array_with_long_option=(-v --version -i --install --config-file /home/long_option/cmk.conf -h --help)
    local _array_with_short_option_no_value=(-v --version -i --install -cf)
    local _array_with_short_option_empty_value=(-v --version -i --install -cf "" -h --help)
    local _array_with_long_option_wrong_startchar=(-v --version -i --install --config-file -/home/long_option/cmk.conf -h)
    local _array_with_short_3_values=(-v --version -i --install -cf value1 value2 value3 -h --help)
    local _array_with_long_3_values_at_end=(-v --version -i --install --config-file value1 value2 value3)
    local _output _tmp_str
    declare -a _result

    _result=()
    _output=$((ut_get_cmd_option_values_array _result "" _array_with_short_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION Argument 2 '_idx' MUST NOT be empty"

    _result=()
    _n=4
    _output=$((ut_get_cmd_option_values_array _result _n _array_with_long_option_wrong_startchar) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option:"*" MUST NOT start with a hyphen-minus" \
        "Test INPUT: <_array_with_long_option_wrong_startchar>"

    _result=()
    _n=4
    ut_get_cmd_option_values_array _result _n _array_with_short_option
    te_same_val _COUNT_OK _COUNT_FAILED "${_result[@]}" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    _result=()
    _n=4
    ut_get_cmd_option_values_array _result _n _array_with_long_option
    te_same_val _COUNT_OK _COUNT_FAILED "${_result[@]}" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    _result=()
    _n=4
    _output=$((ut_get_cmd_option_values_array _result _n _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option: '-cf' requires an value. All Arguments: <-v --v" \
        "Test INPUT: <_array_with_short_option_no_value>."

    _result=()
    _n=4
    _output=$((ut_get_cmd_option_values_array _result _n _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option: '-cf' value: '' MUST NOT be empty: All Argument" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    _result=()
    _n=4
    _output=$((ut_get_cmd_option_values_array _result _n _array_with_short_3_values 0) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Argument '_maximum_expected_values' MUST NOT be 0" \
        "Test Argument _maximum_expected_values MUST NOT be 0"

    _result=()
    _n=4
    _output=$((ut_get_cmd_option_values_array _result _n _array_with_long_3_values_at_end 2) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "option: '--config-file' maximum expected values: '2'. Found '3'"

    _result=()
    _n=4
    ut_get_cmd_option_values_array _result _n _array_with_short_3_values 3
    # Need to convert it first to a string
    _tmp_str=${_result[@]}
    te_same_val _COUNT_OK _COUNT_FAILED "$_tmp_str" "value1 value2 value3" \
        "Test maximum expected values: 3. Found 3. INPUT: <_array_with_short_3_values>"

    _result=()
    _n=4
    ut_get_cmd_option_values_array _result _n _array_with_long_3_values_at_end 5
    _tmp_str=${_result[@]}
    te_same_val _COUNT_OK _COUNT_FAILED "$_tmp_str" "value1 value2 value3" \
        "Test maximum expected values: 5. Found 3. INPUT: <_array_with_long_3_values_at_end>"
    te_same_val _COUNT_OK _COUNT_FAILED "$_n" "7" \
        "Test index value was incremented. Found 3. INPUT: <_array_with_long_3_values_at_end>"
}
ts_ut___ut_get_cmd_option_values_array


#******************************************************************************************************************************
# TEST: ut_get_cmd_option_single_value_string()
#******************************************************************************************************************************
ts_ut___ut_get_cmd_option_single_value_string() {
    te_print_function_msg "ut_get_cmd_option_single_value_string()"
    local _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
    local _array_with_long_option=(-v --version -i --install --config-file /home/long_option/cmk.conf -h --help)
    local _array_with_short_option_no_value=(-v --version -i --install -cf)
    local _array_with_short_option_empty_value=(-v --version -i --install -cf "" -h --help)
    local _array_with_long_option_in_middle_no_value=(-v --version -i --install --config-file -h --help)
    local _output _result

    _output=$((ut_get_cmd_option_single_value_string _result 4 _array_with_short_option "wrong") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "4. VARIBLE: '_abort_if_no_value' MUST be set to: 'yes' or 'no'. Got: 'wrong'"

    ut_get_cmd_option_single_value_string _result 4 _array_with_short_option
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    ut_get_cmd_option_single_value_string _result 4 _array_with_long_option
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    _output=$((ut_get_cmd_option_single_value_string _result 4 _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option: '-cf' requires an value. All Arguments" \
        "Test INPUT: <_array_with_short_option_no_value>."

    _output=$((ut_get_cmd_option_single_value_string _result 4 _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option: '-cf' argument value MUST NOT be empty: All Arg" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    _output=$((ut_get_cmd_option_single_value_string _result 4 _array_with_long_option_in_middle_no_value "yes") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Command-Line option: '--config-file' requires an value. All Argument" \
        "Test _abort_if_no_value=yes: <_array_with_long_option_in_middle_no_value>. "

    ut_get_cmd_option_single_value_string _result 4 _array_with_long_option_in_middle_no_value "no"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test _abort_if_no_value=no: <_array_with_long_option_in_middle_no_value>."
}
ts_ut___ut_get_cmd_option_single_value_string


#******************************************************************************************************************************
# TEST: ut_search_cmd_option_values_string()
#******************************************************************************************************************************
ts_ut___ut_search_cmd_option_values_string() {
    te_print_function_msg "ut_search_cmd_option_values_string()"
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

    _output=$((ut_search_cmd_option_values_string _result "" "" _array_without_search_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "WRONG CODE: Function: 'ut_search_cmd_option_values_string()' Argument 1: '' Argument 2: ''." \
        "Test Both option to check are empty. <_array_without_search_option>."

    _output=$((ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_long_option_wrong_startchar) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Command-Line option: '-"*"'-/home/long_option/cmk.conf' MUST NOT start with a hyphen-minus" \
        "Test INPUT: <_array_with_long_option_wrong_startchar>."

    _output=$((ut_search_cmd_option_values_string _result "-" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Short option to check: '-' MUST be at least 2 character long or empty."

    _output=$((ut_search_cmd_option_values_string _result "+c" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Short option to check: '+c' MUST start with EXACT ONE hyphen-minus."

    _output=$((ut_search_cmd_option_values_string _result "--d" "--config-file" _array_with_short_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Short option to check: '--d' MUST start with EXACT ONE hyphen-minus."

    _output=$((ut_search_cmd_option_values_string _result "-cf" "-" _array_with_long_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Long option to check: '-' MUST be at least 3 character long or empty."

    _output=$((ut_search_cmd_option_values_string _result "-cf" "+config-file" _array_with_long_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Long option to check: '+config-file' MUST start with EXACT TWO hyphen-minus."

    _output=$((ut_search_cmd_option_values_string _result "-cf" "---d" _array_with_long_option) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Long option to check: '---d' MUST start with EXACT TWO hyphen-minus."

    _output=$(ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_without_search_option)
    te_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Test INPUT: <_array_without_search_option> Check info message."

    ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_short_option
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/short_option/cmk.conf" "Test INPUT: <_array_with_short_option>"

    ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_long_option
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/long_option/cmk.conf" "Test INPUT: <_array_with_long_option>"

    ut_search_cmd_option_values_string _result "" "--config-file" _array_without_search_option
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test Short option empty. INPUT: <_array_without_search_option>"

    ut_search_cmd_option_values_string _result "-cf" "" _array_without_search_option
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test Long option empty. INPUT: <_array_without_search_option>"

    _output=$((ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_short_option_no_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Command-Line option: '-cf' requires at least 1 value. All ARGS: <-v --version -i --install" \
        "Test INPUT: <_array_with_short_option_no_value>"

    _output=$((ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_short_option_empty_value) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Command-Line option: '-cf' value: '' MUST NOT be empty: All Arguments: <-v --version -i --i" \
        "Test INPUT: <_array_with_short_option_empty_value>."

    ut_search_cmd_option_values_string _result "-v" "--version" _array_empty 1
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test INPUT: <_array_empty>."

    _output=$((ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_short_3_values 0) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Argument '_maximum_expected_values' MUST NOT be 0"

    _output=$((ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_long_3_values_at_end 2) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Command-Line option: '--config-file' maximum expected values: '2'. Found '3' All ARGS: <-v" \
        "Test maximum expected values: 2"

    ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_short_3_values 3
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "value1 value2 value3" \
        "Test maximum expected values: 3.  Found 3. INPUT: <_array_with_short_3_values>"

    ut_search_cmd_option_values_string _result "-cf" "--config-file" _array_with_long_3_values_at_end 5
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "value1 value2 value3" \
        "Test maximum expected values: 5.  Found 3. INPUT: <_array_with_long_3_values_at_end>"
}
ts_ut___ut_search_cmd_option_values_string


#******************************************************************************************************************************
# TEST: ut_basename()
#******************************************************************************************************************************
ts_ut___ut_basename() {
    te_print_function_msg "ts_ut___ut_basename()"
    local _output _result

    ut_basename _result "/home/test_dir//"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "test_dir" "Test </home/test_dir//>"

    ut_basename _result "home"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "home"

    ut_basename _result ""
    te_empty_val _COUNT_OK _COUNT_FAILED "$_result" "Test empty INPUT: <>."
}
ts_ut___ut_basename


#******************************************************************************************************************************
# TEST: ut_dirname()
#******************************************************************************************************************************
ts_ut___ut_dirname() {
    te_print_function_msg "ut_dirname()"
    local _output _result

    ut_dirname _result "/home/test/Pkgfile.txt"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/home/test" "Test </home/test/Pkgfile.txt>"

    ut_dirname _result "/home////"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "/" "Test </home////>"

    ut_dirname _result "home/test/Pkgfile.txt"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "home/test" "Test <home/test/Pkgfile.txt>"

    ut_dirname _result "Pkgfile.txt"
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "." "Test <Pkgfile.txt>"

    ut_dirname _result ""
    te_same_val _COUNT_OK _COUNT_FAILED "$_result" "." "Test empty input <>"
}
ts_ut___ut_dirname


#******************************************************************************************************************************
# TEST: ut_is_abspath()
#******************************************************************************************************************************
ts_ut___ut_is_abspath() {
    te_print_function_msg "ut_is_abspath()"

    (ut_is_abspath "test/Pkgfile")
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test relative path <test/Pkgfile>."

    (ut_is_abspath "")
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test empty path <>."

    (ut_is_abspath "/home/Pkgfile")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test absolute path </home/Pkgfile>."
}
ts_ut___ut_is_abspath


#******************************************************************************************************************************
# TEST: ut_is_abspath_abort()
#******************************************************************************************************************************
ts_ut___ut_is_abspath_abort() {
    te_print_function_msg "ut_is_abspath_abort()"
    local _output

    _output=$((ut_is_abspath_abort "test/Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Path MUST be an absolute path and MUST start with a slash: <test/Pkgfile>" "Test relative path <test/Pkgfile>"

    _output=$((ut_is_abspath_abort "" "TEST_PATH") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "TEST_PATH MUST be an absolute path and MUST start with a slash: <>" \
        "Test empty path <>"

    (ut_is_abspath_abort "/home/Pkgfile")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test absolute path </home/Pkgfile>."
}
ts_ut___ut_is_abspath_abort


#******************************************************************************************************************************
# TEST: ut_dir_has_content_abort()
#******************************************************************************************************************************
ts_ut___ut_dir_has_content_abort() {
    te_print_function_msg "ut_dir_has_content_abort()"
    local _tmp_dir_empty=$(mktemp -d)
    local _tmp_dir_with_dir=$(mktemp -d)
    local _tmp_dir_with_file=$(mktemp -d)
    local _tmp_dir_with_link=$(mktemp -d)
    local _tmp_dummy_file=$(mktemp)
    local _none_existing_dir=${_tmp_dir_empty}/_none_existing_dir

    mkdir "$_tmp_dir_with_dir/subfolder"
    touch "$_tmp_dir_with_file/simple_file.txt"
    ln -s "$_tmp_dummy_file" "$_tmp_dir_with_link/_dummy_file_link"

    (ut_dir_has_content_abort "$_tmp_dir_empty")
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test has content <_tmp_dir_empty>."

    (ut_dir_has_content_abort "$_tmp_dir_with_dir")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Not empty <_tmp_dir_with_dir>."

    if ut_dir_has_content_abort "$_none_existing_dir"; then
        te_ms_failed _COUNT_FAILED "Comman usage example: Test has no content <_none_existing_dir>"
    else
        te_ms_ok _COUNT_OK "Comman usage example: Test has no content <_none_existing_dir>"
    fi

    (ut_dir_has_content_abort "$_tmp_dir_with_file")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Not empty <_tmp_dir_with_file>."

    (ut_dir_has_content_abort "$_tmp_dir_with_link")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Not empty <_tmp_dir_with_link>."


    # CLEAN UP
    rm -rf "$_tmp_dir_empty"
    rm -rf "$_tmp_dir_with_dir"
    rm -rf "$_tmp_dir_with_file"
    rm -rf "$_tmp_dir_with_link"
    rm -f "$_tmp_dummy_file"
}
ts_ut___ut_dir_has_content_abort


#******************************************************************************************************************************
# TEST: ut_cd_safe_abort()
#******************************************************************************************************************************
ts_ut___ut_cd_safe_abort() {
    te_print_function_msg "ut_cd_safe_abort()"
    local _tmp_dir=$(mktemp -d)
    local _output

    _output=$((ut_cd_safe_abort "") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION Argument 1 MUST NOT be empty."

    ((ut_cd_safe_abort "$_tmp_dir") &> /dev/null)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test CD to existing dir."
    cd "$_TEST_SCRIPT_DIR"     # Get back

    ((ut_cd_safe_abort "$_script_dir/NONE_EXISTING_DIR") &> /dev/null)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test CD to NONE existing dir."
    cd "$_TEST_SCRIPT_DIR"

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ut___ut_cd_safe_abort


# TEST: ut_dir_is_rwx_abort(): Skip testing this function

# TEST: ut_file_is_r_abort(): Skip testing this function

# TEST: ut_file_is_rw_abort(): Skip testing this function

# TEST: ut_utc_date(): Skip testing this function

# TEST: ut_unix_timestamp(): Skip testing this function


#******************************************************************************************************************************
# TEST: ut_is_integer_greater()
#******************************************************************************************************************************
ts_ut___ut_is_integer_greater() {
    te_print_function_msg "ut_is_integer_greater()"

    (ut_is_integer_greater 266)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test INPUT: <ut_is_integer_greater 266>  NOTE: Default CHECK VALUE is: 0."

    (ut_is_integer_greater 266 500)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test INPUT: <ut_is_integer_greater 266 500>."

    (ut_is_integer_greater -1 -15)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test INPUT: <ut_is_integer_greater -1 -15>."

    (ut_is_integer_greater -199 -89)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test INPUT: <ut_is_integer_greater -199 -89>."
}
ts_ut___ut_is_integer_greater


#******************************************************************************************************************************
# TEST: ut_repeat_failed_command()
#******************************************************************************************************************************
ts_ut___ut_repeat_failed_command() {
    te_print_function_msg "ut_repeat_failed_command()"
    local _output

    _output=$((ut_repeat_failed_command 0 1 true) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'_max_tries': must be greater than 0. Got: '0'" \
        "Test INPUT: <ut_repeat_failed_command 0 1 true>"

    _output=$((ut_repeat_failed_command 1 -1 true) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'_delay_sec': must be greater than -1. Got: '-1'" \
        "Test INPUT: <ut_repeat_failed_command 1 -1 true> _DELAY_SEC: must be greater than -1."

    _output=$((ut_repeat_failed_command 1 1 true) 2>&1)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test INPUT: <ut_repeat_failed_command 1 1 true>."
    te_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Test INPUT: <ut_repeat_failed_command 1 1 true> Check no warn message."

    _output=$((ut_repeat_failed_command 2 1 false) 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "WARNING: Command failed: '2' times" \
        "Test INPUT: <ut_repeat_failed_command 2 1 false> Find failed: 2 times WARNING message."
}
ts_ut___ut_repeat_failed_command


#******************************************************************************************************************************
# TEST: ut_in_array()
#******************************************************************************************************************************
ts_ut___ut_in_array() {
    te_print_function_msg "ut_in_array()"
    local _test_array=("a" "VALID ITEM2" "e f" 3 "VALID ITEM" 6 567)
    local _output

    _output=$((ut_in_array _test_array) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION Requires EXACT '2' arguments. Got '1'"

    (ut_in_array "NOT VALID ITEM" _test_array) &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test NOT VALID item in array."

    (ut_in_array "VALID ITEM2" _test_array) &> /dev/null
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test VALID ITEM2 item in array."
}
ts_ut___ut_in_array


#******************************************************************************************************************************
# TEST: ut_got_function()
#******************************************************************************************************************************
ts_ut___ut_got_function() {
    te_print_function_msg "ut_got_function()"

    _valid_function() {
        _a="DUMMY"
    }

    (ut_got_function "_valid_function")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Find <_valid_function>."

    (ut_got_function "_not_valid_function") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test Find <_not_valid_function>."
}
ts_ut___ut_got_function


#******************************************************************************************************************************
# TEST: ut_unset_functions()
#******************************************************************************************************************************
ts_ut___ut_unset_functions() {
    te_print_function_msg "ut_unset_functions()"
    local _fn="ts_ut___ut_unset_functions"
    local _functions_to_unset=(test_func1 test_func3 undefined_function)

    unset -f test_func1 test_func2 test_func3 undefined_function

    test_func1() {
        local _a="test function 1"
    }

    test_func2() {
        local _a="test function 2"
    }

    test_func3() {
        local _a="test function 3"
    }

    # Check we got all 3 functions
    ut_got_function "test_func1" || ms_warn2 "$_fn" Expected to have a function named: "test_func1"
    ut_got_function "test_func2" || ms_warn2 "$_fn" Expected to have a function named: "test_func2"
    ut_got_function "test_func3" || ms_warn2 "$_fn" Expected to have a function named: "test_func3"

    ut_unset_functions _functions_to_unset

    (ut_got_function "test_func1")
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "unset <test_func1> defined in array: Test if it is afterwards set?."

    (ut_got_function "test_func2")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "unset <test_func2> not defined in array: Test if it is afterwards still set?."

    unset -f test_func1 test_func2 test_func3 undefined_function
}
ts_ut___ut_unset_functions


#******************************************************************************************************************************
# TEST: ut_source_safe_abort()
#******************************************************************************************************************************
ts_ut___ut_source_safe_abort() {
    te_print_function_msg "ut_source_safe_abort()"
    local _output

    _output=$((ut_source_safe_abort) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Could not source file: <>" \
        "Test No file supplied: Could not source file: <>."
}
ts_ut___ut_source_safe_abort


#******************************************************************************************************************************
# TEST: ut_get_file_md5sum()
#******************************************************************************************************************************
ts_ut___ut_get_file_md5sum() {
    te_print_function_msg "ut_get_file_md5sum()"
    local _orig_chksum="251aadc2351abf85b3dbfe7261f06218"
    local _text_file="$(dirname _THIS_SCRIPT_PATH)/files/md5sum_testfile.txt"
    local _none_existing_file="$(dirname _THIS_SCRIPT_PATH)/none_existing_file_path.no"
    local _chksum

    ut_get_file_md5sum _chksum "$_text_file"
    te_same_val _COUNT_OK _COUNT_FAILED "$_chksum" "$_orig_chksum"

    ut_get_file_md5sum _chksum "$_none_existing_file"
    te_empty_val _COUNT_OK _COUNT_FAILED "$_chksum" "Test chksum none existing file path. Expected empty.'"
}
ts_ut___ut_get_file_md5sum


#******************************************************************************************************************************
# TEST: ut_no_command_abort()
#******************************************************************************************************************************
ts_ut___ut_no_command_abort() {
    te_print_function_msg "ut_no_command_abort()"
    local _output

    _output=$((ut_no_command_abort "missing_command") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Missing command: 'missing_command'" \
        "Test got command <missing_command>."

    (ut_no_command_abort "bash")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test got command <bash>."
}
ts_ut___ut_no_command_abort


#******************************************************************************************************************************
# TEST: ut_got_internet()
#******************************************************************************************************************************
ts_ut___ut_got_internet() {
    te_print_function_msg "ut_got_internet()"
    local _fn="ts_ut___ut_got_internet"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _output
    declare -i _ret

    _output=$((ut_got_internet) 2>&1)
    _ret=$?
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED $_ret "Test got internet."
}
ts_ut___ut_got_internet


#******************************************************************************************************************************
# TEST: ut_is_git_uri_accessible()
#******************************************************************************************************************************
ts_ut___ut_is_git_uri_accessible() {
    te_print_function_msg "ut_is_git_uri_accessible()"
    local _fn="ts_ut___ut_is_git_uri_accessible"
    local _git_uri="https://github.com/P-Linux/pl_bash_functions.git"
    local _git_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri.git"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _output
    declare -i _ret

    _output=$((ut_is_git_uri_accessible "$_git_uri") 2>&1)
    _ret=$?
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED $_ret "Test got internet."

    _output=$((ut_is_git_uri_accessible "$_git_wrong_uri") 2>&1)
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Couldn't verify that the git uri is accessible:" \
        "Test wrong git uri."
}
ts_ut___ut_is_git_uri_accessible


#******************************************************************************************************************************
# TEST: ut_is_svn_uri_accessible()
#******************************************************************************************************************************
ts_ut___ut_is_svn_uri_accessible() {
    te_print_function_msg "ut_is_svn_uri_accessible()"
    local _fn="ts_ut___ut_is_svn_uri_accessible"
    local _svn_uri="https://svn.code.sf.net/p/portmedia/code/portsmf/trunk"
    local _svn_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _output
    declare -i _ret

    _output=$((ut_is_svn_uri_accessible "$_svn_uri") 2>&1)
    _ret=$?
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED $_ret "Test got internet."

    _output=$((ut_is_svn_uri_accessible "$_svn_wrong_uri") 2>&1)
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Couldn't verify that the svn uri is accessible:" \
        "Test wrong git uri."
}
ts_ut___ut_is_svn_uri_accessible


#******************************************************************************************************************************
# TEST: ut_is_hg_uri_accessible()
#******************************************************************************************************************************
ts_ut___ut_is_hg_uri_accessible() {
    te_print_function_msg "ut_is_hg_uri_accessible()"
    local _fn="ts_ut___ut_is_hg_uri_accessible"
    local _hg_uri="https://bitbucket.org/bos/hg-tutorial-hello"
    local _hg_wrong_uri="https://www.wrong_dummy.test/just_a_wrong_uri"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    local _output
    declare -i _ret

    _output=$((ut_is_hg_uri_accessible "$_hg_uri") 2>&1)
    _ret=$?
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED $_ret "Test got internet."

    _output=$((ut_is_hg_uri_accessible "$_hg_wrong_uri") 2>&1)
    if [[ $_output == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "$_fn" "Internet access is REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Couldn't verify that the hg uri is accessible:" \
        "Test wrong git uri."
}
ts_ut___ut_is_hg_uri_accessible



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
