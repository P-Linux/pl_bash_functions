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
te_print_header "msg.sh"

source "${_TEST_SCRIPT_DIR}/../msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


#******************************************************************************************************************************
# TEST: ms_get_pl_bash_functions_version()
#******************************************************************************************************************************
ts_ms___ms_get_pl_bash_functions_version() {
    te_print_function_msg "ms_get_pl_bash_functions_version()"
    local _version; ms_get_pl_bash_functions_version _version

    te_not_empty_val _COUNT_OK _COUNT_FAILED "$_version" "Testing get pl_bash_functions package version."
}
ts_ms___ms_get_pl_bash_functions_version


#******************************************************************************************************************************
# TEST: ms_has_tested_version()
#******************************************************************************************************************************
ts_ms___ms_has_tested_version() {
    te_print_function_msg "ms_has_tested_version()"
    local _ms_all_off=$(tput sgr0)
    local _ms_bold=$(tput bold)
    local _ms_yellow="${_ms_bold}$(tput setaf 3)"
    local _msg1="${_ms_yellow}====> WARNING:"
    local _pl_bash_functions_version; ms_get_pl_bash_functions_version _pl_bash_functions_version
    local _output

    _output=$((ms_has_tested_version "different_version") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "${_msg1}${_ms_all_off} This script was ${_ms_bold}TESTET${_ms_all_off} with <pl_bash_functions>: 'different_version'"

    _output=$((ms_has_tested_version "$_pl_bash_functions_version") 2>&1)
    te_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Testing same pl_bash_functions version."
}
ts_ms___ms_has_tested_version


#******************************************************************************************************************************
# TEST: ms_pl_bash_functions_installed_dir()
#******************************************************************************************************************************
ts_ms___ms_pl_bash_functions_installed_dir() {
    te_print_function_msg "ms_pl_bash_functions_installed_dir() very limited test"
    local _installed_dir; ms_pl_bash_functions_installed_dir _installed_dir
    local _ref_script_dir=$(readlink -f "${_TEST_SCRIPT_DIR}/..")

    te_same_val _COUNT_OK _COUNT_FAILED "$_installed_dir" "$_ref_script_dir"
}
ts_ms___ms_pl_bash_functions_installed_dir


#******************************************************************************************************************************
# TEST: ms_more()
#******************************************************************************************************************************
ts_ms___ms_more() {
    te_print_function_msg "ts_ms___ms_more()"
    local _filename="/home/testfile.txt"
    local _output

    _MS_VERBOSE_MORE="no"
    _output=$(ms_more "$(gettext "Source file: <%s>")" "$_filename")
    te_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Testing _MS_VERBOSE_MORE=no skip output."

    _MS_VERBOSE_MORE="yes"
    _output=$(ms_more "$(gettext "Source file: <%s>")" "$_filename")
    te_not_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Testing _MS_VERBOSE_MORE=yes expect output."
}
ts_ms___ms_more


#******************************************************************************************************************************
# TEST: ms_bold()
#******************************************************************************************************************************
ts_ms___ms_bold() {
    te_print_function_msg "ts_ms___ms_bold()"
    local _filename="/home/testfile.txt"
    local _output

    _MS_VERBOSE="no"
    _output=$(ms_bold "$(gettext "Source file: <%s>")" "$_filename")
    te_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Testing _MS_VERBOSE=no skip output."

    _MS_VERBOSE="yes"
    _output=$(ms_bold "$(gettext "Source file: <%s>")" "$_filename")
    te_not_empty_val _COUNT_OK _COUNT_FAILED "$_output" "Testing _MS_VERBOSE=yes expect output."
}
ts_ms___ms_bold


#******************************************************************************************************************************
# TEST: ms_abort()
#******************************************************************************************************************************
ts_ms___ms_abort() {
    te_print_function_msg "ms_abort()"
    local _fn="ts_ms___ms_abort"
    local _filename="/home/testfile.txt"
    local _info="Find passed info message: Just some extra info."
    local _output

    _output=$((ms_abort "$_fn" "$(gettext "Did Not find file: <%s> _info: '%s'")" "$_filename" "$_info") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "Find passed info message: Just some extra info."

    (ms_abort "$_fn" "$(gettext "Did Not find file: <%s> _info: '%s'")" "$_filename" "$_info") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Just normal abort."

    _output=$((ms_abort "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION 'ms_abort()': Requires AT LEAST '2' arguments. Got '1'"
}
ts_ms___ms_abort


#******************************************************************************************************************************
# TEST: ms_abort_remove_path()
#******************************************************************************************************************************
ts_ms___ms_abort_remove_path() {
    te_print_function_msg "ms_abort_remove_path()"
    local _fn="ts_ms___ms_abort_remove_path"
    local _tmp_dir=$(mktemp -d)
    local _builds_dir="${_tmp_dir}/builds"
    local _output

    _output=$((ms_abort_remove_path "$_fn") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Requires AT LEAST '4' arguments. Got '1'"

    _output=$((ms_abort_remove_path "$_fn" "yes" "$_builds_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Requires AT LEAST '4' arguments. Got '3'"

    _output=$((ms_abort_remove_path "$_fn" "wrong" "$_builds_dir"  "$(gettext "this is a failure: <%s>")" "ERROR") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Argument '2' MUST be 'yes' or 'no'. Got 'wrong'"

    _output=$((ms_abort_remove_path "$_fn" "no" "" "Path is: ${_tmp_dir}/none_existing") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Path is: ${_tmp_dir}/none_existing" \
        "ARGUMENT 3 empty but ARGUMENT 2 is not."

    _output=$((ms_abort_remove_path "$_fn" "yes" "" "${_tmp_dir}/none_existing") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Argument '3' MUST NOT be empty if argument 2 is 'yes'"

    # create the dir
    mkdir -p "$_builds_dir"

    _output=$((ms_abort_remove_path "$_fn" "no" "" "Keeping build_dir: <%s>" "$_builds_dir") 2>&1)
    if [[ ! -d $_builds_dir ]]; then
        te_warn "$_fn" "!! ERROR IN TEST-case: Keeping build_dir: <$_builds_dir> should still exist."
        exit 1
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "Keeping build_dir:"

    _output=$((ms_abort_remove_path "$_fn" "yes" "$_builds_dir" "Removing build_dir: <%s>" "$_builds_dir") 2>&1)
    if [[ -d $_builds_dir ]]; then
        te_warn "$_fn" "!! ERROR IN TEST-case: Keeping build_dir: <$_builds_dir> should not exist."
        exit 1
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "Removing build_dir:"

    (ms_abort_remove_path "$_fn" "yes" "$_builds_dir" "Removing build_dir: <%s>" "$_builds_dir") &> /dev/null
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Remove Path is: 'yes' BUT none existing."

    # CLEAN UP
    rm -rf "$_tmp_dir"
}
ts_ms___ms_abort_remove_path


#******************************************************************************************************************************
# TEST: ms_hrl()
#******************************************************************************************************************************
ts_ms___ms_hrl() {
    te_print_function_msg "ms_hrl()"
    local _expected_output="${_MS_GREEN}#=========================#${_MS_ALL_OFF}"
    local _output=$(ms_hrl "$_MS_GREEN" "#" "=" 25 "#")

    te_same_val _COUNT_OK _COUNT_FAILED "$_output" "$_expected_output"
}
ts_ms___ms_hrl



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
