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
te_print_header "source_matrix.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format

source "${_FUNCTIONS_DIR}/utilities.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/source_matrix.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: so_prepare_src_matrix() CHECKSUMS array
#******************************************************************************************************************************
ts_so___so_prepare_src_matrix_checksums() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "so_prepare_src_matrix() CHECKSUMS array"
    local _pkgfile_fullpath="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/pkg_sources"
    declare -A _scrmtx
    local _output _sources _checksums

    _sources=("mylocal.patch")
    _checksums=()
    _output=$(so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}")
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "INFO: SRC_CHECKSUMS array size: '0' is less than SRC_ENTRIES Array size: '1'"

    _sources=("mylocal.patch")
    _checksums=("SKIP" "SKIP")
    _output=$(so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}")
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "SRC_CHECKSUMS array size: '2' is greater than SRC_ENTRIES Array size: '1'"

    _sources=("mylocal.patch")
    _checksums=("SKIP")
    _output=$(so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}")
    te_empty_val _COUNT_OK _COUNT_FAILED "${_output}" "Test SCR_CHKSUMS array size same as SRC_ENTRIES Array size."

    _sources=("mylocal.patch")
    _checksums=("00_to_short_checksum")
    _output=$(so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}")
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'00_to_short_checksum' MUST be SKIP or 32 chars. Got:'20'. Pkgfile: </var/cards_mk/ports/only_download/Pkgfile>"

    _sources=("mylocal.patch")
    _checksums=("000000000000000000000_to_long_checksum")
    _output=$(so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}")
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'000000000000000000000_to_long_checksum' MUST be SKIP or 32 chars. Got:'38'. Pkgfile"

    _scrmtx=()
    _sources=("mylocal_1.patch" "mylocal_2.patch" "mylocal_3.patch")
    _checksums=("10000000000000000000000000000000")
    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}"  &> /dev/null
    te_same_val _COUNT_OK _COUNT_FAILED "${_scrmtx[NUM_IDX]}" "3" "Test updated _scrmtx[NUM_IDX]. Expected 3."

    [[ ${_scrmtx[1:CHKSUM]} == 10000000000000000000000000000000 && ${_scrmtx[2:CHKSUM]} == SKIP && \
        ${_scrmtx[3:CHKSUM]} == "SKIP" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test missing checksums - check SKIP checksum items."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_so___so_prepare_src_matrix_checksums


#******************************************************************************************************************************
# TEST: so_prepare_src_matrix() multiple source arrays
#******************************************************************************************************************************
ts_so___so_prepare_src_matrix_multiple_source_arrays() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "so_prepare_src_matrix()  multiple source arrays"
    local _pkgfile_fullpath_1="/home/only_download_1/Pkgfile"
    local _pkgfile_fullpath_2="/home/only_download_2/Pkgfile"
    local _srcdest_dir_1="/home/pkg_sources_1"
    local _srcdest_dir_2="/home/pkg_sources_2"
    declare -A _scrmtx
    local _sources_1 _sources_2 _checksums_1 _checksums_2

    _sources_1=("http://www.download.test/dummy_1" "mylocal_1.patch")
    _checksums_1=("10000000000000000000000000000000" "SKIP")

    _sources_2=("http://www.download.test/dummy_2" "mylocal_2.patch")
    _checksums_2=("SKIP" "20000000000000000000000000000000")

    so_prepare_src_matrix _scrmtx _sources_1 _checksums_1 "${_pkgfile_fullpath_1}" "${_srcdest_dir_1}"
    so_prepare_src_matrix _scrmtx _sources_2 _checksums_2 "${_pkgfile_fullpath_2}" "${_srcdest_dir_2}"

    te_same_val _COUNT_OK _COUNT_FAILED "${_scrmtx[NUM_IDX]}" "4"

    [[ ${_scrmtx[1:ENTRY]} == "http://www.download.test/dummy_1"      && \
        ${_scrmtx[1:CHKSUM]} == "10000000000000000000000000000000"    && \
        -z ${_scrmtx[1:NOEXTRACT]}                                    && \
        -z ${_scrmtx[1:PREFIX]}                                       && \
        ${_scrmtx[1:URI]} == "http://www.download.test/dummy_1"       && \
        -z ${_scrmtx[1:FRAGMENT]}                                     && \
        ${_scrmtx[1:PROTOCOL]} == "http"                              && \
        ${_scrmtx[1:DESTNAME]} == "dummy_1"                           && \
        ${_scrmtx[1:DESTPATH]} == "/home/pkg_sources_1/dummy_1" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 1. entry (from 1. Pkgfile) all Fields as expected. ENTRY: <${_sources_1[0]}>."

    [[ ${_scrmtx[2:ENTRY]} == "mylocal_1.patch"                && \
        ${_scrmtx[2:CHKSUM]} == "SKIP"                         && \
        -z ${_scrmtx[2:NOEXTRACT]}                             && \
        -z ${_scrmtx[2:PREFIX]}                                && \
        ${_scrmtx[2:URI]} == "mylocal_1.patch"       && \
        -z ${_scrmtx[2:FRAGMENT]}                              && \
        ${_scrmtx[2:PROTOCOL]} == "local"                      && \
        ${_scrmtx[2:DESTNAME]} == "mylocal_1.patch"  && \
        ${_scrmtx[2:DESTPATH]} == "/home/only_download_1/mylocal_1.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 2. entry (from 1. Pkgfile) all Fields as expected. ENTRY: <${_sources_1[1]}>."

    [[ ${_scrmtx[3:ENTRY]} == "http://www.download.test/dummy_2"   && \
        ${_scrmtx[3:CHKSUM]} == "SKIP"                             && \
        -z ${_scrmtx[3:NOEXTRACT]}                                 && \
        -z ${_scrmtx[3:PREFIX]}                                    && \
        ${_scrmtx[3:URI]} == "http://www.download.test/dummy_2"    && \
        -z ${_scrmtx[3:FRAGMENT]}                                  && \
        ${_scrmtx[3:PROTOCOL]} == "http"                           && \
        ${_scrmtx[3:DESTNAME]} == "dummy_2"                        && \
        ${_scrmtx[3:DESTPATH]} == "/home/pkg_sources_2/dummy_2" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 3. entry (from 2. Pkgfile) all Fields as expected. ENTRY: <${_sources_2[0]}>."

    [[ ${_scrmtx[4:ENTRY]} == "mylocal_2.patch"                        && \
        ${_scrmtx[4:CHKSUM]} == "20000000000000000000000000000000"     && \
        -z ${_scrmtx[4:NOEXTRACT]}                                     && \
        -z ${_scrmtx[4:PREFIX]}                                        && \
        ${_scrmtx[4:URI]} == "mylocal_2.patch"                         && \
        -z ${_scrmtx[4:FRAGMENT]}                                      && \
        ${_scrmtx[4:PROTOCOL]} == "local"                              && \
        ${_scrmtx[4:DESTNAME]} == "mylocal_2.patch"                    && \
        ${_scrmtx[4:DESTPATH]} == "/home/only_download_2/mylocal_2.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 4. entry (from 2. Pkgfile) all Fields as expected. ENTRY: <${_sources_2[1]}>."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_so___so_prepare_src_matrix_multiple_source_arrays


#******************************************************************************************************************************
# TEST: so_prepare_src_matrix() no srcdst dir input
#******************************************************************************************************************************
ts_so___so_prepare_src_matrix_no_srcdst_dir_input() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "so_prepare_src_matrix() no srcdst dir input"
    local _pkgfile_fullpath="/home/only_download_1/Pkgfile"
    declare -A _scrmtx
    local _sources _checksums

    _sources=("http://www.download.test/dummy_1" "mylocal_1.patch")
    _checksums=("10000000000000000000000000000000" "SKIP")

    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir_1}"

    [[ ${_scrmtx[1:ENTRY]} == "http://www.download.test/dummy_1"       && \
        ${_scrmtx[1:CHKSUM]} == "10000000000000000000000000000000"     && \
        -z ${_scrmtx[1:NOEXTRACT]}                                     && \
        -z ${_scrmtx[1:PREFIX]}                                        && \
        ${_scrmtx[1:URI]} == "http://www.download.test/dummy_1"        && \
        -z ${_scrmtx[1:FRAGMENT]}                                      && \
        ${_scrmtx[1:PROTOCOL]} == "http"                               && \
        ${_scrmtx[1:DESTNAME]} == "dummy_1"                            && \
        ${_scrmtx[1:DESTPATH]} == "/home/only_download_1/dummy_1" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 1. entry no srcdst dir input all Fields as expected. ENTRY: <${_sources[0]}>."

    [[ ${_scrmtx[2:ENTRY]} == "mylocal_1.patch"      && \
        ${_scrmtx[2:CHKSUM]} == "SKIP"                         && \
        -z ${_scrmtx[2:NOEXTRACT]}                             && \
        -z ${_scrmtx[2:PREFIX]}                                && \
        ${_scrmtx[2:URI]} == "mylocal_1.patch"       && \
        -z ${_scrmtx[2:FRAGMENT]}                              && \
        ${_scrmtx[2:PROTOCOL]} == "local"                      && \
        ${_scrmtx[2:DESTNAME]} == "mylocal_1.patch"  && \
        ${_scrmtx[2:DESTPATH]} == "/home/only_download_1/mylocal_1.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} \
        "Test 2. entry no srcdst dir input all Fields as expected. ENTRY: <${_sources[1]}>."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_so___so_prepare_src_matrix_no_srcdst_dir_input


#******************************************************************************************************************************
# TEST: so_prepare_src_matrix() general errors
#******************************************************************************************************************************
ts_so___so_prepare_src_matrix_general_errors() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "so_prepare_src_matrix() general errors"
    local _pkgfile_fullpath="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/pkg_sources"
    declare -A _scrmtx
    declare -a _scrmtx_wrong_index_array
    local _output _sources _checksums

    _sources=("mylocal.patch")
    _checksums=()
    _output=$((so_prepare_src_matrix _scrmtx_wrong_index_array _sources _checksums "${_pkgfile_fullpath}" \
        "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "FUNCTION: 'so_prepare_src_matrix()' Not a referenced associative array: '_ret_matrix'"\
        "Test Not a referenced associative array <_scrmtx_wrong_index_array>"

    _sources=("NOEXTRACT::renamed.tar.xz:::http://dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}"\
        "Entry MUST NOT contain any triple colons (:::). ENTRY: <NOEXTRACT::renamed.tar.xz:::http://dummy.tar.xz>"

    _sources=("NOEXTRACT::renamed.tar.xz::wrong::http://y.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Entry MUST NOT contain more than 2 prefix_sep (::). Got:'3' ENTRY: <NOEXTRACT::renamed.tar.xz::wrong::http://y.tar.xz"

    _sources=("helper_+scripts::git+https://P-Linux/pl_bash_functions.git")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Entry MUST NOT contain more than 1 plus (+). ENTRY: <helper_+scripts::git+https://P-Linux/pl_bash_functions.git>"

    _sources=("helper_#scripts::git+https://urllib3.git#tag=1.14")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Entry MUST NOT contain more than 1 number sign (#). ENTRY: <helper_#scripts::git+https://urllib3.git#tag=1.14"

    _sources=("git+httpsxx://urllib3.git#tag=1.14")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Supported vclplus_schemes: 'http' 'https' 'lp'. Got 'httpsxx'.  ENTRY: <git+httpsxx://urllib3.git#tag=1.14>"

    _sources=("sftp://www.download.test/dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "The protocol: 'sftp' is not supported. ENTRY: <sftp://www.download.test/dummy.tar.xz>" \
        "Test abort: Unsupported protocol."

    _sources=("WRONG::renamed.tar.xz::http://dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'NOEXTRACT' MUST be empty or: NOEXTRACT. Got: 'WRONG' ENTRY: <WRONG::renamed.tar.xz::http://dummy.tar.xz>"

    _sources=("wrong/mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local source MUST NOT contain any slash. ENTRY: <wrong/mylocal.patch>"

    _sources=("NOEXTRACT::mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local source MUST NOT have a 'NOEXTRACT'. ENTRY: <NOEXTRACT::mylocal.patch>"

    _sources=("wrong_renamed.patch::mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        " Local source MUST NOT have a prefix: 'wrong_renamed.patch'. ENTRY: <wrong_renamed.patch::mylocal.patch>"

    _sources=("dummy.patch#wrong_fragment")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Local source MUST NOT have a fragment: 'wrong_fragment'. ENTRY: <dummy.patch#wrong_fragment>"

    _sources=("http://dummy.tar.xz#wrong_fragment")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "ftp|http|https source MUST NOT have a fragment: 'wrong_fragment'. ENTRY: <http://dummy.tar.xz#wrong_fragment>"

    _sources=("NOEXTRACT::git+https://haxelib.git")
    _checksums=("SKIP")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'git|svn|hg|bzr source MUST NOT have a NOEXTRACT. ENTRY: <NOEXTRACT::git+https://haxelib.git>"

    _sources=("git+https://haxelib.git")
    _checksums=("10000000000000000000000000000000")
    _output=$((so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'git|svn|hg|bzr source MUST NOT have a checksum: '10000000000000000000000000000000'. ENTRY: <git+https://haxelib.git>"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_so___so_prepare_src_matrix_general_errors


#******************************************************************************************************************************
# TEST: so_prepare_src_matrix() check expected values
#******************************************************************************************************************************
ts_so___so_prepare_src_matrix_check_expected_values() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "so_prepare_src_matrix() check expected values"
    local _tmpstr
    declare -i _n
    declare -A _scrmtx

    local _sources=(
        "NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz"
        "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz"
        "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz"
        "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz"
        "NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz"
        "renamed_xz.tar.xz::http://tukaani.org/xz/xz-5.2.2.tar.xz"
        "mylocal.patch"
        "mylocal2.patch"

        "helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git"
        "git+https://github.com/shazow/urllib3.git#tag=1.14"
        "git+https://github.com/mate-desktop/mozo.git#branch=gtk3"
        "git+https://github.com/HaxeFoundation/haxelib.git#commit=2f12e1a"

        "svn://svn.code.sf.net/p/netpbm/code/advanced"
        "svn://svn.code.sf.net/p/splix/code/splix#revision=315"
        "vpnc::svn+http://svn.unix-ag.uni-kl.de/vpnc/trunk#revision=550"
        "svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228"

        "hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895"
        "hg+http://bitbucket.org/pypy/pypy#tag=release-4.0.1"
        "hg+http://hg.nginx.org/nginx#branch=stable-1.8"
        "hg_hello_example::hg+https://bitbucket.org/bos/hg-tutorial-hello"

        "contractor::bzr+lp:~elementary-os/contractor/elementary-contracts"
        "bzr+http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/#revision=1295"
        "bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75"
    )

    # Missing checksums will be added as SKIP: too short or too long once will be replaced with skip
    local _checksums=(
        "a61415312426e9c2212bd7dc7929abda"
        "50f97f4159805e374639a73e2636f22e"
        "d762653ec3e1ab0d4a9689e169ca184f"
        "e6a972d4e10d9e76407a432f4a63cd4c"
        "28f1205d8dd2001f26fec1e8c2cebe37"
        "xz_28f1205d8dd20_too_short"
        "mylocal.patch_2d4e10d9e76407a432f8_too_long"
        "SKIP"
    )

    local _pkgfile_fullpath="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/dummy_sources"

    so_prepare_src_matrix _scrmtx _sources _checksums "${_pkgfile_fullpath}" "${_srcdest_dir}" &> /dev/null

    _n=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "a61415312426e9c2212bd7dc7929abda" && \
        ${_scrmtx[${_n}:NOEXTRACT]} == "NOEXTRACT" && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "acl-2.2.52.src.tar.gz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/acl-2.2.52.src.tar.gz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "50f97f4159805e374639a73e2636f22e" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "autoconf-2.69.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/autoconf-2.69.tar.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "d762653ec3e1ab0d4a9689e169ca184f" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "https" && \
        ${_scrmtx[${_n}:DESTNAME]} == "iproute2-4.4.0.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/iproute2-4.4.0.tar.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "e6a972d4e10d9e76407a432f4a63cd4c" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "ftp" && \
        ${_scrmtx[${_n}:DESTNAME]} == "file-5.25.tar.gz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/file-5.25.tar.gz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "28f1205d8dd2001f26fec1e8c2cebe37" && \
        ${_scrmtx[${_n}:NOEXTRACT]} == "NOEXTRACT"  && \
        ${_scrmtx[${_n}:PREFIX]} == "renamed_zlib.tar.xz" && \
        ${_scrmtx[${_n}:URI]} == "http://www.zlib.net/zlib-1.2.8.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "renamed_zlib.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/renamed_zlib.tar.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "renamed_xz.tar.xz::http://tukaani.org/xz/xz-5.2.2.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "renamed_xz.tar.xz" && \
        ${_scrmtx[${_n}:URI]} == "http://tukaani.org/xz/xz-5.2.2.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "renamed_xz.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/renamed_xz.tar.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "mylocal.patch" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "mylocal.patch" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "local" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mylocal.patch" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/var/cards_mk/ports/only_download/mylocal.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "mylocal2.patch" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "mylocal2.patch" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "local" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mylocal2.patch" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/var/cards_mk/ports/only_download/mylocal2.patch" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "helper_scripts" && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/P-Linux/pl_bash_functions.git" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "helper_scripts" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/helper_scripts" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/shazow/urllib3.git#tag=1.14" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/shazow/urllib3.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "tag=1.14" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "urllib3" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/urllib3" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/mate-desktop/mozo.git#branch=gtk3" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/mate-desktop/mozo.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "branch=gtk3" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mozo" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/mozo" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/HaxeFoundation/haxelib.git#commit=2f12e1a" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/HaxeFoundation/haxelib.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "commit=2f12e1a" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "haxelib" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/haxelib" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn://svn.code.sf.net/p/netpbm/code/advanced" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "svn://svn.code.sf.net/p/netpbm/code/advanced" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "advanced" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/advanced" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn://svn.code.sf.net/p/splix/code/splix#revision=315" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "svn://svn.code.sf.net/p/splix/code/splix" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=315" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "splix" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/splix" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "vpnc::svn+http://svn.unix-ag.uni-kl.de/vpnc/trunk#revision=550" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "vpnc" && \
        ${_scrmtx[${_n}:URI]} == "http://svn.unix-ag.uni-kl.de/vpnc/trunk" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=550" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "vpnc" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/vpnc" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://svn.code.sf.net/p/portmedia/code/portsmf/trunk" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=228" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "trunk" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/trunk" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://linuxtv.org/hg/dvb-apps/" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=d40083fff895" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "dvb-apps" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/dvb-apps" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://bitbucket.org/pypy/pypy#tag=release-4.0.1" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://bitbucket.org/pypy/pypy" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "tag=release-4.0.1" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "pypy" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/pypy" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://hg.nginx.org/nginx#branch=stable-1.8" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://hg.nginx.org/nginx" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "branch=stable-1.8" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "nginx" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/nginx" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg_hello_example::hg+https://bitbucket.org/bos/hg-tutorial-hello" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "hg_hello_example" && \
        ${_scrmtx[${_n}:URI]} == "https://bitbucket.org/bos/hg-tutorial-hello" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "hg_hello_example" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/hg_hello_example" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    [[ ${_scrmtx[${_n}:ENTRY]} == "contractor::bzr+lp:~elementary-os/contractor/elementary-contracts" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "contractor" && \
        ${_scrmtx[${_n}:URI]} == "lp:~elementary-os/contractor/elementary-contracts" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "bzr" && \
        ${_scrmtx[${_n}:DESTNAME]} == "contractor" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/contractor" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    _tmpstr="bzr+http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/#revision=1295"
    [[ ${_scrmtx[${_n}:ENTRY]} == "${_tmpstr}" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=1295" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "bzr" && \
        ${_scrmtx[${_n}:DESTNAME]} == "foomatic-db" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/foomatic-db" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    (( _n++ ))
    _tmpstr="bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75"
    [[ ${_scrmtx[${_n}:ENTRY]} == "${_tmpstr}" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=75" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "bzr" && \
        ${_scrmtx[${_n}:DESTNAME]} == "trunk" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/trunk" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED ${?} "Test all fields - expected values. ENTRY: <${_sources[${_n}-1]}>."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_so___so_prepare_src_matrix_check_expected_values



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
