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
te_print_header "download_sources.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format "${_THIS_SCRIPT_PATH}"

source "${_FUNCTIONS_DIR}/utilities.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/source_matrix.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/download_sources.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0

EXCHANGE_LOG=$(mktemp)

do_got_download_programs_abort


#******************************************************************************************************************************
# TEST: do_downloadable_source()
#******************************************************************************************************************************
ts_do___do_downloadable_source() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "ts_do___do_downloadable_source()"
    local _fn="ts_do___do_downloadable_source"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _output _sources _checksums _download_mirrors
    declare -A _scrmtx
    declare -A _protocol_filter
    declare -i _n

    # Create files/folders
    mkdir -p "$(dirname ${_pkgfile_fullpath})"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    _output=$((do_downloadable_source _scrmtx "yes") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'"

    _download_mirrors=()
    _protocol_filter=(["ftp"]=0 ["local"]=0)
    _output=$((do_downloadable_source _scrmtx  "yes" _download_mirrors _protocol_filter) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <ftp local>"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((do_downloadable_source _scrmtx "yes") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source correct checksum (verify checksum yes)."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    _protocol_filter=(["ftp"]=0 ["http"]=0)
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _output=$((do_downloadable_source _scrmtx "yes" _download_mirrors _protocol_filter) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test checksum verification but no download_mirrors."
    _destpath=${_scrmtx[1:DESTPATH]}

    rm -rf "${_destpath}"
    if [[ -f ${_destpath} ]]; then
        te_warn "${_fn}" "File should not exist for this test: <_destpath>"
    fi

    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    _protocol_filter=(["ftp"]=0)
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _output=$((do_downloadable_source _scrmtx "no" _download_mirrors _protocol_filter) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test protocol not in _protocol_filter."
    _destpath=${_scrmtx[1:DESTPATH]}
    [[ -f ${_destpath} ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED ${?} "Test protocol not in _protocol_filter.: file should not have been downloaded."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_downloadable_source


#******************************************************************************************************************************
# TEST: do_download_source() file general
#******************************************************************************************************************************
ts_do___do_download_source_file_general() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "ts_do___do_download_source_file_general()"
    local _fn="ts_do___do_download_source_file_general"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums _download_mirrors _download_prog _download_prog_opts
    declare -A _scrmtx
    declare -i _n

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source correct checksum (verify checksum yes)."

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Failed verifying checksum for existing ftp|http|https source file"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((do_download_source _scrmtx "no") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source wrong checksum (verify checksum no)."

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    if [[ ! -f "${_srcdst_dir}/md5sum_testfile.txt" ]]; then
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    [[ -f "${_srcdst_dir}/md5sum_testfile.txt" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test existing file source is removed when verify checksum failed."

    # wrong download program
    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _download_prog="rsync"
    _output=$((do_download_source _scrmtx "yes" _download_mirrors "${_download_prog}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Unsupported _download_prog: 'rsync'" \
        "Test Unsupported download program."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_file_general


#******************************************************************************************************************************
# TEST: do_download_source() local files
#******************************************************************************************************************************
ts_do___do_download_source_local_files() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() local files"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -i _n

    # Create the local source file
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "$(dirname ${_pkgfile_fullpath})/md5sum_testfile.txt"

    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Found local source file" \
        "Test existing local source correct checksum (verify checksum yes)."

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f09999")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Failed verifying checksum: local source file"

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f09999")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx "no") 2>&1)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "====> Found local source file" \
        "Test existing local source wrong checksum (verify checksum no)."

    _scrmtx=()
    _sources=("none_existing.patch")
    _checksums=("251aadc2351abf85b3dbfe7261f00000")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx "no") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Could not find local source file"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_local_files


#******************************************************************************************************************************
# TEST: do_download_source() file ftp
#******************************************************************************************************************************
ts_do___do_download_source_file_ftp() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() file ftp"
    local _fn="ts_do___do_download_source_file_ftp"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _output=$((do_download_source _scrmtx "yes" _download_mirror) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test checksum verification and download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test checksum verification but no download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    [[ ${_ret} == 0 && ${_output} == *"====> Found ftp|http|https source file"* ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test downloading existing file."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_file_ftp


#******************************************************************************************************************************
# TEST: do_download_source() file http
#******************************************************************************************************************************
ts_do___do_download_source_file_http() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() file http"
    local _fn="ts_do___do_download_source_file_http"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _sources _checksums _destpath
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _output=$((do_download_source _scrmtx "yes" _download_mirrors) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test checksum verification and download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _output=$((do_download_source _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test checksum verification but no download_mirrors."

    _scrmtx=()
    _sources=("NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz")
    _checksums=("e6a972d4e10d9e76407a432f4a63cd4c")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _destpath=${_scrmtx[1:DESTPATH]}

    rm -rf "${_destpath}"

    _download_mirrors=()
    _output=$((do_download_source _scrmtx "no" _download_mirrors) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test prefix rename file."
    [[ -f ${_destpath} ]]
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test prefix rename downloaded file actually exists."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_file_http


#******************************************************************************************************************************
# TEST: do_download_source() file https
#******************************************************************************************************************************
ts_do___do_download_source_file_https() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() file https"
    local _fn="ts_do___do_download_source_file_https"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _sources _checksums _download_prog _download_prog_opts
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("NOEXTRACT::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://none.existing.download/mirror_wrong/")
    _output=$((do_download_source _scrmtx "yes" _download_mirrors) 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test wrong download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("iproute.tar.xz::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _download_mirrors=()
    _download_prog="curl"
    _output=$((do_download_source _scrmtx "yes" _download_mirrors "${_download_prog}") 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test with download_prog curl."

    # use _srcdst_dir2 rename to iproute2
    _scrmtx=()
    _sources=("iproute2.tar.xz::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir2}" &> /dev/null
    _download_mirrors=()
    _download_prog="curl"
    _download_prog_opts="-q --fail --connect-timeout 3"
    _output=$((do_download_source _scrmtx "yes" _download_mirrors "${_download_prog}" "${_download_prog_opts}") 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COUNT_OK _COUNT_FAILED ${_ret} "Test with download_prog curl own _download_prog_opts."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_file_https


#******************************************************************************************************************************
# TEST: do_download_source() git
#******************************************************************************************************************************
ts_do___do_download_source_git() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() git"
    local _fn="ts_do___do_download_source_git"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"

    _sources=("git+https://github.com/should_not_exist_wrong/just_a_wrong_uri.git")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _COUNT_FAILED "Failed to access the git URI ${_off}Test wrong git uri."
    else
        te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Failed to access the git URI" "Test wrong git uri."
    fi

    _scrmtx=()
    _sources=("helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Cloning git repo into destpath*Cloning into bare repository"

    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Fetching (updating) git repo at destpath" \
        "Test Updating git repo."

    _scrmtx=()
    _sources=("helper_scripts::git+https://github.com/P-Linux/P-Linux-Logo.git")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local repo folder:*is not a clone of: <https://github.com/P-Linux/P-Linux-Logo.git>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_git


#******************************************************************************************************************************
# TEST: do_download_source() svn
#******************************************************************************************************************************
ts_do___do_download_source_svn() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() svn"
    local _fn="ts_do___do_download_source_svn"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"

    _sources=("svn+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _COUNT_FAILED "Failed to access the svn URI ${_off}Test wrong svn uri."
    else
        te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Failed to access the svn URI" "Test wrong svn uri."
    fi

    _scrmtx=()
    _sources=("portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#tag=10")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Unrecognized fragment: 'tag=10'. ENTRY: 'portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#tag=10'"

    _scrmtx=()
    _sources=("portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Checking-out svn repo into destpath"

    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Updating svn repo at destpath" \
        "Test Updating svn repo."

    _scrmtx=()
    _sources=("portsmf::svn://svn.code.sf.net/p/splix/code/splix")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of: <svn://svn.code.sf.net/p/splix/code/splix>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_svn


#******************************************************************************************************************************
# TEST: do_download_source() hg
#******************************************************************************************************************************
ts_do___do_download_source_hg() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() hg"
    local _fn="ts_do___do_download_source_hg"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"

    _sources=("hg+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _COUNT_FAILED "Failed to access the hg URI ${_off}Test wrong hg uri."
    else
        te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Failed to access the hg URI" "Test wrong hg uri."
    fi

    _scrmtx=()
    _sources=("hg-tutorial-hello::hg+https://bitbucket.org/bos/hg-tutorial-hello#revision=0a04b98")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Cloning hg repo into destpath"

    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Pulling (updating) hg repo at destpath" \
        "Test Updating hg repo."

    _scrmtx=()
    _sources=("hg-tutorial-hello::hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of: <http://linuxtv.org/hg/dvb-apps/>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_hg


#******************************************************************************************************************************
# TEST: do_download_source() bzr
#******************************************************************************************************************************
ts_do___do_download_source_bzr() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "do_download_source() bzr"
    local _fn="ts_do___do_download_source_bzr"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_fullpath="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_fullpath}")"
    touch "${_pkgfile_fullpath}"
    mkdir -p "${_srcdst_dir}"

    _sources=("bzr+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _COUNT_FAILED "Failed to access the bzr URI ${_off}Test wrong bzr uri."
    else
        te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "Not a branch" "Test wrong bzr uri."
    fi

    _scrmtx=()
    _sources=("gsettings-qt::bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Branching bzr repo into destpath"
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" "Pulling (updating) bzr repo at destpath" \
        "Test Updating bzr repo."

    _scrmtx=()
    _sources=("gsettings-qt::bzr+http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/#revision=1295")
    _checksums=("SKIP")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdst_dir}" &> /dev/null
    _output=$((do_download_source _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_do___do_download_source_bzr



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
