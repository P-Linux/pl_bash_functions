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


#******************************************************************************************************************************
# TEST: pa_get_existing_pkgarchives()
#******************************************************************************************************************************
ts_pk___pa_get_existing_pkgarchives() {
    te_print_function_msg "pa_get_existing_pkgarchives()"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}//${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()

    # Make files
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

    touch "${_port_path1}/README"
    touch "${_port_path1}/test"
    touch "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz"
    touch "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz"
    touch "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}"

    pa_get_existing_pkgarchives _targets _port_name1 _port_path1 _arch _pkg_ext
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
}
ts_pk___pa_get_existing_pkgarchives


#******************************************************************************************************************************
# TEST: pa_remove_existing_pkgarchives()
#******************************************************************************************************************************
ts_pk___pa_remove_existing_pkgarchives() {
    te_print_function_msg "pa_remove_existing_pkgarchives()"
    local _fn="ts_pk___pa_remove_existing_pkgarchives"
    local _tmp_dir=$(mktemp -d)
    local _port_name1="port1"
    local _port_path1="${_tmp_dir}/${_port_name1}"
    local _arch="$(uname -m)"
    local _pkg_ext="cards.tar"
    local _pkgarchive
    local _targets=()

    # Make files
    mkdir -p "${_port_path1}"
    mkdir -p "${_port_path1}/subfolder"

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

    pa_remove_existing_pkgarchives _port_name1 _port_path1 _arch _pkg_ext

    (ut_in_array "${_port_path1}/${_port_name1}1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 1. pkgarchive file was removed."

    (ut_in_array "${_port_path1}/${_port_name1}1458148355any.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 2. pkgarchive file was removed."

    (ut_in_array "${_port_path1}/${_port_name1}devel1458148355${_arch}.${_pkg_ext}.xz" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 3. pkgarchive file was removed."

    (ut_in_array "${_port_path1}/subfolder/${_port_name1}man1458148355${_arch}.${_pkg_ext}" _targets)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test 4. pkgarchive file (in subfolder) was removed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"
}
ts_pk___pa_remove_existing_pkgarchives


#******************************************************************************************************************************
# TEST: pa_get_pkgarchive_name()
#******************************************************************************************************************************
ts_pk___pa_get_pkgarchive_name() {
    te_print_function_msg "pa_get_pkgarchive_name()"
    local _fn="ts_pk___pa_get_pkgarchive_name"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((pa_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pa_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.man"

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pa_get_pkgarchive_name _name _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.devel"
}
ts_pk___pa_get_pkgarchive_name


#******************************************************************************************************************************
# TEST: pa_get_pkgarchive_buildvers()
#******************************************************************************************************************************
ts_pk___pa_get_pkgarchive_buildvers() {
    te_print_function_msg "pa_get_pkgarchive_buildvers()"
    local _fn="ts_pk___pa_get_pkgarchive_buildvers"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _buildvers _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part must be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((pa_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pa_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1462570367"

    _pkgarchive="/home/test/cards.devel1460651449x86_64.cards.tar.xz"
    pa_get_pkgarchive_buildvers _buildvers _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1460651449"
}
ts_pk___pa_get_pkgarchive_buildvers


#******************************************************************************************************************************
# TEST: pa_get_pkgarchive_arch()
#******************************************************************************************************************************
ts_pk___pa_get_pkgarchive_arch() {
    te_print_function_msg "pa_get_pkgarchive_arch()"
    local _fn="ts_pk___pa_get_pkgarchive_arch"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _arch _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pa_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "any" "Test pkgarchive arch: any."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pa_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "x86_64" "Test pkgarchive arch: x86_64."

    _pkgarchive="/home/test/attr.devel1462570367${_system_arch}.cards.tar.xz"
    pa_get_pkgarchive_arch _arch _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "${_system_arch}" "Test pkgarchive system arch: ${_system_arch}."
}
ts_pk___pa_get_pkgarchive_arch


#******************************************************************************************************************************
# TEST: pa_get_pkgarchive_ext()
#******************************************************************************************************************************
ts_pk___pa_get_pkgarchive_ext() {
    te_print_function_msg "pa_get_pkgarchive_ext()"
    local _fn="ts_pk___pa_get_pkgarchive_ext"
    local _ref_ext="cards.tar"
    local _output _ext _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((pa_get_pkgarchive_ext _ext _pkgarchive _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pa_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar" "Test pkgarchive extension without compression."

    _pkgarchive="/home/test/attr.devel1462570367x86_64.cards.tar.xz"
    pa_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension."

    _pkgarchive="attr.fr1462570367any.cards.tar.xz"
    pa_get_pkgarchive_ext _ext _pkgarchive _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz" "Test compressed pkgarchive extension. only file name."
}
ts_pk___pa_get_pkgarchive_ext


#******************************************************************************************************************************
# TEST: pa_get_pkgarchive_parts()
#******************************************************************************************************************************
ts_pk___pa_get_pkgarchive_parts() {
    te_print_function_msg "pa_get_pkgarchive_parts()"
    local _fn="ts_pk___pa_get_pkgarchive_parts"
    local _system_arch=$(uname -m)
    local _ref_ext="cards.tar"
    local _output _name _buildvers _arch _ext _pkgarchive

    _pkgarchive="/home/test/attr.man1462570367any.wrong.tar.xz"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'extension' part MUST end with: 'cards.tar' or 'cards.tar.xz'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man14error367any.cards.tar.xz"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "'buildvers' MUST NOT be empty and only contain digits and not: 'error'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367wrong.cards.tar.xz"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'architecture' part MUST be: '${_system_arch}' or 'any'. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/1462570367any.cards.tar"
    _output=$((pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "${_output}" \
        "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <${_pkgarchive}>"

    _pkgarchive="/home/test/attr.man1462570367any.cards.tar"
    pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "attr.man"
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1462570367"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "any"
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar"

    _pkgarchive="cards1460651449x86_64.cards.tar.xz"
    pa_get_pkgarchive_parts _name _buildvers _arch _ext _pkgarchive _system_arch _ref_ext
    te_same_val _COUNT_OK _COUNT_FAILED "${_name}" "cards"
    te_same_val _COUNT_OK _COUNT_FAILED "${_buildvers}" "1460651449"
    te_same_val _COUNT_OK _COUNT_FAILED "${_arch}" "x86_64"
    te_same_val _COUNT_OK _COUNT_FAILED "${_ext}" ".cards.tar.xz"
}
ts_pk___pa_get_pkgarchive_parts


#******************************************************************************************************************************

te_print_final_result "${_COUNT_OK}" "${_COUNT_FAILED}"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
