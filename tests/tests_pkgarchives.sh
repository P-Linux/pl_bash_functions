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
te_print_header "process_ports.sh"

source "${_FUNCTIONS_DIR}/msg.sh"
ms_format "${_THIS_SCRIPT_PATH}"

source "${_FUNCTIONS_DIR}/utilities.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/source_matrix.sh"
ut_source_safe_abort "${_FUNCTIONS_DIR}/pkgarchives.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0

EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: pka_get_existing_pkgarchives()
#******************************************************************************************************************************
ts_pka___pka_get_existing_pkgarchives() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_existing_pkgarchives()"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}//${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()

    # Make folders
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

    # check none found: must be 0 size return
    touch "${_port_path1}/README"
    touch "${_port_path1}/test"

    pka_get_existing_pkgarchives _targets _port_name1 _port_path1 _arch _pkg_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${#_targets[@]}" "0" "Test find 0 pkgarchive files."

    # Make files
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    pka_get_existing_pkgarchives _targets _port_name1 _port_path1 _arch _pkg_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${#_targets[@]}" "3" \
        "Test find 3 pkgarchive files (one in subfolder should not be included)"

    (ut_in_array "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 1. pkgarchive file in the result array."

    (ut_in_array "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 2. pkgarchive file in the result array."

    (ut_in_array "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 3. pkgarchive file in the result array."

    (ut_in_array "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 4. pkgarchive file (in subfolder) should not be included the in result array."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_existing_pkgarchives


#******************************************************************************************************************************
# TEST: pka_remove_existing_pkgarchives()
#******************************************************************************************************************************
ts_pka___pka_remove_existing_pkgarchives() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_remove_existing_pkgarchives()"
    local _fn="ts_pka___pka_remove_existing_pkgarchives"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}/${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()
    local _pkgarchive_backup_dir

    # Make files
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

    _output=$((pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Requires EXACT '5' arguments. Got '4'"
    
    _pkgarchive_backup_dir=""
    _output=$((pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext _pkgarchive_backup_dir) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" "FUNCTION Argument 5 (_in_pkgarchive_backup_dir) MUST NOT be empty."
    
    _pkgarchive_backup_dir="${_port_path1}/pkgarchive_backup"
    _output=$((pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext _pkgarchive_backup_dir) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "_in_pkgarchive_backup_dir does not exist: <${_pkgarchive_backup_dir}" "Test none existing pkgarchive_backup_dir."

    touch "${_port_path1}/README"
    touch "${_port_path1}/test"
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    # check they really exist
    [[ -f "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    if (( ${?} )); then
        te_warn "_fn" "Test Error: did not find the created files."
    fi
    
    _pkgarchive_backup_dir="NONE"
    pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext _pkgarchive_backup_dir

    [[ -f "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 1. pkgarchive file was removed."

    [[ -f "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 2. pkgarchive file was removed."

    [[ -f "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 3. pkgarchive file was removed."

    [[ -f "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 4. pkgarchive file (in subfolder) was not removed."

    touch "${_port_path1}/README"
    touch "${_port_path1}/test"
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    # check they really exist
    [[ -f "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" && \
       -f "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" && \
       -f "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    if (( ${?} )); then
        te_warn "_fn" "Test Error: did not find the created files."
    fi
    
    _pkgarchive_backup_dir="${_port_path1}/pkgarchive_backup"
    mkdir -p "${_pkgarchive_backup_dir}"
    
    _output=$(pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext _pkgarchive_backup_dir)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "*Moving any existing pkgarchive files for Port*Moving to pkgarchive_backup_dir:*" \
        "Test moving existing pkgarchives to new _backup_dir."

    [[ -f "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 1. pkgarchive file was removed."

    [[ -f "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 2. pkgarchive file was removed."

    [[ -f "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 3. pkgarchive file was removed."

    [[ -f "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 4. pkgarchive file (in subfolder) was not removed."

    [[ -f "${_pkgarchive_backup_dir}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 1. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_pkgarchive_backup_dir}/${_port_name1}1458148355any.${_pkg_ext}.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 2. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_pkgarchive_backup_dir}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test 3. pkgarchive file exists in pkgarchive_backup_dir."

    [[ -f "${_pkgarchive_backup_dir}/${_port_name1}man1458148355${_arch}.${_pkg_ext}" ]]
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 4. pkgarchive file (in subfolder) does not exist in pkgarchive_backup_dir."

    _output=$(pka_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext _pkgarchive_backup_dir)
    te_find_info_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "*Moving any existing pkgarchive files for Port*Moving to pkgarchive_backup_dir:*" \
        "Test moving existing pkgarchives to exiting _backup_dir."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_remove_existing_pkgarchives


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_name()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_name() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_name()"
    local _fn="ts_pka___pka_get_pkgarchive_name"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pka_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((pka_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.man"

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pka_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.devel"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_name


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_buildvers()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_buildvers() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_buildvers()"
    local _fn="ts_pka___pka_get_pkgarchive_buildvers"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _buildvers _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pka_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part must be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((pka_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1462570367"

    _pkgarchive="/home/test/cards.devel1460651449x86_64.cards.tar.xz"
    pka_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1460651449"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_buildvers


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_arch()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_arch() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_arch()"
    local _fn="ts_pka___pka_get_pkgarchive_arch"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _arch _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pka_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "any" "Test pkgarchive arch: any."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pka_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "x86_64" "Test pkgarchive arch: x86_64."

    _pkgarchive="/home/test/attr.devel1462570367${_system_arch}.cards.tar.xz"
    pka_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "${_system_arch}" "Test pkgarchive system arch: ${_system_arch}."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_arch


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_ext()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_ext() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_ext()"
    local _fn="ts_pka___pka_get_pkgarchive_ext"
    local _ref_ext="cards.tar"
    local _output _ext _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((pka_get_pkgarchive_ext _ext _pkgarchive _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar" "Test pkgarchive extension without compression."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pka_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension."

    _pkgarchive="attr.fr1462570367any.cards.tar.xz"
    pka_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension. only file name."

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_ext


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_parts()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_parts(){
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_parts()"
    local _fn="ts_pka___pka_get_pkgarchive_parts"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name _buildvers _arch _ext _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.man"
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1462570367"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "any"
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar"

    _pkgarchive="cards1460651449x86_64.cards.tar.xz"
    pka_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "cards"
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1460651449"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "x86_64"
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_parts


#******************************************************************************************************************************
# TEST: pka_get_pkgarchive_name_arch()
#******************************************************************************************************************************
ts_pka___pka_get_pkgarchive_name_arch() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_get_pkgarchive_name_arch()"
    local _fn="ts_pka___pka_get_pkgarchive_name_arch"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name _arch _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((pka_get_pkgarchive_name_arch _name _arch _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pka_get_pkgarchive_name_arch _name _arch _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((pka_get_pkgarchive_name_arch _name _arch _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pka_get_pkgarchive_name_arch _name _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.man"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "any"

    _pkgarchive="cards1460651449x86_64.cards.tar.xz"
    pka_get_pkgarchive_name_arch _name _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "cards"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "x86_64"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_get_pkgarchive_name_arch


#******************************************************************************************************************************
# TEST: pka_is_pkgarchive_up_to_date()
#******************************************************************************************************************************
ts_pka___pka_is_pkgarchive_up_to_date() {
    (source "${EXCHANGE_LOG}"

    te_print_function_msg "pka_is_pkgarchive_up_to_date()"
    local _fn="ts_pka___pka_is_pkgarchive_up_to_date"
    local _tmp_dir=$(mktemp -d)
    local _port_path1="${_tmp_dir}/port1"
    local _output _is_up_to_date _pkgfile_path _pkgarchive_path_older _pkgarchive_path_newer _pkgarchive_path_not_existing
    local _pkgfile_path_not_existing

    # create port dirs
    mkdir -p "${_port_path1}"

    _pkgarchive_path_older="${_port_path1}/attr0000000000x86_64.cards.tar.xz"
    _pkgfile_path="${_port_path1}/Pkgfile"
    _pkgarchive_path_newer="${_port_path1}/attr0000000001x86_64.cards.tar.xz"
    # Create the testfiles in the correct order
    echo "_pkgarchive_path_older" > "${_pkgarchive_path_older}"
    sleep 2
    echo "_pkgfile_path" > "${_pkgfile_path}"
    sleep 2
    echo "_pkgarchive_path_newer" > "${_pkgarchive_path_newer}"
    if [[ ! ${_pkgfile_path} -nt ${_pkgarchive_path_older} ]]; then
        te_warn "${_fn}" "Erro in test setup: _pkgfile_path: <%s> (%s) is not newer than _pkgarchive_path_older: <%s>  (%s)" \
            "${_pkgfile_path}" "$(stat -c %Y ${_pkgfile_path})" \
            "${_pkgarchive_path_older}" "$(stat -c %Y ${_pkgarchive_path_older})"
    fi
    if [[ ${_pkgfile_path} -nt ${_pkgarchive_path_newer} ]]; then
        te_warn "${_fn}" "Erro in test setup: _pkgfile_path: <%s> (%s) is not older than _pkgarchive_path_newer: <%s>  (%s)" \
            "${_pkgfile_path}" "$(stat -c %Y ${_pkgfile_path})" \
            "${_pkgarchive_path_newer}" "$(stat -c %Y ${_pkgarchive_path_newer})"
    fi
    _pkgarchive_path_not_existing="${_port_path1}/none_existing_pkgarchive"
    pka_is_pkgarchive_up_to_date _is_up_to_date _pkgfile_path _pkgarchive_path_not_existing
    te_same_val _COUNT_OK _COUNT_FAILED "${_is_up_to_date}" "no" "Test <_pkgarchive_path_not_existing>."

    pka_is_pkgarchive_up_to_date _is_up_to_date _pkgfile_path _pkgarchive_path_older
    te_same_val _COUNT_OK _COUNT_FAILED "${_is_up_to_date}" "no" "Test <_pkgarchive_path_older than _pkgfile_path>."

    pka_is_pkgarchive_up_to_date _is_up_to_date _pkgfile_path _pkgarchive_path_newer
    te_same_val _COUNT_OK _COUNT_FAILED "${_is_up_to_date}" "yes" "Test <_pkgarchive_path_newer than _pkgfile_path>."

    _pkgfile_path_not_existing="${_port_path1}/none_existing_pkgfile"
    _output=$((pka_is_pkgarchive_up_to_date _is_up_to_date _pkgfile_path_not_existing _pkgarchive_path_newer) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "Corresponding Pkgfile does not exist. Path: <${_pkgfile_path_not_existing}>"

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COUNT_OK=${_COUNT_OK}; _COUNT_FAILED=${_COUNT_FAILED}" > "${EXCHANGE_LOG}"
    )
}
ts_pka___pka_is_pkgarchive_up_to_date


#******************************************************************************************************************************

source "${EXCHANGE_LOG}"
te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"
rm -f "${EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
