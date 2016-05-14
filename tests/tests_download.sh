#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/../scripts"
_TESTFILE="download.sh"

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
u_source_safe_exit "${_FUNCTIONS_DIR}/download.sh"

declare -i _COK=0
declare -i _CFAIL=0

EXCHANGE_LOG=$(mktemp)

d_got_download_prog_exit


# Skip tests for: d_exit_diff_origin

#******************************************************************************************************************************
# TEST: d_downloadable_src()
#******************************************************************************************************************************
tsd__d_downloadable_src() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "tsd__d_downloadable_src()"
    local _fn="tsd__d_downloadable_src"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _output _sources _checksums _download_mirrors
    declare -A _scrmtx
    declare -A _protocol_filter
    declare -i _n

    # Create files/folders
    mkdir -p "$(dirname ${_pkgfile_path})"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    _output=$((d_downloadable_src _scrmtx "yes") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    _download_mirrors=()
    _protocol_filter=(["ftp"]=0 ["local"]=0)
    _output=$((d_downloadable_src _scrmtx  "yes" _download_mirrors _protocol_filter) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <ftp local>"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((d_downloadable_src _scrmtx "yes") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source correct checksum (verify checksum yes)."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    _protocol_filter=(["ftp"]=0 ["http"]=0)
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _output=$((d_downloadable_src _scrmtx "yes" _download_mirrors _protocol_filter) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test checksum verification but no download_mirrors."
    _destpath=${_scrmtx[1:DESTPATH]}

    rm -rf "${_destpath}"
    if [[ -f ${_destpath} ]]; then
        te_warn "${_fn}" "File should not exist for this test: <_destpath>"
    fi

    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    _protocol_filter=(["ftp"]=0)
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _output=$((d_downloadable_src _scrmtx "no" _download_mirrors _protocol_filter) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test protocol not in _protocol_filter."
    _destpath=${_scrmtx[1:DESTPATH]}
    [[ -f ${_destpath} ]]
    te_retval_1 _COK _CFAIL ${?} "Test protocol not in _protocol_filter.: file should not have been downloaded."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_downloadable_src


#******************************************************************************************************************************
# TEST: d_download_src() file general
#******************************************************************************************************************************
tsd__d_download_src_file_general() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "tsd__d_download_src_file_general()"
    local _fn="tsd__d_download_src_file_general"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums _download_mirrors _download_prog _download_prog_opts
    declare -A _scrmtx
    declare -i _n

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}"\
        "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source correct checksum (verify checksum yes)."

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Failed verifying checksum for existing ftp|http|https source file"

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _output=$((d_download_src _scrmtx "no") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "====> Found ftp|http|https source file" \
        "Test existing file source wrong checksum (verify checksum no)."

    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    if [[ ! -f "${_srcdst_dir}/md5sum_testfile.txt" ]]; then
        te_warn "${_fn}" "Can not find the expected testfile for this test-case."
    fi
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    [[ -f "${_srcdst_dir}/md5sum_testfile.txt" ]]
    te_retval_1 _COK _CFAIL $? "Test existing file source is removed when verify checksum failed."

    # wrong download program
    _scrmtx=()
    _sources=("http://dummy_uri.existing.files/md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06217")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "${_srcdst_dir}/md5sum_testfile.txt"
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _download_prog="rsync"
    _output=$((d_download_src _scrmtx "yes" _download_mirrors "${_download_prog}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Unsupported _download_prog: 'rsync'" \
        "Test Unsupported download program."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_file_general


#******************************************************************************************************************************
# TEST: d_download_src() local files
#******************************************************************************************************************************
tsd__d_download_src_local_files() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() local files"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -i _n

    # Create the local source file
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    cp -f "${_TEST_SCRIPT_DIR}/files/md5sum_testfile.txt" "$(dirname ${_pkgfile_path})/md5sum_testfile.txt"

    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f06218")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Found local source file" \
        "Test existing local source correct checksum (verify checksum yes)."

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f09999")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Failed verifying checksum: local source file"

    _scrmtx=()
    _sources=("md5sum_testfile.txt")
    _checksums=("251aadc2351abf85b3dbfe7261f09999")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx "no") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "====> Found local source file" \
        "Test existing local source wrong checksum (verify checksum no)."

    _scrmtx=()
    _sources=("none_existing.patch")
    _checksums=("251aadc2351abf85b3dbfe7261f00000")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx "no") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find local source file"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_local_files


#******************************************************************************************************************************
# TEST: d_download_src() file ftp
#******************************************************************************************************************************
tsd__d_download_src_file_ftp() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() file ftp"
    local _fn="tsd__d_download_src_file_ftp"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _output _sources _checksums
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _output=$((d_download_src _scrmtx "yes" _download_mirror) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test checksum verification and download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test checksum verification but no download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz")
    _checksums=("5bda2cdb1af51a80aecce58d6e42bd2f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    [[ ${_ret} == 0 && ${_output} == *"====> Found ftp|http|https source file"* ]]
    te_retval_0 _COK _CFAIL ${_ret} "Test downloading existing file."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_file_ftp


#******************************************************************************************************************************
# TEST: d_download_src() file http
#******************************************************************************************************************************
tsd__d_download_src_file_http() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() file http"
    local _fn="tsd__d_download_src_file_http"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _sources _checksums _destpath
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://mirrors-usa.go-parts.com/lfs/lfs-packages/7.9/")
    _output=$((d_download_src _scrmtx "yes" _download_mirrors) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test checksum verification and download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz")
    _checksums=("a61415312426e9c2212bd7dc7929abda")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _output=$((d_download_src _scrmtx "yes") 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test checksum verification but no download_mirrors."

    _scrmtx=()
    _sources=("NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz")
    _checksums=("e6a972d4e10d9e76407a432f4a63cd4c")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _destpath=${_scrmtx[1:DESTPATH]}

    rm -rf "${_destpath}"

    _download_mirrors=()
    _output=$((d_download_src _scrmtx "no" _download_mirrors) 2>&1)
    _ret=${?}
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test prefix rename file."
    [[ -f ${_destpath} ]]
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test prefix rename downloaded file actually exists."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_file_http


#******************************************************************************************************************************
# TEST: d_download_src() file https
#******************************************************************************************************************************
tsd__d_download_src_file_https() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() file https"
    local _fn="tsd__d_download_src_file_https"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _srcdst_dir2="${_tmp_dir}/cards_mk2/sources"
    local _sources _checksums _download_prog _download_prog_opts
    declare -A _scrmtx
    declare -i _ret

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"
    mkdir -p "${_srcdst_dir2}"

    _sources=("NOEXTRACT::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _download_mirrors=("http://none.existing.download/mirror_wrong/")
    _output=$((d_download_src _scrmtx "yes" _download_mirrors) 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test wrong download_mirrors."

    # use _srcdst_dir2
    _scrmtx=()
    _sources=("iproute.tar.xz::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _download_mirrors=()
    _download_prog="curl"
    _output=$((d_download_src _scrmtx "yes" _download_mirrors "${_download_prog}") 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test with download_prog curl."

    # use _srcdst_dir2 rename to iproute2
    _scrmtx=()
    _sources=("iproute2.tar.xz::https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz")
    _checksums=("d762653ec3e1ab0d4a9689e169ca184f")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir2}" &> /dev/null
    _download_mirrors=()
    _download_prog="curl"
    _download_prog_opts="-q --fail --connect-timeout 3"
    _output=$((d_download_src _scrmtx "yes" _download_mirrors "${_download_prog}" "${_download_prog_opts}") 2>&1)
    _ret=$?
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
    fi
    te_retval_0 _COK _CFAIL ${_ret} "Test with download_prog curl own _download_prog_opts."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_file_https


#******************************************************************************************************************************
# TEST: d_download_src() git
#******************************************************************************************************************************
tsd__d_download_src_git() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() git"
    local _fn="tsd__d_download_src_git"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"

    _sources=("git+https://github.com/should_not_exist_wrong/just_a_wrong_uri.git")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _CFAIL "Failed to access the git URI ${_off}Test wrong git uri."
    else
        te_find_err_msg _COK _CFAIL "${_output}" "Failed to access the git URI" "Test wrong git uri."
    fi

    _scrmtx=()
    _sources=("helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Cloning git repo into destpath*Cloning into bare repository"

    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Fetching (updating) git repo at destpath" \
        "Test Updating git repo."

    _scrmtx=()
    _sources=("helper_scripts::git+https://github.com/P-Linux/P-Linux-Logo.git")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the git URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the git uri are REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local repo folder:*is not a clone of: <https://github.com/P-Linux/P-Linux-Logo.git>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_git


#******************************************************************************************************************************
# TEST: d_download_src() svn
#******************************************************************************************************************************
tsd__d_download_src_svn() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() svn"
    local _fn="tsd__d_download_src_svn"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"

    _sources=("svn+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _CFAIL "Failed to access the svn URI ${_off}Test wrong svn uri."
    else
        te_find_err_msg _COK _CFAIL "${_output}" "Failed to access the svn URI" "Test wrong svn uri."
    fi

    _scrmtx=()
    _sources=("portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#tag=10")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Unrecognized fragment: 'tag=10'. ENTRY: 'portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#tag=10'"

    _scrmtx=()
    _sources=("portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Checking-out svn repo into destpath"

    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Updating svn repo at destpath" \
        "Test Updating svn repo."

    _scrmtx=()
    _sources=("portsmf::svn://svn.code.sf.net/p/splix/code/splix")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the svn URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the svn uri are REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of: <svn://svn.code.sf.net/p/splix/code/splix>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_svn


#******************************************************************************************************************************
# TEST: d_download_src() hg
#******************************************************************************************************************************
tsd__d_download_src_hg() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() hg"
    local _fn="tsd__d_download_src_hg"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"

    _sources=("hg+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _CFAIL "Failed to access the hg URI ${_off}Test wrong hg uri."
    else
        te_find_err_msg _COK _CFAIL "${_output}" "Failed to access the hg URI" "Test wrong hg uri."
    fi

    _scrmtx=()
    _sources=("hg-tutorial-hello::hg+https://bitbucket.org/bos/hg-tutorial-hello#revision=0a04b98")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Cloning hg repo into destpath"

    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Pulling (updating) hg repo at destpath" \
        "Test Updating hg repo."

    _scrmtx=()
    _sources=("hg-tutorial-hello::hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Failed to access the hg URI"* ]]; then
        te_warn "${_fn}" "Internet access and access to the hg uri are REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of: <http://linuxtv.org/hg/dvb-apps/>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_hg


#******************************************************************************************************************************
# TEST: d_download_src() bzr
#******************************************************************************************************************************
tsd__d_download_src_bzr() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "d_download_src() bzr"
    local _fn="tsd__d_download_src_bzr"
    local _tmp_dir=$(mktemp -d)
    local _pkgfile_path="${_tmp_dir}/ports/dummy/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _off=$(tput sgr0)
    local _bold=$(tput bold)
    local _red="${_bold}$(tput setaf 1)"
    declare -A _scrmtx
    local _output

    # Create files/folders
    mkdir -p "$(dirname "${_pkgfile_path}")"
    touch "${_pkgfile_path}"
    mkdir -p "${_srcdst_dir}"

    _sources=("bzr+https://github.com/should_not_exist_wrong/just_a_wrong_uri")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access is REQUIRED for this test."
        te_ms_failed _CFAIL "Failed to access the bzr URI ${_off}Test wrong bzr uri."
    else
        te_find_err_msg _COK _CFAIL "${_output}" "Not a branch" "Test wrong bzr uri."
    fi

    _scrmtx=()
    _sources=("gsettings-qt::bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Branching bzr repo into destpath"
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Pulling (updating) bzr repo at destpath" \
        "Test Updating bzr repo."

    _scrmtx=()
    _sources=("gsettings-qt::bzr+http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/#revision=1295")
    _checksums=("SKIP")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdst_dir}" &> /dev/null
    _output=$((d_download_src _scrmtx) 2>&1)
    if [[ ${_output} == *"Couldn't verify internet-connection by pinging popular sites."* ]]; then
        te_warn "${_fn}" "Internet access and access to the bzr uri are REQUIRED for this test."
    fi
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local repo folder: <${_scrmtx[1:DESTPATH]}> is not a clone of"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsd__d_download_src_bzr



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
