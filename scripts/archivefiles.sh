#******************************************************************************************************************************
#
#   <archivefiles.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
#                   GENERAL FUNCTIONS
#
#=============================================================================================================================#


#******************************************************************************************************************************
# Get a list of existing pkgarchives in the port directory. NOTE: This does not search for any pkgarchives in subdirectories.
#
#   ARGUMENTS
#       `_ret_list`: a reference var: an empty index array which will be updated with the absolut path to any pkgarchives
#       `_name`: port name
#       `_path`: port absolute path
#       `_sysarch`: architecture e.g.: "$(uname -m)"
#       `_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       TARGETS=()
#       CM_PORTNAME="hwinfo"
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CM_ARCH="$(uname -m)"
#       CM_PKG_EXT="cards.tar"
#       a_list_pkgarchives TARGETS "${CM_PORTNAME}" "${CM_PORT_PATH}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_list_pkgarchives() {
    i_exact_args_exit ${LINENO} 5 ${#}
    local -n _ret_list=${1}
    local _name=${2}
    local _path=${3}
    local _sysarch=${4}
    local _ref_ext=${5}
    local _f

    # NOTE: Check if no file is found: which returns still 2 results e.g. for acl
    #   /usr/ports/example_collection1/acl/acl*x86_64.cards.tar*
    # /usr/ports/example_collection1/acl/acl*any.cards.tar*
    #
    # to fix this: instead of using a `subshell` and `shopt -s nullglob`
    #   it is in the most common cases faster to check it ourself
    for _f in "${_path}/${_name}"*"${_sysarch}.${_ref_ext}"* "${_path}/${_name}"*"any.${_ref_ext}"*; do
        [[ ${_f} == *"*" ]] || _ret_list+=("${_f}")
    done
}


#******************************************************************************************************************************
# Remove existing pkgarchives. NOTE: This does not search for any pkgarchives in subdirectories to allow for backups.
#
#   ARGUMENTS
#       `_name`: port name
#       `_path`: port absolute path
#       `_sysarch`: architecture e.g.: "$(uname -m)"
#       `_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `_backup_dir`: NONE or absolute path to a pkgarchive backup dir
#                              if NONE: existing_pkgarchives will be deleted, else moved to the _backup_dir
#
#   USAGE
#       PORTNAME="hwinfo"
#       PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CM_ARCH="$(uname -m)"
#       CM_PKG_EXT="cards.tar"
#       a_rm_pkgarchives "${PORTNAME}" "${PORT_PATH}" "${CM_ARCH}" "${CM_PKG_EXT}" "${PKGARCHIVE_BACKUP_DIR}"
#******************************************************************************************************************************
a_rm_pkgarchives() {
    i_exact_args_exit ${LINENO} 5 ${#}
    i_exit_empty_arg ${LINENO} "${5}" 5
    local _name=${1}
    local _path=${2}
    local _sysarch=${3}
    local _ref_ext=${4}
    local _backup_dir=${5}
    local _f

    if [[ ${_backup_dir} == "NONE" ]]; then
        i_more_i "$(_g "Removing any existing pkgarchive files for Port <%s>")" "${_path}"
        for _f in "${_path}/${_name}"*"${_sysarch}.${_ref_ext}"* "${_path}/${_name}"*"any.${_ref_ext}"*; do
            [[ ${_f} == *"*" ]] || rm -f "${_f}"
        done
    else
        i_more_i "$(_g "Moving any existing pkgarchive files for Port <%s>")" "${_path}"
        i_more_i "$(_g "    Moving to pkgarchive_backup_dir: <%s>")" "${_backup_dir}"
        u_dir_is_rwx_exit "${_backup_dir}" "yes" "_in_backup_dir"
        for _f in "${_path}/${_name}"*"${_sysarch}.${_ref_ext}"* "${_path}/${_name}"*"any.${_ref_ext}"*; do
            [[ ${_f} == *"*" ]] || mv -f "${_f}" "${_backup_dir}"
        done
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive extension part.
#
#   ARGUMENTS
#       `_ret_ext_e`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local EXTENTION=""
#       a_get_archive_ext EXTENTION "${PKGARCHIVE}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_ext() {
    i_exact_args_exit ${LINENO} 3 ${#}
    local -n _ret_ext_e=${1}
    local _path=${2}
    local _ref_ext=${3}

    if [[ ${_path} == *"${_ref_ext}.xz" ]]; then
        _ret_ext_e=".${_ref_ext}.xz"
    elif [[ ${_path} == *"${_ref_ext}" ]]; then
        _ret_ext_e=".${_ref_ext}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" \
            "${_ref_ext}" "${_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive name part.
#
#   ARGUMENTS
#       `_ret_name`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_sysarch`: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME=""
#       a_get_archive_name NAME "${PKGARCHIVE}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_name() {
    i_exact_args_exit ${LINENO} 4 ${#}
    local -n _ret_name_n=${1}
    local _path=${2}
    local _sysarch=${3}
    local _ref_ext=${4}
    local _name; u_basename _name "${_path}"
    local _ext; a_get_archive_ext _ext "${_name}" "${_ref_ext}"
    local _ending

    if [[ ${_name} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_name} == *"${_sysarch}${_ext}" ]]; then
        _ret_arch="${_sysarch}"
        _ending="${_sysarch}${_ext}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    _ret_name_n=${_name:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_n} ]] ||  i_exit 1 ${LINENO} "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" "${_path}"
}


#******************************************************************************************************************************
# Returns the pkgarchive buildversion part.
#
#   ARGUMENTS
#       `_ret_buildvers_b`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_sysarch`: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local BUILDVERS=""
#       a_get_archive_buildvers BUILDVERS "${PKGARCHIVE}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_buildvers() {
    i_exact_args_exit ${LINENO} 4 ${#}
    local -n _ret_buildvers_b=${1}
    local _path=${2}
    local _sysarch=${3}
    local _ref_ext=${4}
    local _ext; a_get_archive_ext _ext "${_path}" "${_ref_ext}"
    local _ending

    if [[ ${_path} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_path} == *"${_sysarch}${_ext}" ]]; then
        _ret_arch="${_sysarch}"
        _ending="${_sysarch}${_ext}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'architecture' part must be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    _ret_buildvers_b=${_path:: -${#_ending}}
    _ret_buildvers_b=${_ret_buildvers_b: -10}
    if [[ ${_ret_buildvers_b} != +([[:digit:]]) ]]; then
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s': <%s>")" \
            "${_ret_buildvers_b//[[:digit:]]}" "${_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive architecture part.
#
#   ARGUMENTS
#       `_ret_arch_a`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_sysarch`: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local ARCH=""
#       a_get_archive_arch ARCH "${PKGARCHIVE}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_arch() {
    i_exact_args_exit ${LINENO} 4 ${#}
    local -n _ret_arch_a=${1}
    local _path=${2}
    local _sysarch=${3}
    local _ref_ext=${4}
    local _ext; a_get_archive_ext _ext "${_path}" "${_ref_ext}"

    if [[ ${_path} == *"any${_ext}" ]]; then
        _ret_arch_a="any"
    elif [[ ${_path} == *"${_sysarch}${_ext}" ]]; then
        _ret_arch_a="${_sysarch}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive individual parts.
#
#   NOTE: for speed reason we do not use the other separate functions: this here takes approximately only 1/3 of the time.
#
#   ARGUMENTS
#       `_ret_name_parts`: a reference var: an empty string which will be updated with the result.
#       `_ret_buildvers_parts`: a reference var: an empty string which will be updated with the result.
#       `_ret_arch_parts`: a reference var: an empty string which will be updated with the result.
#       `_ret_ext_parts`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_sysarch`: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`:the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME BUILDVERS ARCH EXT
#       a_get_archive_parts NAME BUILDVERS ARCH EXT "${PKGARCHIVE}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_parts() {
    i_exact_args_exit ${LINENO} 7 ${#}
    local -n _ret_name_parts=${1}
    local -n _ret_buildvers_parts=${2}
    local -n _ret_arch_parts=${3}
    local -n _ret_ext_parts=${4}
    local _path=${5}
    local _sysarch=${6}
    local _ref_ext=${7}
    local _name; u_basename _name "${_path}"
    local _ending
    declare -i _ending_size

    # EXT
    if [[ ${_name} == *"${_ref_ext}.xz" ]]; then
        _ret_ext_parts=".${_ref_ext}.xz"
    elif [[ ${_name} == *"${_ref_ext}" ]]; then
        _ret_ext_parts=".${_ref_ext}"
    else
        i_exit 1 ${LINENO} \
            "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" "${_ref_ext}" "${_path}"
    fi

    # ARCH
    if [[ ${_name} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_parts="any"
    elif [[ ${_name} == *"${_sysarch}${_ret_ext_parts}" ]]; then
        _ret_arch_parts="${_sysarch}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    ###
    _ending="${_ret_arch_parts}${_ret_ext_parts}"
    _ending_size=${#_ending}

    # BUILDVERS
    _ret_buildvers_parts=${_name:: -${_ending_size}}
    _ret_buildvers_parts=${_ret_buildvers_parts: -10}
    if [[ ${_ret_buildvers_parts} != +([[:digit:]]) ]]; then
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s': <%s>")" \
            "${_ret_buildvers_parts//[[:digit:]]}" "${_path}"
    fi

    # NAME
    _ret_name_parts=${_name:: -((${_ending_size}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_parts} ]] || i_exit 1 ${LINENO} "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" "${_path}"
}


#******************************************************************************************************************************
# Returns the pkgarchive name and architecture parts.
#
#   NOTE: for speed reason we do not use the other separate functions: this here takes approximately only 1/3 of the time.
#
#   ARGUMENTS
#       `_ret_name_na`: a reference var: an empty string which will be updated with the result.
#       `_ret_arch_na`: a reference var: an empty string which will be updated with the result.
#       `_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_sysarch`: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME ARCH
#       a_get_archive_name_arch NAME ARCH "${PKGARCHIVE}" "${CM_ARCH}" "${CM_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_name_arch() {
    i_exact_args_exit ${LINENO} 5 ${#}
    local -n _ret_name_na=${1}
    local -n _ret_arch_na=${2}
    local _path=${3}
    local _sysarch=${4}
    local _ref_ext=${5}
    local _name; u_basename _name "${_path}"
    local _ending

    # EXT
    if [[ ${_name} == *"${_ref_ext}.xz" ]]; then
        _ret_ext_parts=".${_ref_ext}.xz"
    elif [[ ${_name} == *"${_ref_ext}" ]]; then
        _ret_ext_parts=".${_ref_ext}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" \
            "${_ref_ext}" "${_path}"
    fi

    # ARCH
    if [[ ${_name} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_na="any"
    elif [[ ${_name} == *"${_sysarch}${_ret_ext_parts}" ]]; then
        _ret_arch_na="${_sysarch}"
    else
        i_exit 1 ${LINENO} "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    ###
    _ending="${_ret_arch_na}${_ret_ext_parts}"

    # NAME
    _ret_name_na=${_name:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_na} ]] || i_exit 1 ${LINENO} "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" "${_path}"
}


#******************************************************************************************************************************
# Returns 'yes' if the pkgarchive is up-to-date otherwise 'no'
#
#   ARGUMENTS
#       `_ret`: a reference var: an empty string which will be updated with the result.
#       `_pkgfile`: absolute path to the ports pkgfile
#       `_archive`: the full path of a pkgarchive to check
#
#   USAGE
#       local PKGARCHIVE_IS_UP_TO_DATE=""
#       a_is_archive_uptodate PKGARCHIVE_IS_UP_TO_DATE "${PKGFILE_PATH}" "${PKGARCHIVE_PATH}"
#******************************************************************************************************************************
a_is_archive_uptodate() {
    i_exact_args_exit ${LINENO} 3 ${#}
    local -n _ret=${1}
    local _pkgfile=${2}
    local _archive=${3}

    _ret="no"
    if [[ -f ${_archive} ]]; then
        _ret="yes"
        [[ -f ${_pkgfile} ]] || i_exit 1 ${LINENO} "$(_g "Corresponding Pkgfile does not exist. Path: <%s>")" "${_pkgfile}"
        if [[ ${_pkgfile} -nt ${_archive} ]]; then
            _ret="no"
        fi
    fi
}


#******************************************************************************************************************************
# TODO: UPDATE THIS if there are functions/variables added or removed.
#
# EXPORT:
#   helpful command to get function names: `declare -F` or `compgen -A function`
#******************************************************************************************************************************
a_export() {
    local _func_names _var_names

    _func_names=(
        a_export
        a_get_archive_arch
        a_get_archive_buildvers
        a_get_archive_ext
        a_get_archive_name
        a_get_archive_name_arch
        a_get_archive_parts
        a_is_archive_uptodate
        a_list_pkgarchives
        a_rm_pkgarchives
    )

    [[ -v _BF_EXPORT_ALL ]] || i_exit 1 ${LINENO} "$(_g "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'.")"
    if [[ ${_BF_EXPORT_ALL} == "yes" ]]; then
        export -f "${_func_names[@]}"
    elif [[ ${_BF_EXPORT_ALL} == "no" ]]; then
        export -nf "${_func_names[@]}"
    else
        i_exit 1 ${LINENO} "$(_g "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: '%s'.")" "${_BF_EXPORT_ALL}"
    fi
}
a_export


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
