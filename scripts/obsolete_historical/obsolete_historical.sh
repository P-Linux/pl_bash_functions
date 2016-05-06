#******************************************************************************************************************************
#
#   <obsolete_historical.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       Contains old obsolete histprical functions which are kept for reference/examples.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

unset GREP_OPTIONS
shopt -s extglob
set +o noclobber



#******************************************************************************************************************************
# Checks if AT LEAST the required number of arguments were supplied       USAGE: ut_min_number_args_abort "_example_func" 2 $#
#******************************************************************************************************************************
ut_min_number_args_abort() {
    local _fn="ut_min_number_args_abort"
    if (( ${3} < ${2} )); then
        ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires AT LEAST '%s' argument/s. Got '%s'")" "${1}" "${2}" "${3}"
    fi
}


#******************************************************************************************************************************
# Checks if AT LEAST the required number of arguments were supplied: and are NOT empty
#
#   USAGE:
#       ut_min_number_args_not_empty_abort "_example_func" 3 "${@}"
#******************************************************************************************************************************
ut_min_number_args_not_empty_abort() {
    local _fn="ut_min_number_args_not_empty_abort"
    local _caller_name=${1}
    declare -i _required_args=${2}
    local _function_args=("${@:3}")
    declare -i _n

    ut_min_number_args_abort "${_caller_name}" ${_required_args} $(( ${#}- 2 ))

    for (( _n=0; _n < ${_required_args}; _n++ )); do
        if [[ -z ${_function_args[${_n}]} ]]; then
            ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '%s': MUST NOT be empty")" "${_caller_name}" $((_n + 1))
        fi
    done
}


#******************************************************************************************************************************
# Checks if the EXACT number of arguments were supplied                USAGE: ut_exact_number_args_abort "_example_func" 3 $#
#******************************************************************************************************************************
ut_exact_number_args_abort() {
    local _fn="ut_exact_number_args_abort"
    if (( ${2} != ${3} )); then
        ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Requires EXACT '%s' argument/s. Got '%s'")" "${1}" "${2}" "${3}"
    fi
}


#******************************************************************************************************************************
# Checks if the EXACT number of arguments were supplied    USAGE: ut_exact_number_args_not_empty_abort "_example_func" 3 "${@}"
#******************************************************************************************************************************
ut_exact_number_args_not_empty_abort() {
    local _fn="ut_min_number_args_not_empty_abort"
    local _caller_name=${1}
    declare -i _required_args=${2}
    local _function_args=( "${@:3}" )
    declare -i _n

    ut_exact_number_args_abort "${_caller_name}" ${_required_args}  $(( ${#}- 2 ))

    for (( _n=0; _n < ${_required_args}; _n++ )); do
        if [[ -z ${_function_args[${_n}]} ]]; then
            ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '%s': MUST NOT be empty")" "${_caller_name}" $((_n + 1))
        fi
    done
}


#******************************************************************************************************************************
# Aborts if an 'index array' HAS NOT continuous index numbers.
#
#   ARGUMENTS:
#       `_in_check_sparse array`: a reference var: an index array which will be checked if it has continues index numbers
#       `_caller_name`: e.g. function name from where this was called for error messages
#
#    NOTE: this does not mean it was set. Could have elements or 0 size.
#
#   USAGE:
#       ut_abort_sparse_array SOURCE_ARRAY "SOURCE_ARRAY"
#******************************************************************************************************************************
ut_abort_sparse_array() {
    local _fn="ut_abort_sparse_array"
    (( ${#}!= 2 )) &&  ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Requires EXACT '2' arguments. Got '%s'")" "${_fn}" "${#}"
    local -n _in_check_sparse=${1}
    local _caller_name=${2}
    declare -i _idxs=("${!_in_check_sparse[@]}")

    if ! [[ $(declare -p | grep -E "declare -a[lrtux]{0,4} ${1}='\(") ]]; then
        ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Not an index array: '%s'")" "${_caller_name}" "${_in_check_sparse}"
    fi

    if (( ${#_in_check_sparse[*]} > 0 && (${_idxs[@]: -1} + 1) != ${#_in_check_sparse[*]} )); then
        ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Found a sparse array which is not allowd. Array-Name: '%s'")" \
            "${_caller_name}" "${_in_check_sparse}"
    fi
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
