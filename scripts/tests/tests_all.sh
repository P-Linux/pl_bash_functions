#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#   IMPORTANT:
#       This will output some messages about: `msg.sh & _THIS_SCRIPT_PATH`: readonly variable`
#            just ignore it or run the individual test files
#
#******************************************************************************************************************************


declare -r _THIS_SCRIPT_PATH_ALL=$(readlink -f "${BASH_SOURCE[0]}")5
declare -r _TEST_SCRIPT_DIR_ALL=$(dirname "$_THIS_SCRIPT_PATH_ALL")

source "${_TEST_SCRIPT_DIR_ALL}/../trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"$_signal\"" "$_signal"; done
trap "tr_trap_exit_interrupted" INT
#DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "tr_trap_exit_unknown_error" ERR

source "${_TEST_SCRIPT_DIR_ALL}/../testing.sh"

declare -i _COUNT_OK_ALL=0
declare -i _COUNT_FAILED_ALL=0


#******************************************************************************************************************************

# trap_exit.sh: No tests for this file

source ${_TEST_SCRIPT_DIR_ALL}/tests_testing.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_msg.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_utilities.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_source_matrix.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_download_sources.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_extract_sources.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_localization.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_pkgfile.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))

source ${_TEST_SCRIPT_DIR_ALL}/tests_process_ports.sh
((_COUNT_OK_ALL+=$_COUNT_OK))
((_COUNT_FAILED_ALL+=$_COUNT_FAILED))



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK_ALL" "$_COUNT_FAILED_ALL" "ALL _COUNT_OK" "ALL _COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
