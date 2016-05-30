#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="extract.sh"

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
i_source_safe_exit "${_FUNCTIONS_DIR}/src_matrix.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/extract.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)

# check that we have the needed porgrams
_OUTPUT=$((e_got_extract_prog_exit) 2>&1)
(( ${?} )) && te_abort ${LINENO} "${_OUTPUT}"
unset _OUTPUT


#******************************************************************************************************************************
# TEST: e_extract_src() files abort
#******************************************************************************************************************************
tse__e_extract_src_files_abort() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() files abort"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="no"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    # Copy sources
    cp "${_TEST_SCRIPT_DIR}/files/bridge-utils_1.5-9.deb" "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    cp "${_TEST_SCRIPT_DIR}/files/corrupt_archive.tar.xz" "${_srcdst_dir}/corrupt_archive.tar.xz"

    _output=$((e_extract_src) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'e_extract_src()' Requires AT LEAST '2' arguments. Got '0'"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    _output=$((e_extract_src _scrmtx "" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'e_extract_src()' Argument '2' MUST NOT be empty."

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null

    _rm_build_dir="no"
    rm -rf "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "File source  not found" \
        "Test none existing file source abort (remove_build_dir no)."

    [[ -d ${_srcdir} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test none existing file source abort (remove_build_dir no): Check build_dir is kept."

    _rm_build_dir="yes"
    rm -rf "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "File source  not found*Removing path:" \
        "Test none existing file source abort (remove_build_dir yes)."

    [[ -d ${_srcdir} ]]
    te_retcode_1 _COK _CFAIL ${?} "Test none existing file source abort (remove_build_dir yes): Check build_dir is removed."

    _scrmtx=()
    rm -rf "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/corrupt_archive.tar.xz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _rm_build_dir="no"
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Failed to extract file" \
        "Test corrupted existing file source abort (remove_build_dir no)."

    [[ -d ${_srcdir} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test corrupted existing file source abort (remove_build_dir no): Check build_dir is kept."

    _rm_build_dir="yes"
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Failed to extract file*Removing path:" \
        "Test corrupted existing file source abort (remove_build_dir yes)."

    [[ -d ${_srcdir} ]]
    te_retcode_1 _COK _CFAIL ${?} \
        "Test corrupted existing file source abort (remove_build_dir yes): Check build_dir is removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_files_abort


#******************************************************************************************************************************
# TEST: e_extract_src() local files
#******************************************************************************************************************************
tse__e_extract_src_local_files() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() local files"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _tmp_dir2=$(mktemp -d)
    local _pkgfile_path2="${_tmp_dir2}/ports/dummy/Pkgfile"
    local _srcdst_dir2="${_tmp_dir2}/cards_mk/sources"
    local _srcdir2="${_tmp_dir2}/cards_mk/builds"
    local _output _sources _checksums _rm_build_dir
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "$(dirname ${_pkgfile_path})/md5sum_testfile.txt"

    mkdir -p "$(dirname ${_pkgfile_path2})"
    touch "${_pkgfile_path2}"
    mkdir -p "${_srcdst_dir2}"
    mkdir -p "${_srcdir2}"
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "$(dirname ${_pkgfile_path2})/md5sum_testfile.txt"

    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _rm_build_dir="yes"
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/md5sum_testfile.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test Local source final build-dir file exists."

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path2}" "${_srcdst_dir2}" &> /dev/null

    rm -rf "$(dirname ${_pkgfile_path2})/md5sum_testfile.txt"
    _rm_build_dir="no"
    _output=$((e_extract_src _scrmtx "${_srcdir2}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "File copy source not found" "Test Local source abort (remove_build_dir no)."

    [[ -d ${_srcdir2} ]]
    te_retcode_0 _COK _CFAIL ${?} "Test Local source abort (remove_build_dir no): Check build_dir is kept."

    _rm_build_dir="yes"
    _output=$((e_extract_src _scrmtx "${_srcdir2}" "${_rm_build_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "File copy source not found*Removing path" \
        "Test Local source final build-dir did not exist (remove_build_dir yes)."

    [[ -d ${_srcdir2} ]]
    te_retcode_1 _COK _CFAIL ${?} "Test Local source abort (remove_build_dir yes): Check build_dir was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
    rm -rf "${_tmp_dir2}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_local_files


#******************************************************************************************************************************
# TEST: e_extract_src() files normal extract
#******************************************************************************************************************************
tse__e_extract_src_files_normal_extract() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() files normal extract"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _output _sources _checksums _rm_build_dir
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    # Copy all
    cp -r "${_TEST_SCRIPT_DIR}/files/." "${_srcdst_dir}"

    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _rm_build_dir="yes"
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/md5sum_testfile.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test other (text) source file."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/dummy_file_tar.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.tar> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.bz2")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/dummy_file_tar_bz2.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.tar.bz2> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.gz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/dummy_file_tar_gz.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.tar.gz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.xz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/dummy_file_tar_xz.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.tar.xz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.zip")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/dummy_file_zip.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.zip> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/data.tar.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.deb> source file. Check extracted file (data.tar.xz) exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/bridge-utils-1.5-12.rpm")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/bridge-utils-1.0.4-inc.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.rpm> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.cpio")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/example_cpio.txt" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.cpio> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}"  || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.bz2")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/example-1.2.3" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.bz2> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.gz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/example-1.2.3" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.gz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "${_srcdir}" || te_abort ${LINENO} "Error wile removing _srcdir: <%s>" "${_srcdir}"
    mkdir -p "${_srcdir}"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.xz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/example-1.2.3" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test extract <.xz> source file. Check extracted file exists."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_files_normal_extract


#******************************************************************************************************************************
# TEST: e_extract_src() files NOEXTRACT
#******************************************************************************************************************************
tse__e_extract_src_files__noextract() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() files NOEXTRACT"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    # Copy sources
    cp "${_TEST_SCRIPT_DIR}/files/dummy_package-1.2.3.tar.bz2" "${_srcdst_dir}/dummy_package-1.2.3.tar.bz2"
    cp "${_TEST_SCRIPT_DIR}/files/example-1.2.3.xz" "${_srcdst_dir}/example-1.2.3.xz"

    _sources=("NOEXTRACT::http://dummy_uri.existing.files/dummy_package-1.2.3.tar.bz2")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -e "${_srcdir}/dummy_file_tar_bz2.txt" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test NOEXTRACT: <.tar.bz2> source file. Check extracted file DOES NOT exists."

    [[ -f "${_srcdir}/dummy_package-1.2.3.tar.bz2" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test NOEXTRACT: <.tar.bz2> source file. Check archive file exists in _srcdir."

    _scrmtx=()
    _sources=("NOEXTRACT::http://dummy_uri.existing.files/example-1.2.3.xz")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -e "${_srcdir}/example-1.2.3" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test NOEXTRACT: <.xz> source file. Check extracted file DOES NOT exists."

    [[ -f "${_srcdir}/example-1.2.3.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test NOEXTRACT: <.xz> source file. Check archive file exists in _srcdir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_files__noextract


#******************************************************************************************************************************
# TEST: e_extract_src() git
#******************************************************************************************************************************
tse__e_extract_src_git() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() git"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/git_pl_test_dummy.tar.xz"
    mv "${_srcdst_dir}/git_pl_test_dummy" "${_srcdst_dir}/git_renamed_test_dummy"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/git_pl_test_dummy.tar.xz"

    _sources=("git_renamed_test_dummy::git+https://github.com/P-Linux/pl_test_dummy.git")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/git_renamed_test_dummy/README.md" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test git source file exists in build_dir."

    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Switched to a new branch 'p-linux-work-branch'" \
        "Test git extract into existing: Switched to a new branch."
    [[ -f "${_srcdir}/git_renamed_test_dummy/README.md" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test git source: Switched to a new branch file exists in build_dir."

    _scrmtx=()
    _sources=("git_pl_test_dummy::git+https://github.com/P-Linux/pl_test_dummy.git#commit=12760e3")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/git_pl_test_dummy/README.md" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test git source with fragment (#commit=12760e3): file exists in build_dir."

    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Reset branch 'p-linux-work-branch" \
        "Test git source with fragment: extract into existing: Reset branch. "
    [[ -f "${_srcdir}/git_pl_test_dummy/README.md" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test git source with fragment: Reset branch file exists in build_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_git


#******************************************************************************************************************************
# TEST: e_extract_src() svn
#******************************************************************************************************************************
tse__e_extract_src_svn() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() svn"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="yes"
    local _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/svn_portsmf.tar.xz"

    _sources=("svn_portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/svn_portsmf/portSMF.pc.in" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test svn source file exists in build_dir."

    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/svn_portsmf/portSMF.pc.in" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test svn extract into existing: check file exists in build_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_svn


#******************************************************************************************************************************
# TEST: e_extract_src() hg
#******************************************************************************************************************************
tse__e_extract_src_hg() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() hg"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/hg-tutorial-hello.tar.xz"

    _sources=("hg-tutorial-hello::hg+https://bitbucket.org/bos/hg-tutorial-hello#revision=0a04b98")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "updating to branch default" "Test hg extract updating to branch default."

    [[ -f "${_srcdir}/hg-tutorial-hello/hello.c" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test hg source file exists in build_dir."

    _output=$((e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "pulling from"*"searching for changes" \
        "Test hg extract into existing: pulling from ...searching for changes."

    [[ -f "${_srcdir}/hg-tutorial-hello/hello.c" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test hg extract into existing: source file exists in build_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_hg


#******************************************************************************************************************************
# TEST: e_extract_src() bzr
#******************************************************************************************************************************
tse__e_extract_src_bzr() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_extract_src() bzr"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdir="${_tmp_dir}/cards_mk/builds"
    local _rm_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdir}"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/bzr_gsettings-qt.tar.xz"

    _sources=("bzr_gsettings-qt::bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/bzr_gsettings-qt/gsettings-qt.pro" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test bzr source file exists in build_dir."

    (e_extract_src _scrmtx "${_srcdir}" "${_rm_build_dir}") &> /dev/null
    [[ -f "${_srcdir}/bzr_gsettings-qt/gsettings-qt.pro" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test bzr extract into existing: source file exists in build_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tse__e_extract_src_bzr


#******************************************************************************************************************************
# TEST: e_export()
#******************************************************************************************************************************
tsi__e_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "e_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((e_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((e_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        e_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx e_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx e_export'."

        _BF_EXPORT_ALL="no"
        e_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f e_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f e_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__e_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 52
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
