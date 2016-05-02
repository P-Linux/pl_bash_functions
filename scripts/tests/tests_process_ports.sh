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
te_print_header "process_ports.sh"

source "${_TEST_SCRIPT_DIR}/../msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

source "${_TEST_SCRIPT_DIR}/../utilities.sh"
ut_source_safe_abort "${_TEST_SCRIPT_DIR}/../process_ports.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


# pk_unset_official_pkgfile_variables skip test for this function


#******************************************************************************************************************************
# TEST: pr_make_pkg_build_dir()
#******************************************************************************************************************************
ts_pk___pr_make_pkg_build_dir() {
    te_print_function_msg "pr_make_pkg_build_dir()"
    local _tmp_dir=$(mktemp -d)
    local _pkg_build_dir _tmp_pkg_build_dir_file _tmp_srcdir_file _tmp_pkgdir_file

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test0"
    _output=$((pr_make_pkg_build_dir) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION 'pr_make_pkg_build_dir()': Argument 1 MUST NOT be empty."

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test1"
    pr_make_pkg_build_dir "$_pkg_build_dir"
    te_retval_0 _COUNT_OK _COUNT_FAILED _ret "Test pr_make_pkg_build_dir return OK."

    [[ -n $pkgdir && -n $srcdir ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test (pkgdir, srcdir) variables are set."

    [[ -d "${_pkg_build_dir}/pkg" && -d "${_pkg_build_dir}/src" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test (pkgdir, srcdir) exist."

    _tmp_pkg_build_dir_file="${_pkg_build_dir}/_tmp_pkg_build_dir_file"
    _tmp_pkgdir_file="${_pkg_build_dir}/pkg/_tmp_pkgdir_file"
    _tmp_srcdir_file="${_pkg_build_dir}/src/_tmp_pkgdir_file"
    touch "$_tmp_pkg_build_dir_file"
    touch "$_tmp_pkgdir_file"
    touch "$_tmp_srcdir_file"
    [[ -f $_tmp_pkg_build_dir_file &&  -f $_tmp_pkgdir_file && -f $_tmp_srcdir_file ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test created files in: pkg_build_dir pkgdir and srcdir exist."

    unset -v pkgdir srcdir
    pr_make_pkg_build_dir "$_pkg_build_dir"
    [[ -f $_tmp_pkg_build_dir_file &&  -f $_tmp_pkgdir_file && -f $_tmp_srcdir_file ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test existing _pkg_build_dir was really first deleted."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_pk___pr_make_pkg_build_dir



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
