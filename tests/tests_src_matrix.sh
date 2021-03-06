#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************
_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="src_matrix.sh"

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

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: s_get_src_matrix() CHECKSUMS array
#******************************************************************************************************************************
tss__s_get_src_matrix_checksums() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_get_src_matrix() CHECKSUMS array"
    local _pkgfile_path="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/pkg_sources"
    declare -A _scrmtx
    local _output _sources _checksums

    _sources=("mylocal.patch")
    _checksums=()
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "INFO: SRC_CHECKSUMS array size: '0' is less than SRC_ENTRIES Array size: '1'"

    _sources=("mylocal.patch")
    _checksums=()
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 's_get_src_matrix()' Argument '5' MUST NOT be empty."

    _sources=("mylocal.patch" "mylocal2.patch")
    _checksums=("SKIP")
    _output=$(s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") &> /dev/null
    te_find_info_msg _COK _CFAIL "${_output}" "INFO: Added temporarily checksum entries SKIP."

    _sources=("mylocal.patch")
    _checksums=("SKIP" "SKIP")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "SRC_CHECKSUMS array size: '2' is greater than SRC_ENTRIES Array size: '1'"

    _sources=("mylocal.patch")
    _checksums=("SKIP")
    _output=$(s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}")
    te_empty_val _COK _CFAIL "${_output}" "Test SCR_CHKSUMS array size same as SRC_ENTRIES Array size."

    _sources=("mylocal.patch")
    _checksums=("00_to_short_checksum")
    _output=$(s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}")
    te_find_err_msg _COK _CFAIL "${_output}" "'00_to_short_checksum' MUST be 'SKIP' or 32 chars. Got: '20'."

    _sources=("mylocal.patch")
    _checksums=("000000000000000000000_to_long_checksum")
    _output=$(s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}")
    te_find_err_msg _COK _CFAIL "${_output}" "'000000000000000000000_to_long_checksum' MUST be 'SKIP' or 32 chars. Got: '38'."

    _scrmtx=()
    _sources=("mylocal_1.patch" "mylocal_2.patch" "mylocal_3.patch")
    _checksums=("10000000000000000000000000000000")
    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}"  &> /dev/null
    te_same_val _COK _CFAIL "${_scrmtx[NUM_IDX]}" "3" "Test updated _scrmtx[NUM_IDX]. Expected 3."

    [[ ${_scrmtx[1:CHKSUM]} == 10000000000000000000000000000000 && ${_scrmtx[2:CHKSUM]} == SKIP && \
        ${_scrmtx[3:CHKSUM]} == "SKIP" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test missing checksums - check SKIP checksum items."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tss__s_get_src_matrix_checksums


#******************************************************************************************************************************
# TEST: s_get_src_matrix() multiple source arrays
#******************************************************************************************************************************
tss__s_get_src_matrix_multiple_source_arrays() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_get_src_matrix()  multiple source arrays"
    local _pkgfile_path_1="/home/only_download_1/Pkgfile"
    local _pkgfile_path_2="/home/only_download_2/Pkgfile"
    local _srcdest_dir_1="/home/pkg_sources_1"
    local _srcdest_dir_2="/home/pkg_sources_2"
    declare -A _scrmtx
    local _sources_1 _sources_2 _checksums_1 _checksums_2

    _sources_1=("http://www.download.test/dummy_1" "mylocal_1.patch")
    _checksums_1=("10000000000000000000000000000000" "SKIP")

    _sources_2=("http://www.download.test/dummy_2" "mylocal_2.patch")
    _checksums_2=("SKIP" "20000000000000000000000000000000")

    s_get_src_matrix _scrmtx _sources_1 _checksums_1 "${_pkgfile_path_1}" "${_srcdest_dir_1}"
    s_get_src_matrix _scrmtx _sources_2 _checksums_2 "${_pkgfile_path_2}" "${_srcdest_dir_2}"

    te_same_val _COK _CFAIL "${_scrmtx[NUM_IDX]}" "4"

    [[ ${_scrmtx[1:ENTRY]} == "http://www.download.test/dummy_1"      && \
        ${_scrmtx[1:CHKSUM]} == "10000000000000000000000000000000"    && \
        -z ${_scrmtx[1:NOEXTRACT]}                                    && \
        -z ${_scrmtx[1:PREFIX]}                                       && \
        ${_scrmtx[1:URI]} == "http://www.download.test/dummy_1"       && \
        -z ${_scrmtx[1:FRAGMENT]}                                     && \
        ${_scrmtx[1:PROTOCOL]} == "http"                              && \
        ${_scrmtx[1:DESTNAME]} == "dummy_1"                           && \
        ${_scrmtx[1:DESTPATH]} == "/home/pkg_sources_1/dummy_1" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 1. entry (from 1. Pkgfile) all Fields as expected: <${_sources_1[0]}>."

    [[ ${_scrmtx[2:ENTRY]} == "mylocal_1.patch"                && \
        ${_scrmtx[2:CHKSUM]} == "SKIP"                         && \
        -z ${_scrmtx[2:NOEXTRACT]}                             && \
        -z ${_scrmtx[2:PREFIX]}                                && \
        ${_scrmtx[2:URI]} == "mylocal_1.patch"                 && \
        -z ${_scrmtx[2:FRAGMENT]}                              && \
        ${_scrmtx[2:PROTOCOL]} == "local"                      && \
        ${_scrmtx[2:DESTNAME]} == "mylocal_1.patch"            && \
        ${_scrmtx[2:DESTPATH]} == "/home/only_download_1/mylocal_1.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 2. entry (from 1. Pkgfile) all Fields as expected: <${_sources_1[1]}>."

    [[ ${_scrmtx[3:ENTRY]} == "http://www.download.test/dummy_2"   && \
        ${_scrmtx[3:CHKSUM]} == "SKIP"                             && \
        -z ${_scrmtx[3:NOEXTRACT]}                                 && \
        -z ${_scrmtx[3:PREFIX]}                                    && \
        ${_scrmtx[3:URI]} == "http://www.download.test/dummy_2"    && \
        -z ${_scrmtx[3:FRAGMENT]}                                  && \
        ${_scrmtx[3:PROTOCOL]} == "http"                           && \
        ${_scrmtx[3:DESTNAME]} == "dummy_2"                        && \
        ${_scrmtx[3:DESTPATH]} == "/home/pkg_sources_2/dummy_2" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 3. entry (from 2. Pkgfile) all Fields as expected: <${_sources_2[0]}>."

    [[ ${_scrmtx[4:ENTRY]} == "mylocal_2.patch"                        && \
        ${_scrmtx[4:CHKSUM]} == "20000000000000000000000000000000"     && \
        -z ${_scrmtx[4:NOEXTRACT]}                                     && \
        -z ${_scrmtx[4:PREFIX]}                                        && \
        ${_scrmtx[4:URI]} == "mylocal_2.patch"                         && \
        -z ${_scrmtx[4:FRAGMENT]}                                      && \
        ${_scrmtx[4:PROTOCOL]} == "local"                              && \
        ${_scrmtx[4:DESTNAME]} == "mylocal_2.patch"                    && \
        ${_scrmtx[4:DESTPATH]} == "/home/only_download_2/mylocal_2.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 4. entry (from 2. Pkgfile) all Fields as expected: <${_sources_2[1]}>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tss__s_get_src_matrix_multiple_source_arrays


#******************************************************************************************************************************
# TEST: s_get_src_matrix() no srcdst dir input
#******************************************************************************************************************************
tss__s_get_src_matrix_no_srcdst_dir_input() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_get_src_matrix() no srcdst dir input"
    local _pkgfile_path="/home/only_download_1/Pkgfile"
    declare -A _scrmtx
    local _sources _checksums

    _sources=("http://www.download.test/dummy_1" "mylocal_1.patch")
    _checksums=("10000000000000000000000000000000" "SKIP")

    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}"

    [[ ${_scrmtx[1:ENTRY]} == "http://www.download.test/dummy_1"       && \
        ${_scrmtx[1:CHKSUM]} == "10000000000000000000000000000000"     && \
        -z ${_scrmtx[1:NOEXTRACT]}                                     && \
        -z ${_scrmtx[1:PREFIX]}                                        && \
        ${_scrmtx[1:URI]} == "http://www.download.test/dummy_1"        && \
        -z ${_scrmtx[1:FRAGMENT]}                                      && \
        ${_scrmtx[1:PROTOCOL]} == "http"                               && \
        ${_scrmtx[1:DESTNAME]} == "dummy_1"                            && \
        ${_scrmtx[1:DESTPATH]} == "/home/only_download_1/dummy_1" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 1. entry no srcdst dir input all Fields as expected: <${_sources[0]}>."

    [[ ${_scrmtx[2:ENTRY]} == "mylocal_1.patch"      && \
        ${_scrmtx[2:CHKSUM]} == "SKIP"                         && \
        -z ${_scrmtx[2:NOEXTRACT]}                             && \
        -z ${_scrmtx[2:PREFIX]}                                && \
        ${_scrmtx[2:URI]} == "mylocal_1.patch"       && \
        -z ${_scrmtx[2:FRAGMENT]}                              && \
        ${_scrmtx[2:PROTOCOL]} == "local"                      && \
        ${_scrmtx[2:DESTNAME]} == "mylocal_1.patch"  && \
        ${_scrmtx[2:DESTPATH]} == "/home/only_download_1/mylocal_1.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 2. entry no srcdst dir input all Fields as expected: <${_sources[1]}>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tss__s_get_src_matrix_no_srcdst_dir_input


#******************************************************************************************************************************
# TEST: s_get_src_matrix() general errors
#******************************************************************************************************************************
tss__s_get_src_matrix_general_errors() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_get_src_matrix() general errors"
    local _pkgfile_path="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/pkg_sources"
    declare -A _scrmtx
    declare -a _scrmtx_wrong_index_array
    local _output _sources _checksums

    _sources=()
    _checksums=()
    (s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test empty _sources array."

    _sources=("mylocal.patch")
    _checksums=()
    _output=$((s_get_src_matrix _scrmtx_wrong_index_array _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a referenced associative array: '_retmatrix'" \
        "Test Not a referenced associative array <_scrmtx_wrong_index_array>"

    _sources=("NOEXTRACT::renamed.tar.xz:::http://dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Entry MUST NOT contain any triple colons (:::): <NOEXTRACT::renamed.tar.xz:::http://dummy.tar.xz>"

    _sources=("NOEXTRACT::renamed.tar.xz::wrong::http://y.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Entry MUST NOT contain more than 2 prefix_sep (::). Got:'3': <NOEXTRACT::renamed.tar.xz::wrong::http://y.tar.xz>"

    _sources=("helper_+scripts::git+https://P-Linux/pl_bash_functions.git")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Entry MUST NOT contain more than 1 plus (+): <helper_+scripts::git+https://P-Linux/pl_bash_functions.git>"

    _sources=("helper_#scripts::git+https://urllib3.git#tag=1.14")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Entry MUST NOT contain more than 1 number sign (#): <helper_#scripts::git+https://urllib3.git#tag=1.14"

    _sources=("git+httpsxx://urllib3.git#tag=1.14")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Supported vclplus_schemes: 'http' 'https' 'lp'. Got 'httpsxx': <git+httpsxx://urllib3.git#tag=1.14>"

    _sources=("sftp://www.download.test/dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "The protocol: 'sftp' is not supported: <sftp://www.download.test/dummy.tar.xz>" \
        "Test abort: Unsupported protocol."

    _sources=("WRONG::renamed.tar.xz::http://dummy.tar.xz")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'NOEXTRACT' MUST be empty or: NOEXTRACT. Got: 'WRONG': <WRONG::renamed.tar.xz::http://dummy.tar.xz>"

    _sources=("wrong/mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Local source MUST NOT contain any slash: <wrong/mylocal.patch>"

    _sources=("NOEXTRACT::mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Local source MUST NOT have a 'NOEXTRACT': <NOEXTRACT::mylocal.patch>"

    _sources=("wrong_renamed.patch::mylocal.patch")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local source MUST NOT have a prefix: 'wrong_renamed.patch': <wrong_renamed.patch::mylocal.patch>"

    _sources=("dummy.patch#wrong_fragment")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Local source MUST NOT have a fragment: 'wrong_fragment': <dummy.patch#wrong_fragment>"

    _sources=("http://dummy.tar.xz#wrong_fragment")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \d
        "ftp|http|https source MUST NOT have a fragment: 'wrong_fragment': <http://dummy.tar.xz#wrong_fragment>"

    _sources=("NOEXTRACT::git+https://haxelib.git")
    _checksums=("SKIP")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'git|svn|hg|bzr source MUST NOT have a NOEXTRACT: <NOEXTRACT::git+https://haxelib.git>"

    _sources=("git+https://haxelib.git")
    _checksums=("10000000000000000000000000000000")
    _output=$((s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'git|svn|hg|bzr source MUST NOT have a checksum: '10000000000000000000000000000000': <git+https://haxelib.git>"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tss__s_get_src_matrix_general_errors


#******************************************************************************************************************************
# TEST: s_get_src_matrix() check expected values
#******************************************************************************************************************************
tss__s_get_src_matrix_check_expected_values() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_get_src_matrix() check expected values"
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

    local _pkgfile_path="/var/cards_mk/ports/only_download/Pkgfile"
    local _srcdest_dir="/home/dummy_sources"

    s_get_src_matrix _scrmtx _sources _checksums "${_pkgfile_path}" "${_srcdest_dir}" &> /dev/null

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
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "50f97f4159805e374639a73e2636f22e" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "autoconf-2.69.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/autoconf-2.69.tar.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "d762653ec3e1ab0d4a9689e169ca184f" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "https" && \
        ${_scrmtx[${_n}:DESTNAME]} == "iproute2-4.4.0.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/iproute2-4.4.0.tar.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "e6a972d4e10d9e76407a432f4a63cd4c" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "ftp" && \
        ${_scrmtx[${_n}:DESTNAME]} == "file-5.25.tar.gz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/file-5.25.tar.gz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "28f1205d8dd2001f26fec1e8c2cebe37" && \
        ${_scrmtx[${_n}:NOEXTRACT]} == "NOEXTRACT"  && \
        ${_scrmtx[${_n}:PREFIX]} == "renamed_zlib.tar.xz" && \
        ${_scrmtx[${_n}:URI]} == "http://www.zlib.net/zlib-1.2.8.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "renamed_zlib.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/renamed_zlib.tar.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "renamed_xz.tar.xz::http://tukaani.org/xz/xz-5.2.2.tar.xz" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "renamed_xz.tar.xz" && \
        ${_scrmtx[${_n}:URI]} == "http://tukaani.org/xz/xz-5.2.2.tar.xz" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "http" && \
        ${_scrmtx[${_n}:DESTNAME]} == "renamed_xz.tar.xz" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/renamed_xz.tar.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "mylocal.patch" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "mylocal.patch" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "local" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mylocal.patch" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/var/cards_mk/ports/only_download/mylocal.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "mylocal2.patch" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "mylocal2.patch" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "local" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mylocal2.patch" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/var/cards_mk/ports/only_download/mylocal2.patch" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "helper_scripts" && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/P-Linux/pl_bash_functions.git" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "helper_scripts" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/helper_scripts" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/shazow/urllib3.git#tag=1.14" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/shazow/urllib3.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "tag=1.14" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "urllib3" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/urllib3" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/mate-desktop/mozo.git#branch=gtk3" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/mate-desktop/mozo.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "branch=gtk3" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "mozo" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/mozo" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "git+https://github.com/HaxeFoundation/haxelib.git#commit=2f12e1a" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://github.com/HaxeFoundation/haxelib.git" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "commit=2f12e1a" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "git" && \
        ${_scrmtx[${_n}:DESTNAME]} == "haxelib" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/haxelib" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn://svn.code.sf.net/p/netpbm/code/advanced" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "svn://svn.code.sf.net/p/netpbm/code/advanced" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "advanced" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/advanced" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn://svn.code.sf.net/p/splix/code/splix#revision=315" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "svn://svn.code.sf.net/p/splix/code/splix" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=315" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "splix" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/splix" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "vpnc::svn+http://svn.unix-ag.uni-kl.de/vpnc/trunk#revision=550" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "vpnc" && \
        ${_scrmtx[${_n}:URI]} == "http://svn.unix-ag.uni-kl.de/vpnc/trunk" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=550" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "vpnc" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/vpnc" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "https://svn.code.sf.net/p/portmedia/code/portsmf/trunk" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=228" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "svn" && \
        ${_scrmtx[${_n}:DESTNAME]} == "trunk" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/trunk" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://linuxtv.org/hg/dvb-apps/" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "revision=d40083fff895" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "dvb-apps" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/dvb-apps" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://bitbucket.org/pypy/pypy#tag=release-4.0.1" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://bitbucket.org/pypy/pypy" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "tag=release-4.0.1" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "pypy" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/pypy" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg+http://hg.nginx.org/nginx#branch=stable-1.8" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        -z ${_scrmtx[${_n}:PREFIX]} && \
        ${_scrmtx[${_n}:URI]} == "http://hg.nginx.org/nginx" && \
        ${_scrmtx[${_n}:FRAGMENT]} == "branch=stable-1.8" && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "nginx" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/nginx" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "hg_hello_example::hg+https://bitbucket.org/bos/hg-tutorial-hello" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "hg_hello_example" && \
        ${_scrmtx[${_n}:URI]} == "https://bitbucket.org/bos/hg-tutorial-hello" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "hg" && \
        ${_scrmtx[${_n}:DESTNAME]} == "hg_hello_example" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/hg_hello_example" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
    [[ ${_scrmtx[${_n}:ENTRY]} == "contractor::bzr+lp:~elementary-os/contractor/elementary-contracts" && \
        ${_scrmtx[${_n}:CHKSUM]} == "SKIP" && \
        -z ${_scrmtx[${_n}:NOEXTRACT]} && \
        ${_scrmtx[${_n}:PREFIX]} == "contractor" && \
        ${_scrmtx[${_n}:URI]} == "lp:~elementary-os/contractor/elementary-contracts" && \
        -z ${_scrmtx[${_n}:FRAGMENT]} && \
        ${_scrmtx[${_n}:PROTOCOL]} == "bzr" && \
        ${_scrmtx[${_n}:DESTNAME]} == "contractor" && \
        ${_scrmtx[${_n}:DESTPATH]} == "/home/dummy_sources/contractor" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
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
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    _n+=1
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
    te_retcode_0 _COK _CFAIL ${?} "Test all fields - expected values: <${_sources[${_n}-1]}>."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tss__s_get_src_matrix_check_expected_values



#******************************************************************************************************************************
# TEST: s_export()
#******************************************************************************************************************************
tsi__s_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "s_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((s_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((s_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        s_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx s_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx s_export'."

        _BF_EXPORT_ALL="no"
        s_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f s_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f s_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__s_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 61
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
