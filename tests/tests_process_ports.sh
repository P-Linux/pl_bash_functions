#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/../scripts"
_TESTFILE="process_ports.sh"

source "${_FUNCTIONS_DIR}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\"" "${_signal}"; done
trap "t_trap_i" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "t_trap_u" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

source "${_FUNCTIONS_DIR}/msg.sh"
m_format

source "${_FUNCTIONS_DIR}/util.sh"
u_source_safe_exit "${_FUNCTIONS_DIR}/src_matrix.sh"
u_source_safe_exit "${_FUNCTIONS_DIR}/pkgfile.sh"
u_source_safe_exit "${_FUNCTIONS_DIR}/archivefiles.sh"
u_source_safe_exit "${_FUNCTIONS_DIR}/process_ports.sh"

declare -i _COK=0
declare -i _CFAIL=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: p_make_pkg_build_dir()
#******************************************************************************************************************************
tsp__p_make_pkg_build_dir() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_make_pkg_build_dir()"
    local _tmp_dir=$(mktemp -d)
    local _pkg_build_dir _tmp_pkg_build_dir_file _tmp_srcdir_file _tmp_pkgdir_file

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test0"
    _output=$((p_make_pkg_build_dir) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 1 MUST NOT be empty."

    unset -v pkgdir srcdir
    _pkg_build_dir="${_tmp_dir}/test1"
    p_make_pkg_build_dir "${_pkg_build_dir}"
    te_retval_0 _COK _CFAIL _ret "Test p_make_pkg_build_dir return OK."

    [[ -n ${pkgdir} && -n ${srcdir} ]]
    te_retval_0 _COK _CFAIL $? "Test (pkgdir, srcdir) variables are set."

    [[ -d "${_pkg_build_dir}/pkg" && -d "${_pkg_build_dir}/src" ]]
    te_retval_0 _COK _CFAIL $? "Test (pkgdir, srcdir) exist."

    _tmp_pkg_build_dir_file="${_pkg_build_dir}/_tmp_pkg_build_dir_file"
    _tmp_pkgdir_file="${_pkg_build_dir}/pkg/_tmp_pkgdir_file"
    _tmp_srcdir_file="${_pkg_build_dir}/src/_tmp_pkgdir_file"
    touch "${_tmp_pkg_build_dir_file}"
    touch "${_tmp_pkgdir_file}"
    touch "${_tmp_srcdir_file}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retval_0 _COK _CFAIL $? "Test created files in: pkg_build_dir pkgdir and srcdir exist."

    unset -v pkgdir srcdir
    p_make_pkg_build_dir "${_pkg_build_dir}"
    [[ -f ${_tmp_pkg_build_dir_file} &&  -f ${_tmp_pkgdir_file} && -f ${_tmp_srcdir_file} ]]
    te_retval_1 _COK _CFAIL $? "Test existing _pkg_build_dir was really first deleted."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_make_pkg_build_dir


#******************************************************************************************************************************
# TEST: p_remove_pkgfile_backup()
#******************************************************************************************************************************
tsp__p_remove_pkgfile_backup() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_remove_pkgfile_backup()"
    local _fn="tsp__p_remove_pkgfile_backup"
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

    p_remove_pkgfile_backup "${_pkgfile_path}" &> /dev/null

    [[ -f "${_pkgfile_path}" ]]
    te_retval_0 _COK _CFAIL $? "Test original pkgfile still exits."

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retval_1 _COK _CFAIL $? "Test backup pkgfile was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_remove_pkgfile_backup


#******************************************************************************************************************************
# TEST: p_remove_downloaded_src()
#******************************************************************************************************************************
tsp__p_remove_downloaded_src() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_remove_downloaded_src()"
    local _fn="tsp__p_remove_downloaded_src"
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
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    (p_remove_downloaded_src _scrmtx) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" || -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retval_1 _COK _CFAIL $? "Test the 2 source files are removed."

    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    _filter=(["ftp"]=0)
    (p_remove_downloaded_src _scrmtx _filter) &> /dev/null
    [[ -f "${_srcdst_dir}/dummy_source_file.tar.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test the 1 source file which is in protocol _filter is removed."

    [[ -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]
    te_retval_0 _COK _CFAIL $? "Test the 1 source file which is not in protocol _filter is kept."

    _filter=(["ftp"]=0 ["local"]=0)
    _output=$((p_remove_downloaded_src _scrmtx _filter) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <ftp local>"

    _scrmtx=()
    _output=$((p_remove_downloaded_src _scrmtx) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_remove_downloaded_src


#******************************************************************************************************************************
# TEST: p_update_pkgfile_pkgmd5sums()
#******************************************************************************************************************************
tsp__p_update_pkgfile_pkgmd5sums() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_update_pkgfile_pkgmd5sums()"
    local _fn="tsp__p_update_pkgfile_pkgmd5sums"
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
    p_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums &> /dev/null

    [[ -f "${_backup_pkgfile_path}" ]]
    te_retval_0 _COK _CFAIL $? "Test a backupfile was created:"
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COK _CFAIL "${#pkgmd5sums[@]}" "3" "Test the size of the updated pkgmd5sums."
        te_same_val _COK _CFAIL "${pkgmd5sums[0]}" "123456789" "Test updated pkgmd5sums index 0."
        te_same_val _COK _CFAIL "${pkgmd5sums[1]}" "SKIP" "Test updated pkgmd5sums index 1."
        te_same_val _COK _CFAIL "${pkgmd5sums[2]}" "987654321" "Test updated pkgmd5sums index 2."
    )

    _new_pkgmd5sums=()
    p_update_pkgfile_pkgmd5sums "${_pkgfile_path}" _new_pkgmd5sums &> /dev/null
    (
        unset pkgmd5sums
        source "${_pkgfile_path}"

        te_same_val _COK _CFAIL "${#pkgmd5sums[@]}" "0" "Test the size of the updated pkgmd5sums."
    )

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_update_pkgfile_pkgmd5sums


#******************************************************************************************************************************
# TEST: p_update_port_repo_file()
#******************************************************************************************************************************
tsp__p_update_port_repo_file() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_update_port_repo_file()"
    local _fn="tsp__p_update_port_repo_file"
    local _tmp_dir=$(mktemp -d)
    local _collection_path="${_tmp_dir}/example_collection1"
    local _acl_portpath="${_collection_path}/acl"
    local _cpio_portpath="${_collection_path}/cpio"
    local  _required_func_names=("build")
    declare -A _cmk_groups_func_names=(["lib"]=0 ["devel"]=0 ["doc"]=0 ["man"]=0 ["service"]=0)
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _repo=".PKGREPO"
    declare -a _cmk_groups
    local _output _pkgfile_path _portname _portpath  _port_repo_file _repofile_content _ref_repofile_content

    # Make files
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_collection1" "${_collection_path}"

    _pkgfile_path="${_acl_portpath}/Pkgfile"
    _portname="acl"
    _portpath="${_acl_portpath}"
    _output=$((p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" \
        "${_repo}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}"\
        "Could not get expected Pkgfile variable! Hint: did you forget to source the pkgfile: <${_pkgfile_path}>"

    _cmk_groups=()
    _pkgfile_path="${_acl_portpath}/Pkgfile"
    _portname="acl"
    _portpath="${_acl_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    rm -f "${_port_repo_file}"
    if [[ -f ${_port_repo_file} ]]; then
        te_warn "_fn" "Test Error: 'acl' Port-Repo-File should have been removed."
    fi
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cmk_groups_func_names _cmk_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retval_0 _COK _CFAIL $? "Test 'acl' Port-Repo-File was created."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collection_path}/acl_ref.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retval_0 _COK _CFAIL $? "Test new Repo-File content is the same as the Reference Repo-file content."

    _cmk_groups=()
    _pkgfile_path="${_cpio_portpath}/Pkgfile"
    _portname="cpio"
    _portpath="${_cpio_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    rm -f "${_port_repo_file}"
    if [[ -f ${_port_repo_file} ]]; then
        te_warn "_fn" "Test Error: 'cpio' Port-Repo-File should have been removed."
    fi
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cmk_groups_func_names _cmk_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retval_0 _COK _CFAIL $? "Test 'cpio' Port-Repo-File was created."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collection_path}/cpio_ref.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retval_0 _COK _CFAIL $? "Test new Repo-File content is the same as the Reference Repo-file content."

    _cmk_groups=()
    _pkgfile_path="${_cpio_portpath}/Pkgfile"
    _portname="cpio"
    _portpath="${_cpio_portpath}"
    _port_repo_file="${_portpath}/${_repo}"
    # Remove first some files
    rm -f "${_cpio_portpath}/cpio.README"
    rm -f "${_cpio_portpath}/cpio.da1462741466any.cards.tar.xz"
    rm -f "${_cpio_portpath}/cpio.fi1462741466any.cards.tar.xz"
    rm -f "${_cpio_portpath}/cpio.nl1462741466any.cards.tar.xz"
    pk_source_validate_pkgfile "${_pkgfile_path}" _required_func_names _cmk_groups_func_names _cmk_groups
    p_update_port_repo_file "${_pkgfile_path}" "${_portname}" "${_portpath}" "${_arch}" "${_pkg_ext}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test p_update_port_repo_file function return value."

    [[ -f ${_port_repo_file} ]]
    te_retval_0 _COK _CFAIL $? "Test 'cpio' Port-Repo-File was created. Overwrite existing."
    _repofile_content=$(<"${_port_repo_file}")
    _ref_repofile_content=$(<"${_collection_path}/cpio_ref_removed_files.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retval_0 _COK _CFAIL $? \
        "Test new overwritten Repo-File content is the same as the Reference Repo-file content."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_update_port_repo_file


#******************************************************************************************************************************
# TEST: p_update_collection_repo_file()
#******************************************************************************************************************************
tsp__p_update_collection_repo_file() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_update_collection_repo_file()"
    local _fn="tsp__p_update_collection_repo_file"
    local _tmp_dir=$(mktemp -d)
    local _collection_path="${_tmp_dir}/example_collection1"
    local _acl_portpath="${_collection_path}/acl"
    local _cpio_portpath="${_collection_path}/cpio"
    local _repo=".PKGREPO"
    local _collection_repofile_path="${_collection_path}/${_repo}"
    local _portname _portpath _repofile_content _ref_repofile_content

    # Make files
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_collection1" "${_collection_path}"
    cp -f "${_collection_path}/acl_ref.PKGREPO" "${_acl_portpath}/${_repo}"
    cp -f "${_collection_path}/cpio_ref.PKGREPO" "${_cpio_portpath}/${_repo}"

    rm -f "${_collection_repofile_path}"

    _portname="acl"
    _portpath="${_acl_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test p_update_collection_repo_file function return value. New File."

    [[ -f ${_collection_repofile_path} ]]
    te_retval_0 _COK _CFAIL $? "Test Collection-Repo-File was created."

    _portname="cpio"
    _portpath="${_cpio_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test p_update_collection_repo_file function return value. Update File."

    _repofile_content=$(<"${_collection_repofile_path}")
    _ref_repofile_content=$(<"${_collection_path}/collection_ref1.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retval_0 _COK _CFAIL $? \
        "Test Collection-Repo-File content is the same as the Reference Collection1-Repo-file content."

    _portname="acl"
    _portpath="${_acl_portpath}"
    p_update_collection_repo_file "${_portname}" "${_portpath}" "${_repo}" &> /dev/null
    te_retval_0 _COK _CFAIL $? "Test update same port again."

    _repofile_content=$(<"${_collection_repofile_path}")
    _ref_repofile_content=$(<"${_collection_path}/collection_ref2.PKGREPO")
    [[ ${_repofile_content} == ${_ref_repofile_content} ]]
    te_retval_0 _COK _CFAIL $? \
        "Test Collection-Repo-File content is the same as the Reference Collection2-Repo-file content."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_update_collection_repo_file


#******************************************************************************************************************************
# TEST: p_strip_files()
#******************************************************************************************************************************
tsp__p_strip_files() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "p_strip_files()"
    local _fn="tsp__p_strip_files"
    local _tmp_dir=$(mktemp -d)

    # Create test files/folders
    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/example_to_strip.tar.xz"

    if ! [[ $(file -b "${_tmp_dir}/example_to_strip/attr/.libs/attr") == "ELF"*"executable"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/setfattr/.libs/setfattr") == "ELF"*"executable"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/libattr/.libs/libattr.so.1.1.0") == "ELF"*"shared object"*"not stripped" && \
        $(file -b "${_tmp_dir}/example_to_strip/getfattr/.libs/getfattr") == "ELF"*"executable"*"not stripped" ]]; then
        te_warn "${_fn}" "Test-Case setup error: Can not find 'not stripped' info."
    fi

    (p_strip_files "${_tmp_dir}")

    [[ $(file -b "${_tmp_dir}/example_to_strip/attr/.libs/attr") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/setfattr/.libs/setfattr") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/libattr/.libs/libattr.so.1.1.0") != *"not stripped"* && \
        $(file -b "${_tmp_dir}/example_to_strip/getfattr/.libs/getfattr") != *"not stripped"* ]]
    te_retval_0 _COK _CFAIL ${?} "Test 4 files: Seems to be stripped ok -  can not find: <not stripped>."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsp__p_strip_files



echo "TODO: TEST ARE MISSING FOR: pr_compress_man_info_pages()"


echo "TODO: TEST ARE MISSING FOR: p_build_archives()"



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
