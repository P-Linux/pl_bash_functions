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
te_print_header "process_ports.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format "${_THIS_SCRIPT_PATH}"

source "${_FUNCTIONS_DIR}/utilities.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/source_matrix.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/process_ports.sh"

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
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION 'pr_make_pkg_build_dir()': Argument 1 MUST NOT be empty."

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test1"
    pr_make_pkg_build_dir "${_pkg_build_dir}"
    te_retval_0 _COUNT_OK _COUNT_FAILED _ret "Test pr_make_pkg_build_dir return OK."

    [[ -n ${pkgdir} && -n ${srcdir} ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test (pkgdir, srcdir) variables are set."

    [[ -d "${_pkg_build_dir}/pkg" && -d "${_pkg_build_dir}/src" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test (pkgdir, srcdir) exist."

    _tmp_pkg_build_dir_file="${_pkg_build_dir}/_tmp_pkg_build_dir_file"
    _tmp_pkgdir_file="${_pkg_build_dir}/pkg/_tmp_pkgdir_file"
    _tmp_srcdir_file="${_pkg_build_dir}/src/_tmp_pkgdir_file"
    touch "${_tmp_pkg_build_dir_file}"
    touch "${_tmp_pkgdir_file}"
    touch "${_tmp_srcdir_file}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test created files in: pkg_build_dir pkgdir and srcdir exist."

    unset -v pkgdir srcdir
    pr_make_pkg_build_dir "${_pkg_build_dir}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test existing _pkg_build_dir was really first deleted."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_make_pkg_build_dir


#******************************************************************************************************************************
# TEST: pr_get_existing_pkg_archives()
#******************************************************************************************************************************
ts_pk___pr_get_existing_pkg_archives() {
    te_print_function_msg "pr_get_existing_pkg_archives()"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}//${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkg_archive
    local _targets=()

    # Make files
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

    touch "${_port_path1}/README"
    touch "${_port_path1}/test"
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    pr_get_existing_pkg_archives _targets _port_name1 _port_path1 _arch _pkg_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${#_targets[@]}" "4" "Test find 4 pkg_archive files (one in subfolder)"

    (ut_in_array "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 1. pkg_archive file in result array."

    (ut_in_array "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 2. pkg_archive file in result array."

    (ut_in_array "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 3. pkg_archive file in result array."

    (ut_in_array "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 4. pkg_archive file (in subfolder) in result array."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_get_existing_pkg_archives


#******************************************************************************************************************************
# TEST: pr_remove_existing_pkg_archives()
#******************************************************************************************************************************
ts_pk___pr_remove_existing_pkg_archives() {
    te_print_function_msg "pr_remove_existing_pkg_archives()"
    local _fn="ts_pk___pr_remove_existing_pkg_archives"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}/${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkg_archive
    local _targets=()

    # Make files
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

    touch "${_port_path1}/README"
    touch "${_port_path1}/test"
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    # check they really exist
    [[ -f "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    if (( ${?} )); then
        te_warn "_fn" "Test Error: did not find the created files."
    fi

    pr_remove_existing_pkg_archives _port_name1 _port_path1 _arch _pkg_ext

    (ut_in_array "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 1. pkg_archive file was removed."

    (ut_in_array "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 2. pkg_archive file was removed."

    (ut_in_array "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 3. pkg_archive file was removed."

    (ut_in_array "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 4. pkg_archive file (in subfolder) was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_remove_existing_pkg_archives


#******************************************************************************************************************************
# TEST: pr_remove_existing_backup_pkgfile()
#******************************************************************************************************************************
ts_pk___pr_remove_existing_backup_pkgfile() {
    te_print_function_msg "pr_remove_existing_backup_pkgfile()"
    local _fn="ts_pk___pr_remove_existing_backup_pkgfile"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _backup_pkgfile_path="${_pkgfile_path}.bak"

    # Make files
    touch "${_pkgfile_path}"
    cp -f "${_pkgfile_path}" "${_backup_pkgfile_path}"

    # check they really exist
    [[ -f "${_pkgfile_path}" && \
       -f "${_backup_pkgfile_path}" ]]
    if (( ${?} )); then
        te_warn "_fn" "Test Error: did not find the created files."
    fi

    pr_remove_existing_backup_pkgfile "${_pkgfile_path}"

    [[ -f "${_pkgfile_path}" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test original pkgfile still exits."

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test backup pkgfile was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_remove_existing_backup_pkgfile



#******************************************************************************************************************************
# TEST: pr_remove_downloaded_sources()
#******************************************************************************************************************************
ts_pk___pr_remove_downloaded_sources() {
    te_print_function_msg "pr_remove_downloaded_sources()"
    local _fn="ts_pk___pr_remove_downloaded_sources"
    local _tmp_dir=$(mktemp -d)
    local _ports_dir="${_tmp_dir}/ports"
    local _pkgfile_fullpath="${_tmp_dir}/${_ports_dir}/example_port/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -A _filter
    declare -i _n

    # Create files/folders
    mkdir -p "${_ports_dir}"
    mkdir -p "${_srcdst_dir}"
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_port" "${_tmp_dir}/ports"

    _scrmtx=()
    _sources=("ftp://dummy_uri.existing.files/dummy_source_file.tar.xz"
        "dummy_source_file2.tar.bz2::http://dummy_uri.existing.files/dummy_source_file-1.2.34.tar.bz2"
        "example_port.patch1")
    _checksums=("2987a55e31c80f189a2868ada1cf31df"
        "fd096ad1c3fa5975c5619488165c625b"
        "01530b8c0b67b5a2a2a46f4c5943a345")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null

    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    (pr_remove_downloaded_sources _scrmtx) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" || -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test the 2 source files are removed."

    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    _filter=(["ftp"]=0)
    (pr_remove_downloaded_sources _scrmtx _filter) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test the 1 source file which is in protocol _filter is removed."

    [[ -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test the 1 source file which is not in protocol _filter is kept."

    _filter=(["ftp"]=0 ["local"]=0)
    _output=$((pr_remove_downloaded_sources _scrmtx _filter) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <ftp local>"

    _scrmtx=()
    _output=$((pr_remove_downloaded_sources _scrmtx) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'"

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_remove_downloaded_sources


#******************************************************************************************************************************
# TEST: pr_update_pkgfile_pkgmd5sums()
#******************************************************************************************************************************
ts_pk___pr_update_pkgfile_pkgmd5sums() {
    te_print_function_msg "pr_update_pkgfile_pkgmd5sums()"
    local _fn="ts_pk___pr_update_pkgfile_pkgmd5sums"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _backup_pkgfile_path="${_pkgfile_path}.bak"
    local _new_pkgmd5sums=()

    # Make files
    cp -f "${_TEST_SCRIPT_DIR}/files/Pkgfile_dummy_package" "${_pkgfile_path}"

    # check the pkgfile really exist
    [[ -f "${_pkgfile_path}" ]]
    if (( ${?} )); then
        te_warn "_fn" "Test Error: did not find the created Pkgfile file."
    fi

    rm -f "${_backup_pkgfile_path}"
    _new_pkgmd5sums=("123456789" "SKIP" 987654321)
    pr_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test a backupfile was created:"
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COUNT_OK _COUNT_FAILED "${#pkgmd5sums[@]}" "3" "Test the size of the updated pkgmd5sums."
        te_same_val _COUNT_OK _COUNT_FAILED "${pkgmd5sums[0]}" "123456789" "Test updated pkgmd5sums index 0."
        te_same_val _COUNT_OK _COUNT_FAILED "${pkgmd5sums[1]}" "SKIP" "Test updated pkgmd5sums index 1."
        te_same_val _COUNT_OK _COUNT_FAILED "${pkgmd5sums[2]}" "987654321" "Test updated pkgmd5sums index 2."
    )

    _new_pkgmd5sums=()
    pr_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COUNT_OK _COUNT_FAILED "${#pkgmd5sums[@]}" "0" "Test the size of the updated pkgmd5sums."
    )

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pr_update_pkgfile_pkgmd5sums


#******************************************************************************************************************************

te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
