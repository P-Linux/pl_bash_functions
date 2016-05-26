#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************
_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="init_conf.sh"

source "${_FUNCTIONS_DIR}/init_conf.sh"
_BF_ON_ERROR_KILL_PROCESS=0     # Set the sleep seconds before killing all related processes or to less than 1 to skip it

for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
trap 'i_trap_i ${?}' INT
# For testing don't use error traps: as we expect failed tests - otherwise we would need to adjust all
#trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR

# do not use `i_source_safe_exit` in this case because it was not yet testet
source "${_FUNCTIONS_DIR}/testing.sh"
te_print_header "${_TESTFILE}"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: i_set_pl_bash_function_var_readonly                             SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_general_opt() Limited test to just cross check some setting
#******************************************************************************************************************************
tsi__i_general_opt() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_general_opt()"
    local _output

    _output=$(set +o)
    te_find_info_msg _COK _CFAIL "${_output}" "set +o errexit" "Test option: set +o errexit"
    te_find_info_msg _COK _CFAIL "${_output}" "set -o errtrace" "Test option: set -o errtrace"
    te_find_info_msg _COK _CFAIL "${_output}" "set +o histexpand" "Test option: set +o histexpand"
    te_find_info_msg _COK _CFAIL "${_output}" "set +o monitor" "Test option: set +o monitor"
    te_find_info_msg _COK _CFAIL "${_output}" "set +o noclobber" "Test option: set +o noclobber"
    te_find_info_msg _COK _CFAIL "${_output}" "set -o nounset" "Test option: set -o nounset"
    te_find_info_msg _COK _CFAIL "${_output}" "set -o pipefail" "Test option: set -o pipefail"
    te_find_info_msg _COK _CFAIL "${_output}" "set +o posix" "Test option: set +o posix"

    _output=$(shopt -p)
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -s dotglob" "Test shopt -s dotglob"
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -s expand_aliases" "Test shopt -s expand_aliases"
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -s extglob" "Test shopt -s extglob"
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -s interactive_comments" "Test shopt -s interactive_comments"
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -u nocasematch" "Test shopt -u nocasematch"
    te_find_info_msg _COK _CFAIL "${_output}" "shopt -u nullglob" "Test shopt -u nullglob"

    te_same_val _COK _CFAIL "$(alias -p)" "alias _g='gettext'" "Test if we only got the defined aliases"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_general_opt


#******************************************************************************************************************************
# TEST: i_get_pgid()
#******************************************************************************************************************************
tsi__i_get_pgid() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_get_pgid()"
    declare  -i _PGID; i_get_pgid _PGID ${BASHPID}
    declare  -i _PGID2; i_get_pgid _PGID2 ${$}

    te_same_val _COK _CFAIL "${_PGID}" "${_PGID2}" \
        "Test BASHPID: <${BASHPID}> and ParentPid: <${$}> retrieve the same Process-Group-ID."

    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_get_pgid


#******************************************************************************************************************************
# TEST: i_source_safe_exit()
#******************************************************************************************************************************
tsi__i_source_safe_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_source_safe_exit()"
    local _output

    _output=$((i_source_safe_exit) 2>&1)  # avoid trap call
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '1' argument (_file). Got '0'" \
        "Test No argument (file) supplied."

    _output=$((i_source_safe_exit "${_TEST_SCRIPT_DIR}/files/none_existing_file") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" " Could not source file" \
        "Test none existing file supplied."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_source_safe_exit


#******************************************************************************************************************************
# TEST: i_pl_bash_functions_dir()
#******************************************************************************************************************************
tsi__i_pl_bash_functions_dir() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_pl_bash_functions_dir() very limited test"
    local _installed_dir; i_pl_bash_functions_dir _installed_dir
    local _ref_script_dir=$(readlink -f "${_FUNCTIONS_DIR}")

    te_same_val _COK _CFAIL "${_installed_dir}" "${_ref_script_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_pl_bash_functions_dir


#******************************************************************************************************************************
# TEST: i_has_tested_version()
#******************************************************************************************************************************
tsi__i_has_tested_version() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_has_tested_version()"
    local _msg1="${_BF_YELLOW}====> WARNING:"
    local _output

    _output=$((i_has_tested_version "different_version") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" \
        "${_msg1}${_BF_OFF} This script was ${_BF_BOLD}TESTET${_BF_OFF} with <pl_bash_functions>: 'different_version'"

    _output=$((i_has_tested_version "${_BF_VERSION}") 2>&1)
    te_empty_val _COK _CFAIL "${_output}" "Testing same pl_bash_functions version."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_has_tested_version


#******************************************************************************************************************************
# TEST: i_ask_continue                                                  SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_common_exit()
#******************************************************************************************************************************
tsi__i_common_exit() {
    (source "${_EXCHANGE_LOG}"

    _dummy_test() {
        printf "%s\n" "Just a dummy test function"
    }

    te_print_function_msg "i_common_exit()"
    local _output

    _output=$((i_common_exit 19 BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "_dummy_test") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "============== CALL STACK INFO ==============" "Test general Call Stack Output"
    te_find_info_msg _COK _CFAIL "${_output}" "Just a dummy test function" "Test function is run before exit."

    unset -f "noneexisting_function"
    _output=$((i_common_exit 19 BASH_LINENO[@] BASH_SOURCE[@] FUNCNAME[@] "noneexisting_function") 2>&1)
    [[ "${_output}" != *"Just a dummy test function"* ]]
    te_retcode_0 _COK _CFAIL ${?} "Test wrong function name given. Function is skipped."
    te_find_err_msg _COK _CFAIL "${_output}" \
        "CODE-ERROR Could not find the specified function: 'noneexisting_function' to run before exiting." \
        "Test wrong function name given."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_common_exit


#******************************************************************************************************************************
# TEST: i_trap_s
#******************************************************************************************************************************
tsi__i_trap_s() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_trap_s()"
    local _filename="/home/testfile.txt"
    local _info="Find passed info message: Just some extra info."
    local _output

    _output=$((i_trap_s 20 "QUIT") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "<i_trap_s (signal: 'QUIT')>"

    _output=$((i_trap_s 20 "TERM") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "<i_trap_s (signal: 'TERM')>"

    _output=$((i_trap_s 20 "HUP") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "<i_trap_s (signal: 'HUP')>"

    (i_trap_s 20 "QUIT") &> /dev/null
    te_retcode_same _COK _CFAIL ${?} 20 "Test return code is passed through."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_trap_s


#******************************************************************************************************************************
# TEST: i_trap_i
#******************************************************************************************************************************
tsi__i_trap_i() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_trap_i()"
    local _output

    _output=$((i_trap_i 130) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Interrupted by user! Exit Status: '130'"

    (i_trap_i 25) &> /dev/null
    te_retcode_same _COK _CFAIL ${?} 25 "Test return code is passed through."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_trap_i


#******************************************************************************************************************************
# TEST: i_trap_err
#******************************************************************************************************************************
tsi__i_trap_err() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_trap_err()"
    local _output


    _output=$((i_trap_err 27 "test command" 139) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Line: '${_BF_BOLD}139${_BF_OFF}' File: '${_BF_BOLD}tests_init_conf.sh${_BF_OFF}'"
    te_find_err_msg _COK _CFAIL "${_output}" "Command: '${_BF_BOLD}test command${_BF_OFF}'"

    (i_trap_err 127 "test command" 139) &> /dev/null
    te_retcode_same _COK _CFAIL ${?} 127 "Test return code is passed through."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_trap_err


#******************************************************************************************************************************
# TEST: i_exit()
#******************************************************************************************************************************
tsi__i_exit() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_exit()"
    local _filename="/home/testfile.txt"
    local _info="Find passed info message: Just some extra info."
    local _output

    _output=$((i_exit 1 180) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '3' arguments. Got '2'"

    _output=$((i_exit 1 180 "Did Not find file: <${_filename}> _info: '${_info}'") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "_info: 'Find passed info message: Just some extra info.'"

    (i_exit 18 180 "$(_g "Did Not find file: <%s> _info: '%s'")" "${_filename}" "${_info}") &> /dev/null
    te_retcode_same _COK _CFAIL ${?} 18 "Test return code is passed through. using gettext example."

    ##
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_exit


#******************************************************************************************************************************
# TEST: i_exit_remove_path()
#******************************************************************************************************************************
tsi__i_exit_remove_path() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_exit_remove_path()"
    local _tmp_dir=$(mktemp -d)
    local _builds_dir="${_tmp_dir}/builds"
    local _output

    _output=$((i_exit_remove_path 180) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Requires AT LEAST '5' arguments. Got '1'"

    _output=$((i_exit_remove_path 5 180 "wrong" "${_builds_dir}" "No examples") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION Argument '3' (_do_remove) MUST be 'yes' or 'no'. Got 'wrong'"

    _output=$((i_exit_remove_path 5 180 "yes" "" "Path is: ${_tmp_dir}/none_existing") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION Argument '4' (_path) MUST NOT be empty if argument '3' (_do_remove) is 'yes'"

    _output=$((i_exit_remove_path 90 190 "yes" "${_builds_dir}" "Did not find any examples") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Did not find any examples"
    te_find_err_msg _COK _CFAIL "${_output}" "INFO: Removing path"

    # create the dir
    mkdir -p "${_builds_dir}"

    _output=$((i_exit_remove_path 90 190 "no" "" "Keeping build_dir: <%s>" "${_builds_dir}") 2>&1)
    if [[ ! -d ${_builds_dir} ]]; then
        te_abort ${LINENO} "ERROR IN TEST-case: Keeping build_dir: <${_builds_dir}> should still exist."
    fi
    te_find_info_msg _COK _CFAIL "${_output}" "Keeping build_dir" "Test build_dir is kept."

    _output=$((i_exit_remove_path 90 190 "yes" "${_builds_dir}" "Removing build_dir: <%s>" "${_builds_dir}") 2>&1)
    te_find_info_msg _COK _CFAIL "${_output}" "Removing build_dir" "Test build_dir is removed."

    (i_exit_remove_path 1 190 "yes" "${_builds_dir}" "Removing build_dir: <%s>" "${_builds_dir}") &> /dev/null
    te_retcode_1 _COK _CFAIL ${?} "Remove Path is: 'yes' BUT none existing."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_exit_remove_path


#******************************************************************************************************************************
# TEST: i_err                                                           SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_err2                                                          SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_warn                                                          SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_warn2                                                         SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_bold                                                          SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_bold_i                                                        SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_bold()
#******************************************************************************************************************************
tsi__bold() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "tsi__bold()"
    local _filename="/home/testfile.txt"
    local _output

    _BF_OUT="no"
    _output=$(i_bold "$(_g "Source file: <%s>")" "${_filename}")
    te_empty_val _COK _CFAIL "${_output}" "Testing _BF_OUT=no skip output."

    _BF_OUT="yes"
    _output=$(i_bold "$(_g "Source file: <%s>")" "${_filename}")
    te_not_empty_val _COK _CFAIL "${_output}" "Testing _BF_OUT=yes expect output."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__bold


#******************************************************************************************************************************
# TEST: i_bold2_i                                                       SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_msg                                                           SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_msg_b                                                         SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_msg_i                                                         SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_msg2                                                          SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_msg2_i                                                        SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_more()
#******************************************************************************************************************************
tsi__i_more() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_more()"
    local _filename="/home/testfile.txt"
    local _output

    _BF_OUT_I="no"
    _output=$(i_more "$(_g "Source file: <%s>")" "${_filename}")
    te_empty_val _COK _CFAIL "${_output}" "Testing _BF_OUT_I=no skip output."

    _BF_OUT_I="yes"
    _output=$(i_more "$(_g "Source file: <%s>")" "${_filename}")
    te_not_empty_val _COK _CFAIL "${_output}" "Testing _BF_OUT_I=yes expect output."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_more


#******************************************************************************************************************************
# TEST: i_more_i                                                        SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_color                                                         SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: i_header                                                        SKIP THIS TEST
#******************************************************************************************************************************


#******************************************************************************************************************************
# TEST: i_hrl()
#******************************************************************************************************************************
tsi__i_hrl() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "i_hrl()"
    local _expected_output="${_BF_GREEN}#=========================#${_BF_OFF}"
    local _output=$(i_hrl "${_BF_GREEN}" "#" "=" 25 "#")

    te_same_val _COK _CFAIL "${_output}" "${_expected_output}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__i_hrl


#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}"
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
