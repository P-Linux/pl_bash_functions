#!/bin/bash

#******************************************************************************************************************************
#
#   <example_usage__function_return_values.sh> **peter1000**
#                                         see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

_EX_VERSION="0.9.0"


#******************************************************************************************************************************
# Example: test functions to compare speed and usage
#******************************************************************************************************************************
example_print_version() {
    local _version="0.9.0"
    printf "%s\n" "$_version"
}


example_ret_result_version () {
    local -n _ret_result=$1
    _ret_result="0.9.0"
}


#******************************************************************************************************************************
# Example: usage
#******************************************************************************************************************************
usagefunc1() {
    local _result=$(example_print_version)
    if [[ $_result == $_EX_VERSION ]]; then
        echo "usagefunc1: subshell example_print_version"
        true
    fi
}


usagefunc2() {
    local _result; example_ret_result_version _result
    if [[ $_result == $_EX_VERSION ]]; then
        echo "usagefunc2: example_ret_result_version"
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
    [[ $_result == $_EX_VERSION ]]
}


testfunc2() {
    local _result; example_ret_result_version _result
    [[ $_result == $_EX_VERSION ]]

}


_EX_VERSION="0.9.0"
echo
echo "CHECKING:: _EX_VERSION: <$_EX_VERSION> expect all return values to be 0"
testfunc1
echo "<$?>"
testfunc2
echo "<$?>"

_EX_VERSION="0.9.1"
echo
echo "CHECKING:: _EX_VERSION: <$_EX_VERSION> expect all return values to be 1"
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
