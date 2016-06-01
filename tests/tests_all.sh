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
_THIS_SCRIPT_PATH_ALL=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR_ALL=$(dirname "${_THIS_SCRIPT_PATH_ALL}")
_FUNCTIONS_DIR_ALL="$(dirname "${_TEST_SCRIPT_DIR_ALL}")/scripts"
declare -r _TESTFILE_ALL="ALL"

_BF_EXPORT_ALL="yes"
source "${_FUNCTIONS_DIR_ALL}/init_conf.sh"
_BF_ON_ERROR_KILL_PROCESS=0     # Set the sleep seconds before killing all related processes or to less than 1 to skip it

for _signal in TERM HUP QUIT; do trap 'i_trap_s ${?} "${_signal}"' "${_signal}"; done
trap 'i_trap_i ${?}' INT
# For testing don't use error traps: as we expect failed tests - otherwise we would need to adjust all
#trap 'i_trap_err ${?} "${BASH_COMMAND}" ${LINENO}' ERR
trap 'i_trap_exit ${?} "${BASH_COMMAND}"' EXIT

i_ask_continue

i_source_safe_exit "${_FUNCTIONS_DIR_ALL}/testing.sh"
te_print_header "${_TESTFILE_ALL}"

declare -i _COK_ALL=0
declare -i _CFAIL_ALL=0


#******************************************************************************************************************************

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
i_source_safe_exit "${_TEST_SCRIPT_DIR_ALL}/tests_init_conf.sh"
_COK_ALL+=${_COK}
_CFAIL_ALL+=${_CFAIL}

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_testing.sh"
_COK_ALL+=${_COK}
_CFAIL_ALL+=${_CFAIL}

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_util.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_src_matrix.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_download.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_extract.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_localization.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_pkgfile.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_archivefiles.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))

# reset them in case a file is not sourced
_COK=0; _CFAIL=0
source "${_TEST_SCRIPT_DIR_ALL}/tests_process_ports.sh"
((_COK_ALL+=${_COK}))
((_CFAIL_ALL+=${_CFAIL}))



#******************************************************************************************************************************

te_print_final_result "${_TESTFILE_ALL}" "${_COK_ALL}" "${_CFAIL_ALL}" 700

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
