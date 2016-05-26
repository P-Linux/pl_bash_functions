#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="process_ports.sh"

source "${_FUNCTIONS_DIR}/init_conf.sh"
_BF_ON_ERROR_KILL_PROCESS=0     # Set the sleep seconds before killing all related processes or to less than 1 to skip it

for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
trap 'i_trap_i ${?}' INT
# For testing don't use error traps: as we expect failed tests - otherwise we would need to adjust all
#trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR

i_source_safe_exit "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

i_source_safe_exit "${_FUNCTIONS_DIR}/util.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/src_matrix.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/pkgfile.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/archivefiles.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/process_ports.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: p_make_pkg_build_dir()
#******************************************************************************************************************************
tsp__p_make_pkg_build_dir() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_make_pkg_build_dir()"
    local _tmp_dir=$(mktemp -d)
    local _pkg_build_dir _tmp_pkg_build_dir_file _tmp_srcdir_file _tmp_pkgdir_file

    unset -v pkgdir srcdir
    _output=$((p_make_pkg_build_dir) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '1' argument. Got '0'"

    unset -v pkgdir srcdir
    _output=$((p_make_pkg_build_dir "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument '1' MUST NOT be empty"

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test1"
    p_make_pkg_build_dir "${_pkg_build_dir}"
    te_retcode_0 _COK _CFAIL ${?} "Test p_make_pkg_build_dir return OK."

    [[ -n ${pkgdir} && -n ${srcdir} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test (pkgdir, srcdir) variables are set."

    [[ -d "${_pkg_build_dir}/pkg" && -d "${_pkg_build_dir}/src" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test (pkgdir, srcdir) exist."

    _tmp_pkg_build_dir_file="${_pkg_build_dir}/_tmp_pkg_build_dir_file"
    _tmp_pkgdir_file="${_pkg_build_dir}/pkg/_tmp_pkgdir_file"
    _tmp_srcdir_file="${_pkg_build_dir}/src/_tmp_pkgdir_file"
    touch "${_tmp_pkg_build_dir_file}"
    touch "${_tmp_pkgdir_file}"
    touch "${_tmp_srcdir_file}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test created files in: pkg_build_dir pkgdir and srcdir exist."

    unset -v pkgdir srcdir
    p_make_pkg_build_dir "${_pkg_build_dir}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retcode_1 _COK _CFAIL ${?} "Test existing _pkg_build_dir was really first deleted."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_make_pkg_build_dir


#******************************************************************************************************************************
# TEST: p_remove_downloaded_src()
#******************************************************************************************************************************
tsp__p_remove_downloaded_src() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_remove_downloaded_src()"
    local _tmp_dir=$(mktemp -d)
    local _ports_dir="${_tmp_dir}/ports"
    local _pkgfile_path="${_ports_dir}/example_port/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -A _filter
    declare -i _n

    # Create files/folders
    mkdir -p "${_ports_dir}"
    mkdir -p "${_srcdst_dir}"
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_port" "${_ports_dir}"

    _output=$((p_remove_downloaded_src) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '1' argument. Got '0'"

    _filter=(["ftp"]=0 ["local"]=0)
    _output=$((p_remove_downloaded_src _scrmtx _filter) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <ftp local>"

    _scrmtx=()
    _output=$((p_remove_downloaded_src _scrmtx) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    _scrmtx=()
    _sources=("ftp://dummy_uri.existing.files/dummy_source_file.tar.xz"
        "dummy_source_file2.tar.bz2::http://dummy_uri.existing.files/dummy_source_file-1.2.34.tar.bz2"
        "example_port.patch1")
    _checksums=("2987a55e31c80f189a2868ada1cf31df"
        "fd096ad1c3fa5975c5619488165c625b"
        "01530b8c0b67b5a2a2a46f4c5943a345")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null

    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${FUNCNAME[0]}" "Can not find the expected testfile for this test-case."
    fi
    (p_remove_downloaded_src _scrmtx) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" || -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test the 2 source files are removed."

    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${FUNCNAME[0]}" "Can not find the expected testfile for this test-case."
    fi
    _filter=(["ftp"]=0)
    (p_remove_downloaded_src _scrmtx _filter) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test the 1 source file which is in protocol _filter is removed."

    [[ -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test the 1 source file which is not in protocol _filter is kept."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_remove_downloaded_src


#******************************************************************************************************************************
# TEST: p_remove_pkgfile_backup()
#******************************************************************************************************************************
tsp__p_remove_pkgfile_backup() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_remove_pkgfile_backup()"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _backup_pkgfile_path="${_pkgfile_path}.bak"

    _output=$((p_remove_pkgfile_backup) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '1' argument. Got '0'"

    # Make files
    touch "${_pkgfile_path}"
    cp -f "${_pkgfile_path}" "${_backup_pkgfile_path}"

    # check they really exist
    [[ -f "${_pkgfile_path}" && \
       -f "${_backup_pkgfile_path}" ]]
    if (( ${?} )); then
        te_warn "${FUNCNAME[0]}" "Test Error: did not find the created files."
    fi

    p_remove_pkgfile_backup "${_pkgfile_path}" &> /dev/null

    [[ -f "${_pkgfile_path}" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test original pkgfile still exits."

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test backup pkgfile was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_remove_pkgfile_backup


#******************************************************************************************************************************
# TEST: p_update_pkgfile_pkgmd5sums()
#******************************************************************************************************************************
tsp__p_update_pkgfile_pkgmd5sums() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_update_pkgfile_pkgmd5sums()"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _backup_pkgfile_path="${_pkgfile_path}.bak"
    local _new_pkgmd5sums=()

    # Make files
    cp -f "${_TEST_SCRIPT_DIR}/files/Pkgfile_dummy_package" "${_pkgfile_path}"

    # check the pkgfile really exist
    [[ -f "${_pkgfile_path}" ]]
    if (( ${?} )); then
        te_warn "${FUNCNAME[0]}" "Test Error: did not find the created Pkgfile file."
    fi

    _output=$((p_update_pkgfile_pkgmd5sums) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '2' argument. Got '0'"

    rm -f "${_backup_pkgfile_path}"
    _new_pkgmd5sums=("123456789" "SKIP" 987654321)
    p_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums &> /dev/null

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test a backupfile was created:"
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COK _CFAIL "${#pkgmd5sums[@]}" "3" "Test the size of the updated pkgmd5sums."
        te_same_val _COK _CFAIL "${pkgmd5sums[0]}" "123456789" "Test updated pkgmd5sums index 0."
        te_same_val _COK _CFAIL "${pkgmd5sums[1]}" "SKIP" "Test updated pkgmd5sums index 1."
        te_same_val _COK _CFAIL "${pkgmd5sums[2]}" "987654321" "Test updated pkgmd5sums index 2."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"

    _new_pkgmd5sums=()
    p_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums &> /dev/null
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COK _CFAIL "${#pkgmd5sums[@]}" "0" "Test the size of the updated pkgmd5sums."
        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_update_pkgfile_pkgmd5sums


#******************************************************************************************************************************
# TEST: p_update_port_repo_file()
#******************************************************************************************************************************
tsp__p_update_port_repo_file() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_update_port_repo_file()"
    local _tmp_dir=$(mktemp -d)
    local _collectionpath="${_tmp_dir}/example_collection1"
    local _acl_portpath="${_collectionpath}/acl"
    local _cpio_portpath="${_collectionpath}/cpio"
    local  _required_func_names=("build")
    declare -A _cm_groups_func_names=(["lib"]=0 ["devel"]=0 ["doc"]=0 ["man"]=0 ["service"]=0)
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _repo=".PKGREPO"
    declare -a _cm_groups CM_PORTNAME
    local _output _pkgfile_path _portname _portpath  _port_repo_file _repofile_content _ref_repofile_content

    # Make files
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_collection1" "${_collectionpath}"

    #_output=$((p_update_port_repo_file) 2>&1)
    #te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '6' arguments. Got '0'"

    _pkgfile_path="${_acl_portpath}/Pkgfile"
    _portname="acl"
    _portpath="${_acl_portpath}"

    _output=$((p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" \
        "${_repo}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}"\
        "Could not get expected Pkgfile variable 'pkgpackager'! Hint: did you forget to source the pkgfile: <${_pkgfile_path}>"

    _cm_groups=()
    _pkgfile_path="${_acl_portpath}/Pkgfile"
    _portname="acl"
    _portpath="${_acl_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    CM_PORTNAME="${_portname}"  # just to avoid CM_PORTNAME: unbound variable for the test case
    rm -f "${_port_repo_file}"
    if [[ -f ${_port_repo_file} ]]; then
        te_warn "${FUNCNAME[0]}" "Test Error: 'acl' Port-Repo-File should have been removed."
    fi
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cm_groups_func_names _cm_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 'acl' Port-Repo-File was created."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collectionpath}/acl_ref.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test new Repo-File content is the same as the Reference Repo-file content."

    _cm_groups=()
    _pkgfile_path="${_cpio_portpath}/Pkgfile"
    _portname="cpio"
    _portpath="${_cpio_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    rm -f "${_port_repo_file}"
    if [[ -f ${_port_repo_file} ]]; then
        te_warn "${FUNCNAME[0]}" "Test Error: 'cpio' Port-Repo-File should have been removed."
    fi
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cm_groups_func_names _cm_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 'cpio' Port-Repo-File was created."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collectionpath}/cpio_ref.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test new Repo-File content is the same as the Reference Repo-file content."

    _cm_groups=()
    _pkgfile_path="${_cpio_portpath}/Pkgfile"
    _portname="cpio"
    _portpath="${_cpio_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    # Remove first some files
    rm -f "${_cpio_portpath}/cpio.README"
    rm -f "${_cpio_portpath}/cpio.da1462741466any.cards.tar.xz"
    rm -f "${_cpio_portpath}/cpio.fi1462741466any.cards.tar.xz"
    rm -f "${_cpio_portpath}/cpio.nl1462741466any.cards.tar.xz"
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cm_groups_func_names _cm_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 'cpio' Port-Repo-File was created. Overwrite existing."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collectionpath}/cpio_ref_removed_files.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test new overwritten Repo-File content is the same as the Reference Repo-file content."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_update_port_repo_file


#******************************************************************************************************************************
# TEST: p_update_collection_repo_file()
#******************************************************************************************************************************
tsp__p_update_collection_repo_file() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_update_collection_repo_file()"
    local _tmp_dir=$(mktemp -d)
    local _collectionpath="${_tmp_dir}/example_collection1"
    local _acl_portpath="${_collectionpath}/acl"
    local _cpio_portpath="${_collectionpath}/cpio"
    local _repo=".PKGREPO"
    local _collection_repofile_path="${_collectionpath}/${_repo}"
    local _portname _portpath _repofile_content _ref_repofile_content

    # Make files
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_collection1" "${_collectionpath}"
    cp -f "${_collectionpath}/acl_ref.PKGREPO" "${_acl_portpath}/${_repo}"
    cp -f "${_collectionpath}/cpio_ref.PKGREPO" "${_cpio_portpath}/${_repo}"

    rm -f "${_collection_repofile_path}"

    _output=$((p_update_collection_repo_file) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '4' arguments. Got '0'"

    _portname="acl"
    _portpath="${_acl_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_collectionpath}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test p_update_collection_repo_file function return value. New File."

    [[ -f ${_collection_repofile_path} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test Collection-Repo-File was created."

    _portname="cpio"
    _portpath="${_cpio_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_collectionpath}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test p_update_collection_repo_file function return value. Update File."

    _repofile_content=$(<"${_collection_repofile_path}")
    _ref_repofile_content=$(<"${_collectionpath}/collection_ref1.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retcode_0 _COK _CFAIL ${?} \
        "Test Collection-Repo-File content is the same as the Reference Collection1-Repo-file content."

    _portname="acl"
    _portpath="${_acl_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_collectionpath}" "${_repo}" &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test update same port again."

    _repofile_content=$(<"${_collection_repofile_path}")
    _ref_repofile_content=$(<"${_collectionpath}/collection_ref2.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retcode_0 _COK _CFAIL ${?} \
        "Test Collection-Repo-File content is the same as the Reference Collection2-Repo-file content."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_update_collection_repo_file


#******************************************************************************************************************************
# TEST: p_strip_files()
#******************************************************************************************************************************
tsp__p_strip_files() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "p_strip_files()"
    local _tmp_dir=$(mktemp -d)
    local _output
    
    _output=$((p_strip_files) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '1' arguments. Got '0'"
    
    # Create test files/folders
    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/example_to_strip.tar.xz"

    if ! [[ $(file -b "${_tmp_dir}/example_to_strip/attr/.libs/attr") == "ELF"*"executable"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/setfattr/.libs/setfattr") == "ELF"*"executable"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/libattr/.libs/libattr.so.1.1.0") == "ELF"*"shared object"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/getfattr/.libs/getfattr") == "ELF"*"executable"*"not stripped" ]]; then
        te_warn "${FUNCNAME[0]}" "Test-Case setup error: Can not find 'not stripped' info."
    fi

    (p_strip_files "${_tmp_dir}")

    [[ $(file -b "${_tmp_dir}/example_to_strip/attr/.libs/attr") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/setfattr/.libs/setfattr") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/libattr/.libs/libattr.so.1.1.0") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/getfattr/.libs/getfattr") != *"not stripped"* ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 4 files: Seems to be stripped ok -  can not find: <not stripped>."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsp__p_strip_files

echo
echo
echo
echo "TODO: TEST ARE MISSING FOR: pr_compress_man_info_pages()"


echo "TODO: TEST ARE MISSING FOR: p_build_archives()"



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
