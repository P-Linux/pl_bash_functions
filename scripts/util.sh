#******************************************************************************************************************************
#
#   <util.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

i_general_opt



#=============================================================================================================================#
#
#                   OTHER VARIABLE RELATED CHECKS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Checks if a varible is set to: 'yes' or 'no': else abort
#
#   ARGUMENTS:
#       `_var`: the variable.
#       `_var_name`: the name of a variable. IMPORTANT: only the name no $
#
#   OPTIONAL ARGUMENTS
#       `_inf`: optional additional info to add to any error messages
#
#   USAGE
#       local _ignore_md5="no"
#       u_is_yes_no_var_exit "${_ignore_md5}" "Variable_name"
#       u_is_yes_no_var_exit "${_ignore_md5}" "_ignore_md5" "Some optional additional info"
#******************************************************************************************************************************
u_is_yes_no_var_exit() {
    (( ${#} < 2 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '2' argument. Got '%s'")" "${#}"
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    [[ -n ${2} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 2 MUST NOT be empty.")"
    local _var=${1}
    local _var_name=${2}
    local _inf=${3:-""}

    if [[ ${_var} != "yes" && ${_var} != "no" ]]; then
        if [[ -n ${_inf} ]]; then
            i_exit 1 ${LINENO} "$(_g "FUNCTION Argument '1' (_var: '%s') MUST be set to: 'yes' or 'no'. Got: '%s' INFO: %s")" \
                "${_var_name}" "${_var}" "${_inf}"
        else
            i_exit 1 ${LINENO} "$(_g "FUNCTION Argument '1' (_var: '%s') MUST be set to: 'yes' or 'no'. Got: '%s'")" \
                "${_var_name}" "${_var}"
        fi
    fi
}



#******************************************************************************************************************************
# Checks if variable is a declared 'string variable': USAGE: ut_is_declared_string "variable_name"
#
#    NOTE: this does not mean it was set. Could have chars or 0 size (empty string).
#
# SPEED INFO:
#   BASH ONLY meassured: 0m0.396s WORKS fine: but very slow especially this part: *([-lrtux])"
#       [[ $(declare -p) == *"declare -"*([-lrtux])" ${1}"?(=\"*\")?(+([[:space:]])*) ]]
#
#       `?(=\"*\")` match optionaly assigned strings
#       `?(+([[:space:]])*)` Match: not assigned and avoid other longer names which start with the same prefix
#   GREP: measured: 0m0.004s
#       [[ -n $(declare -p | grep -E "declare -[-lrtux]{1,4} ${1}") ]]
#******************************************************************************************************************************
u_is_str_var() {
    [[ -n $(declare -p | grep -E "declare -[-lrtux]{1,4} ${1}") ]]
}


#******************************************************************************************************************************
# Checks if variable is a declared 'string variable and empty': USAGE: u_is_empty_str_var "variable_name"
#
#   This differs from: [[ -z $variable ]] which returns true even if the variable was never declared 1
#
#    NOTE: this does not mean it was set.: Example matches
#
#       local unassigned_str
#       local unassigned_str=""
#
#   ARGUMENTS:
#       `$1`: the name of the variable. IMPORTANT: only the name no $
#******************************************************************************************************************************
u_is_empty_str_var() {
    [[ $(declare -p | grep -E "declare -[-lrtux]{1,4} ${1}?(=\"\"|$)") ]]
}


#******************************************************************************************************************************
# Aborts if the variable is not a 'string variable'
#
#   ARGUMENTS:
#       `$1 (_var_name)`: the variable name. IMPORTANT: only the name no $
#
#   OPTIONAL ARGUMENTS
#       `_inf`: optional additional info to add to any error messages
#
#   USAGE
#       local _path="/home/test"
#       u_is_str_var_exit "_path" "additional info"
#******************************************************************************************************************************
u_is_str_var_exit() {
    (( ${#} < 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '1' argument. Got '%s'")" "${#}"
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    # skip assignment:  local _var_name=${1}
    local _inf=${2:-""}
    if ! u_is_str_var "${1}"; then
        if [[ -n ${_inf} ]]; then
            i_exit 1 ${LINENO} "$(_g "Not a declared string variable: '%s' INFO: %s")" "${1}" "${_inf}"
        else
            i_exit 1 ${LINENO} "$(_g "Not a declared string variable: '%s'")" "${1}"
        fi
    fi
}


#******************************************************************************************************************************
# Checks if variable is a declared 'index array': USAGE: u_is_idx_array_var "variable_name"
#
#    NOTE: this does not mean it was set. Could have elements or 0 size.
#
# SPEED INFO:
#       declare -alrtx _array=(a "e f" 3 x 6 567)
#   BASH ONLY meassured: 0m2.057s    time { for ((n=0;n<100;n++)); do u_is_idx_array_var "_array" &> /dev/null; done; }
#       [[ $(declare -p) == *"declare -a"*([lrtux])" ${1}='("* ]]
#   GREP: measured: 0m0.420s     time { for ((n=0;n<100;n++)); do u_is_idx_array_var "_array" &> /dev/null; done; }
#       [[ $(declare -p | grep -E "declare -a[lrtux]{0,4} ${1}='\(") ]]
#******************************************************************************************************************************
u_is_idx_array_var() {
    [[ $(declare -p | grep -E "declare -a[lrtux]{0,4} ${1}='\(") ]]
}


#******************************************************************************************************************************
# Aborts if the variable is not a 'index array variable'
#
#   ARGUMENTS:
#       `$1 (_var_name)`: the name of a variable. IMPORTANT: only the name no $
#
#   OPTIONAL ARGUMENTS
#       `_inf`: optional additional info to add to any error messages
#
#   USAGE
#       local _array=(a b c)
#       u_is_idx_array_exit "_array" "additional info"
#******************************************************************************************************************************
u_is_idx_array_exit() {
    (( ${#} < 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '1' argument. Got '%s'")" "${#}"
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    # skip assignment:  local _var_name=${1}
    local _inf=${2:-""}
    if ! u_is_idx_array_var "${1}"; then
        if [[ -n ${_inf} ]]; then
            i_exit 1 ${LINENO} "$(_g "Not a declared index array variable: '%s' INFO: %s")" "${1}" "${_inf}"
        else
            i_exit 1 ${LINENO} "$(_g "Not a declared index array variable: '%s'")" "${1}"
        fi
    fi
}


#******************************************************************************************************************************
# Checks if variable is a declared 'associative array': USAGE: u_is_associative_array_var "variable_name"
#
#    NOTE: this does not mean it was set. Could have elements or 0 size.
#
#   USAGE
#       declare -A _testarray=([a]="Value 1" [b]="Value 2"
#       u_is_associative_array_var "_testarray" || echo error
#       (( $(u_is_associative_array_var "_array") )) || echo error
#******************************************************************************************************************************
u_is_associative_array_var() {
    [[ $(declare -p | grep -E "declare -A[lrtux]{0,4} ${1}='\(") ]]
}


#******************************************************************************************************************************
# Aborts if the variable is not a referenced 'associative array'
#
#   ARGUMENTS:
#       `_ref_name`: the reference name of the array IMPORTANT: only the name no $
#
#   USAGE
#       declare -A _testarray=([a]="Value 1" [b]="Value 2"
#       declare -n _refarray=_testarray
#       u_ref_associative_array_exit "_refarray"
#******************************************************************************************************************************
u_ref_associative_array_exit() {
    (( ${#} != 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '1' argument. Got '%s'")" "${#}"
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    local _ref_name=${1}
    local _line="$(declare -p | grep -E "declare -n[lrtux]{0,4} ${_ref_name}=\"[[:alnum:]_]{0,}\"")"
    local _v

    if [[ ! -n ${_line} ]]; then
        i_exit 1 ${LINENO} "$(_g "Not a referenced associative array: '%s'")" "${_ref_name}"
    fi
    # extract the name: still has the ending double quote
    _v=${_line#*\"}
    if ! u_is_associative_array_var "${_v:: -1}"; then
        i_exit 1 ${LINENO} "$(_g "Not a referenced associative array: '%s'")" "${_ref_name}"
    fi
}



#=============================================================================================================================#
#
#                   STRING FUNCTIONS - MANIPULATION, EXTRACTION etc..
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Returns the number of occurrences of '_substring' in "_input'
#
#   ARGUMENTS:
#       `$1`: _substring
#       `$2`: _input
#
#   USAGE:
#       _input="text::text::text::text"
#       number_of_occurrences=$(u_count_substr "::" "${_input}")
#       echo "number_of_occurrences: <$number_of_occurrences>"
#
#       RESULT:
#           number_of_occurrences: <3>
#******************************************************************************************************************************
u_count_substr() {
    (( ${#} != 2 )) &&  i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '2' arguments. Got '%s'")" "${#}"
    grep -o "${1}" <<< "${2}" | wc -l
}


#******************************************************************************************************************************
# Strips all trailing slahes
#
#   ARGUMENTS:
#       `_retres`: a reference var: an empty string wll be updated with the result
#       `$2 (_in_string`: a reference var: a string
#
#   USAGE: local _result; u_strip_end_slahes _result "/home/test////"
#******************************************************************************************************************************
u_strip_end_slahes() {
    local -n _retres=${1}
    # skip assignment:  _in_string=${2}
    _retres="${2%%+(/)}"
}


#******************************************************************************************************************************
# Strips all leading and trailing whitespace: NOTE: needs shopt -s extglob
#
#   ARGUMENTS:
#       `_retres`: a reference var: an empty string wll be updated with the result
#       `$2 (_in_string`: a reference var: a string
#
#   USAGE: local _result; u_strip_whitespace _result "     Just a dummy text      "
#******************************************************************************************************************************
u_strip_whitespace() {
    local -n _retres=${1}
    # skip assignment:  _str=${2}
    _retres=${2##+([[:space:]])}
    _retres=${_retres%%+([[:space:]])}
}



#******************************************************************************************************************************
#
#   GET PREFIX
#
#   USAGE
#       _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
#       declare _prefix
#
#       u_prefix_shortest_empty _prefix "${_entry}" "::"
#       printf "u_prefix_shortest_empty: <%s>\n" "${_prefix}"
#
#       u_prefix_longest_empty _prefix "${_entry}" "::"
#       printf "u_prefix_longest_empty: <%s>\n" "${_prefix}"
#
#       u_prefix_shortest_all _prefix "${_entry}" "::"
#       printf "u_prefix_shortest_all: <%s>\n" "${_prefix}"
#
#       u_prefix_longest_all _prefix "${_entry}" "::"
#       printf "u_prefix_longest_all: <%s>\n" "${_prefix}"
#
#       * RESULTS *
#           u_prefix_shortest_empty: <NOEXTRACT>
#           u_prefix_longest_empty: <NOEXTRACT::helper_scripts>
#           u_prefix_shortest_all: <NOEXTRACT>
#           u_prefix_longest_all: <NOEXTRACT::helper_scripts>
#
#   INPUT without delimiter:
#       _entry="https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
#
#       * RESULTS *
#           u_prefix_shortest_empty: <>
#           u_prefix_longest_empty: <>
#           u_prefix_shortest_all: <https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a>
#           u_prefix_longest_all: <https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a>
#******************************************************************************************************************************

#******************************************************************************************************************************
# Returns from beginning till the first found '_delimiter': else an empty string ""
#******************************************************************************************************************************
u_prefix_shortest_empty() {
    local -n _retres=${1}
    _retres=""
    [[ ${2} == *"${3}"* ]] && _retres=${2%%${3}*}
}


#******************************************************************************************************************************
# Returns from beginning till the last found '_delimiter': else an empty string ""
#******************************************************************************************************************************
u_prefix_longest_empty() {
    local -n _retres=${1}
    _retres=""
    [[ ${2} == *"${3}"* ]] && _retres=${2%${3}*}
}


#******************************************************************************************************************************
# Returns from beginning till the first found '_delimiter': else all (_input)
#******************************************************************************************************************************
u_prefix_shortest_all() {
    local -n _retres=${1}
    _retres="${2%%${3}*}"
}


#******************************************************************************************************************************
# Returns from beginning till the last found '_delimiter': else all (_input)
#******************************************************************************************************************************
u_prefix_longest_all() {
    local -n _retres=${1}
    _retres="${2%${3}*}"
}




#******************************************************************************************************************************
#
#   GET POSTFIX
#
#   USAGE
#       _entry="NOEXTRACT::helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0"
#       declare _postfix
#
#       u_postfix_shortest_empty _postfix "${_entry}" "::"
#       printf "u_postfix_shortest_empty: <%s>\n" "${_postfix}"
#
#       u_postfix_longest_empty _postfix "${_entry}" "::"
#       printf "u_postfix_longest_empty: <%s>\n" "${_postfix}"
#
#       u_postfix_shortest_all _postfix "${_entry}" "::"
#       printf "u_postfix_shortest_all: <%s>\n" "${_postfix}"
#
#       u_postfix_longest_all _postfix "${_entry}" "::"
#       printf "u_postfix_longest_all: <%s>\n" "${_postfix}"
#
#       * RESULTS *
#           u_postfix_shortest_empty: <https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#           u_postfix_longest_empty: <helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#           u_postfix_shortest_all: <https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#           u_postfix_longest_all: <helper_scripts::https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#
#   INPUT without delimiter:
#       _entry="https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0"
#
#       * RESULTS *
#           u_postfix_shortest_empty: <>
#           u_postfix_longest_empty: <>
#           u_postfix_shortest_all: <https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#           u_postfix_longest_all: <https://github.com/P-Linux/pl_bash_functions.git#tag=v0.1.0>
#******************************************************************************************************************************

#******************************************************************************************************************************
# Returns from the last found '_delimiter' till the end: else an empty string ""
#******************************************************************************************************************************
u_postfix_shortest_empty() {
    local -n _retres=${1}
    _retres=""
    [[ ${2} == *"${3}"* ]] && _retres=${2##*${3}}
}


#******************************************************************************************************************************
# Returns from the first found '_delimiter' till the end: else an empty string ""
#******************************************************************************************************************************
u_postfix_longest_empty() {
    local -n _retres=${1}
    _retres=""
    [[ ${2} == *"${3}"* ]] && _retres=${2#*${3}}
}


#******************************************************************************************************************************
# Returns from the last found '_delimiter' till the end: else all (_input)
#******************************************************************************************************************************
u_postfix_shortest_all() {
    local -n _retres=${1}
    _retres="${2##*${3}}"
}


#******************************************************************************************************************************
# Returns from the first found '_delimiter' till the end: else all (_input)
#******************************************************************************************************************************
u_postfix_longest_all() {
    local -n _retres=${1}
    _retres="${2#*${3}}"
}


#=============================================================================================================================#
#
#                   COMMAN-LINE OPTION HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Updates the _retarray with one or more expected argument values for a command-line option.
#   Values MUST NOT start with a hyphen-minus
#       Aborts if a value is an empty string. See also optional argument: _max_expected_values
#
#   NOTE: running the function in  subshells does not update _retres_array or increment the passed variable _idx
#
#   ARGUMENTS:
#       `_retarray`: a reference var: an empty index array
#       `_idx`: a reference var: integer of the current options index in the *_in_all_args array*:
#                                Remember bash arrays are 0 indexed
#       `_in_all_args`: a reference var: an index array: command-line arguments
#
#   OPTIONAL ARGUMENTS
#       `_max_expected_values`: (Default: -1) if greater than 0 - aborts if more values are found
#
#   USAGE:
#       _ARGS1=(-h --help -i --install --config-file /etc/cmk.conf -v --version)
#       _n=4
#       RESULT=()
#       u_get_cmd_arg_values_array RESULT _n _ARGS1 1
#
#     * This is typically use if one loops already through command-line arguments
#
#       for (( _n=0; _n < ${_in_all_args_size}; _n++ )); do
#           _arg=${_in_all_args[${_n}]}
#           case "${_arg}" in
#               -pc|--ports-collection) CM_PORTSLIST=()
#                   u_get_cmd_arg_values_array CM_PORTSLIST _n _in_all_args || exit 1 ;;
#               -v|--version) printf "(cards) %s: %s\n" "$VERSION"; exit 0 ;;
#               -h|--help)    print_help; exit 0 ;;
#               *)            i_exit xxxxxxx\n";;
#           esac
#       done
#
#   USAGE WRONG: the _idx MUST be a variable and not a number
#       _ARGS1=(-h --help -i --install --config-file /etc/cmk.conf -v --version)
#       RESULT=()
#       u_get_cmd_arg_values_array RESULT 4 _ARGS1  1
#******************************************************************************************************************************
u_get_cmd_arg_values_array() {
    (( ${#} < 3 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '3' arguments. Got '%s'")" "${#}"
    [[ -n ${2} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 2 '_idx' MUST NOT be empty.")"
    declare -n _retarray=${1}
    local -n _idx=${2}
    declare -n _in_all_args=${3}
    declare -i _max_expected_values=${4:--1}
    declare -i _in_all_args_size=${#_in_all_args[@]}
    local _orig_option=${_in_all_args[${_idx}]}
    local _s=${_in_all_args[@]}     # string of _in_all_args

    (( ${#_retarray[@]} > 0 )) && i_exit 1 ${LINENO} "$(_g "Argument '_retarray' MUST be an empty array.")"
    (( ${_max_expected_values} == 0 )) && i_exit 1 ${LINENO} "$(_g "Argument '_max_expected_values' MUST NOT be 0")"

    ((_idx++))
    if (( ${_idx} < ${_in_all_args_size} )); then
        _arg=${_in_all_args[${_idx}]}
        for (( _idx; _idx < ${_in_all_args_size}; _idx++ )); do
            _arg=${_in_all_args[${_idx}]}
            if [[ ! -n ${_arg} ]]; then
                i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' value: '%s' MUST NOT be empty: All Arguments: <%s>")" \
                    "${_orig_option}" "${_arg}" "${_s}"
            elif [[ ${_arg} == "-"* ]]; then
                (( ${#_retarray[@]} > 0 )) && break
                i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' value: '%s' MUST NOT start with a hyphen-minus")" \
                    "${_orig_option}" "${_arg}"
            fi
            # Add it
            _retarray+=(${_arg})
        done
    else
        i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' requires an value. All Arguments: <%s>")" "${_orig_option}" "${_s}"
    fi
    if (( ${_max_expected_values} > 0 && ${#_retarray[@]} > ${_max_expected_values} )); then
        i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' maximum expected values: '%s'. Found '%s' All ARGS: <%s>")" \
                "${_orig_option}" "${_max_expected_values}" "${#_retarray[@]}" "${_s}"
    fi
    # remove 1 _idx
    ((_idx--))
}


#******************************************************************************************************************************
# Returns an expected SINGLE argument value for a command-line option. (updates _retres)
#       Aborts if the value is an empty string or starts with a hyphen-minus: `-`
#
#   ARGUMENTS:
#       `_retres`: a reference var: a reference var: an empty string
#       `_cur_idx`: integer of the current options index in the '_in_all_args array'
#       `_in_all_args`: a reference var: an index array: command-line arguments
#
#   OPTIONAL ARGUMENTS:
#       `_exit_if_no_value`: Default is "yes" if "no" it will not abort if there was no value.
#
#   USAGE:
#       declare _array_with_short_option=(-v --version -i --install -cf /home/short_option/cmk.conf -h --help)
#       declare _path; u_get_cmd_arg_single_value_string _path 4 _array_with_short_option "no"
#       printf "u_get_cmd_arg_single_value_string:_path: <%s>\n" "${_path}"
#******************************************************************************************************************************
u_get_cmd_arg_single_value_string() {
    (( ${#} < 3 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '3' arguments. Got '%s'")" "${#}"
    [[ -n ${2} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 2 MUST NOT be empty.")"
    local -n _retres=${1}
    declare -i _cur_idx=${2}
    declare -n _in_all_args=${3}
    local _exit_if_no_value=${4:-"yes"}
    declare -i _in_all_args_size=${#_in_all_args[@]}
    declare -i _next_idx=$((_cur_idx + 1))
    local _s=${_in_all_args[@]}     # string of _in_all_args

    _retres=""
    if [[ ${_exit_if_no_value} != "yes" && ${_exit_if_no_value} != "no" ]]; then
        i_exit 1 ${LINENO} "$(_g "4. VARIBLE: '_exit_if_no_value' MUST be set to: 'yes' or 'no'. Got: '%s'")" \
            "${_exit_if_no_value}"
    fi

    if (( ${_next_idx} < ${_in_all_args_size} )); then
        _retres=${_in_all_args[${_next_idx}]}
        if [[ ! -n ${_retres} ]]; then
            i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' argument value MUST NOT be empty: All Arguments: <%s>")" \
                "${_in_all_args[${_cur_idx}]}" "${_s}"
        fi
        [[ ${_retres} == "-"* ]] && _retres=""
    fi

    if [[ ${_exit_if_no_value} == "yes" && ! -n ${_retres} ]]; then
        i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' requires an value. All Arguments: <%s>")" \
            "${_in_all_args[${_cur_idx}]}" "${_s}"
    fi
}


#******************************************************************************************************************************
# Search for a commnd-line option and return one or more expected argument values. Values MUST NOT start with a hyphen-minus.
#   Aborts if a value is an empty string. See also optional argument: _max_expected_values
#
#   EXAMPLE:
#
#       -f, --file <file_path>
#
#       If a command-line option: `-f` or `--file` was found in `_in_all_args` than it would return the found value(s)
#       If the specified short/long option was not found it returns an empty string
#
#   ARGUMENTS:
#       `_retres`: a reference var: an empty string
#       `_short_arg`: command-line short option to look for: MUST start With ONE hyphen-minus or be empty.
#       `_long_arg`: command-line long option to look for: MUST start With TWO hyphen-minus or be empty.
#       `_in_all_args`: a reference var: an index array: command-line arguments
#
#   OPTIONAL ARGUMENTS
#       `_max_expected_values`: (Default: -1) if greater than 0 - aborts if more values are found
#
#   USAGE:
#       _ARGS1=(-h --help -i --install --config-file /etc/cmk.conf -v --version)
#       declare _result; u_search_cmd_arg_values_string _result "-cf" "--config-file" _ARGS1 1
#
#       _array_with_short_option=(-v --version -h --help --ports-collection bash wget curl git --config-file /etc/cmk.conf)
#       declare _result; u_search_cmd_arg_values_string _result "" "--ports-collection" _array_with_short_option
#       printf "u_get_cmd_arg_single_value_string:_result: <%s>\n" "${_result}"
#
#       * RESULT *
#           u_search_cmd_arg_values_string:_result: <bash wget curl git>
#******************************************************************************************************************************
u_search_cmd_arg_values_string() {
    (( ${#} < 4 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '4' arguments. Got '%s'")" "${#}"
    local -n _retres=${1}
    local _short_arg=${2}
    local _long_arg=${3}
    declare -n _in_all_args=${4}
    declare -i _max_expected_values=${5:--1}
    declare -i _in_all_args_size=${#_in_all_args[@]}
    local _option_value=""
    declare  -i _counted_values=0
    local _s     # string of _in_all_args
    declare -i _check_arg_length
    local _found_opt _found_search_arg _arg

    _retres=""
    if [[ ! -n ${_short_arg} && ! -n ${_long_arg} ]]; then
        i_exit 1 ${LINENO} "$(_g "WRONG CODE: Argument 1: '%s' Argument 2: '%s'. Only one MAY be empty.")" "${_short_arg}" \
            "${_long_arg}"
    fi
    (( _max_expected_values == 0 )) && i_exit 1 ${LINENO} "$(_g "Argument '_max_expected_values' MUST NOT be 0")"

    #  Validate Short option to check Input
    if [[ -n ${_short_arg} ]]; then
        _check_arg_length=${#_short_arg}
        if (( ${_check_arg_length} < 2 )); then
            i_exit 1 ${LINENO} "$(_g "Short option to check: '%s' MUST be at least 2 character long or empty.")" "${_short_arg}"
        elif [[ ${_short_arg} != "-"[!-]* ]]; then
            i_exit 1 ${LINENO} "$(_g "Short option to check: '%s' MUST start with EXACT ONE hyphen-minus.")" "${_short_arg}"
        fi
    fi

    #  Validate Long option to check Input
    if [[ -n ${_long_arg} ]]; then
        _check_arg_length=${#_long_arg}
        if (( ${_check_arg_length} < 3 )); then
            i_exit 1 ${LINENO} "$(_g "Long option to check: '%s' MUST be at least 3 character long or empty.")" "${_long_arg}"
        elif [[ ${_long_arg:0:2} != "--" || ${_long_arg:2:1} == "-" ]]; then
            i_exit 1 ${LINENO} "$(_g "Long option to check: '%s' MUST start with EXACT TWO hyphen-minus.")" "${_long_arg}"
        fi
    fi

    ####
    _found_opt="no"
    if (( ${_in_all_args_size} > 0 )); then
        _s=${_in_all_args[@]}     # string of _in_all_args
        for (( _n=0; _n < ${_in_all_args_size}; _n++ )); do
            _arg=${_in_all_args[${_n}]}
            if [[ ${_found_opt} == "no" ]]; then
                if [[ ${_arg} == ${_short_arg} ||  ${_arg} == ${_long_arg} ]]; then
                    _found_opt="yes"
                    _found_search_arg=${_arg}
                fi
            else
                if [[ ! -n ${_arg} ]]; then
                    i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' value: '%s' MUST NOT be empty: All Arguments: <%s>")" \
                        "${_found_search_arg}" "${_arg}" "${_s}"
                elif [[ ${_arg} == "-"* ]]; then
                    [[ -n ${_retres} ]] && break
                    i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' value: '%s' MUST NOT start with a hyphen-minus")" \
                        "${_found_search_arg}" "${_arg}"
                fi
                # Add it
                if [[ -n ${_retres} ]]; then
                    _retres+=" ${_arg}"
                    ((_counted_values++))
                else
                    _retres="${_arg}"
                    ((_counted_values++))
                fi
            fi
        done
    fi

    if [[ ${_found_opt} == "yes" ]]; then
        if (( _counted_values < 1 )); then
            i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' requires at least 1 value. All ARGS: <%s>")" \
                "${_found_search_arg}" "${_s}"
        elif (( ${_max_expected_values} > 0 && _counted_values > ${_max_expected_values} )); then
            i_exit 1 ${LINENO} "$(_g "Command-Line option: '%s' maximum expected values: '%s'. Found '%s' All ARGS: <%s>")" \
                "${_found_search_arg}" "${_max_expected_values}" "${_counted_values}" "${_s}"
        fi
    fi
}


#=============================================================================================================================#
#
#                   DIRECTORIES / FILES / PATH HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Returns _in_path with any leading directory components removed. Trailing slahes are also removed.
#   is faster (3-10 times) than the *basename* command.
#
#   Path does not need to exist
#
#   EXAMPLES:
#       declare _result_basename
#       u_basename _result_basename "/home/test_dir//"
#       printf "u_basename: <%s>\n" "${_result_basename}"
#
#       u_basename _result_basename "home"
#       printf "u_basename: <%s>\n" "${_result_basename}"
#
#       u_basename _result_basename ""
#       printf "u_basename: <%s>\n" "${_result_basename}"
#
#       * RESULTS *
#           u_basename: <test_dir>
#           u_basename: <home>
#           u_basename: <>
#
# SPEED INFO:
#   BASENAME meassured: 0m0.773s  time { for ((n=0;n<1000;n++)); do testfunc1; done; }
#       local _basename=$(basename "/home/test_dir//")
#   U_BASENAME meassured: 0m0.057s  time { for ((n=0;n<1000;n++)); do testfunc1; done; }
#       local _basename; u_basename _basename "/home/test_dir//"
#******************************************************************************************************************************
u_basename() {
    local -n _ret_bname=${1}
    _ret_bname="${2%%+(/)}"
    _ret_bname="${_ret_bname##*/}"
}


#******************************************************************************************************************************
# Returns _in_path with its trailing / component removed; if _in_path contains no /'s, output '.' (meaning current directory).
#   is faster (3-10 times) than the *dirname* command.
#
#   Path does not need to exist
#
#   EXAMPLES:
#       declare _result_dirname
#       u_dirname _result_dirname "/home/test_dir//"
#       printf "u_dirname: <%s>\n" "${_result_dirname}"
#
#       u_dirname _result_dirname "/home////"
#       printf "u_dirname: <%s>\n" "${_result_dirname}"
#
#       u_dirname _result_dirname "home/test/Pkgfile.txt"
#       printf "u_dirname: <%s>\n" "${_result_dirname}"
#
#       u_dirname _result_dirname "Pkgfile.txt"
#       printf "u_dirname: <%s>\n" "${_result_dirname}"
#
#       * RESULTS *
#           u_dirname: </home>
#           u_dirname: </>
#           u_dirname: <home/test>
#           u_dirname: <.>
#
# SPEED INFO:
#   DIRNAME meassured: 0m3.075s  time { for ((n=0;n<1000;n++)); do testfunc1; done; }
#       testfunc1() {
#           local _result_dirname
#           _result_dirname=$(dirname "/home/test_dir//")
#           _result_dirname=$(dirname "/home////")
#           _result_dirname=$(dirname "home/test/Pkgfile.txt")
#           _result_dirname=$(dirname "Pkgfile.txt")
#       }
#   U_DIRNAME meassured: 0m0.234s  time { for ((n=0;n<1000;n++)); do testfunc1; done; }
#       testfunc2() {
#           local _result_dirname
#           u_dirname _result_dirname "/home/test_dir//"
#           u_dirname _result_dirname "/home////"
#           u_dirname _result_dirname "home/test/Pkgfile.txt"
#           u_dirname _result_dirname "Pkgfile.txt"
#       }
#******************************************************************************************************************************
u_dirname() {
    local -n _ret_dname=${1}
    local _no_trailing_slash="${2%%+(/)}"
    _ret_dname="."
    [[ ${_no_trailing_slash} == *"/"* ]] && _ret_dname="${_no_trailing_slash%/*}"
    [[ ! -n ${_ret_dname} ]] && _ret_dname="/"
}


#******************************************************************************************************************************
# Return code: (0) if a the `_in_path` is an absolute path: starts with an slash, else return 1
#
#   Path does not need to exist
#
#   USAGE:
#       _dir="/home/test_dir"
#       if u_is_abspath "${_dir}"; then
#           echo "dir is an absolute path"
#       fi
#
# SPEED INFO:
#   BASH 1 meassured: 0m0.320s  time { for ((n=0;n<10000;n++)); do u_is_abspath "/home/test" &> /dev/null; done; }
#       [[ ${1:0:1} == "/" ]]
#   BASH 2 meassured: 0m0.269s  time { for ((n=0;n<10000;n++)); do u_is_abspath "/home/test" &> /dev/null; done; }
#       [[ ${1} == "/"* ]]
#******************************************************************************************************************************
u_is_abspath() {
    [[ ${1} == "/"* ]]
}


#******************************************************************************************************************************
# Checks if `_in_path` is an absolute path (start with a slash), if not it aborts
#
#   Path does not need to exist
#
#   OPTIONAL ARGUMENTS:
#       `_err_name`:  used for error messages defaults to: Path
#
#   USAGE
#       u_is_abspath_exit "$SOME_PATH"
#       u_is_abspath_exit "$SOME_PATH" "Checkpath"
#******************************************************************************************************************************
u_is_abspath_exit() {
    local _path=${1}
    local _err_name=${2:-"Path"}

    if [[ ${_path} != "/"* ]]; then
        i_exit 1 ${LINENO} "$(_g "%s MUST be an absolute path and MUST start with a slash: <%s>")" "${_err_name}" "${_path}"
    fi
}


#******************************************************************************************************************************
# Return code: (0) if a directory exists, is readable and has content else (1). Aborts if it exists but is not readable.
#                                  Remember: You need read permission on the directory, or it will always appear empty.
#
#   USAGE:
#       _dir="/home/test_dir"
#       if ! u_dir_has_content_exit "${_dir}"; then
#           echo "do something: dir does not exist or is empty and readable e.g. clone into it"
#       fi
#******************************************************************************************************************************
u_dir_has_content_exit() {
    local _in_dir=${1}
    declare -i _ret=1
    local _content

    if [[ -d ${_in_dir} ]]; then
        [[ -r ${_in_dir} ]] || i_exit 1 ${LINENO} "$(_g "Directory exists but is not readable: <%s>")" "${_in_dir}"
        _content=("${_in_dir}"/*)
        if (( ${#_content[@]} > 1 )); then
            _ret=0
        # Do this much faster checkup instead of 'shopt -s nullglob' in subshell
        elif [[ ${_content[0]} != "${_in_dir}/*" ]]; then
            _ret=0
        fi
    fi
    return ${_ret}
}


#******************************************************************************************************************************
# Cd to '_in_dir' abort on failure
#******************************************************************************************************************************
u_cd_safe_exit() {
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    cd "${1}" || i_exit 1 ${LINENO} "$(_g "Could not change to directory: <%s>")" "${1}"
}


#******************************************************************************************************************************
# Checks '_dpath': Exists, is readable, is writeable, is executeable, (optional is absolute path) - aborts on failure
#
#   OPTIONAL ARGUMENTS:
#       `_check_abspath`:  yes/no. if "yes" it is additionally checked if the _dpath is an absolute path: starts with slash.
#       `_err_name`:  used for error messages defaults to: Directory
#
#   USAGE
#       u_dir_is_rwx_exit "testdir/subdir"
#       u_dir_is_rwx_exit "$SOME_DIR" "yes" "CHECK_DIR"
#******************************************************************************************************************************
u_dir_is_rwx_exit() {
    local _dpath=${1}
    local _check_abspath=${2:-"no"}
    local _err_name=${3:-"Directory"}

    [[ -d ${_dpath} ]] || i_exit 1 ${LINENO} "$(_g "%s does not exist: <%s>")" "${_err_name}" "${_dpath}"
    [[ -r ${_dpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not readable: <%s>")" "${_err_name}" "${_dpath}"
    [[ -w ${_dpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not writable: <%s>")" "${_err_name}" "${_dpath}"
    [[ -x ${_dpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not executable: <%s>")" "${_err_name}" "${_dpath}"
    if [[ ${_check_abspath} == "yes" && ${_dpath} != "/"* ]]; then
        i_exit 1 ${LINENO} "$(_g "%s An absolute directory path MUST start with a slash: <%s>")" "${_err_name}" "${_dpath}"
    fi
}


#******************************************************************************************************************************
# Checks '_fpath': Exists, is readable (optional is absolute path) - aborts on failure
#
#   OPTIONAL ARGUMENTS:
#       `_check_abspath`:  yes/no. if "yes" it is additionally checked if the _dir_path is an absolute path: starts with slash.
#       `_err_name`:  used for error messages defaults to: File
#
#   USAGE
#       u_file_is_r_exit "testdir/test_file.txt"
#       u_file_is_r_exit "${TEST_FILE}" "yes" "Pkgfile"
#******************************************************************************************************************************
u_file_is_r_exit() {
    local _fpath=${1}
    local _check_abspath=${2:-"no"}
    local _err_name=${3:-"File"}

    [[ -f ${_fpath} ]] || i_exit 1 ${LINENO} "$(_g "%s does not exist: <%s>")" "${_err_name}" "${_fpath}"
    [[ -r ${_fpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not readable: <%s>")" "${_err_name}" "${_fpath}"
    if [[ ${_check_abspath} == "yes" && ${_fpath} != "/"* ]]; then
        i_exit 1 ${LINENO} "$(_g "%s MUST be an absolute file path and MUST start with a slash: <%s>")" "${_err_name}" \
            "${_fpath}"
    fi
}


#******************************************************************************************************************************
# Checks '_fpath': Exists, is readable, is writeable (optional is absolute path) - aborts on failure
#
#   OPTIONAL ARGUMENTS:
#       `_check_abspath`:  yes/no. if "yes" it is additionally checked if the _dir_path is an absolute path: starts with slash.
#       `_err_name`:  used for error messages defaults to: File
#
#   USAGE
#       u_file_is_rw_exit "testdir/test_file.txt"
#       u_file_is_rw_exit "$TEST_FILE" "yes" "Pkgfile"
#******************************************************************************************************************************
u_file_is_rw_exit() {
    local _fpath=${1}
    local _check_abspath=${2:-"no"}
    local _err_name=${3:-"File"}

    [[ -f ${_fpath} ]] || i_exit 1 ${LINENO} "$(_g "%s does not exist: <%s>")" "${_err_name}" "${_fpath}"
    [[ -r ${_fpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not readable: <%s>")" "${_err_name}" "${_fpath}"
    [[ -w ${_fpath} ]] || i_exit 1 ${LINENO} "$(_g "%s is not writable: <%s>")" "${_err_name}" "${_fpath}"
    if [[ ${_check_abspath} == "yes" && ${_fpath} != "/"* ]]; then
        i_exit 1 ${LINENO} "$(_g "%s MUST be an absolute file path and MUST start with a slash: <%s>")" "${_err_name}" \
            "${_fpath}"
    fi
}



#=============================================================================================================================#
#
#                   DIVERSE OTHER HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Returns the current date: LC_ALL=C
#
#   USAGE: local _date; u_get_utc_date _date
#******************************************************************************************************************************
u_get_utc_date() {
    local -n _retres=${1}
    _retres="$(LC_ALL=C date -u)"
}


#******************************************************************************************************************************
# Returns current Unix timestamp (seconds since '1970-01-01 00:00:00' UTC)
#
#   USAGE: local _timestamp; u_get_unix_timestamp _timestamp
#******************************************************************************************************************************
u_get_unix_timestamp() {
    local -n _retres=${1}
    _retres="$(LC_ALL=C date +%s)"
}


#******************************************************************************************************************************
# Check that the input (${1}) is an integer greater: _greater_than (defaults to 0)
#
#   Note: 64-bit bash integers limits: -9223372036854775808 to 9223372036854775807
#
#
#   OPTIONAL ARGUMENTS:
#       `_greater_than`: (defaults to 0)
#
#   USAGE:
#       if u_is_integer_greater 1 0; then
#           printf "%s\n" "Input was greater than 0"
#       else
#           printf "%s\n" "Input was NOT greater than 0"
#       fi
#
#       u_is_integer_greater 0 || printf "%s\n" "Input was NOT greater than 0"
#       u_is_integer_greater 0 -15 && printf "%s\n" "Input was greater than -15"
#******************************************************************************************************************************
u_is_integer_greater() {
    local _input=${1}         # do not declare as integer as the input could be anything even an empty string
    local _greater_than=${2:-0}

    [[ -n ${_greater_than} ]] || _greater_than=0
    (( ${_input} > ${_greater_than} )) &> /dev/null && return 0
    return 1
}


#******************************************************************************************************************************
# Repeats a failed command for a '_max_tries' times with '_delay_sec between' breaks as soon as commands returns: 0
#
#   Note: 64-bit bash integers limits: -9223372036854775808 to 9223372036854775807
#
#   USAGE:
#       u_repeat_failed_command 3 4 echo "hello" | tr 'l' 'L'
#       u_repeat_failed_command 3 4 wget "not found"
#******************************************************************************************************************************
u_repeat_failed_command() {
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    [[ -n ${2} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 2 MUST NOT be empty.")"
    [[ -n ${3} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 3 MUST NOT be empty.")"
    declare -i _max_tries=${1}
    declare -i _delay_sec=${2}; shift
    declare -i _n _ret

    if ! u_is_integer_greater ${_max_tries} 0; then
        i_exit 1 ${LINENO} "$(_g "'_max_tries': must be greater than 0. Got: '%s'")" "${_max_tries}"
    elif ! u_is_integer_greater ${_delay_sec} -1; then
        i_exit 1 ${LINENO} "$(_g "'_delay_sec': must be greater than -1. Got: '%s'")" "${_delay_sec}"
    fi

    for (( _n=1; _n <= ${_max_tries}; _n++ )); do
        "${@:2}" && return 0
        if (( _n < ${_max_tries} )); then
            sleep ${_delay_sec}
            i_more_i "$(_g "Repeating failed command: '%s.' time")"  $((_n + 1))
        fi
    done
    i_color "${_BF_YELLOW}" "$(_g "    ====> WARNING: Command failed: '%s' times")"  $((_n - 1))
    return 1  # Do not exit on this one
}


#******************************************************************************************************************************
# Returns 0 if '_needle' is in  '_array' else 1
#
#   Note: 64-bit bash integers limits: -9223372036854775808 to 9223372036854775807
#
#   ARGUMENTS
#       `_needle`: item to search for
#       `_in_array`: a reference var
#
#   USAGE:
#       _TEST_ARRAY=("yes" 1 45 "VALID ITEMs" "" "test")
#       if u_in_array "VALID ITEM" _TEST_ARRAY; then
#           echo "FOUND"
#       else
#           echo "NOT FOUND"
#       fi
#
#       u_in_array "VALID ITEM" _TEST_ARRAY || echo "NOT FOUND"
#******************************************************************************************************************************
u_in_array() {
    # could also be an empty first element or empty _needle
    (( ${#} != 2 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '2' arguments. Got '%s'")" "${#}"
    local _needle=${1}
    local -n _in_array=${2}
    local _element

    for _element in "${_in_array[@]}"; do
        [[ ${_element} == ${_needle} ]] && return 0
    done
    return 1
}


#******************************************************************************************************************************
# Checks if function with '_function_name' is declared:              USAGE: u_got_function "function_name"
#******************************************************************************************************************************
u_got_function() {
    (
        declare -f "${1}" >/dev/null
    )
}


#******************************************************************************************************************************
# Return the md5sum for an existing file path: if file path is not readable return an empty ""
#       On purpose we do not abort here.
#
#   USAGE: local _chksum; u_get_file_md5sum _chksum "/home/path_to_file"
#******************************************************************************************************************************
u_get_file_md5sum() {
    local -n _retres=${1}
    local _file=${2}

    _retres=""
    if [[ -f ${_file} && -r ${_file} ]]; then
        _retres=$(md5sum "${_file}")
        _retres=${_retres:0:32}
    fi
}


#******************************************************************************************************************************
# Return the md5sum for an existing file path: abort if it failed
#
#   USAGE: local _chksum; u_get_file_md5sum_exit _chksum "/home/path_to_file"
#******************************************************************************************************************************
u_get_file_md5sum_exit() {
    local -n _retres=${1}
    local _file=${2}

    _retres=""
    if [[ -f ${_file} && -r ${_file} ]]; then
        _retres=$(md5sum "${_file}")
        _retres=${_retres:0:32}
        if [[ ! -n ${_retres} ]]; then
            i_exit 1 ${LINENO} "$(_g "Could not generate a md5sum for file: <%s>")" "${_file}"
        fi
    else
        i_exit 1 ${LINENO} "$(_g "Not a readable file path: <%s>")" "${_file}"
    fi
}


#******************************************************************************************************************************
# Aborts if command '${1}' is not found. USAGE: u_no_command_exit "wget"
#******************************************************************************************************************************
u_no_command_exit() {
    (( ${#} != 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '1' argument. Got '%s'")" "${#}"
    [[ $(type -p "${1}") ]] || i_exit 1 ${LINENO} "$(_g "Missing command: '%s'")" "${1}"
}



#=============================================================================================================================#
#
#                   CHECKS INTERNET RELATED
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Return 0 if internet connection could be verified: else 1 and warns: use subshell for this
#******************************************************************************************************************************
u_got_internet() {
    (
        local _web_uris=(
            "en.wikipedia.org"
            "www.yahoo.com"
            "www.google.com"
            "www.facebook.com"
            "www.kernel.org"
            "www.usa.gov"           # USA.gov: US Government's Official Web Portal
            "www.ecb.europa.eu"     # European Central Bank
        )
        local _uri _interface

        u_no_command_exit "ping"

        for _uri in "${_web_uris[@]}"; do
            ping -q -w 1 -c 1 "${_uri}" &> /dev/null && return 0
        done
        i_warn "$(_g "u_got_internet() Couldn't verify internet-connection by pinging popular sites.\n")"
        return 1
    )
}


#******************************************************************************************************************************
# Return 0 if git uri is accessible: else 1 and warns: use subshell for this
#******************************************************************************************************************************
u_is_git_uri_accessible() {
    (
        [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
        local _uri=${1}

        u_got_internet || return 1

        GIT_ASKPASS=true git ls-remote "${_uri}" &> /dev/null && return 0
        i_warn "$(_g "u_is_git_uri_accessible() Couldn't verify that the git uri is accessible: <%s>\n")" "${_uri}"
        return 1
    )
}


#******************************************************************************************************************************
# Return 0 if svn uri is accessible: else 1 and warns: use subshell for this
#******************************************************************************************************************************
u_is_svn_uri_accessible() {
    (
        [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
        local _uri=${1}

        u_got_internet || return 1

        svn info "${_uri}" --no-auth-cache --non-interactive --trust-server-cert &> /dev/null && return 0
        i_warn "$(_g "u_is_svn_uri_accessible() Couldn't verify that the svn uri is accessible: <%s>\n")" "${_uri}"
        return 1
    )
}


#******************************************************************************************************************************
# Return 0 if hg uri is accessible: else 1 and warns: use subshell for this
#******************************************************************************************************************************
u_is_hg_uri_accessible() {
    (
        [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
        local _uri=${1}

        u_got_internet || return 1

        hg identify "${_uri}" &> /dev/null && return 0
        i_warn "$(_g "%u_is_hg_uri_accessible() Couldn't verify that the hg uri is accessible: <%s>\n")" "${_uri}"
        return 1
    )
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
