#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="archivefiles.sh"

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
i_source_safe_exit "${_FUNCTIONS_DIR}/archivefiles.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: a_list_pkgarchives()
#******************************************************************************************************************************
tsa__a_list_pkgarchives() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_list_pkgarchives()"
    local _tmp_dir=$(mktemp -d)
    local _portname1="port1"
    local _portpath1="${_tmp_dir}//${_portname1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()

    # Make folders
    mkdir -p "${_portpath1}"
    mkdir -p "${_portpath1}/subfolder"

    # check none found: must be 0 size return
    touch "${_portpath1}/README"
    touch "${_portpath1}/test"

    a_list_pkgarchives _targets "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}"
    te_same_val _COK _CFAIL "${#_targets[@]}" "0" "Test find 0 pkgarchive files."

    # Make files
    touch "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}"

    a_list_pkgarchives _targets "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}"
    te_same_val _COK _CFAIL "${#_targets[@]}" "3" "Test find 3 pkgarchive files (one in subfolder should not be included)"

    (u_in_array "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retcode_0 _COK _CFAIL ${?} "Test 1. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retcode_0 _COK _CFAIL ${?} "Test 2. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retcode_0 _COK _CFAIL ${?} "Test 3. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retcode_1 _COK _CFAIL ${?} "Test 4. pkgarchive file (in subfolder) should not be included the in result array."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_list_pkgarchives


#******************************************************************************************************************************
# TEST: a_rm_pkgarchives()
#******************************************************************************************************************************
tsa__a_rm_pkgarchives() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_rm_pkgarchives()"
    local _tmp_dir=$(mktemp -d)
    local _portname1="port1"
    local _portpath1="${_tmp_dir}/${_portname1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()
    local _archive_backup_dir

    # Make files
    mkdir -p "${_portpath1}"
    mkdir -p "${_portpath1}/subfolder"

    _output=$((a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_rm_pkgarchives()' Requires EXACT '5' arguments. Got '4'"

    _archive_backup_dir=""
    _output=$((a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_rm_pkgarchives()' Argument '5' MUST NOT be empty."

    _archive_backup_dir="${_portpath1}/pkgarchive_backup"
    _output=$((a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "_backup_dir does not exist: <${_archive_backup_dir}>" \
        "Test none existing pkgarchive_backup_dir."

    touch "${_portpath1}/README"
    touch "${_portpath1}/test"
    touch "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}"

    # check they really exist
    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" && \
       -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    if (( ${?} )); then
        te_warn "${FUNCNAME[0]}" "Test Error: did not find the created files."
    fi

    _archive_backup_dir="NONE"
    a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}"

    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 1. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 2. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 3. pkgarchive file was removed."

    [[ -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 4. pkgarchive file (in subfolder) was not removed."

    touch "${_portpath1}/README"
    touch "${_portpath1}/test"
    touch "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz"
    touch "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}"

    # check they really exist
    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" && \
       -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    if (( ${?} )); then
        te_warn "${FUNCNAME[0]}" "Test Error: did not find the created files."
    fi

    _archive_backup_dir="${_portpath1}/pkgarchive_backup"
    mkdir -p "${_archive_backup_dir}"

    _output=$(a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}")
    te_find_info_msg _COK _CFAIL "${_output}" \
        "*Moving any existing pkgarchive files for Port <${_portpath1}>*to pkgarchive_backup_dir: <${_archive_backup_dir}>" \
        "Test moving existing pkgarchives to new _backup_dir."

    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 1. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 2. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 3. pkgarchive file was removed."

    [[ -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 4. pkgarchive file (in subfolder) was not removed."

    [[ -f "${_archive_backup_dir}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 1. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 2. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test 3. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retcode_1 _COK _CFAIL ${?} "Test 4. pkgarchive file (in subfolder) does not exist in pkgarchive_backup_dir."

    _output=$(a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" \
        "${_archive_backup_dir}")
    te_find_info_msg _COK _CFAIL "${_output}" \
        "*Moving any existing pkgarchive files for Port <${_portpath1}>*to pkgarchive_backup_dir: <${_archive_backup_dir}>" \
        "Test moving existing pkgarchives to exiting _backup_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_rm_pkgarchives


#******************************************************************************************************************************
# TEST: a_get_archive_ext()
#******************************************************************************************************************************
tsa__a_get_archive_ext() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_ext()"
    local _ref_ext="cards.tar"
    local _output _ext _pkgarchive

    _output=$((a_get_archive_ext) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_ext()' Requires EXACT '3' arguments. Got '0'"

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((a_get_archive_ext _ext "${_pkgarchive}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_ext _ext "${_pkgarchive}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_ext}" ".cards.tar" "Test pkgarchive extension without compression."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    a_get_archive_ext _ext "${_pkgarchive}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension."

    _pkgarchive="attr.fr1462570367any.cards.tar.xz"
    a_get_archive_ext _ext "${_pkgarchive}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension. only file name."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_ext


#******************************************************************************************************************************
# TEST: a_get_archive_name()
#******************************************************************************************************************************
tsa__a_get_archive_name() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_name()"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar.xz"
    _output=$((a_get_archive_name _name_x "${_pkgarchive}" "${_sysarch}" "${_ref_ext}" "too_many_args") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_name()' Requires EXACT '4' arguments. Got '5'"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((a_get_archive_name _name_x "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_sysarch}' or 'any': <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((a_get_archive_name _name_x "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "A pkgarchive 'name' part MUST NOT be empty: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_name _name_x "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "attr.man"

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    a_get_archive_name _name_x "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "attr.devel"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_name


#******************************************************************************************************************************
# TEST: a_get_archive_buildvers()
#******************************************************************************************************************************
tsa__a_get_archive_buildvers() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_buildvers()"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _buildvers _pkgarchive

    _output=$((a_get_archive_buildvers) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_buildvers()' Requires EXACT '4' arguments. Got '0'"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((a_get_archive_buildvers _buildvers "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'architecture' part must be: '${_sysarch}' or 'any': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((a_get_archive_buildvers _buildvers "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_buildvers _buildvers "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_buildvers}" "1462570367"

    _pkgarchive="/home/test/cards.devel1460651449x86_64.cards.tar.xz"
    a_get_archive_buildvers _buildvers "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_buildvers}" "1460651449"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_buildvers


#******************************************************************************************************************************
# TEST: a_get_archive_arch()
#******************************************************************************************************************************
tsa__a_get_archive_arch() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_arch()"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _arch _pkgarchive

    _output=$((a_get_archive_arch) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_arch()' Requires EXACT '4' arguments. Got '0'"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((a_get_archive_arch _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_sysarch}' or 'any': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_arch _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_arch}" "any" "Test pkgarchive arch: any."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    a_get_archive_arch _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_arch}" "x86_64" "Test pkgarchive arch: x86_64."

    _pkgarchive="/home/test/attr.devel1462570367${_sysarch}.cards.tar.xz"
    a_get_archive_arch _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_arch}" "${_sysarch}" "Test pkgarchive system arch: ${_sysarch}."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_arch


#******************************************************************************************************************************
# TEST: a_get_archive_parts()
#******************************************************************************************************************************
tsa__a_get_archive_parts(){
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_parts()"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _buildvers _arch _ext _pkgarchive

    _output=$((a_get_archive_parts _name_x) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_parts()' Requires EXACT '7' arguments. Got '1'"

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_sysarch}' or 'any': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error': <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "A pkgarchive 'name' part MUST NOT be empty: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "attr.man"
    te_same_val _COK _CFAIL "${_buildvers}" "1462570367"
    te_same_val _COK _CFAIL "${_arch}" "any"
    te_same_val _COK _CFAIL "${_ext}" ".cards.tar"

    _pkgarchive="cards1460651449x86_64.cards.tar.xz"
    a_get_archive_parts _name_x _buildvers _arch _ext "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "cards"
    te_same_val _COK _CFAIL "${_buildvers}" "1460651449"
    te_same_val _COK _CFAIL "${_arch}" "x86_64"
    te_same_val _COK _CFAIL "${_ext}" ".cards.tar.xz"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_parts


#******************************************************************************************************************************
# TEST: a_get_archive_name_arch()
#******************************************************************************************************************************
tsa__a_get_archive_name_arch() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_name_arch()"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _arch _pkgarchive

    _output=$((a_get_archive_name_arch _name_x) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_get_archive_name_arch()' Requires EXACT '5' arguments. Got '1'"

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((a_get_archive_name_arch _name_x _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz': <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((a_get_archive_name_arch _name_x _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_sysarch}' or 'any': <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((a_get_archive_name_arch _name_x _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "A pkgarchive 'name' part MUST NOT be empty: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    a_get_archive_name_arch _name_x _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "attr.man"
    te_same_val _COK _CFAIL "${_arch}" "any"

    _pkgarchive="cards1460651449x86_64.cards.tar.xz"
    a_get_archive_name_arch _name_x _arch "${_pkgarchive}" "${_sysarch}" "${_ref_ext}"
    te_same_val _COK _CFAIL "${_name_x}" "cards"
    te_same_val _COK _CFAIL "${_arch}" "x86_64"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_name_arch


#******************************************************************************************************************************
# TEST: a_is_archive_uptodate()
#******************************************************************************************************************************
tsa__a_is_archive_uptodate() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_is_archive_uptodate()"
    local _tmp_dir=$(mktemp -d)
    local _portpath1="${_tmp_dir}/port1"
    local _output _is_up_to_date _pkgfile_path _pkgarchive_path_older _pkgarchive_path_newer _pkgarchive_path_not_existing
    local _pkgfile_path_not_existing

    # create port dirs
    mkdir -p "${_portpath1}"

    _output=$((a_is_archive_uptodate) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'a_is_archive_uptodate()' Requires EXACT '3' arguments. Got '0'"

    _pkgarchive_path_older="${_portpath1}/attr0000000000x86_64.cards.tar.xz"
    _pkgfile_path="${_portpath1}/Pkgfile"
    _pkgarchive_path_newer="${_portpath1}/attr0000000001x86_64.cards.tar.xz"
    # Create the testfiles in the correct order
    echo "_pkgarchive_path_older" > "${_pkgarchive_path_older}"
    sleep 2
    echo "_pkgfile_path" > "${_pkgfile_path}"
    sleep 2
    echo "_pkgarchive_path_newer" > "${_pkgarchive_path_newer}"
    if [[ ! ${_pkgfile_path} -nt ${_pkgarchive_path_older} ]]; then
        te_warn "${FUNCNAME[0]}" \
            "Erro in test setup: _pkgfile_path: <%s> (%s) is not newer than _pkgarchive_path_older: <%s>  (%s)" \
            "${_pkgfile_path}" "$(stat -c %Y ${_pkgfile_path})" "${_pkgarchive_path_older}" \
            "$(stat -c %Y ${_pkgarchive_path_older})"
    fi
    if [[ ${_pkgfile_path} -nt ${_pkgarchive_path_newer} ]]; then
        te_warn "${FUNCNAME[0]}" \
            "Erro in test setup: _pkgfile_path: <%s> (%s) is not older than _pkgarchive_path_newer: <%s>  (%s)" \
            "${_pkgfile_path}" "$(stat -c %Y ${_pkgfile_path})" "${_pkgarchive_path_newer}" \
            "$(stat -c %Y ${_pkgarchive_path_newer})"
    fi
    _pkgarchive_path_not_existing="${_portpath1}/none_existing_pkgarchive"
    a_is_archive_uptodate _is_up_to_date "${_pkgfile_path}" "${_pkgarchive_path_not_existing}"
    te_same_val _COK _CFAIL "${_is_up_to_date}" "no" "Test <_pkgarchive_path_not_existing>."

    a_is_archive_uptodate _is_up_to_date "${_pkgfile_path}" "${_pkgarchive_path_older}"
    te_same_val _COK _CFAIL "${_is_up_to_date}" "no" "Test <_pkgarchive_path_older than _pkgfile_path>."

    a_is_archive_uptodate _is_up_to_date "${_pkgfile_path}" "${_pkgarchive_path_newer}"
    te_same_val _COK _CFAIL "${_is_up_to_date}" "yes" "Test <_pkgarchive_path_newer than _pkgfile_path>."

    _pkgfile_path_not_existing="${_portpath1}/none_existing_pkgfile"
    _output=$((a_is_archive_uptodate _is_up_to_date "${_pkgfile_path_not_existing}" "${_pkgarchive_path_newer}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Corresponding Pkgfile does not exist. Path: <${_pkgfile_path_not_existing}>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsa__a_is_archive_uptodate


#******************************************************************************************************************************
# TEST: a_export()
#******************************************************************************************************************************
tsi__a_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "a_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((a_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((a_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        a_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx a_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx a_export'."

        _BF_EXPORT_ALL="no"
        a_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f a_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f a_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__a_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 75
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
