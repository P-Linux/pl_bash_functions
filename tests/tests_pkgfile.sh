#!/bin/bash

#******************************************************************************************************************************
#
#       For more info and example usage: see the 'pl_bash_functions' package *documentation*.
#
#******************************************************************************************************************************

_THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
_TEST_SCRIPT_DIR=$(dirname "${_THIS_SCRIPT_PATH}")
_FUNCTIONS_DIR="$(dirname "${_TEST_SCRIPT_DIR}")/scripts"
_TESTFILE="src_matrix.sh"

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
i_source_safe_exit "${_FUNCTIONS_DIR}/src_matrix.sh"
i_source_safe_exit "${_FUNCTIONS_DIR}/pkgfile.sh"

# MUST SET THESE GLOBAL for the tests_all.sh
declare -gi _COK=0
declare -gi _CFAIL=0

_EXCHANGE_LOG=$(mktemp)


#******************************************************************************************************************************
# TEST: pk_unset_official_pkgfile_var                                   SKIP THIS TEST
#******************************************************************************************************************************

#******************************************************************************************************************************
# TEST: pk_get_collections_lookup()
#******************************************************************************************************************************
tspk__pk_get_collections_lookup() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_get_collections_lookup()"
    local _tmp_dir=$(mktemp -d)
    local _croot="${_tmp_dir}/test_collection_root"
    local _reg_collections=()
    declare -A _collection_lookup=()
    declare -A _collection_lookup_not_empty=([a]=a [b]=b)
    declare -a _collection_lookup_wrong=()
    local _output

    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/test_collection_root.tar.xz"

    _reg_collections=()
    _output=$((pk_get_collections_lookup _collection_lookup_not_empty "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_get_collections_lookup()' Requires EXACT '3' arguments. Got '2'"

    _reg_collections=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile/" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Reference Pkgfile-Name '_ref_pkgfile_name': MUST NOT end with a slash: <Pkgfile/>"

    _reg_collections=()
    _output=$((pk_get_collections_lookup _collection_lookup_wrong "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Not a referenced associative array: '_ret_col_ports_lookup'"

    _reg_collections=()
    (pk_get_collections_lookup _collection_lookup_not_empty "Pkgfile" _reg_collections)
    te_retcode_0 _COK _CFAIL ${?} "Test _in_collection_ports_lookup OK."

    _reg_collections=("not_absolute_path/wrong_collection_path")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "COLLECTION_ENTRY: An absolute directory path MUST start with a slash: <not_absolute_path/wrong_collection_path>"

    _reg_collections=("${_croot}/none_existing_dir")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "COLLECTION directory does not exist" "INPUT: <none_existing_dir>."

    _reg_collections=("${_croot}/only_a_file")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "COLLECTION directory does not exist" "INPUT: <only_a_file>."

    _reg_collections=("${_croot}/lxde_LINK")
    _collection_lookup=()
    pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections
    te_same_val _COK _CFAIL "${#_collection_lookup[@]}" "5" "Test link to collection with 5 ports."

    _reg_collections=("${_croot}/collection_too_short_portname")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '1'" \
        "Too short portname."
    _reg_collections=("${_croot}/collection_too_long_portname")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '53'" \
        "Too long portname."

    _reg_collections=("${_croot}/collection_invalide_char_portname")
    _collection_lookup=()
    _output=$((pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME contains invalid chars: '..'"

    _reg_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _collection_lookup=()
    pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections
    te_same_val _COK _CFAIL "${#_collection_lookup[@]}" "16" "Test 16 ports with collection: personal overlayer."

    te_same_val _COK _CFAIL "${_collection_lookup[autoconf]}" "${_croot}/personal/autoconf/Pkgfile" \
        "Test order first found: personal/autoconf."

    te_same_val _COK _CFAIL "${_collection_lookup[btrfs-progs]}" "${_croot}/base-extra/btrfs-progs/Pkgfile" \
        "Test found: base-extra/btrfs-progs."

    te_same_val _COK _CFAIL "${_collection_lookup[lxde-panel]}" "${_croot}/lxde/lxde-panel/Pkgfile" \
        "Test Linked collection found: lxde/lxde-panel."

    _reg_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _collection_lookup=()
    pk_get_collections_lookup _collection_lookup "Pkgfile" _reg_collections
    te_same_val _COK _CFAIL "${#_collection_lookup[@]}" "16" \
        "Test 16 ports without collection: personal overlayer."

    te_same_val _COK _CFAIL "${_collection_lookup[autoconf]}" "${_croot}/base/autoconf/Pkgfile" \
        "Test without collection: personal overlayer: base/autoconf."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_get_collections_lookup


#******************************************************************************************************************************
# TEST: pk_get_pkgfiles_to_process()
#******************************************************************************************************************************
tspk__pk_get_pkgfiles_to_process() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_get_pkgfiles_to_process()"
    local _tmp_dir=$(mktemp -d)
    local _croot="${_tmp_dir}/test_collection_root"
    local _reg_collections=()
    declare -A _collection_lookup=()
    declare -A _collection_lookup_not_empty=([a]=a [b]=b)
    declare -a _collection_lookup_wrong=()
    local_pkgfiles_to_process=()
    local _portslist=()
    local _output

    bsdtar -p -C "${_tmp_dir}/" -xf "${_TEST_SCRIPT_DIR}/files/test_collection_root.tar.xz"

    _pkgfiles_to_process=()
    _output=$((pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_get_pkgfiles_to_process()' Requires EXACT '4' arguments. Got '2'"

    _portslist=()
    _reg_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    te_same_val _COK _CFAIL "${#_pkgfiles_to_process[@]}" "0" "Test empty portslist."

    _portslist=(lxde-panel autoconf attr)
    _reg_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    te_same_val _COK _CFAIL "${#_pkgfiles_to_process[@]}" "3" "Test Prepare 3 ports."

    _portslist=(lxde-panel autoconf attr)
    _reg_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=(a b c)
    (pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections)
    te_retcode_0 _COK _CFAIL ${?} "Test Not empty _in_pkgfiles_to_process OK."

    _portslist=(lxde-panel autoconf attr)
    _reg_collections=(
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    [[ ${_pkgfiles_to_process[0]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/base/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/base/attr/Pkgfile" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test final Pkgfiles to process - same as input order."

    _portslist=(lxde-panel autoconf attr)
    _reg_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    [[ ${_pkgfiles_to_process[0]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/personal/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/base/attr/Pkgfile" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test final Pkgfiles to process overlay <personal> - same as input order."

    _portslist=("${_croot}/lxde/lxde-panel")
    _reg_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    te_same_val _COK _CFAIL "${_pkgfiles_to_process[0]}" "${_croot}/lxde/lxde-panel/Pkgfile" \
        "Test final Pkgfile is a single absolute directory path."

    _portslist=(
        "autoconf"
        "${_croot}/lxde/lxde-panel"
        "apr"
        "${_croot}/base-extra/dhcpcd"
        "automake"
        "autoconf"
    )
    _reg_collections=(
        "${_croot}/personal"
        "${_croot}/base"
        "${_croot}/base-extra"
        "${_croot}/cli"
        "${_croot}/lxde_LINK"
    )
    _pkgfiles_to_process=()
    pk_get_pkgfiles_to_process _pkgfiles_to_process "Pkgfile" _portslist _reg_collections
    te_same_val _COK _CFAIL "${#_pkgfiles_to_process[@]}" "6" "Test registered port names and absolute port path mixed."

    [[ ${_pkgfiles_to_process[0]} == "${_croot}/personal/autoconf/Pkgfile" &&  \
        ${_pkgfiles_to_process[1]} == "${_croot}/lxde/lxde-panel/Pkgfile" &&  \
        ${_pkgfiles_to_process[2]} == "${_croot}/cli/apr/Pkgfile" && \
        ${_pkgfiles_to_process[3]} == "${_croot}/base-extra/dhcpcd/Pkgfile" && \
        ${_pkgfiles_to_process[4]} == "${_croot}/base/automake/Pkgfile" && \
        ${_pkgfiles_to_process[5]} == "${_croot}/personal/autoconf/Pkgfile" ]]
    te_retcode_0 _COK _CFAIL ${?} "Test registered port names and absolute port path mixed."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_get_pkgfiles_to_process


#******************************************************************************************************************************
# TEST: pk_check_pkgvers()
#******************************************************************************************************************************
tspk__pk_check_pkgvers() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_check_pkgvers()"
    local _output

    _output=$((pk_check_pkgvers "0.1.0.r1.2f12e1a") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_check_pkgvers()' Requires EXACT '2' arguments. Got '1'"


    (pk_check_pkgvers "0.1.0.r1.2f12e1a" "Pkgfile")
    te_retcode_0 _COK _CFAIL ${?} "Test <0.1.0.r1.2f12e1a>."

    _output=$((pk_check_pkgvers "" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable 'pkgvers' MUST NOT be empty" "Test empty pkgversion."

    _output=$((pk_check_pkgvers "0.1.0+ced" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'pkgvers' contains invalid chars: '+'" "Test pkgvers contains invalid chars."

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_check_pkgvers


#******************************************************************************************************************************
# TEST: pk_make_pkgmd5sums()
#******************************************************************************************************************************
tspk__pk_make_pkgmd5sums() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_make_pkgmd5sums()"
    local _tmp_dir=$(mktemp -d)
    local _ports_dir="${_tmp_dir}/ports"
    local _pkgfile_path="${_ports_dir}/example_port/Pkgfile"
    local _srcdst_dir="${_tmp_dir}/cards_mk/sources"
    local _output _new_pkgmd5sums
    declare -A _scrmtx

    # Create files/folders
    mkdir -p "${_ports_dir}"
    mkdir -p "${_srcdst_dir}"
    cp -rf "${_TEST_SCRIPT_DIR}/files/example_port" "${_ports_dir}"

    _new_pkgmd5sums=()
    source "${_pkgfile_path}"

    _output=$((pk_make_pkgmd5sums) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_make_pkgmd5sums()' Requires EXACT '2' arguments. Got '0'"

    _scrmtx=()
    _new_pkgmd5sums=()
    _output=$((pk_make_pkgmd5sums _new_pkgmd5sums _scrmtx) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'"

    _scrmtx=()
    _new_pkgmd5sums=()
    s_get_src_matrix _scrmtx pkgsources pkgmd5sums "${_pkgfile_path}" "${_srcdst_dir}" # &> /dev/null
    # need to redo 'cp' as it gets removed if there was an error
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file.tar.xz" "${_srcdst_dir}/dummy_source_file.tar.xz"
    cp -f "${_TEST_SCRIPT_DIR}/files/example_port/dummy_source_file2.tar.bz2" "${_srcdst_dir}/dummy_source_file2.tar.bz2"
    if [[ ! -f "${_srcdst_dir}/dummy_source_file.tar.xz" || ! -f "${_srcdst_dir}/dummy_source_file2.tar.bz2" ]]; then
        te_warn "${FUNCNAME[0]}" "Can not find the expected testfile for this test-case."
    fi
    pk_make_pkgmd5sums _new_pkgmd5sums _scrmtx
    te_same_val _COK _CFAIL "${#_new_pkgmd5sums[@]}" "4" "Test generated 4 pkgmd5sums entries."

    te_same_val _COK _CFAIL "${_new_pkgmd5sums[0]}" "2987a55e31c80f189a2868ada1cf31df" \
        "Test generated pkgmd5sums index 0 'ftp' entry."

    te_same_val _COK _CFAIL "${_new_pkgmd5sums[1]}" "fd096ad1c3fa5975c5619488165c625b" \
        "Test generated pkgmd5sums index 1 'http' entry."

    te_same_val _COK _CFAIL "${_new_pkgmd5sums[2]}" "SKIP" "Test generated pkgmd5sums index 2 'git' entry."

    te_same_val _COK _CFAIL "${_new_pkgmd5sums[3]}" "01530b8c0b67b5a2a2a46f4c5943a345" \
        "Test generated pkgmd5sums index 3 'local' entry."

    # CLEAN UP
    rm -rf "${_tmp_dir}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_make_pkgmd5sums


#******************************************************************************************************************************
# TEST: pk_check_pkgfile_port_path_name()
#******************************************************************************************************************************
tspk__pk_check_pkgfile_port_path_name() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_check_pkgfile_port_path_name()"
    local _tmp_dir_main=$(mktemp -d)
    local _tmp_dir="${_tmp_dir_main}/tmp_port_dir1"   # may not contain full stops
    local _pkgfile_path="${_tmp_dir}/Pkgfile"
    local _output _tmp_dir2

    mkdir -p "${_tmp_dir}"

    _output=$((pk_check_pkgfile_port_path_name) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: 'pk_check_pkgfile_port_path_name()' Requires EXACT '2' arguments. Got '0'"

    _output=$((pk_check_pkgfile_port_path_name "" "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_check_pkgfile_port_path_name()' Argument '1' MUST NOT be empty."

    _output=$((pk_check_pkgfile_port_path_name "${_pkgfile_path}" "") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_check_pkgfile_port_path_name()' Argument '2' MUST NOT be empty."

    _output=$((pk_check_pkgfile_port_path_name "files/example_collection1/acl" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "COLLECTION_PATH An absolute directory path MUST start with a slash: <files>"

    rm -f "${_pkgfile_path}"
    _output=$((pk_check_pkgfile_port_path_name "${_pkgfile_path}" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PKGFILE_PATH does not exist"
    touch "${_pkgfile_path}"
    _output=$((pk_check_pkgfile_port_path_name "${_pkgfile_path}" "Other_Reference_Name") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "PKGFILE-Basename: 'Pkgfile' is not the same as the defined Reference-Pkgfile-Name: 'Other_Reference_Name'"

    (pk_check_pkgfile_port_path_name "${_pkgfile_path}" "Pkgfile")
    te_retcode_0 _COK _CFAIL ${?} "Test existing Pkgfile path OK."

    _tmp_dir2="${_tmp_dir_main}/x/Pkgfile"
    install -D /dev/null "${_tmp_dir2}"
    _output=$((pk_check_pkgfile_port_path_name "${_tmp_dir2}" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '1'" \
        "Test too short PORTNAME (pkgfile directory) name."

    _tmp_dir2="${_tmp_dir_main}/too__long_pkgfile_directory_name_______is_not_allowed/Pkgfile"
    install -D /dev/null "${_tmp_dir2}"
    _output=$((pk_check_pkgfile_port_path_name "${_tmp_dir2}" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '53'" \
        "Test too long PORTNAME (pkgfile directory) name."

    _tmp_dir2="${_tmp_dir_main}/invalid_char..in_dir_name/Pkgfile"
    install -D /dev/null "${_tmp_dir2}"
    _output=$((pk_check_pkgfile_port_path_name "${_tmp_dir2}" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME contains invalid chars: '..'"

    _tmp_dir2="${_tmp_dir_main}/-is_not_allowed_as_first_char/Pkgfile"
    install -D /dev/null "${_tmp_dir2}"
    _output=$((pk_check_pkgfile_port_path_name "${_tmp_dir2}" "Pkgfile") 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "PORTNAME MUST start with an alphanumeric character. Got: '-'"

    # CLEAN UP
    rm -rf "${_tmp_dir_main}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_check_pkgfile_port_path_name


#******************************************************************************************************************************
# TEST: pk_source_validate_pkgfile()
#******************************************************************************************************************************
tspk__pk_source_validate_pkgfile() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_source_validate_pkgfile()"
    local _testdir="${_TEST_SCRIPT_DIR}"
    local  _required_func_names=("build")
    declare -A _cm_groups_func_names=(["lib"]=0 ["devel"]=0 ["doc"]=0 ["man"]=0 ["service"]=0)
    local _output _pkgfile
    declare -a _cm_groups

    _output=$((pk_source_validate_pkgfile) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "FUNCTION: 'pk_source_validate_pkgfile()' Requires AT LEAST '3' arguments. Got '0'"

    _cm_groups=()
    _pkgfile="${_testdir}/files/none_existing_Pkgfile"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not source file: <${_pkgfile}>"

    _cm_groups=()
    _output=$((pk_source_validate_pkgfile "" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "FUNCTION: 'pk_source_validate_pkgfile()' Argument '1' MUST NOT be empty."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    (pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups)
    te_retcode_0 _COK _CFAIL ${?} "Test <Pkgfile_minimum_info> OK."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile"
    (pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups)
    te_retcode_0 _COK _CFAIL ${?} "Test <Pkgfile> OK."

    _cm_groups=(lib devel doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    (pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups)
    te_retcode_0 _COK _CFAIL ${?} "Test _cm_groups only defaults OK."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_missing_var_pkgdeps"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared index array variable: 'pkgdeps'" \
        "Test Pkgfile_missing_var_pkgdeps."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_too_long_description"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'pkgdesc' MUST have at least 10 and a maximum of 110 chars. Got: '115'" "Test Pkgfile_too_long_description."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_too_short_description"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "'pkgdesc' MUST have at least 10 and a maximum of 110 chars. Got: '5'" "Test Pkgfile_too_short_description."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_version_wrong_char"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'pkgvers' contains invalid chars: '+' File" \
        "Test Pkgfile_version_wrong_char."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_release_wrong_char"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'pkgrel' MUST NOT be empty and only contain digits and not: 'a'" \
        "Test Pkgfile_release_wrong_char."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_release_too_high_number"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "'pkgrel' MUST be greater than 0 and less than 100000000." \
        "Test Pkgfile_release_too_high_number."

    _cm_groups=(customary_group_function doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_minimum_info"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_retcode_1 _COK _CFAIL ${?} "Test _cm_groups not existing customary_group_function."

    te_find_err_msg _COK _CFAIL "${_output}" \
        "CM_GROUPS Function 'customary_group_function' not specified in File" \
        "Test _cm_groups not existing customary_group_function."

    _cm_groups=(customary_group_function lib devel doc man service)
    _pkgfile="${_testdir}/files/Pkgfile_source_customary_group_function_in_file"
    (pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups)
    te_retcode_0 _COK _CFAIL ${?} "Test _cm_groups existing customary_group_function."

    _cm_groups=()
    _pkgfile="${_testdir}/files/Pkgfile_source_missing_required_function"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names _cm_groups) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Required Function 'build' not specified in File" \
        "Test Pkgfile_source_missing_required_function"

    pk_source_validate_pkgfile "${_testdir}/files/Pkgfile" _required_func_names _cm_groups_func_names
    [[ ${pkgpackager} == "peter1000 <https://github.com/peter1000>"                                 && \
        ${pkgdesc} == "Bash functions used by other P-Linux packages."                              && \
        ${pkgurl} == "https://github.com/P-Linux/pl_bash_functions"                                 && \
        ${pkgdeps[@]} == "libarchive gzip bzip2 xz git subversion mercurial bzr"                    && \
        ${pkgvers} == "0.1.0.r1.2f12e1a"                                                            && \
        ${pkgrel} == "4"                                                                            && \
        ${pkgsources[@]} == "pl_bash_functions::https://github.com/P-Linux/pl_bash_functions.git"   && \
        ${pkgmd5sums[@]} == "SKIP"                                                                  && \
        ${pkgdepsrun[@]} == "bash" ]]
    te_retcode_0 _COK _CFAIL ${?} " Test all official pkgfile variables."

    pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_minimum_info" _required_func_names _cm_groups_func_names
    [[ ${pkgpackager} == "Package 'Packager' variable MUST NOT be empty."   && \
        ${pkgdesc} == "Package 'Description variable MUST NOT be empty."    && \
        -z ${pkgurl}                                                        && \
        ${#pkgdeps[@]} == 0                                                 && \
        ${pkgvers} == "0.1.0"                                               && \
        ${pkgrel} == "1"                                                    && \
        ${#pkgsources[@]} == 0                                              && \
        ${#pkgmd5sums[@]} == 0                                              && \
        ${#pkgdepsrun[@]} ]]
    te_retcode_0 _COK _CFAIL ${?} " Test all official pkgfile variables - minimum_info."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgpackager"  _required_func_names \
        _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find variable 'pkgpackager'."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgdesc" _required_func_names \
        _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find variable 'pkgdesc'." "Test <Pkgfile_missing_var_pkgdesc>."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgurl" _required_func_names \
        _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find variable 'pkgurl'." "Test <Pkgfile_missing_var_pkgurl>."

    _pkgfile="${_testdir}/files/Pkgfile_missing_var_pkgdeps"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared index array variable: 'pkgdeps' Called From: 'pk_source_validate_pkgfile()' INFO: ${_pkgfile}"

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgvers" _required_func_names \
        _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find variable 'pkgvers'."

    _output=$((pk_source_validate_pkgfile "${_testdir}/files/Pkgfile_missing_var_pkgrel" _required_func_names \
        _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Could not find variable 'pkgrel'."

    _pkgfile="${_testdir}/files/Pkgfile_missing_var_pkgsources"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared index array variable: 'pkgsources' Called From: 'pk_source_validate_pkgfile()' INFO: ${_pkgfile}"

    _pkgfile="${_testdir}/files/Pkgfile_missing_var_pkgmd5sums"
    _output=$((pk_source_validate_pkgfile "${_pkgfile}" _required_func_names _cm_groups_func_names) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" \
        "Not a declared index array variable: 'pkgmd5sums' Called From: 'pk_source_validate_pkgfile()' INFO: ${_pkgfile}"

    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tspk__pk_source_validate_pkgfile


#******************************************************************************************************************************
# TEST: pk_export()
#******************************************************************************************************************************
tsi__pk_export() {
    (source "${_EXCHANGE_LOG}"

    te_print_function_msg "pk_export()"
    local _output

    unset _BF_EXPORT_ALL

    _output=$((pk_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'."

    _BF_EXPORT_ALL="wrong"
    _output=$((pk_export) 2>&1)
    te_find_err_msg _COK _CFAIL "${_output}" "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: 'wrong'."

    (
        _BF_EXPORT_ALL="yes"
        pk_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes'."

        [[ $(declare -F) == *"declare -fx pk_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'yes' - find exported function: 'declare -fx pk_export'."

        _BF_EXPORT_ALL="no"
        pk_export &> /dev/null
        te_retcode_0 _COK _CFAIL ${?} "Test _BF_EXPORT_ALL set to 'no'."

        [[ $(declare -F) == *"declare -f pk_export"* ]]
        te_retcode_0 _COK _CFAIL ${?} \
            "Test _BF_EXPORT_ALL set to 'yes' - find NOT exported function: 'declare -f pk_export'."

        # need to write the results from the subshell
        echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
    # need to resource the results from the subshell
    source "${_EXCHANGE_LOG}"


    ###
    echo -e "_COK=${_COK}; _CFAIL=${_CFAIL}" > "${_EXCHANGE_LOG}"
    )
}
tsi__pk_export



#******************************************************************************************************************************

source "${_EXCHANGE_LOG}"
te_print_final_result "${_TESTFILE}" "${_COK}" "${_CFAIL}" 80
rm -f "${_EXCHANGE_LOG}"

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
