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
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"$_signal\"" "$_signal"; done
trap "tr_trap_exit_interrupted" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "tr_trap_exit_unknown_error" ERR

source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "extract_sources.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

source "${_FUNCTIONS_DIR}/utilities.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/source_matrix.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/extract_sources.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0


do_got_extract_programs_abort


#******************************************************************************************************************************
# TEST: ex_extract_source() files abort
#******************************************************************************************************************************
ts_ex___ex_extract_source_files_abort() {
    te_print_function_msg "ex_extract_source() files abort"
    local _fn="ts_ex___ex_extract_source_files_abort"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _output _sources _checksums _remove_build_dir
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    # Copy sources
    cp "$(dirname $_THIS_SCRIPT_PATH)/files/bridge-utils_1.5-9.deb" "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    cp "$(dirname $_THIS_SCRIPT_PATH)/files/corrupt_archive.tar.xz" "${_srcdst_dir}/corrupt_archive.tar.xz"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    _output=$((ex_extract_source _scrmtx "" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FUNCTION: 'ex_extract_source()' Argument '2': MUST NOT be empty"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null

    _remove_build_dir="no"
    rm -rf "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_file>"*"File source  not found" \
        "Test none existing file source abort (remove_build_dir no)."

    [[ -d $_build_srcdir ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? \
        "Test none existing file source abort (remove_build_dir no): Check build_dir is kept."

    _remove_build_dir="yes"
    rm -rf "${_srcdst_dir}/bridge-utils_1.5-9.deb"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_file>"*"File source  not found" \
        "Test none existing file source abort (remove_build_dir yes)."

    [[ -d $_build_srcdir ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? \
        "Test none existing file source abort (remove_build_dir yes): Check build_dir is removed."

    _scrmtx=()
    rm -rf "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/corrupt_archive.tar.xz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    _remove_build_dir="no"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_file>"*"Failed to extract file" \
        "Test corrupted existing file source abort (remove_build_dir no)."

    [[ -d $_build_srcdir ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? \
        "Test corrupted existing file source abort (remove_build_dir no): Check build_dir is kept."

    _remove_build_dir="yes"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_file>"*"Failed to extract file" \
        "Test corrupted existing file source abort (remove_build_dir yes)."

    [[ -d $_build_srcdir ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? \
        "Test corrupted existing file source abort (remove_build_dir yes): Check build_dir is removed."

    # CLEAN UP
    rm -rf "$_tmp_dir"
}
ts_ex___ex_extract_source_files_abort


#******************************************************************************************************************************
# TEST: ex_extract_source() local files
#******************************************************************************************************************************
ts_ex___ex_extract_source_local_files() {
    te_print_function_msg "ex_extract_source() local files"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _tmp_dir2=$(mktemp -d)
    local _pkgfile_fullpath2="${_tmp_dir2}/ports/dummy/Pkgfile"
    local _srcdst_dir2="${_tmp_dir2}/cards_mk/sources"
    local _build_srcdir2="${_tmp_dir2}/cards_mk/builds"
    local _output _sources _checksums _remove_build_dir
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    cp -f "$(dirname $_THIS_SCRIPT_PATH)/files/md5sum_testfile.txt" \
        "$(dirname $_pkgfile_fullpath)/md5sum_testfile.txt"

    mkdir -p "$(dirname $_pkgfile_fullpath2)"
    touch "$_pkgfile_fullpath2"
    mkdir -p "$_srcdst_dir2"
    mkdir -p "$_build_srcdir2"
    cp -f "$(dirname $_THIS_SCRIPT_PATH)/files/md5sum_testfile.txt" \
        "$(dirname $_pkgfile_fullpath2)/md5sum_testfile.txt"

    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null

    _remove_build_dir="yes"
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/md5sum_testfile.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Local source final build-dir file exists."

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath2" "$_srcdst_dir2" &> /dev/null

    rm -rf "$(dirname $_pkgfile_fullpath2)/md5sum_testfile.txt"
    _remove_build_dir="no"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir2" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_only_copy>"*"File copy source  not found" \
        "Test Local source abort (remove_build_dir no)."

    [[ -d $_build_srcdir2 ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? \
        "Test Local source abort (remove_build_dir no): Check build_dir is kept."

    _remove_build_dir="yes"
    _output=$((ex_extract_source _scrmtx "$_build_srcdir2" "$_remove_build_dir") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "ABORTING....from:"*"<ex_extract_only_copy>"*"INFO: Removing path" \
        "Test Local source final build-dir did not exist (remove_build_dir yes)."

    [[ -d $_build_srcdir2 ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? \
        "Test Local source abort (remove_build_dir yes): Check build_dir was removed."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    rm -rf "$_tmp_dir2"
    echo
}
ts_ex___ex_extract_source_local_files


#******************************************************************************************************************************
# TEST: ex_extract_source() files normal extract
#******************************************************************************************************************************
ts_ex___ex_extract_source_files_normal_extract() {
    te_print_function_msg "ex_extract_source() files normal extract"
    local _fn="ts_ex___ex_extract_source_files_normal_extract"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _output _sources _checksums _remove_build_dir
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    # Copy all
    cp -r "$(dirname $_THIS_SCRIPT_PATH)/files/." "$_srcdst_dir"

    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    _remove_build_dir="yes"
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/md5sum_testfile.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test other (text) source file."

    _scrmtx=()
    rm -rf "$_build_srcdir" || "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/dummy_file_tar.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.tar> source file. Check extracted file exists."


    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.bz2")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/dummy_file_tar_bz2.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.tar.bz2> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.gz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/dummy_file_tar_gz.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.tar.gz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.tar.xz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/dummy_file_tar_xz.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.tar.xz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/dummy_package-1.2.3.zip")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/dummy_file_zip.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.zip> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/bridge-utils_1.5-9.deb")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/data.tar.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.deb> source file. Check extracted file (data.tar.xz) exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/bridge-utils-1.5-12.rpm")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/bridge-utils-1.0.4-inc.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.rpm> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.cpio")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/example_cpio.txt" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.cpio> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir"  || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.bz2")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/example-1.2.3" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.bz2> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.gz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/example-1.2.3" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.gz> source file. Check extracted file exists."

    _scrmtx=()
    rm -rf "$_build_srcdir" || ms_abort "$_fn" "Error wile removing _build_srcdir: <%s>" "$_build_srcdir"
    mkdir -p "$_build_srcdir"
    _sources=("http://dummy_uri.existing.files/example-1.2.3.xz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/example-1.2.3" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test extract <.xz> source file. Check extracted file exists."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ex___ex_extract_source_files_normal_extract


#******************************************************************************************************************************
# TEST: ex_extract_source() files NOEXTRACT
#******************************************************************************************************************************
ts_ex___ex_extract_source_files__noextract() {
    te_print_function_msg "ex_extract_source() files NOEXTRACT"
    local _fn="ts_ex___ex_extract_source_files__noextract"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _remove_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source file
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    # Copy sources
    cp "$(dirname $_THIS_SCRIPT_PATH)/files/dummy_package-1.2.3.tar.bz2" \
        "${_srcdst_dir}/dummy_package-1.2.3.tar.bz2"
    cp "$(dirname $_THIS_SCRIPT_PATH)/files/example-1.2.3.xz" "${_srcdst_dir}/example-1.2.3.xz"

    _sources=("NOEXTRACT::http://dummy_uri.existing.files/dummy_package-1.2.3.tar.bz2")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -e "${_build_srcdir}/dummy_file_tar_bz2.txt" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test NOEXTRACT: <.tar.bz2> source file. Check extracted file DOES NOT exists."

    [[ -f "${_build_srcdir}/dummy_package-1.2.3.tar.bz2" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? \
        "Test NOEXTRACT: <.tar.bz2> source file. Check archive file exists in _build_srcdir."

    _scrmtx=()
    _sources=("NOEXTRACT::http://dummy_uri.existing.files/example-1.2.3.xz")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -e "${_build_srcdir}/example-1.2.3" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test NOEXTRACT: <.xz> source file. Check extracted file DOES NOT exists."

    [[ -f "${_build_srcdir}/example-1.2.3.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test NOEXTRACT: <.xz> source file. Check archive file exists in _build_srcdir."

    # CLEAN UP
    rm -rf "$_tmp_dir"
}
ts_ex___ex_extract_source_files__noextract


#******************************************************************************************************************************
# TEST: ex_extract_source() git
#******************************************************************************************************************************
ts_ex___ex_extract_source_git() {
    te_print_function_msg "ex_extract_source() git"
    local _fn="ts_ex___ex_extract_source_git"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _remove_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    bsdtar -p -C "${_srcdst_dir}/" -xf "$(dirname $_THIS_SCRIPT_PATH)/files/git_pl_test_dummy.tar.xz"
    mv "${_srcdst_dir}/git_pl_test_dummy" "${_srcdst_dir}/git_renamed_test_dummy"
    bsdtar -p -C "${_srcdst_dir}/" -xf "$(dirname $_THIS_SCRIPT_PATH)/files/git_pl_test_dummy.tar.xz"

    _sources=("git_renamed_test_dummy::git+https://github.com/P-Linux/pl_test_dummy.git")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/git_renamed_test_dummy/README.md" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test git source file exists in build_dir."

    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "Switched to a new branch 'p-linux-work-branch'" \
        "Test git extract into existing: Switched to a new branch."
    [[ -f "${_build_srcdir}/git_renamed_test_dummy/README.md" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test git source: Switched to a new branch file exists in build_dir."

    _scrmtx=()
    _sources=("git_pl_test_dummy::git+https://github.com/P-Linux/pl_test_dummy.git#commit=12760e3")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/git_pl_test_dummy/README.md" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test git source with fragment (#commit=12760e3): file exists in build_dir."

    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "Reset branch 'p-linux-work-branch" \
        "Test git source with fragment: extract into existing: Reset branch. "

    [[ -f "${_build_srcdir}/git_pl_test_dummy/README.md" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test git source with fragment: Reset branch file exists in build_dir."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ex___ex_extract_source_git


#******************************************************************************************************************************
# TEST: ex_extract_source() svn
#******************************************************************************************************************************
ts_ex___ex_extract_source_svn() {
    te_print_function_msg "ex_extract_source() svn"
    local _fn="ts_ex___ex_extract_source_svn"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _remove_build_dir="yes"
    local _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    bsdtar -p -C "${_srcdst_dir}/" -xf "$(dirname $_THIS_SCRIPT_PATH)/files/svn_portsmf.tar.xz"

    _sources=("svn_portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/svn_portsmf/portSMF.pc.in" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test svn source file exists in build_dir."

    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/svn_portsmf/portSMF.pc.in" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test svn extract into existing: check file exists in build_dir."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ex___ex_extract_source_svn


#******************************************************************************************************************************
# TEST: ex_extract_source() hg
#******************************************************************************************************************************
ts_ex___ex_extract_source_hg() {
    te_print_function_msg "ex_extract_source() hg"
    local _fn="ts_ex___ex_extract_source_hg"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _remove_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    bsdtar -p -C "${_srcdst_dir}/" -xf "$(dirname $_THIS_SCRIPT_PATH)/files/hg-tutorial-hello.tar.xz"

    _sources=("hg-tutorial-hello::hg+https://bitbucket.org/bos/hg-tutorial-hello#revision=0a04b98")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null
    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "updating to branch default" \
        "Test hg extract updating to branch default."

    [[ -f "${_build_srcdir}/hg-tutorial-hello/hello.c" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test hg source file exists in build_dir."

    _output=$((ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "$_output" "pulling from"*"searching for changes" \
        "Test hg extract into existing: pulling from ...searching for changes."

    [[ -f "${_build_srcdir}/hg-tutorial-hello/hello.c" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test hg extract into existing: source file exists in build_dir."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ex___ex_extract_source_hg


#******************************************************************************************************************************
# TEST: ex_extract_source() bzr
#******************************************************************************************************************************
ts_ex___ex_extract_source_bzr() {
    te_print_function_msg "ex_extract_source() bzr"
    local _fn="ts_ex___ex_extract_source_bzr"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _build_srcdir="${_tmp_dir}/cards_mk/builds"
    local _remove_build_dir="yes"
    local _output _sources _checksums
    declare -A _scrmtx

    # Create the local source
    mkdir -p "$(dirname "$_pkgfile_fullpath")"
    touch "$_pkgfile_fullpath"
    mkdir -p "$_srcdst_dir"
    mkdir -p "$_build_srcdir"
    bsdtar -p -C "${_srcdst_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/bzr_gsettings-qt.tar.xz"

    _sources=("bzr_gsettings-qt::bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "$_pkgfile_fullpath" "$_srcdst_dir" &> /dev/null

    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/bzr_gsettings-qt/gsettings-qt.pro" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test bzr source file exists in build_dir."

    (ex_extract_source _scrmtx "$_build_srcdir" "$_remove_build_dir") &> /dev/null
    [[ -f "${_build_srcdir}/bzr_gsettings-qt/gsettings-qt.pro" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test bzr extract into existing: source file exists in build_dir."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_ex___ex_extract_source_bzr



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
