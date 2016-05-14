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

t_general_opt



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
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       a_list_pkgarchives TARGETS "${CMK_PORTNAME}" "${CMK_PORT_PATH}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_list_pkgarchives() {
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
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       a_rm_pkgarchives "${PORTNAME}" "${PORT_PATH}" "${CMK_ARCH}" "${CMK_PKG_EXT}" "${PKGARCHIVE_BACKUP_DIR}"
#******************************************************************************************************************************
a_rm_pkgarchives() {
    local _fn="a_rm_pkgarchives"
    (( ${#} != 5 )) &&  m_exit "${_fn}" "$(_g "FUNCTION Requires EXACT '5' arguments. Got '%s'")" "${#}"
    local _name=${1}
    local _path=${2}
    local _sysarch=${3}
    local _ref_ext=${4}
    local _backup_dir=${5}
    local _f

    [[ -n ${_backup_dir} ]] || m_exit "${_fn}" "$(_g "FUNCTION Argument 5 (_backup_dir) MUST NOT be empty.")"

    if [[ ${_backup_dir} == "NONE" ]]; then
        m_more "$(_g "Removing any existing pkgarchive files for Port <%s>")" "${_path}"

        for _f in "${_path}/${_name}"*"${_sysarch}.${_ref_ext}"* "${_path}/${_name}"*"any.${_ref_ext}"*; do
            [[ ${_f} == *"*" ]] || rm -f "${_f}"
        done
    else
        m_more "$(_g "Moving any existing pkgarchive files for Port <%s>")" "${_path}"
        m_more_i "$(_g "Moving to pkgarchive_backup_dir: <%s>")" "${_backup_dir}"

        u_dir_is_rwx_exit "${_backup_dir}" "yes" "_in_backup_dir"

        for _f in "${_path}/${_name}"*"${_sysarch}.${_ref_ext}"* "${_path}/${_name}"*"any.${_ref_ext}"*; do
            [[ ${_f} == *"*" ]] || mv -f "${_f}" "${_backup_dir}"
        done
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
#       a_get_archive_name NAME "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_name() {
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
        m_exit "a_get_archive_name" "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" \
            "${_path}"
    fi

    _ret_name_n=${_name:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_n} ]] ||  m_exit "a_get_archive_name" "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" \
        "${_path}"
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
#       a_get_archive_buildvers BUILDVERS "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_buildvers() {
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
        m_exit "a_get_archive_buildvers" \
            "$(_g "A pkgarchive 'architecture' part must be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    _ret_buildvers_b=${_path:: -${#_ending}}
    _ret_buildvers_b=${_ret_buildvers_b: -10}
    if [[ ${_ret_buildvers_b} != +([[:digit:]]) ]]; then
        m_exit "a_get_archive_buildvers" \
            "$(_g "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s': <%s>")" \
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
#       a_get_archive_arch ARCH "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_arch() {
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
        m_exit "a_get_archive_arch" "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" \
            "${_path}"
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
#       a_get_archive_ext EXTENTION "${PKGARCHIVE}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_ext() {
    local -n _ret_ext_e=${1}
    local _path=${2}
    local _ref_ext=${3}

    if [[ ${_path} == *"${_ref_ext}.xz" ]]; then
        _ret_ext_e=".${_ref_ext}.xz"
    elif [[ ${_path} == *"${_ref_ext}" ]]; then
        _ret_ext_e=".${_ref_ext}"
    else
        m_exit "a_get_archive_ext" "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" \
            "${_ref_ext}" "${_path}"
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
#       a_get_archive_parts NAME BUILDVERS ARCH EXT "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_parts() {
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
        m_exit "a_get_archive_parts" \
            "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" "${_ref_ext}" "${_path}"
    fi

    # ARCH
    if [[ ${_name} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_parts="any"
    elif [[ ${_name} == *"${_sysarch}${_ret_ext_parts}" ]]; then
        _ret_arch_parts="${_sysarch}"
    else
        m_exit "a_get_archive_parts" "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" \
            "${_path}"
    fi

    ###
    _ending="${_ret_arch_parts}${_ret_ext_parts}"
    _ending_size=${#_ending}

    # BUILDVERS
    _ret_buildvers_parts=${_name:: -${_ending_size}}
    _ret_buildvers_parts=${_ret_buildvers_parts: -10}
    if [[ ${_ret_buildvers_parts} != +([[:digit:]]) ]]; then
        m_exit "a_get_archive_parts" \
            "$(_g "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s': <%s>")" \
            "${_ret_buildvers_parts//[[:digit:]]}" "${_path}"
    fi

    # NAME
    _ret_name_parts=${_name:: -((${_ending_size}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_parts} ]] || m_exit "a_get_archive_parts" "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" \
                                    "${_path}"
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
#       a_get_archive_name_arch NAME ARCH "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
a_get_archive_name_arch() {
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
        m_exit "a_get_archive_name_arch" \
            "$(_g "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz': <%s>")" "${_ref_ext}" "${_ref_ext}" "${_path}"
    fi

    # ARCH
    if [[ ${_name} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_na="any"
    elif [[ ${_name} == *"${_sysarch}${_ret_ext_parts}" ]]; then
        _ret_arch_na="${_sysarch}"
    else
        m_exit "a_get_archive_name_arch" \
            "$(_g "A pkgarchive 'architecture' part MUST be: '%s' or 'any': <%s>")" "${_sysarch}" "${_path}"
    fi

    ###
    _ending="${_ret_arch_na}${_ret_ext_parts}"

    # NAME
    _ret_name_na=${_name:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    [[ -n ${_ret_name_na} ]] || m_exit "a_get_archive_name_arch" "$(_g "A pkgarchive 'name' part MUST NOT be empty: <%s>")" \
                                    "${_path}"
}


#******************************************************************************************************************************
# Returns 'yes' if the pkgarchive is up-to-date otherwise 'no'
#
#   ARGUMENTS
#       `_retres`: a reference var: an empty string which will be updated with the result.
#       `_pkgfile`: absolute path to the ports pkgfile
#       `_archive`: the full path of a pkgarchive to check
#
#   USAGE
#       local PKGARCHIVE_IS_UP_TO_DATE=""
#       a_is_archive_uptodate PKGARCHIVE_IS_UP_TO_DATE "${PKGFILE_PATH}" "${PKGARCHIVE_PATH}"
#******************************************************************************************************************************
a_is_archive_uptodate() {
    local -n _retres=${1}
    local _pkgfile=${2}
    local _archive=${3}

    _retres="no"
    if [[ -f ${_archive} ]]; then
        _retres="yes"
        [[ -f ${_pkgfile} ]] || m_exit "a_is_archive_uptodate" "$(_g "Corresponding Pkgfile does not exist. Path: <%s>")" \
                                    "${_pkgfile}"
        [[ ${_pkgfile} -nt ${_archive} ]] && _retres="no"
    fi
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
