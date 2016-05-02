#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "$_THIS_SCRIPT_PATH")

source "${_TEST_SCRIPT_DIR}/../trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"$_signal\"" "$_signal"; done
trap "tr_trap_exit_interrupted" INT
# DOES NOT WORK IF 'tests_all.sh' runs because of the readonly variables:  trap "tr_trap_exit_unknown_error" ERR

source "${_TEST_SCRIPT_DIR}/../testing.sh"
te_print_header "pkgfile.sh"

source "${_TEST_SCRIPT_DIR}/../msg.sh"
ms_format "$_THIS_SCRIPT_PATH"

source "${_TEST_SCRIPT_DIR}/../utilities.sh"
ut_source_safe_abort "${_TEST_SCRIPT_DIR}/../source_matrix.sh"
ut_source_safe_abort "${_TEST_SCRIPT_DIR}/../pkgfile.sh"

declare -i _COUNT_OK=0
declare -i _COUNT_FAILED=0



# pk_unset_official_pkgfile_variables skip test for this function


#******************************************************************************************************************************
# TEST: pk_prepare_collections_lookup()
#******************************************************************************************************************************
ts_pk___pk_prepare_collections_lookup() {
    te_print_function_msg "pk_prepare_collections_lookup()"
    local _tmp_dir=$(mktemp -d)
    local _croot="${_tmp_dir}/test_collection_root"
    local _registered_collections=()
    declare -A _collection_lookup=()
    declare -A _collection_lookup_not_empty=([a]=a [b]=b)
    declare -a _collection_lookup_wrong=()
    local _output

    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/test_collection_root.tar.xz"

    _registered_collections=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile/" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "Reference Pkgfile-Name '_reference_pkgfile_name': MUST NOT end with a slash: <Pkgfile/>"

    _registered_collections=()
    _output=$((pk_prepare_collections_lookup _collection_lookup_wrong "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "FUNCTION: 'pk_prepare_collections_lookup()' Not a referenced associative array: '_ret_collection_ports_lookup'"

    _registered_collections=()
    (pk_prepare_collections_lookup _collection_lookup_not_empty "Pkgfile" _registered_collections)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test _in_collection_ports_lookup OK."

    _registered_collections=("not_absolute_path/wrong_collection_path")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "COLLECTION_ENTRY: An absolute directory path MUST start with a slash: <not_absolute_path/wrong_collection_path>"

    _registered_collections=("${_croot}/none_existing_dir")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FINAL COLLECTION directory does not exist" \
        "INPUT: <none_existing_dir>."

    _registered_collections=("${_croot}/only_a_file")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "FINAL COLLECTION directory does not exist" "INPUT: <only_a_file>."

    _registered_collections=("${_croot}/lxde_LINK")
    _collection_lookup=()
    pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${#_collection_lookup[@]}" "5" "Test link to collection with 5 ports."

    _registered_collections=("${_croot}/collection_too_short_portname")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '1'" \
        "Too short portname."

    _registered_collections=("${_croot}/collection_too_long_portname")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '53'" \
        "Too long portname."

    _registered_collections=("${_croot}/collection_invalide_char_portname")
    _collection_lookup=()
    _output=$((pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME contains invalid characters: '..'"

    _registered_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _collection_lookup=()
    pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${#_collection_lookup[@]}" "16" "Test 16 ports with collection: personal overlayer."

    te_same_val _COUNT_OK _COUNT_FAILED "${_collection_lookup[autoconf]}" "${_croot}/personal/autoconf/Pkgfile" \
        "Test order first found: personal/autoconf."

    te_same_val _COUNT_OK _COUNT_FAILED "${_collection_lookup[btrfs-progs]}" "${_croot}/base-extra/btrfs-progs/Pkgfile" \
        "Test found: base-extra/btrfs-progs."

    te_same_val _COUNT_OK _COUNT_FAILED "${_collection_lookup[lxde-panel]}" "${_croot}/lxde/lxde-panel/Pkgfile" \
        "Test Linked collection found: lxde/lxde-panel."

    _registered_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _collection_lookup=()
    pk_prepare_collections_lookup _collection_lookup "Pkgfile" _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${#_collection_lookup[@]}" "16" \
        "Test 16 ports without collection: personal overlayer."

    te_same_val _COUNT_OK _COUNT_FAILED "${_collection_lookup[autoconf]}" "${_croot}/base/autoconf/Pkgfile" \
        "Test without collection: personal overlayer: base/autoconf."
    # CLEAN UP
    rm -rf "$_tmp_dir"
}
ts_pk___pk_prepare_collections_lookup


#******************************************************************************************************************************
# TEST: pk_prepare_pkgfiles_to_process()
#******************************************************************************************************************************
ts_pk___pk_prepare_pkgfiles_to_process() {
    te_print_function_msg "pk_prepare_pkgfiles_to_process()"
    local _tmp_dir=$(mktemp -d)
    local _croot="${_tmp_dir}/test_collection_root"
    local _registered_collections=()
    declare -A _collection_lookup=()
    declare -A _collection_lookup_not_empty=([a]=a [b]=b)
    declare -a _collection_lookup_wrong=()
    local_pkgfiles_to_process=()
    local _portslist=()
    local _output

    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/test_collection_root.tar.xz"

    _portslist=(lxde-panel autoconf attr)
    _registered_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${#_pkgfiles_to_process[@]}" "3" "TTest Prepare 3 ports."

    _portslist=(lxde-panel autoconf attr)
    _registered_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=(a b c)
    (pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test Not empty _in_pkgfiles_to_process OK."

    _portslist=(lxde-panel autoconf attr)
    _registered_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections
    [[ ${_pkgfiles_to_process[0]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/base/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/base/attr/Pkgfile" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test final Pkgfiles to process - same as input order."

    _portslist=(lxde-panel autoconf attr)
    _registered_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections
    [[ ${_pkgfiles_to_process[0]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/personal/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/base/attr/Pkgfile" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test final Pkgfiles to process overlay <personal> - same as input order."

    _portslist=("${_croot}/lxde/lxde-panel")
    _registered_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${_pkgfiles_to_process[0]}" "${_croot}/lxde/lxde-panel/Pkgfile" \
        "Test final Pkgfile is a single absolute directory path."

    _portslist=(
        "autoconf"
        "${_croot}/lxde/lxde-panel"
        "apr"
        "${_croot}/base-extra/dhcpcd"
        "automake"
        "autoconf"
    )
    _registered_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_prepare_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _registered_collections
    te_same_val _COUNT_OK _COUNT_FAILED "${#_pkgfiles_to_process[@]}" "6" \
        "Test registered port names and absolute port path mixed."

    [[ ${_pkgfiles_to_process[0]} == "${_croot}/personal/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/cli/apr/Pkgfile" && \
        ${_pkgfiles_to_process[3]} == "${_croot}/base-extra/dhcpcd/Pkgfile" && \
        ${_pkgfiles_to_process[4]} == "${_croot}/base/automake/Pkgfile" && \
        ${_pkgfiles_to_process[5]} == "${_croot}/personal/autoconf/Pkgfile" ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test registered port names and absolute port path mixed."

    # CLEAN UP
    rm -rf "$_tmp_dir"
    echo
}
ts_pk___pk_prepare_pkgfiles_to_process


#******************************************************************************************************************************
# TEST: pk_validate_pkgvers()
#******************************************************************************************************************************
ts_pk___pk_validate_pkgvers() {
    te_print_function_msg "pk_validate_pkgvers()"
    local _output

    (pk_validate_pkgvers "0.1.0.r1.2f12e1a" "Pkgfile")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test <0.1.0.r1.2f12e1a>."

    _output=$((pk_validate_pkgvers "" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Variable 'pkgvers' MUST NOT be empty" \
        "Test empty pkgversion."

    _output=$((pk_validate_pkgvers "0.1.0+ced" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgvers' contains invalid characters: '+'" \
        "Test pkgvers contains invalid characters."
}
ts_pk___pk_validate_pkgvers


#******************************************************************************************************************************
# TEST: pk_get_only_pkgvers_abort()
#******************************************************************************************************************************
ts_pk___pk_get_only_pkgvers_abort() {
    te_print_function_msg "pk_get_only_pkgvers_abort()"
    local _testdir="${_TEST_SCRIPT_DIR}"
    local _output

    _output=$(pk_get_only_pkgvers_abort "${_testdir}/files/Pkgfile")
    te_same_val _COUNT_OK _COUNT_FAILED "$_output" "0.1.0.r1.2f12e1a" "Test <Pkgfile> pkgversion."

    _output=$(pk_get_only_pkgvers_abort "${_testdir}/files/Pkgfile_minimum_info")
    te_same_val _COUNT_OK _COUNT_FAILED "$_output" 0.1.0"" "Test <Pkgfile_minimum_info> pkgversion."

    _output=$((pk_get_only_pkgvers_abort "${_testdir}/files/Pkgfile_missing_var_pkgvers") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Variable 'pkgvers' MUST NOT be empty" \
        "Test <Pkgfile_missing_var_pkgvers> pkgversion."

    _output=$((pk_get_only_pkgvers_abort "${_testdir}/files/Pkgfile_version_wrong_char") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgvers' contains invalid characters: '+'" \
        "Test <Pkgfile_version_wrong_char> pkgversion."
}
ts_pk___pk_get_only_pkgvers_abort


#******************************************************************************************************************************
# TEST: pk_validate_pkgfile_port_path_name()
#******************************************************************************************************************************
ts_pk___pk_validate_pkgfile_port_path_name() {
    te_print_function_msg "pk_validate_pkgfile_port_path_name()"
    local _fn="ts_do___do_download_source_file_general"
    local _tmp_dir_main=$(mktemp -d)
    local _tmp_dir="${_tmp_dir_main}/tmp_port_dir1"   # may not contain full stops
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _output _tmp_dir2

    mkdir -p "$_tmp_dir"

    _output=$((pk_validate_pkgfile_port_path_name "$_pkgfile_path" "") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "FUNCTION 'pk_validate_pkgfile_port_path_name()': Argument 2 MUST NOT be empty."

    _output=$((pk_validate_pkgfile_port_path_name "files/Pkgfile" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORT_PATH An absolute directory path MUST start with a slash: <files>"

    rm -f "$_pkgfile_path"
    _output=$((pk_validate_pkgfile_port_path_name "$_pkgfile_path" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PKGFILE_PATH does not exist"
    touch "$_pkgfile_path"
    _output=$((pk_validate_pkgfile_port_path_name "$_pkgfile_path" "Other_Reference_Name") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "PKGFILE-Basename: 'Pkgfile' is not the same as the defined Reference-Pkgfile-Name: 'Other_Reference_Name'"

    (pk_validate_pkgfile_port_path_name "$_pkgfile_path" "Pkgfile")
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test existing Pkgfile path OK."

    _tmp_dir2="${_tmp_dir_main}/x/Pkgfile"
    install -D /dev/null "$_tmp_dir2"
    _output=$((pk_validate_pkgfile_port_path_name "$_tmp_dir2" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME MUST have at least 2 and maximum 50 characters. Got: '1'" \
        "Test too short PORTNAME (pkgfile directory) name."

    _tmp_dir2="${_tmp_dir_main}/too__long_pkgfile_directory_name_______is_not_allowed/Pkgfile"
    install -D /dev/null "$_tmp_dir2"
    _output=$((pk_validate_pkgfile_port_path_name "$_tmp_dir2" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME MUST have at least 2 and maximum 50 characters. Got: '53'" \
        "Test too long PORTNAME (pkgfile directory) name."

    _tmp_dir2="${_tmp_dir_main}/invalid_char..in_dir_name/Pkgfile"
    install -D /dev/null "$_tmp_dir2"
    _output=$((pk_validate_pkgfile_port_path_name "$_tmp_dir2" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME contains invalid characters: '..'"

    _tmp_dir2="${_tmp_dir_main}/-is_not_allowed_as_first_char/Pkgfile"
    install -D /dev/null "$_tmp_dir2"
    _output=$((pk_validate_pkgfile_port_path_name "$_tmp_dir2" "Pkgfile") 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "PORTNAME MUST start with an alphanumeric character. Got: '-'"

    # CLEAN UP
    rm -rf "$_tmp_dir_main"
}
ts_pk___pk_validate_pkgfile_port_path_name


#******************************************************************************************************************************
# TEST: pk_source_validate_pkgfile()
#******************************************************************************************************************************
ts_pk___pk_source_validate_pkgfile() {
    te_print_function_msg "pk_source_validate_pkgfile()"
    local _testdir="${_TEST_SCRIPT_DIR}"
    local  _required_func_names=("build")
    local _cmk_groups_func_names=("lib" "devel" "doc" "man" "service")
    local _output _pkgfile
    declare -a _cmk_groups

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    (pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test <Pkgfile_minimum_info> OK."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile"
    (pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test <Pkgfile> OK."

    _cmk_groups=(lib devel doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    (pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test _cmk_groups only defaults OK."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_missing_var_pkgdeps"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "FUNCTION: 'pk_source_validate_pkgfile()' Not a declared index array: 'pkgdeps' INFO" \
        "Test Pkgfile_missing_var_pkgdeps."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_too_long_description"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "'pkgdesc' MUST have at least 10 and a maximum of 110 characters. Got: '115'" "Test Pkgfile_too_long_description."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_too_short_description"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "'pkgdesc' MUST have at least 10 and a maximum of 110 characters. Got: '5'" "Test Pkgfile_too_short_description."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_version_wrong_char"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgvers' contains invalid characters: '+' File" \
        "Test Pkgfile_version_wrong_char."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_release_wrong_char"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgrel' MUST NOT be empty and only contain digits and not: 'a'" \
        "Test Pkgfile_release_wrong_char."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_release_too_high_number"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgrel' MUST be greater than 0 and less than 100000000." \
        "Test Pkgfile_release_too_high_number."

    _cmk_groups=(customary_group_function doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_retval_1 _COUNT_OK _COUNT_FAILED $? "Test _cmk_groups not existing customary_group_function."

    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "CMK_GROUPS Function 'customary_group_function' not specified in File" \
        "Test _cmk_groups not existing customary_group_function."

    _cmk_groups=(customary_group_function lib devel doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_source_customary_group_function_in_file"
    (pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups)
    te_retval_0 _COUNT_OK _COUNT_FAILED $? "Test _cmk_groups existing customary_group_function."

    _cmk_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_source_missing_required_function"
    _output=$((pk_source_validate_pkgfile "$_pkgfile" _required_func_names _cmk_groups_func_names _cmk_groups) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Required Function 'build' not specified in File" \
        "Test Pkgfile_source_missing_required_function"

    pk_source_validate_pkgfile "${_testdir}/files/Pkgfile" _required_func_names _cmk_groups_func_names
    [[ $pkgpackager == "peter1000 <https://github.com/peter1000>"                                && \
        $pkgdesc == "Bash functions used by other P-Linux packages."                              && \
        $pkgurl == "https://github.com/P-Linux/pl_bash_functions"                                 && \
        ${pkgdeps[@]} == "libarchive gzip bzip2 xz git subversion mercurial bzr"                  && \
        $pkgvers == "0.1.0.r1.2f12e1a"                                                            && \
        $pkgrel == "4"                                                                            && \
        ${pkgsources[@]} == "pl_bash_functions::https://github.com/P-Linux/pl_bash_functions.git" && \
        ${pkgmd5sums[@]} == "SKIP"                                                                && \
        -z ${pkgdepsrun[@]} ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? " Test all official pkgfile variables."

    pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_minimum_info" _required_func_names _cmk_groups_func_names
    [[ $pkgpackager == "Package 'Packager' variable MUST NOT be empty."  && \
        $pkgdesc == "Package 'Description variable MUST NOT be empty."    && \
        -z $pkgurl                                                        && \
        -z ${pkgdeps[@]}                                                  && \
        $pkgvers == "0.1.0"                                               && \
        $pkgrel == "1"                                                    && \
        -z ${pkgsources[@]}                                               && \
        -z ${pkgmd5sums[@]}                                               && \
        -z ${pkgdepsrun[@]} ]]
    te_retval_0 _COUNT_OK _COUNT_FAILED $? " Test all official pkgfile variables - minimum_info."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgpackager"  _required_func_names \
        _cmk_groups_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Variable 'pkgpackager' MUST NOT be empty"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgdesc" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" \
        "'pkgdesc' MUST have at least 10 and a maximum of 110 characters. Got: '0'" \
        "Test Variable <pkgdesc> MUST NOT be empty."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgurl" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared string variable: 'pkgurl' INFO"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgdeps" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: 'pkgdeps' INFO"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgvers" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Variable 'pkgvers' MUST NOT be empty"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgrel" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "'pkgrel' MUST NOT be empty and only contain digits and not: ''"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgsources" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: 'pkgsources' INFO"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgmd5sums" _required_func_names) 2>&1)
    te_find_err_msg _COUNT_OK _COUNT_FAILED "$_output" "Not a declared index array: 'pkgmd5sums' INFO"
}
ts_pk___pk_source_validate_pkgfile



#******************************************************************************************************************************

te_print_final_result "$_COUNT_OK" "$_COUNT_FAILED"


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
