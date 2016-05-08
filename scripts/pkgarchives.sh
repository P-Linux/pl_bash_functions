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
shopt -s extglob
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
#       `_in_port_name_ge`: a reference var: port name
#       `_in_port_path_ge`: a reference var: port absolute path
#       `_in_system_arch_ge`: a reference var: architecture e.g.: "$(uname -m)"
#       `_ref_ext_ge`: a reference var: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       TARGETS=()
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pka_get_existing_pkgarchives TARGETS CMK_PORTNAME CMK_PORT_PATH CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_existing_pkgarchives() {
    local -n _ret_extisting_pkgarchives=${1}
    local -n _in_port_name_ge=${2}
    local -n _in_port_path_ge=${3}
    local -n _in_system_arch_ge=${4}
    local -n _ref_ext_ge=${5}
    _ret_extisting_pkgarchives=("${_in_port_path_ge}/${_in_port_name_ge}"*"${_in_system_arch_ge}.${_ref_ext_ge}"* \
        "${_in_port_path_ge}/${_in_port_name_ge}"*"any.${_ref_ext_ge}"*)
}


#******************************************************************************************************************************
# Remove existing pkgarchives.
#
#   ARGUMENTS
#       `_in_port_name_re`: a reference var: port name
#       `_in_port_path_re`: a reference var: port absolute path
#       `_in_system_arch_re`: a reference var: architecture e.g.: "$(uname -m)"
#       `_ref_ext_re`: a reference var: The extention name of a package tar archive file withouth any compression specified.
#
#   USAGE
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pka_remove_existing_pkgarchives CMK_PORTNAME CMK_PORT_PATH CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_remove_existing_pkgarchives() {
    local -n _in_port_name_re=${1}
    local -n _in_port_path_re=${2}
    local -n _in_system_arch_re=${3}
    local -n _ref_ext_re=${4}
    local _find1="${_in_port_name_re}*${_in_system_arch_re}.${_ref_ext_re}*"
    local _find2="${_in_port_name_re}*any.${_ref_ext_re}*"

    ms_more "$(gettext "Removing any existing pkgarchive files for Port <%s>")" "${_in_port_path_re}"
    find "${_in_port_path_re}" \( -name "${_find1}" -or -name "${_find2}" \) -delete
}


#******************************************************************************************************************************
# Returns the pkgarchive name part.
#
#   ARGUMENTS
#       `_ret_name`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_n`: a reference var: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch_n`: a reference var: the system architecture e.g. "$(uname -m)"
#       `_ref_ext_n`: a reference var: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME=""
#       pka_get_pkgarchive_name NAME PKGARCHIVE CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_pkgarchive_name() {
    local _fn="pka_get_pkgarchive_name"
    local -n _ret_name_n=${1}
    local -n _in_pkgarchive_n=${2}
    local -n _in_system_arch_n=${3}
    local -n _ref_ext_n=${4}
    local _pkgarchive_basename; ut_basename _pkgarchive_basename "${_in_pkgarchive_n}"
    local _ext; pka_get_pkgarchive_ext _ext _pkgarchive_basename _ref_ext_n
    local _ending
    declare -i _rest_size

    if [[ ${_pkgarchive_basename} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_pkgarchive_basename} == *"${_in_system_arch_n}${_ext}" ]]; then
        _ret_arch="${_in_system_arch_n}"
        _ending="${_in_system_arch_n}${_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch_n}" "${_in_pkgarchive_n}"
    fi

    _rest_size=${#_ending}
    ((_rest_size+=10)) # add 10 for UTC Build timestamp

    _ret_name_n=${_pkgarchive_basename:: -${_rest_size}}
    if [[ ! -n ${_ret_name_n} ]]; then
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <%s>")" "${_in_pkgarchive_n}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive buildversion part.
#
#   ARGUMENTS
#       `_ret_buildvers_a`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_b`: a reference var: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch_b`: a reference var: the system architecture e.g. "$(uname -m)"
#       `_ref_ext_b`: a reference var: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local BUILDVERS=""
#       pka_get_pkgarchive_buildvers BUILDVERS PKGARCHIVE CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_pkgarchive_buildvers() {
    local _fn="pka_get_pkgarchive_buildvers"
    local -n _ret_buildvers_a=${1}
    local -n _in_pkgarchive_b=${2}
    local -n _in_system_arch_b=${3}
    local -n _ref_ext_b=${4}
    local _ext; pka_get_pkgarchive_ext _ext _in_pkgarchive_b _ref_ext_b
    local _ending
    declare -i _ending_size

    if [[ ${_in_pkgarchive_b} == *"any${_ext}" ]]; then
        _ending="any${_ext}"
    elif [[ ${_in_pkgarchive_b} == *"${_in_system_arch_b}${_ext}" ]]; then
        _ret_arch="${_in_system_arch_b}"
        _ending="${_in_system_arch_b}${_ext}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part must be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch_b}" "${_in_pkgarchive_b}"
    fi

    _ending_size=${#_ending}
    _ret_buildvers_a=${_in_pkgarchive_b:: -${_ending_size}}
    _ret_buildvers_a=${_ret_buildvers_a: -10}
    if [[ ${_ret_buildvers_a} != +([[:digit:]]) ]]; then
        ms_abort "${_fn}" \
            "$(gettext "A pkgarchive 'buildvers' MUST NOT be empty and only contain digits and not: '%s'. Pkgarchive: <%s>")" \
            "${_ret_buildvers_a//[[:digit:]]}" "${_in_pkgarchive_b}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive architecture part.
#
#   ARGUMENTS
#       `_ret_arch_a`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_a`: a reference var: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch_a`: a reference var: the system architecture e.g. "$(uname -m)"
#       `_ref_ext_a`: a reference var: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local ARCH=""
#       pka_get_pkgarchive_arch ARCH PKGARCHIVE CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_pkgarchive_arch() {
    local _fn="pka_get_pkgarchive_arch"
    local -n _ret_arch_a=${1}
    local -n _in_pkgarchive_a=${2}
    local -n _in_system_arch_a=${3}
    local -n _ref_ext_a=${4}
    local _ext; pka_get_pkgarchive_ext _ext _in_pkgarchive_a _ref_ext_a

    if [[ ${_in_pkgarchive_a} == *"any${_ext}" ]]; then
        _ret_arch_a="any"
    elif [[ ${_in_pkgarchive_a} == *"${_in_system_arch_a}${_ext}" ]]; then
        _ret_arch_a="${_in_system_arch_a}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch_a}" "${_in_pkgarchive_a}"
    fi
}


#******************************************************************************************************************************
# Returns the pkgarchive extension part.
#
#   ARGUMENTS
#       `_ret_ext_e`: a reference var: an empty string which will be updated with the result.
#       `_in_pkgarchive_e`: a reference var: the full path of a pkgarchive or just the pkgarchive file name
#       `_ref_ext_e`: a reference var: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local EXTENTION=""
#       pka_get_pkgarchive_ext EXTENTION PKGARCHIVE CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_pkgarchive_ext() {
    local _fn="pka_get_pkgarchive_ext"
    local -n _ret_ext_e=${1}
    local -n _in_pkgarchive_e=${2}
    local -n _ref_ext_e=${3}

    if [[ ${_in_pkgarchive_e} == *"${_ref_ext_e}.xz" ]]; then
        _ret_ext_e=".${_ref_ext_e}.xz"
    elif [[ ${_in_pkgarchive_e} == *"${_ref_ext_e}" ]]; then
        _ret_ext_e=".${_ref_ext_e}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz'. Pkgarchive: <%s>")" \
            "${_ref_ext_e}" "${_ref_ext_e}" "${_in_pkgarchive_e}"
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
#       `_in_pkgarchive_parts`: a reference var: the full path of a pkgarchive or just the pkgarchive file name
#       `_in_system_arch_parts`: a reference var: the system architecture e.g. "$(uname -m)"
#       `_ref_ext`: a reference var: the Reference pkgarchive extension withouth compression
#
#   USAGE
#       local NAME BUILDVERS ARCH EXT
#       pka_get_pkgarchive_parts NAME BUILDVERS ARCH EXT PKGARCHIVE CMK_ARCH CMK_PKG_EXT
#******************************************************************************************************************************
pka_get_pkgarchive_parts() {
    local _fn="pka_get_pkgarchive_parts"
    local -n _ret_name_parts=${1}
    local -n _ret_buildvers_parts=${2}
    local -n _ret_arch_parts=${3}
    local -n _ret_ext_parts=${4}
    local -n _in_pkgarchive_parts=${5}
    local -n _in_system_arch_parts=${6}
    local -n _in_ref_ext_parts=${7}
    local _pkgarchive_basename; ut_basename _pkgarchive_basename "${_in_pkgarchive_parts}"
    local _ending
    declare -i _ending_size
    declare -i _rest_size

    # EXT
    if [[ ${_pkgarchive_basename} == *"${_in_ref_ext_parts}.xz" ]]; then
        _ret_ext_parts=".${_in_ref_ext_parts}.xz"
    elif [[ ${_pkgarchive_basename} == *"${_in_ref_ext_parts}" ]]; then
        _ret_ext_parts=".${_in_ref_ext_parts}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'extension' part MUST end with: '%s' or '%s.xz'. Pkgarchive: <%s>")" \
            "${_in_ref_ext_parts}" "${_in_ref_ext_parts}" "${_in_pkgarchive_parts}"
    fi

    # ARCH
    if [[ ${_pkgarchive_basename} == *"any${_ret_ext_parts}" ]]; then
        _ret_arch_parts="any"
    elif [[ ${_pkgarchive_basename} == *"${_in_system_arch_parts}${_ret_ext_parts}" ]]; then
        _ret_arch_parts="${_in_system_arch_parts}"
    else
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'architecture' part MUST be: '%s' or 'any'. Pkgarchive: <%s>")" \
            "${_in_system_arch_parts}" "${_in_pkgarchive_parts}"
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
            "${_ret_buildvers_parts//[[:digit:]]}" "${_in_pkgarchive_parts}"
    fi

    # NAME
    _rest_size=${_ending_size}+10  # add 10 for UTC Build timestamp
    _ret_name_parts=${_pkgarchive_basename:: -${_rest_size}}
    if [[ ! -n ${_ret_name_parts} ]]; then
        ms_abort "${_fn}" "$(gettext "A pkgarchive 'name' part MUST NOT be empty. Pkgarchive: <%s>")" "${_in_pkgarchive_parts}"
    fi
}

#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************