#!/bin/bash

#******************************************************************************************************************************
#
#   <example_usage__function_return_values.sh> **peter1000**
#                                         see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

_EX_VERSION="0.1.1"


#******************************************************************************************************************************
# Example: test functions to compare speed and usage
#******************************************************************************************************************************
example_print_version() {
    local _version="0.1.1"
    printf "%s\n" "${_version}"
}


example_retres_version () {
    local -n _retres=${1}
    _retres="0.1.1"
}


#******************************************************************************************************************************
# Example: usage
#******************************************************************************************************************************
usagefunc1() {
    local _result=$(example_print_version)
    if [[ ${_result} == ${_EX_VERSION} ]]; then
        echo "usagefunc1: subshell example_print_version"
        true
    fi
}


usagefunc2() {
    local _result; example_retres_version _result
    if [[ ${_result} == ${_EX_VERSION} ]]; then
        echo "usagefunc2: example_retres_version"
        true
    fi
}


usagefunc1
usagefunc2


#******************************************************************************************************************************
# Example: test return values
#******************************************************************************************************************************
testfunc1() {
    local _result=$(example_print_version)
    [[ ${_result} == ${_EX_VERSION} ]]
}


testfunc2() {
    local _result; example_retres_version _result
    [[ ${_result} == ${_EX_VERSION} ]]

}


_EX_VERSION="0.1.1"
echo
echo "CHECKING:: _EX_VERSION: <${_EX_VERSION}> expect all return values to be 0"
testfunc1
echo "<$?>"
testfunc2
echo "<$?>"

_EX_VERSION="0.0.1"
echo
echo "CHECKING:: _EX_VERSION: <${_EX_VERSION}> expect all return values to be 1"
testfunc1
echo "<$?>"
testfunc2
echo "<$?>"


#******************************************************************************************************************************
# Example: SPeed test
#******************************************************************************************************************************


time { for ((n=0;n<1000;n++)); do testfunc1; done; }
time { for ((n=0;n<1000;n++)); do testfunc2; done; }



#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
