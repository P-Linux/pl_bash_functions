#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************
_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="localization.sh"

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
i_source_safe_exit "${_FUNCTIONS_DIR}/localization.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: l_generate_pot_file()
#******************************************************************************************************************************
tsl__l_generate_pot_file() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "l_generate_pot_file()"
    local _srcfile="${_FUNCTIONS_DIR}/util.sh"
    local _wrong_srcfile="none_existing.sh"
    local _outdir=$(mktemp -d)
    local _pkgname="pl_bash_functions"
    local _copyright="peter1000 <https://github.com/peter1000>"
    local _copyright_start="2016"
    local _url="https://github.com/peter1000"
    local _bugs_url="https://github.com/peter1000/issue"
    local _basename; u_basename _basename "${_srcfile}"
    local _file_txt

    (l_generate_pot_file "${_wrong_srcfile}" "${_outdir}" "${_pkgname}" "${_copyright}" "${_copyright_start}" "${_url}" \
        "${_bugs_url}") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Test none existing source file."

    (l_generate_pot_file "${_srcfile}" "${_outdir}" "${_pkgname}" "${_copyright}" "${_copyright_start}" "${_url}" \
        "${_bugs_url}") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test existing source file."

    _file_txt=$(<"${_outdir}/${_basename}.pot")

    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "# Package: <pl_bash_functions> autogenerated from source-file: <util.sh" "Test pot file header TITLE."

    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "# peter1000 <https://github.com/peter1000> <https://github.com/peter1000>. 2016." "Test pot file header Copyright."

    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "# peter1000 <https://github.com/peter1000> <https://github.com/pe" "Test pot file header AUTHOR."

    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "Language-Team: LANGUAGE <https://github.com/peter1000>" "Test pot file header Language-Team."

    te_find_info_msg _COK _CFAIL "${_file_txt}" "Content-Type: text/plain; charset=UTF-8" "Test pot file header charset."

    # CLEAN UP
    rm -rf "${_outdir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsl__l_generate_pot_file


#******************************************************************************************************************************
# TEST: l_generate_po_files()
#******************************************************************************************************************************
tsl__l_generate_po_files() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "l_generate_po_files()"
    local _srcfiles=("${_FUNCTIONS_DIR}/util.sh")
    local _utf8_languages=("de_DE.UTF-8" "en_US.UTF-8" "pt_BR.UTF-8")
    local _wrong_srcfile="none_existing.sh"
    local _outdir=$(mktemp -d)
    local _pkgname="pl_bash_functions"
    local _copyright="peter1000 <https://github.com/peter1000>"
    local _copyright_start="2016"
    local _url="https://github.com/peter1000"
    local _bugs_url="https://github.com/peter1000/issue"
    local _src_name; u_basename _src_name "${_srcfiles[0]}"
    local _file_txt

    (l_generate_po_files _srcfiles _utf8_languages "${_outdir}" "${_pkgname}" "${_copyright}" "${_copyright_start}" "${_url}" \
        "${_bugs_url}") &> /dev/null
    te_retcode_0 _COK _CFAIL ${?} "Test existing source file."

    [[ -f "${_outdir}/${_src_name}.pot"                    && \
        -f "${_outdir}/de_DE.UTF-8/LC_MESSAGES/util.sh_empty.po"   && \
        -f "${_outdir}/en_US.UTF-8/LC_MESSAGES/util.sh_empty.po"   && \
        -f "${_outdir}/pt_BR.UTF-8/LC_MESSAGES/util.sh_empty.po"
        ]]
    te_retcode_0 _COK _CFAIL ${?} "Test all expected / generated .pot and .po files exist."

    _file_txt=$(<"${_outdir}/${_src_name}.pot")
    # Header check
    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "# Package: <pl_bash_functions> autogenerated from source-file: <util.sh" "Test pot file header TITLE."

    _file_txt=$(<"${_outdir}/de_DE.UTF-8/LC_MESSAGES/util.sh_empty.po")
    te_find_info_msg _COK _CFAIL "${_file_txt}" \
        "Last-Translator: peter1000 <https://github.com/peter1000> <https:" "Test de_DE po file Last-Translator."

    te_find_info_msg _COK _CFAIL "${_file_txt}" "Language-Team: LANGUAGE <https://github.com/peter1000>" \
        "Test de_DE po file Language-Team."

    te_find_info_msg _COK _CFAIL "${_file_txt}" "Language: de_DE" "Test de_DE po file Language."

    _file_txt=$(<"${_outdir}/en_US.UTF-8/LC_MESSAGES/util.sh_empty.po")
    te_find_info_msg _COK _CFAIL "${_file_txt}" "Language: en_US" "Test en_US po file Language."

    _file_txt=$(<"${_outdir}/pt_BR.UTF-8/LC_MESSAGES/util.sh_empty.po")
    te_find_info_msg _COK _CFAIL "${_file_txt}" "Language: pt_BR" "Test pt_BR po file Language."

     CLEAN UP
    rm -rf "${_outdir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsl__l_generate_po_files


#******************************************************************************************************************************
# TEST: l_export()
#******************************************************************************************************************************
tsi__l_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "l_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((l_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((l_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        l_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx l_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx l_export'."

        _BF_EXPORT_ALL="no"
        l_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f l_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f l_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__l_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 21
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
