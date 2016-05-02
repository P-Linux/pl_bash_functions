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
# End of file
#******************************************************************************************************************************
