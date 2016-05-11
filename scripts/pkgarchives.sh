#******************************************************************************************************************************
#
#   <pkgarchives.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
shopt -s extglob dotglob
set +o noclobber



#=============================================================================================================================#
#
#                   GENERAL FUNCTIONS
#
#=============================================================================================================================#


#******************************************************************************************************************************
# Get a list of existing pkgarchives in the port directory. NOTE: This does not search for any pkgarchives in subdirectories.
#
#   ARGUMENTS
#       `_ret_extisting_pkgarchives`: a reference var: an empty index array which will be updated with the absolut path to any
#                                     port pkgarchives
#       `_in_port_name`: port name
#       `_in_port_path`: port absolute path
#       `_in_system_arch`: architecture e.g.: "$(uname -m)"
#       `_in_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       TARGETS=()
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pka_get_existing_pkgarchives TARGETS "${CMK_PORTNAME}" "${CMK_PORT_PATH}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_existing_pkgarchives() {
    local -n _ret_extisting_pkgarchives=${1}
    local _in_port_name=${2}
    local _in_port_path=${3}
    local _in_system_arch=${4}
    local _in_ref_ext=${5}
    local _file

    # NOTE: Check if no file is found: which returns still 2 results e.g. for acl
    #   /usr/ports/example_collection1/acl/acl*x86_64.cards.tar*
    # /usr/ports/example_collection1/acl/acl*any.cards.tar*
    #
    # to fix this: instead of using a `subshell` and `shopt -s nullglob`
    #   it is in the most common cases faster to check it ourself
    for _file in "${_in_port_path}/${_in_port_name}"*"${_in_system_arch}.${_in_ref_ext}"* \
        "${_in_port_path}/${_in_port_name}"*"any.${_in_ref_ext}"*; do
        [[ ${_file} == *"*" ]] || _ret_extisting_pkgarchives+=("${_file}")
    done
}


#******************************************************************************************************************************
# Remove existing pkgarchives. NOTE: This does not search for any pkgarchives in subdirectories to allow for backups.
#
#   ARGUMENTS
#       `_in_port_name`: port name
#       `_in_port_path`: port absolute path
#       `_in_system_arch`: architecture e.g.: "$(uname -m)"
#       `_in_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `_in_pkgarchive_backup_dir`: NONE or absolute path to a pkgarchive backup dir
#                                    if NONE: existing_pkgarchives will be deleted, else moved to the _in_pkgarchive_backup_dir
#
#   USAGE
#       PORTNAME="hwinfo"
#       PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pka_remove_existing_pkgarchives "${PORTNAME}" "${PORT_PATH}" "${CMK_ARCH}" "${CMK_PKG_EXT}" "${PKGARCHIVE_BACKUP_DIR}"
#******************************************************************************************************************************
pka_remove_existing_pkgarchives() {
    local _fn="pka_remove_existing_pkgarchives"
    (( ${#} != 5 )) &&  ms_abort "${_fn}" "$(gettext "FUNCTION Requires EXACT '5' arguments. Got '%s'")" "${#}"
    local _in_port_name=${1}
    local _in_port_path=${2}
    local _in_system_arch=${3}
    local _in_ref_ext=${4}
    local _in_pkgarchive_backup_dir=${5}
    local _find1="${_in_port_name}*${_in_system_arch}.${_in_ref_ext}*"
    local _find2="${_in_port_name}*any.${_in_ref_ext}*"

    if [[ ! -n ${_in_pkgarchive_backup_dir} ]]; then
        ms_abort "${_fn}" "$(gettext "FUNCTION Argument 5 (_in_pkgarchive_backup_dir) MUST NOT be empty.")"
    fi
    if [[ ${_in_pkgarchive_backup_dir} == "NONE" ]]; then
        ms_more "$(gettext "Removing any existing pkgarchive files for Port <%s>")" "${_in_port_path}"

        for _file in "${_in_port_path}/${_in_port_name}"*"${_in_system_arch}.${_in_ref_ext}"* \
            "${_in_port_path}/${_in_port_name}"*"any.${_in_ref_ext}"*; do
            [[ ${_file} == *"*" ]] || rm -f "${_file}"
        done
    else
        ms_more "$(gettext "Moving any existing pkgarchive files for Port <%s>")" "${_in_port_path}"
        ms_more_i "$(gettext "Moving to pkgarchive_backup_dir: <%s>")" "${_in_pkgarchive_backup_dir}"

        ut_dir_is_rwx_abort "${_in_pkgarchive_backup_dir}" "yes" "_in_pkgarchive_backup_dir"

        for _file in "${_in_port_path}/${_in_port_name}"*"${_in_system_arch}.${_in_ref_ext}"* \
            "${_in_port_path}/${_in_port_name}"*"any.${_in_ref_ext}"*; do
            [[ ${_file} == *"*" ]] || mv -f "${_file}" "${_in_pkgarchive_backup_dir}"
        done
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive name part.
#
#   ARGUMENTS
#       `_ret_name`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch`: the system architecture e.g. "$(uname -m)"
#       `_in_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME=""
#       pka_get_pkgarchive_name NAME "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_name() {
    local _fn="pka_get_pkgarchive_name"
    local -n _ret_name_n=${1}
    local _in_pkgarchive_path=${2}
    local _in_system_arch=${3}
    local _in_ref_ext=${4}
    local _pkgarchive_basename; ut_basename _pkgarchive_basename "${_in_pkgarchive_path}"
    local _ext; pka_get_pkgarchive_ext _ext "${_pkgarchive_basename}" "${_in_ref_ext}"
    local _ending

    if [[ ${_pkgarchive_basename} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_pkgarchive_basename} == *"${_in_system_arch}${_ext}" ]]; then
        _ret_arch="${_in_system_arch}"
        _ending="${_in_system_arch}${_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch}" "${_in_pkgarchive_path}"
    fi

    _ret_name_n=${_pkgarchive_basename:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    if [[ ! -n ${_ret_name_n} ]]; then
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <%s>")" \
            "${_in_pkgarchive_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive buildversion part.
#
#   ARGUMENTS
#       `_ret_buildvers_b`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch`: the system architecture e.g. "$(uname -m)"
#       `_in_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local BUILDVERS=""
#       pka_get_pkgarchive_buildvers BUILDVERS "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_buildvers() {
    local _fn="pka_get_pkgarchive_buildvers"
    local -n _ret_buildvers_b=${1}
    local _in_pkgarchive_path=${2}
    local _in_system_arch=${3}
    local _in_ref_ext=${4}
    local _ext; pka_get_pkgarchive_ext _ext "${_in_pkgarchive_path}" "${_in_ref_ext}"
    local _ending
    declare -i _ending_size

    if [[ ${_in_pkgarchive_path} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_in_pkgarchive_path} == *"${_in_system_arch}${_ext}" ]]; then
        _ret_arch="${_in_system_arch}"
        _ending="${_in_system_arch}${_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part must be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch}" "${_in_pkgarchive_path}"
    fi

    _ending_size=${#_ending}
    _ret_buildvers_b=${_in_pkgarchive_path:: -${_ending_size}}
    _ret_buildvers_b=${_ret_buildvers_b: -10}
    if [[ ${_ret_buildvers_b} != +([[:digit:]]) ]]; then
        ms_abort "${_fn}" \
            "$(gettext "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s'. Pkgarchive: <%s>")" \
            "${_ret_buildvers_b//[[:digit:]]}" "${_in_pkgarchive_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive architecture part.
#
#   ARGUMENTS
#       `_ret_arch_a`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch`: the system architecture e.g. "$(uname -m)"
#       `_in_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local ARCH=""
#       pka_get_pkgarchive_arch ARCH "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_arch() {
    local _fn="pka_get_pkgarchive_arch"
    local -n _ret_arch_a=${1}
    local _in_pkgarchive_path=${2}
    local _in_system_arch=${3}
    local _in_ref_ext=${4}
    local _ext; pka_get_pkgarchive_ext _ext "${_in_pkgarchive_path}" "${_in_ref_ext}"

    if [[ ${_in_pkgarchive_path} == *"any${_ext}" ]]; then
        _ret_arch_a="any"
    elif [[ ${_in_pkgarchive_path} == *"${_in_system_arch}${_ext}" ]]; then
        _ret_arch_a="${_in_system_arch}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch}" "${_in_pkgarchive_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive extension part.
#
#   ARGUMENTS
#       `_ret_ext_e`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local EXTENTION=""
#       pka_get_pkgarchive_ext EXTENTION "${PKGARCHIVE}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_ext() {
    local _fn="pka_get_pkgarchive_ext"
    local -n _ret_ext_e=${1}
    local _in_pkgarchive_path=${2}
    local _in_ref_ext=${3}

    if [[ ${_in_pkgarchive_path} == *"${_in_ref_ext}.xz" ]]; then
        _ret_ext_e=".${_in_ref_ext}.xz"
    elif [[ ${_in_pkgarchive_path} == *"${_in_ref_ext}" ]]; then
        _ret_ext_e=".${_in_ref_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz'. Pkgarchive: <%s>")" \
            "${_in_ref_ext}" "${_in_ref_ext}" "${_in_pkgarchive_path}"
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
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch`: the system architecture e.g. "$(uname -m)"
#       `_in_ref_ext`:the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME BUILDVERS ARCH EXT
#       pka_get_pkgarchive_parts NAME BUILDVERS ARCH EXT "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_parts() {
    local _fn="pka_get_pkgarchive_parts"
    local -n _ret_name_parts=${1}
    local -n _ret_buildvers_parts=${2}
    local -n _ret_arch_parts=${3}
    local -n _ret_ext_parts=${4}
    local _in_pkgarchive_path=${5}
    local _in_system_arch=${6}
    local _in_ref_ext=${7}
    local _pkgarchive_basename; ut_basename _pkgarchive_basename "${_in_pkgarchive_path}"
    local _ending
    declare -i _ending_size

    # EXT
    if [[ ${_pkgarchive_basename} == *"${_in_ref_ext}.xz" ]]; then
        _ret_ext_parts=".${_in_ref_ext}.xz"
    elif [[ ${_pkgarchive_basename} == *"${_in_ref_ext}" ]]; then
        _ret_ext_parts=".${_in_ref_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz'. Pkgarchive: <%s>")" \
            "${_in_ref_ext}" "${_in_ref_ext}" "${_in_pkgarchive_path}"
    fi

    # ARCH
    if [[ ${_pkgarchive_basename} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_parts="any"
    elif [[ ${_pkgarchive_basename} == *"${_in_system_arch}${_ret_ext_parts}" ]]; then
        _ret_arch_parts="${_in_system_arch}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch}" "${_in_pkgarchive_path}"
    fi

    ###
    _ending="${_ret_arch_parts}${_ret_ext_parts}"
    _ending_size=${#_ending}

    # BUILDVERS
    _ret_buildvers_parts=${_pkgarchive_basename:: -${_ending_size}}
    _ret_buildvers_parts=${_ret_buildvers_parts: -10}
    if [[ ${_ret_buildvers_parts} != +([[:digit:]]) ]]; then
        ms_abort "${_fn}" \
            "$(gettext "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s'. Pkgarchive: <%s>")" \
            "${_ret_buildvers_parts//[[:digit:]]}" "${_in_pkgarchive_path}"
    fi

    # NAME
    _ret_name_parts=${_pkgarchive_basename:: -((${_ending_size}+10))} # add 10 for UTC Build timestamp
    if [[ ! -n ${_ret_name_parts} ]]; then
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <%s>")" \
            "${_in_pkgarchive_path}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive name and architecture parts.
#
#   NOTE: for speed reason we do not use the other separate functions: this here takes approximately only 1/3 of the time.
#
#   ARGUMENTS
#       `_ret_name_na`: a reference var: an empty string which will be updated with the result.
#       `_ret_arch_na`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_path`: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch`: the system architecture e.g. "$(uname -m)"
#       `_in_ref_ext`: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME ARCH
#       pka_get_pkgarchive_name_arch NAME ARCH "${PKGARCHIVE}" "${CMK_ARCH}" "${CMK_PKG_EXT}"
#******************************************************************************************************************************
pka_get_pkgarchive_name_arch() {
    local _fn="pka_get_pkgarchive_name_arch"
    local -n _ret_name_na=${1}
    local -n _ret_arch_na=${2}
    local _in_pkgarchive_path=${3}
    local _in_system_arch=${4}
    local _in_ref_ext=${5}
    local _pkgarchive_basename; ut_basename _pkgarchive_basename "${_in_pkgarchive_path}"
    local _ending

    # EXT
    if [[ ${_pkgarchive_basename} == *"${_in_ref_ext}.xz" ]]; then
        _ret_ext_parts=".${_in_ref_ext}.xz"
    elif [[ ${_pkgarchive_basename} == *"${_in_ref_ext}" ]]; then
        _ret_ext_parts=".${_in_ref_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz'. Pkgarchive: <%s>")" \
            "${_in_ref_ext}" "${_in_ref_ext}" "${_in_pkgarchive_path}"
    fi

    # ARCH
    if [[ ${_pkgarchive_basename} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_na="any"
    elif [[ ${_pkgarchive_basename} == *"${_in_system_arch}${_ret_ext_parts}" ]]; then
        _ret_arch_na="${_in_system_arch}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch}" "${_in_pkgarchive_path}"
    fi

    ###
    _ending="${_ret_arch_na}${_ret_ext_parts}"

    # NAME
    _ret_name_na=${_pkgarchive_basename:: -((${#_ending}+10))} # add 10 for UTC Build timestamp
    if [[ ! -n ${_ret_name_na} ]]; then
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <%s>")" \
            "${_in_pkgarchive_path}"
    fi
}


#******************************************************************************************************************************
# Returns 'yes' if the pkgarchive is up-to-date otherwise 'no'
#
#   ARGUMENTS
#       `_ret_result`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgfile_path`: absolute path to the ports pkgfile
#       `_in_pkgarchive_path`: the full path of a pkgarchive to check
#
#   USAGE
#       local PKGARCHIVE_IS_UP_TO_DATE=""
#       pka_is_pkgarchive_up_to_date PKGARCHIVE_IS_UP_TO_DATE "${PKGFILE_PATH}" "${PKGARCHIVE_PATH}"
#******************************************************************************************************************************
pka_is_pkgarchive_up_to_date() {
    local _fn="pka_is_pkgarchive_up_to_date"
    local -n _ret_result=${1}
    local _in_pkgfile_path=${2}
    local _in_pkgarchive_path=${3}

    _ret_result="no"
	if [[ -f ${_in_pkgarchive_path} ]]; then
		_ret_result="yes"
        if [[ ! -f ${_in_pkgfile_path} ]]; then
            ms_abort "${_fn}" "$(gettext "Corresponding Pkgfile does not exist. Path: <%s>")" "${_in_pkgfile_path}"
        fi
		[[ ${_in_pkgfile_path} -nt ${_in_pkgarchive_path} ]] && _ret_result="no"
	fi
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
