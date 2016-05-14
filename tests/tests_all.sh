#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#   IMPORTANT:
#       This will output some messages about: `msg.sh`: readonly variable`
#            just ignore it or run the individual test files
#
#******************************************************************************************************************************


declare -r _THIS_SCRIPT_PATH_ALL=$(readlink -f "${BASH_SOURCE[0]}")
declare -r _TEST_SCRIPT_DIR_ALL=$(dirname "${_THIS_SCRIPT_PATH_ALL}")
declare -r _FUNCTIONS_DIR_ALL="${_TEST_SCRIPT_DIR_ALL}/../scripts"
declare -r _TESTFILE_ALL="ALL"

source "${_FUNCTIONS_DIR_ALL}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\"" "${_signal}"; done
trap "t_trap_i" INT
#DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "t_trap_u" ERR

source "${_FUNCTIONS_DIR_ALL}/testing.sh"

declare -i _COK_ALL=0
declare -i _CFAIL_ALL=0


#******************************************************************************************************************************

# trap_opt.sh: No tests for this file

source "${_TEST_SCRIPT_DIR_ALL}/tests_testing.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_msg.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_util.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_src_matrix.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_download.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_extract.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_localization.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_pkgfile.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_archivefiles.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

source "${_TEST_SCRIPT_DIR_ALL}/tests_process_ports.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))



#******************************************************************************************************************************

te_print_final_result "${_TESTFILE_ALL}" "${_COK_ALL}" "${_CFAIL_ALL}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
