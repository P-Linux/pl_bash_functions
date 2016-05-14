#******************************************************************************************************************************
#
#   <pkgfile.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
#                   PKGFILE GENERAL FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Unset official Pkgfile variables
#******************************************************************************************************************************
pk_unset_official_pkgfile_var() {
    unset -v pkgpackager pkgdesc pkgurl pkgdeps pkgdepsrun pkgvers pkgrel pkgsources pkgmd5sums
}


#******************************************************************************************************************************
# Prepares a lookup MATRIX for all REGISTERED_COLLECTIONS where the keys are the individual port names
#   and the values the first found port path
#
#   VALIDATES:
#       - Collection Path: absolute path to an existing dir or link with rwx access
#       - PORT: contains a Portfile (_ref_pkgfile_name) with rw access
#       - PORTNAME: validates length and chareracters
#
#   ARGUMENTS
#       `_ret_col_ports_lookup`: a reference var: an empty associative array which will be updated with the ports names
#       `_ref_pkgfile_name`: A reference Pkgfile name which must exist in a valid port folder
#       `_in_reg_collections_l` a reference var
#               A `REGISTERED_COLLECTIONS` array item must specify the full path to a collection of ports directories. e.g
#               CMK_REGISTERED_COLLECTIONS=(
#                   "/home/overlayer-collection"
#                   "/usr/ports/lxde-extra"
#                   "/usr/ports/lxde"
#                   "/usr/ports/gui-extra"
#                   "/usr/ports/gui"
#                   "/usr/ports/cli-extra"
#                   "/usr/ports/cli"
#                   "/usr/ports/base-extra"
#                   "/usr/ports/base"
#               )
#   USAGE:
#       declare -A COLLECTION_LOOKUP=()
#       pk_get_collections_lookup COLLECTION_LOOKUP "${CMK_PKGFILE_NAME}" CMK_REGISTERED_COLLECTIONS
#
#   EXAMPLE
#       CMK_REGISTERED_COLLECTIONS=(
#           "/usr/ports/personal"
#           "/usr/ports/kde5-extra"
#           "/usr/ports/kde5"
#           "/usr/ports/gnome"
#           "/usr/ports/gnome-extra"
#           "/usr/ports/gui"
#           "/usr/ports/gui-extra"
#           "/usr/ports/cli-extra"
#           "/usr/ports/cli"
#           "/usr/ports/base-extra"
#           "/usr/ports/base"
#       )
#       declare -A COLLECTION_LOOKUP=()
#       pk_get_collections_lookup COLLECTION_LOOKUP "Pkgfile" CMK_REGISTERED_COLLECTIONS
#       echo "<${#COLLECTION_LOOKUP[@]}>"
#******************************************************************************************************************************
pk_get_collections_lookup() {
    local _fn="pk_get_collections_lookup"
    local -n _ret_col_ports_lookup=${1}
    local _ref_pkgfile_name=${2}
    local -n _in_reg_collections_l=${3}
    local _col_ent _col_path _col_portpath _col_portname _col_pkgfile
    declare -i _col_portname_size

    if [[ ${_ref_pkgfile_name} == *"/" ]]; then
        m_exit "${_fn}" "$(_g "Reference Pkgfile-Name '_ref_pkgfile_name': MUST NOT end with a slash: <%s>")" \
            "${_ref_pkgfile_name}"
    fi

    u_ref_associative_array_exit "_ret_col_ports_lookup" "${_fn}"

    # always reset the _ret_col_ports_lookup
    _ret_col_ports_lookup=()
    for _col_ent in "${_in_reg_collections_l[@]}"; do
        if [[ ${_col_ent} != "/"* ]]; then
            m_exit "${_fn}" "$(_g "COLLECTION_ENTRY: An absolute directory path MUST start with a slash: <%s>")" "${_col_ent}"
        fi
        if [[ -L ${_col_ent} ]];then
            _col_path=$(readlink -f "${_col_ent}")
        else
            _col_path=${_col_ent}
        fi

        if [[ ! -d ${_col_path} ]]; then
            m_exit "${_fn}" "$(_g "COLLECTION directory does not exist: <%s>: <%s>")" "${_col_path}" "${_col_ent}"
        elif [[ ! -r ${_col_path} ]]; then
            m_exit "${_fn}" "$(_g "COLLECTION directory is not readable: <%s>: <%s>")" "${_col_path}" "${_col_ent}"
        elif [[ ! -w ${_col_path} ]]; then
            m_exit "${_fn}" "$(_g "COLLECTION directory is not writable:: <%s>: <%s>")" "${_col_path}" "${_col_ent}"
        elif [[ ! -x ${_col_path} ]]; then
            m_exit "${_fn}" "$(_g "COLLECTION directory is not executable: <%s>: <%s>")" "${_col_path}" "${_col_ent}"
        fi
        # only get one level down
        for _col_portpath in "${_col_path}"/*; do
            if [[ -d ${_col_portpath} ]]; then
                # Just add the first found path
                _col_pkgfile="${_col_portpath}/${_ref_pkgfile_name}"
                # Only dirs with Pkgfiles are considered
                if [[ -f ${_col_pkgfile} ]]; then
                    if [[ ! -r ${_col_path} ]]; then
                        m_exit "${_fn}" "$(_g "COLLECTION Pkgfile is not readable: <%s>: <%s>")" \
                            "${_col_pkgfile}" "${_col_ent}"
                    elif [[ ! -w ${_col_path} ]]; then
                        m_exit "${_fn}" "$(_g "COLLECTION Pkgfile is not writable:: <%s>: <%s>")" \
                            "${_col_pkgfile}" "${_col_ent}"
                    fi

                    u_postfix_shortest_all _col_portname "${_col_portpath}" "/"
                    if [[ ! -v _ret_col_ports_lookup[${_col_portname}] ]]; then
                        _col_portname_size=${#_col_portname}
                        # Validate: _portname
                        if (( _col_portname_size < 2 || _col_portname_size > 50 )); then
                            m_exit "${_fn}" \
                                "$(_g "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '%s' <%s>")" \
                                "${_col_portname_size}" "${_col_portpath}"
                        fi
                        if [[ ${_col_portname} == *[![:alnum:]-_+]* ]]; then
                            m_exit "${_fn}" "$(_g "PORTNAME contains invalid chars: '%s' PATH: <%s>")" \
                                "${_col_portname//[[:alnum:]-_+]}" "${_col_portpath}"
                        fi
                        if [[ ${_col_portname} == [![:alnum:]]* ]]; then
                            m_exit "${_fn}" "$(_g "PORTNAME MUST start with an alphanumeric char. Got: '%s' <%s>")" \
                                "${_col_portname:0:1}" "${_col_portpath}"
                        fi
                        _ret_col_ports_lookup["${_col_portname}"]=${_col_pkgfile}
                    fi
                fi
            fi
        done
    done
}


#******************************************************************************************************************************
# Prepares a final PKGFILES_TO_PROCESS array from a `PORTSLIST` and a registered `REGISTERED_COLLECTIONS`.
#
#   ARGUMENTS
#       `_ret_pkgfiles_to_process`: a reference var: an empty index array which will be updated with absolute Pkgfile path.
#       `_ref_pkgfile_name`: A reference name for a pkgfile - used to search for valid ports
#       `_in_portslist`: a reference var: a array of registered collection port names or absolute path to ports: e.g.
#               CMK_PORTSLIST=(
#                   bzip2
#                   coreutils
#                   /usr/ports/personal/wget
#               )
#       `_in_reg_collections`: a reference var:
#               A `REGISTERED_COLLECTIONS` array item must specify the full path to a collection of ports directories. e.g
#               CMK_REGISTERED_COLLECTIONS=(
#                   "/home/overlayer-collection"
#                   "/usr/ports/lxde-extra"
#                   "/usr/ports/lxde"
#                   "/usr/ports/gui-extra"
#                   "/usr/ports/gui"
#                   "/usr/ports/cli-extra"
#                   "/usr/ports/cli"
#                   "/usr/ports/base-extra"
#                   "/usr/ports/base"
#               )
#   USAGE:
#       CMK_PKGFILES_TO_PROCESS=()
#       pk_get_pkgfiles_to_process PKGFILES_TO_PROCESS "${CMK_PKGFILE_NAME}" CMK_PORTSLIST CMK_REGISTERED_COLLECTIONS
#******************************************************************************************************************************
pk_get_pkgfiles_to_process() {
    local _fn="pk_get_pkgfiles_to_process"
    local -n _ret_pkgfiles_to_process=${1}
    local _ref_pkgfile_name=${2}
    local -n _in_portslist=${3}
    local -n _in_reg_collections=${4}
    declare -A _col_lookup=()
    local _port _pkgfile_portpath _reg_collection

    # always reset the _ret_pkgfiles_to_process
    _ret_pkgfiles_to_process=()

    # Check if we have only one absolute path: most often:
    #           then there is no need to prepare the collections_lookup which takes time
    if (( ${#_in_portslist[@]} == 1 )) && [[ ${_in_portslist[0]} == "/"* ]] ; then
        _pkgfile_portpath="${_in_portslist[0]}/${_ref_pkgfile_name}"
        pk_check_pkgfile_port_path_name "${_pkgfile_portpath}" "${_ref_pkgfile_name}"
        _ret_pkgfiles_to_process+=("${_pkgfile_portpath}")
    else
        pk_get_collections_lookup _col_lookup "${_ref_pkgfile_name}" _in_reg_collections

        for _port in "${_in_portslist[@]}"; do
            if [[ ${_port} == "/"* ]]; then
                _pkgfile_portpath="${_port}/${_ref_pkgfile_name}"
                pk_check_pkgfile_port_path_name "${_pkgfile_portpath}" "${_ref_pkgfile_name}"
                _ret_pkgfiles_to_process+=("${_pkgfile_portpath}")
            elif [[ -v _col_lookup[${_port}] ]]; then
                _ret_pkgfiles_to_process+=("${_col_lookup[${_port}]}")
            else
                # NOT FOUND
                m_more "$(_g "======== All Registered Collections ========")"
                for _reg_collection in "${_in_reg_collections[@]}"; do
                    m_more_i "$(_g "* Collection Path: <%s>")" "${_reg_collection}"
                done
                 m_exit "${_fn}" "$(_g "Portslist entry: <%s> not found in the registered collections.")" "${_port}"
            fi
        done
    fi
}


#******************************************************************************************************************************
# Validates a Pkgfile / Port Version: Checks only the version syntax
#
#   ARGUMENTS
#       `_pkgvers`: _pkgvers string
#       `_pkgfile`: absolute path to the pkgfile
#
#   USAGE:
#       pk_check_pkgvers "1.3.5" "${CMK_PKGFILE_PATH}"
#******************************************************************************************************************************
pk_check_pkgvers() {
    local _pkgvers=${1}
    local _pkgfile=${2}

    if [[ -n ${_pkgvers} ]]; then
        if [[ ${_pkgvers} == *[![:alnum:].]* ]]; then
            m_exit "pk_check_pkgvers" "$(_g "'pkgvers' contains invalid chars: '%s' File: <%s>")" \
                "${_pkgvers//[[:alnum:].]}" "${_pkgfile}"
        fi
    else
        m_exit "pk_check_pkgvers" "$(_g "Variable 'pkgvers' MUST NOT be empty: <%s>")" "${_pkgfile}"
    fi
}


#******************************************************************************************************************************
# Return Pkgfile / Port Version: Checks only the version syntax
#
#   ARGUMENTS
#       `$1 (_pkgfile)`: absolute path to the pkgfile
#
#   USAGE:
#       pk_get_only_pkgvers_exit "${CMK_PKGFILE_PATH}"
#
#   NOTE: Keept this as an subshell
#******************************************************************************************************************************
pk_get_only_pkgvers_exit() {
    (
        [[ -n $1 ]] || m_exit "pk_get_only_pkgvers_exit" "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
        # skip assignment: _pkgfile=${1}

        # unset all official related variable
        pk_unset_official_pkgfile_var

        u_source_safe_exit "${1}"

        pk_check_pkgvers "${pkgvers}" "${1}"
        printf "%s\n" "${pkgvers}"
    )
}


#******************************************************************************************************************************
# Generate for all `pkgsources` entires corresponding `pkgmd5sums` entries. It is expected that all sources exist already.
#   for protocols: ftp|http|https|local md5sums are generated for all others a SKIP entry.
#
#   ARGUMENTS
#       `_ret_pkgmd5sums`: reference var: will be updated with the final corresponding entries
#       `_in_pkgp_scrmtx`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#
#   USAGE
#       local NEW_PKGMD5SUMS=()
#       pk_make_pkgmd5sums NEW_PKGMD5SUMS SCRMTX
#******************************************************************************************************************************
pk_make_pkgmd5sums() {
    local -n _ret_pkgmd5sums=${1}
    local -n _in_pkgp_scrmtx=${2}
    declare -i _n
    local _md5sum _ent _destpath

    if [[ ! -v _in_pkgp_scrmtx[NUM_IDX] ]]; then
        m_exit "pk_make_pkgmd5sums" \
            "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_pkgp_scrmtx[NUM_IDX]}; _n++ )); do
        _ent=${_in_pkgp_scrmtx[${_n}:ENTRY]}
        _destpath=${_in_pkgp_scrmtx[${_n}:DESTPATH]}
        case "${_in_pkgp_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https|local)
                if [[ -f ${_destpath} && -r ${_destpath} ]]; then
                    _md5sum=$(md5sum "${_destpath}")
                    _md5sum=${_md5sum:0:32}
                    [[ -n ${_md5sum} ]] || m_exit "pk_make_pkgmd5sums" \
                                            "$(_g "Could not generate a md5sum for _destpath: <%s> Entry: <%s>")"  \
                                            "${_destpath}" "${_ent}"
                else
                    m_exit "pk_make_pkgmd5sums" "$(_g "Not a readable file path: <%s> Entry: <%s>")" "${_destpath}" "${_ent}"
                fi
                _ret_pkgmd5sums+=("${_md5sum}")
                ;;
            *) _ret_pkgmd5sums+=("SKIP")
                ;;
        esac
    done
}


#=============================================================================================================================#
#
#                   PKGFILE SOURCING & VALIDATION
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Validates a Pkgfile path, port directory and port directory name:
#   Pkgfile path ACESS RIGHTS: exists, read & write access, basename same as a reference name, is an absolute path
#
# Pkgfile-Header:
#
#       | Required | Variable Name | Description                                                         | Type   |
#       |:--------:|:--------------|:--------------------------------------------------------------------|:------:|
#       | YES      | `pkgpackager` | Name, pseudonym, e-mail address or web-link                         | STRING |
#       | YES      | `pkgdesc`     | A short description of the package                                  | STRING |
#       | YES      | `pkgurl`      | An URL that is associated with the software package or empty.       | STRING |
#       | YES      | `pkgdeps`     | A list of dependencies needed to build or run the package or empty. | ARRAY  |
#       | NO       | `pkgdepsrun`  | A list of runtime dependencies, empty or omitted.                   | ARRAY  |
#
# Pkgfile-Variables
#
#       | Required | Variable Name | Description                                                             | Type   |
#       |:--------:|:--------------|:------------------------------------------------------------------------|:------:|
#       | YES      | `pkgvers`     | The version of the package (typically the same as the upstream version. | STRING |
#       | YES      | `pkgrel`      | This is typically re-set to 1 for each new upstream release.            | STRING |
#       | YES      | `pkgsources`  | A list of source files required to build the package.                   | ARRAY  |
#       | YES      | `pkgmd5sum`   | A list of corresponding md5checksums (for file sources).                | ARRAY  |
#
#   ARGUMENTS
#       `_pkgfile`: absolute path to the pkgfile: must exist
#       `_ref_pkgfile_name`: A reference name against the _pkgfile basename is checked
#
#   USAGE:
#       pk_check_pkgfile_port_path_name "${CMK_PKGFILE_PATH}" "${CMK_PKGFILE_NAME}"
#******************************************************************************************************************************
pk_check_pkgfile_port_path_name() {
    local _fn="pk_check_pkgfile_port_path_name"
    [[ -n $1 ]] || m_exit "${_fn}" "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    [[ -n $2 ]] || m_exit "${_fn}" "$(_g "FUNCTION Argument 2 MUST NOT be empty.")"
    local _pkgfile=${1}
    local _ref_pkgfile_name=${2}
    local _portpath; u_dirname _portpath "${_pkgfile}"
    local _portname; u_basename _portname "${_portpath}"
    local _pkgfile_name; u_basename _pkgfile_name "${_pkgfile}"
    declare -i _portname_size=${#_portname}

    # Validate: _portpath
    u_dir_is_rwx_exit "${_portpath}" "yes" "PORT_PATH"
    # Validate: _portname
    if (( ${_portname_size} < 2 || ${_portname_size} > 50 )); then
        m_exit "${_fn}" "$(_g "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '%s' PATH: <%s>")" \
            "${_portname_size}" "${_pkgfile}"
    fi
    [[ ${_portname} == *[![:alnum:]-_+]* ]] && m_exit "${_fn}" \
                                                "$(_g "PORTNAME contains invalid chars: '%s' PATH: <%s>")" \
                                                "${_portname//[[:alnum:]-_+]}" "${_pkgfile}"
    if [[ ${_portname} == [![:alnum:]]* ]]; then
        m_exit "${_fn}" "$(_g "PORTNAME MUST start with an alphanumeric character. Got: '%s' PATH: <%s>")" \
            "${_portname:0:1}" "${_pkgfile}"
    fi

    # Validate: _pkgfile no need to check again for absolute path this is done with the port check above.
    u_file_is_rw_exit "${_pkgfile}" "yes" "PKGFILE_PATH"
    [[ -f ${_pkgfile} ]] || m_exit "${_fn}" "$(_g "PKGFILE_PATH does not exist: <%s>")" "${_pkgfile}"
    [[ -r ${_pkgfile} ]] || m_exit "${_fn}" "$(_g "PKGFILE_PATH is not readable: <%s>")" "${_pkgfile}"

    if [[ ${_pkgfile_name} != ${_ref_pkgfile_name} ]]; then
        m_exit "${_fn}" "$(_g "PKGFILE-Basename: '%s' is not the same as the defined Reference-Pkgfile-Name: '%s'")" \
                "${_pkgfile_name}" "${_ref_pkgfile_name}"
    fi
}


#******************************************************************************************************************************
# Sources a Pkgfile: Aborts if a basic validate does not pass
#                          IMPORTANT: the pkgsources is more thoroughly validated in the function: s_get_src_matrix().
#
# Pkgfile-Header:
#
#       | Required | Variable Name | Description                                                         | Type   |
#       |:--------:|:--------------|:--------------------------------------------------------------------|:------:|
#       | YES      | `pkgpackager` | Name, pseudonym, e-mail address or web-link                         | STRING |
#       | YES      | `pkgdesc`     | A short description of the package                                  | STRING |
#       | YES      | `pkgurl`      | An URL that is associated with the software package or empty.       | STRING |
#       | YES      | `pkgdeps`     | A list of dependencies needed to build or run the package or empty. | ARRAY  |
#       | NO       | `pkgdepsrun`  | A list of runtime dependencies, empty or omitted.                   | ARRAY  |
#
# Pkgfile-Variables
#
#       | Required | Variable Name | Description                                                             | Type   |
#       |:--------:|:--------------|:------------------------------------------------------------------------|:------:|
#       | YES      | `pkgvers`     | The version of the package (typically the same as the upstream version. | STRING |
#       | YES      | `pkgrel`      | This is typically re-set to 1 for each new upstream release.            | STRING |
#       | YES      | `pkgsources`  | A list of source files required to build the package.                   | ARRAY  |
#       | YES      | `pkgmd5sum`   | A list of corresponding md5checksums (for file sources).                | ARRAY  |
#
#   ARGUMENTS
#       `_pkgfile`: absolute path to the pkgfile: for test purpose it is not required that the path exists
#       `_in_cmk_required_function_names`: a reference var: An index array with the required `Pkgfile` function names
#       `_in__cmk_groups_default_function_names`: a reference var: An associative array with the default `CMK_GROUP` function
#           names as keys.
#           e.g. declare -A _cmk_groups_default_function_names=(["lib"]=0 ["devel"]=0 ["doc"]=0 ["man"]=0 ["service"]=0)
#
#   OPTIONAL ARGS:
#       `_in_cmk_groups`: a reference var: index array typically set in `cmk.conf` and sometimes in a Pkgfile:
#                         will be validated
#
#   USAGE:
#       pk_source_validate_pkgfile "${PKGFILE_PATH}" REQUIRED_FUNCTION_NAMES GROUPS_DEFAULT_FUNCTION_NAMES CMK_GROUPS
#******************************************************************************************************************************
pk_source_validate_pkgfile() {
    local _fn="pk_source_validate_pkgfile"
    [[ -n $1 ]] || m_exit "${_fn}" "$(_g "FUNCTION Argument 1 MUST NOT be empty.")"
    local _pkgfile=${1}
    local -n _in_cmk_required_function_names=${2}
    local -n _in__cmk_groups_default_function_names=${3}
    if [[ -n $4 ]]; then
        local -n _in_cmk_groups=${4}
    else
        local _in_cmk_groups=()
    fi

    declare -i _pkgdesc_size
    local _func

    # unset all official related variable
    pk_unset_official_pkgfile_var
    u_unset_functions _in_cmk_required_function_names
    u_unset_functions2 _in__cmk_groups_default_function_names  # NEED u_unset_functions2 for associative array

    u_source_safe_exit "${_pkgfile}"

    ##### Pkgfile-Header
    # pkgpackager
    [[ -n ${pkgpackager} ]] || m_exit "${_fn}" "$(_g "Variable 'pkgpackager' MUST NOT be empty: <%s>")" "${_pkgfile}"
    # pkgdesc
    _pkgdesc_size=${#pkgdesc}
    if (( ${_pkgdesc_size} < 10 || ${_pkgdesc_size} > 110 )); then
        m_exit "${_fn}" \
            "$(_g "'pkgdesc' MUST have at least 10 and a maximum of 110 chars. Got: '%s' File: <%s>")" "${_pkgdesc_size}" \
            "${_pkgfile}"
    fi

    # pkgurl: can also be empty
    u_is_str_var_abort "pkgurl" "${_fn}" "${_pkgfile}"

    # pkgdeps
    u_is_idx_array_exit "pkgdeps" "${_fn}" "${_pkgfile}"

    # pkgdepsrun: Optional
    u_is_idx_array_var "pkgdepsrun" || pkgdepsrun=()

    #### Pkgfile-Variables
    #pkgvers
    pk_check_pkgvers "${pkgvers}" "${_pkgfile}"

    # pkgrel
    if [[ ${pkgrel} != +([[:digit:]]) ]]; then
        m_exit "${_fn}" "$(_g "'pkgrel' MUST NOT be empty and only contain digits and not: '%s' File: <%s>")" \
            "${pkgrel//[[:digit:]]}" "${_pkgfile}"
    fi
    if (( ${pkgrel} < 1 || ${pkgrel} > 99999999 )); then
        m_exit "${_fn}" "$(_g "'pkgrel' MUST be greater than 0 and less than 100000000. File: <%s>")" "${_pkgfile}"
    fi

    # pkgsources
    u_is_idx_array_exit "pkgsources" "${_fn}" "${_pkgfile}"

    # pkgmd5sums
    u_is_idx_array_exit "pkgmd5sums" "${_fn}" "${_pkgfile}"

    #### Check CMK_GROUPS function exist
    for _func in "${_in_cmk_groups[@]}"; do
        if ! u_got_function "${_func}" && [[ ! -v _in__cmk_groups_default_function_names[${_func}] ]]; then
            m_exit "${_fn}" "$(_g "CMK_GROUPS Function '%s' not specified in File: <%s>")" "${_func}" "${_pkgfile}"
        fi
    done

    ### Check required Pkgfile functions exist
    for _func in "${_in_cmk_required_function_names[@]}"; do
        u_got_function "${_func}" || m_exit "${_fn}" "$(_g "Required Function '%s' not specified in File: <%s>")" "${_func}" \
                                        "${_pkgfile}"
    done
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
