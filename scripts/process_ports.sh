#******************************************************************************************************************************
#
#   <process_ports.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

unset GREP_OPTIONS
shopt -s extglob



#=============================================================================================================================#
#
#                   GENERAL FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Create the individual PKG_BUILD_DIR and subfolders
#
# sets Variables:
#
#       | Variable Name | Description                             |
#       |:--------------|:----------------------------------------|
#       | `pkgdir`      | package directory: _pkg_build_dir/pkg   |
#       | `srcdir`      | sources directory: _pkg_build_dir/src   |
#
#   ARGUMENTS
#       `_pkg_build_dir`: Path to the PKG_BUILD_DIR
#******************************************************************************************************************************
pr_make_pkg_build_dir() {
    local _fn="pr_make_pkg_build_dir"
    [[ -n $1 ]] || ms_abort "$_fn" "$(gettext "FUNCTION '%s()': Argument 1 MUST NOT be empty.")" "$_fn"
    local _pkg_build_dir=$1
    pkgdir="${_pkg_build_dir}/pkg"
    srcdir="${_pkg_build_dir}/src"
    umask 0022

    rm -rf "$_pkg_build_dir"
    mkdir -p "$pkgdir" "$srcdir"
}


#******************************************************************************************************************************
# Get a list of existing pkg_archives.
#
#   ARGUMENTS
#       `_ret_existing_pkg_archives`: a reference var: an empty index array which will be updated with the absolut path to any
#                                     port package archives
#       `_in_port_name`: a reference var: port name
#       `_in_port_path`: a reference var: port absolute path
#       `_in_arch`: a reference var: architecture e.g.: "$(uname -m)"
#       `_in_extention`: a reference var: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       TARGETS=()
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pr_get_existing_pkg_archives TARGETS CMK_PORTNAME CMK_PORT_PATH CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pr_get_existing_pkg_archives() {
    local -n _ret_existing_pkg_archives=$1
    local -n _in_port_name=$2
    local -n _in_port_path=$3
    local -n _in_arch=$4
    local -n _in_extention=$5

    local _find1="${_in_port_name}*${_in_arch}.${_in_extention}*"
    local _find2="${_in_port_name}*any.${_in_extention}*"
    local _pkg_archive

    # always reset the _ret_existing_pkg_archives
    _ret_existing_pkg_archives=()
    for _pkg_archive in $(find $_in_port_path \( -name "$_find1" -or -name "$_find2" \)); do
        _ret_existing_pkg_archives+=("$_pkg_archive")
    done
}


#******************************************************************************************************************************
# Remove existing pkg_archives.
#
#   ARGUMENTS
#       `_in_port_name`: a reference var: port name
#       `_in_port_path`: a reference var: port absolute path
#       `_in_arch`: a reference var: architecture e.g.: "$(uname -m)"
#       `_in_extention`: a reference var: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pr_remove_existing_pkg_archives CMK_PORTNAME CMK_PORT_PATH CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pr_remove_existing_pkg_archives() {
    local -n _in_port_name=$1
    local -n _in_port_path=$2
    local -n _in_arch=$3
    local -n _in_extention=$4

    local _find1="${_in_port_name}*${_in_arch}.${_in_extention}*"
    local _find2="${_in_port_name}*any.${_in_extention}*"
    local _pkg_archive

    find $_in_port_path \( -name "$_find1" -or -name "$_find2" \) -delete
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
