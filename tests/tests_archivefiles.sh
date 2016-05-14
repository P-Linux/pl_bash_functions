#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="${_TEST_SCRIPT_DIR}/../scripts"
_TESTFILE="archivefiles.sh"


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
u_source_safe_exit "${_FUNCTIONS_DIR}/archivefiles.sh"

declare -i _COK=0
declare -i _CFAIL=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: a_list_pkgarchives()
#******************************************************************************************************************************
tsa__a_list_pkgarchives() {
    (source "${EXCHANGE_LOG}"

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
    te_retval_0 _COK _CFAIL $? "Test 1. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retval_0 _COK _CFAIL $? "Test 2. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_0 _COK _CFAIL $? "Test 3. pkgarchive file in the result array."

    (u_in_array "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retval_1 _COK _CFAIL $? "Test 4. pkgarchive file (in subfolder) should not be included the in result array."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_list_pkgarchives


#******************************************************************************************************************************
# TEST: a_rm_pkgarchives()
#******************************************************************************************************************************
tsa__a_rm_pkgarchives() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_rm_pkgarchives()"
    local _fn="tsa__a_rm_pkgarchives"
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
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires EXACT '5' arguments. Got '4'"

    _archive_backup_dir=""
    _output=$((a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument 5 (_backup_dir) MUST NOT be empty."

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
        te_warn "_fn" "Test Error: did not find the created files."
    fi

    _archive_backup_dir="NONE"
    a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}"

    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 1. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 2. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 3. pkgarchive file was removed."

    [[ -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_0 _COK _CFAIL $? "Test 4. pkgarchive file (in subfolder) was not removed."

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
        te_warn "_fn" "Test Error: did not find the created files."
    fi

    _archive_backup_dir="${_portpath1}/pkgarchive_backup"
    mkdir -p "${_archive_backup_dir}"

    _output=$(a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" "${_archive_backup_dir}")
    te_find_info_msg _COK _CFAIL "${_output}" \
        "*Moving any existing pkgarchive files for Port*Moving to pkgarchive_backup_dir:*" \
        "Test moving existing pkgarchives to new _backup_dir."

    [[ -f "${_portpath1}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 1. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 2. pkgarchive file was removed."

    [[ -f "${_portpath1}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COK _CFAIL $? "Test 3. pkgarchive file was removed."

    [[ -f "${_portpath1}/subfolder/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_0 _COK _CFAIL $? "Test 4. pkgarchive file (in subfolder) was not removed."

    [[ -f "${_archive_backup_dir}/${_portname1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_0 _COK _CFAIL $? "Test 1. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_0 _COK _CFAIL $? "Test 2. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_0 _COK _CFAIL $? "Test 3. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_archive_backup_dir}/${_portname1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_1 _COK _CFAIL $? "Test 4. pkgarchive file (in subfolder) does not exist in pkgarchive_backup_dir."

    _output=$(a_rm_pkgarchives "${_portname1}" "${_portpath1}" "${_arch}" "${_pkg_ext}" \
        "${_archive_backup_dir}")
    te_find_info_msg _COK _CFAIL "${_output}" \
        "*Moving any existing pkgarchive files for Port*Moving to pkgarchive_backup_dir:*" \
        "Test moving existing pkgarchives to exiting _backup_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_rm_pkgarchives


#******************************************************************************************************************************
# TEST: a_get_archive_name()
#******************************************************************************************************************************
tsa__a_get_archive_name() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_name()"
    local _fn="tsa__a_get_archive_name"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_name


#******************************************************************************************************************************
# TEST: a_get_archive_buildvers()
#******************************************************************************************************************************
tsa__a_get_archive_buildvers() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_buildvers()"
    local _fn="tsa__a_get_archive_buildvers"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _buildvers _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_buildvers


#******************************************************************************************************************************
# TEST: a_get_archive_arch()
#******************************************************************************************************************************
tsa__a_get_archive_arch() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_arch()"
    local _fn="tsa__a_get_archive_arch"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _arch _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_arch


#******************************************************************************************************************************
# TEST: a_get_archive_ext()
#******************************************************************************************************************************
tsa__a_get_archive_ext() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_ext()"
    local _fn="tsa__a_get_archive_ext"
    local _ref_ext="cards.tar"
    local _output _ext _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_ext


#******************************************************************************************************************************
# TEST: a_get_archive_parts()
#******************************************************************************************************************************
tsa__a_get_archive_parts(){
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_parts()"
    local _fn="tsa__a_get_archive_parts"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _buildvers _arch _ext _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_parts


#******************************************************************************************************************************
# TEST: a_get_archive_name_arch()
#******************************************************************************************************************************
tsa__a_get_archive_name_arch() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_get_archive_name_arch()"
    local _fn="tsa__a_get_archive_name_arch"
    local _sysarch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name_x _arch _pkgarchive

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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_get_archive_name_arch


#******************************************************************************************************************************
# TEST: a_is_archive_uptodate()
#******************************************************************************************************************************
tsa__a_is_archive_uptodate() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "a_is_archive_uptodate()"
    local _fn="tsa__a_is_archive_uptodate"
    local _tmp_dir=$(mktemp -d)
    local _portpath1="${_tmp_dir}/port1"
    local _output _is_up_to_date _pkgfile_path _pkgarchive_path_older _pkgarchive_path_newer _pkgarchive_path_not_existing
    local _pkgfile_path_not_existing

    # create port dirs
    mkdir -p "${_portpath1}"

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
        te_warn "${_fn}" "Erro in test setup: _pkgfile_path: <%s> (%s) is not newer than _pkgarchive_path_older: <%s>  (%s)" \
            "${_pkgfile_path}" "$(stat -c %Y ${_pkgfile_path})" "${_pkgarchive_path_older}" \
            "$(stat -c %Y ${_pkgarchive_path_older})"
    fi
    if [[ ${_pkgfile_path} -nt ${_pkgarchive_path_newer} ]]; then
        te_warn "${_fn}" "Erro in test setup: _pkgfile_path: <%s> (%s) is not older than _pkgarchive_path_newer: <%s>  (%s)" \
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
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${EXCHANGE_LOG}"
    )
}
tsa__a_is_archive_uptodate



#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
