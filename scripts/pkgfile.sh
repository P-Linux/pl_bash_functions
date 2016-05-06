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

unset GREP_OPTIONS
shopt -s extglob
set +o noclobber



#=============================================================================================================================#
#
#                   PKGFILE GENERAL FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Unset official Pkgfile variables
#******************************************************************************************************************************
pk_unset_official_pkgfile_variables() {
    unset -v pkgpackager pkgdesc pkgurl pkgdeps pkgdepsrun pkgvers pkgrel pkgsources pkgmd5sums
}


#******************************************************************************************************************************
# Prepares a lookup MATRIX for all REGISTERED_COLLECTIONS where the keys are the individual port names
#   and the values the first found port path
#
#   VALIDATES:
#       - Collection Path: absolute path to an existing dir or link with rwx access
#       - PORT: contains a Portfile (_reference_pkgfile_name) with rw access
#       - PORTNAME: validates length and chareracters
#
#   ARGUMENTS
#       `_ret_collection_ports_lookup`: a reference var: an empty associative array which will be updated with the ports names
#       `_reference_pkgfile_name`: A reference Pkgfile name which must exist in a valid port folder
#       `_in_registered_collections_l` a reference var
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
#       pk_prepare_collections_lookup COLLECTION_LOOKUP "${CMK_PKGFILE_NAME}" CMK_REGISTERED_COLLECTIONS
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
#       pk_prepare_collections_lookup COLLECTION_LOOKUP "Pkgfile" CMK_REGISTERED_COLLECTIONS
#       echo "<${#COLLECTION_LOOKUP[@]}>"
#******************************************************************************************************************************
pk_prepare_collections_lookup() {
    local _fn="pk_prepare_collections_lookup"
    local -n _ret_collection_ports_lookup=${1}
    local _reference_pkgfile_name=${2}
    local -n _in_registered_collections_l=${3}
    local _collection_entry _collection_path _collection_port_path _collection_port_name _collection_pkgfile_path
    declare -i _collection_port_name_size

    if [[ ${_reference_pkgfile_name} == *"/" ]]; then
        ms_abort "${_fn}" "$(gettext "Reference Pkgfile-Name '_reference_pkgfile_name': MUST NOT end with a slash: <%s>")" \
            "${_reference_pkgfile_name}"
    fi

    ut_ref_associative_array_abort "_ret_collection_ports_lookup" "${_fn}"

    # always reset the _ret_collection_ports_lookup
    _ret_collection_ports_lookup=()
    for _collection_entry in "${_in_registered_collections_l[@]}"; do
        if [[ ${_collection_entry} != "/"* ]]; then
            ms_abort "${_fn}" "$(gettext "COLLECTION_ENTRY: An absolute directory path MUST start with a slash: <%s>")" \
                "${_collection_entry}"
        fi
        if [[ -L ${_collection_entry} ]];then
            _collection_path=$(readlink -f "${_collection_entry}")
        else
            _collection_path=${_collection_entry}
        fi
        if [[ ! -d ${_collection_path} ]]; then
            ms_abort "${_fn}" "$(gettext "FINAL COLLECTION directory does not exist: <%s> COLLECTION-ENTRY: <%s>")" \
                "${_collection_path}" "${_collection_entry}"
        elif [[ ! -r ${_collection_path} ]]; then
            ms_abort "${_fn}" "$(gettext "FINAL COLLECTION directory is not readable: <%s> COLLECTION-ENTRY: <%s>")" \
                "${_collection_path}" "${_collection_entry}"
        elif [[ ! -w ${_collection_path} ]]; then
            ms_abort "${_fn}" "$(gettext "FINAL COLLECTION directory is not writable:: <%s> COLLECTION-ENTRY: <%s>")" \
                "${_collection_path}" "${_collection_entry}"
        elif [[ ! -x ${_collection_path} ]]; then
            ms_abort "${_fn}" "$(gettext "FINAL COLLECTION directory is not executable: <%s> COLLECTION-ENTRY: <%s>")" \
                "${_collection_path}" "${_collection_entry}"
        fi
        # only get one level down
        for _collection_port_path in "${_collection_path}"/*; do
            if [[ -d ${_collection_port_path} ]]; then
                # Just add the first found path
                _collection_pkgfile_path="${_collection_port_path}/${_reference_pkgfile_name}"
                # Only dirs with Pkgfiles are considered
                if [[ -f ${_collection_pkgfile_path} ]]; then
                    if [[ ! -r ${_collection_path} ]]; then
                        ms_abort "${_fn}" "$(gettext "COLLECTION Pkgfile is not readable: <%s> COLLECTION-ENTRY: <%s>")" \
                            "${_collection_pkgfile_path}" "${_collection_entry}"
                    elif [[ ! -w ${_collection_path} ]]; then
                        ms_abort "${_fn}" "$(gettext "COLLECTION Pkgfile is not writable:: <%s> COLLECTION-ENTRY: <%s>")" \
                            "${_collection_pkgfile_path}" "${_collection_entry}"
                    fi

                    ut_get_postfix_shortest_all _collection_port_name "${_collection_port_path}" "/"
                    if [[ ! -v _ret_collection_ports_lookup[${_collection_port_name}] ]]; then
                        _collection_port_name_size=${#_collection_port_name}
                        # Validate: _portname
                        if (( _collection_port_name_size < 2 || _collection_port_name_size > 50 )); then
                            ms_abort "${_fn}" \
                                "$(gettext "PORTNAME MUST have at least 2 and maximum 50 chars. Got: '%s' <%s>")" \
                                "${_collection_port_name_size}" "${_collection_port_path}"
                        fi
                        if [[ ${_collection_port_name} == *[![:alnum:]-_+]* ]]; then
                            ms_abort "${_fn}" "$(gettext "PORTNAME contains invalid characters: '%s' PATH: <%s>")" \
                                "${_collection_port_name//[[:alnum:]-_+]}" "${_collection_port_path}"
                        fi
                        if [[ ${_collection_port_name} == [![:alnum:]]* ]]; then
                            ms_abort "${_fn}" "$(gettext "PORTNAME MUST start with an alphanumeric char. Got: '%s' <%s>")" \
                                "${_collection_port_name:0:1}" "${_collection_port_path}"
                        fi
                        _ret_collection_ports_lookup["${_collection_port_name}"]=${_collection_pkgfile_path}
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
#       `_reference_pkgfile_name`: A reference name for a pkgfile - used to search for valid ports
#       `_in_portslist`: a reference var: a array of registered collection port names or absolute path to ports: e.g.
#               CMK_PORTSLIST=(
#                   bzip2
#                   coreutils
#                   /usr/ports/personal/wget
#               )
#       `_in_registered_collections`: a reference var:
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
#       pk_prepare_pkgfiles_to_process PKGFILES_TO_PROCESS "${CMK_PKGFILE_NAME}" CMK_PORTSLIST CMK_REGISTERED_COLLECTIONS
#******************************************************************************************************************************
pk_prepare_pkgfiles_to_process() {
    local _fn="pk_prepare_pkgfiles_to_process"
    local -n _ret_pkgfiles_to_process=${1}
    local _reference_pkgfile_name=${2}
    local -n _in_portslist=${3}
    local -n _in_registered_collections=${4}
    declare -A _collection_lookup=()
    local _port_entry _pkgfile_port_path _reg_collection

    # always reset the _ret_pkgfiles_to_process
    _ret_pkgfiles_to_process=()

    # Check if we have only one absolute path: most often:
    #           then there is no need to prepare the collections_lookup which takes time
    if (( ${#_in_portslist[@]} == 1 )) && [[ ${_in_portslist[0]} == "/"* ]] ; then
        _pkgfile_port_path="${_in_portslist[0]}/${_reference_pkgfile_name}"
        pk_validate_pkgfile_port_path_name "${_pkgfile_port_path}" "${_reference_pkgfile_name}"
        _ret_pkgfiles_to_process+=("${_pkgfile_port_path}")
    else
        pk_prepare_collections_lookup _collection_lookup "${_reference_pkgfile_name}" _in_registered_collections

        for _port_entry in "${_in_portslist[@]}"; do
            if [[ ${_port_entry} == "/"* ]]; then
                _pkgfile_port_path="${_port_entry}/${_reference_pkgfile_name}"
                pk_validate_pkgfile_port_path_name "${_pkgfile_port_path}" "${_reference_pkgfile_name}"
                _ret_pkgfiles_to_process+=("${_pkgfile_port_path}")
            elif [[ -v _collection_lookup[${_port_entry}] ]]; then
                _ret_pkgfiles_to_process+=("${_collection_lookup[${_port_entry}]}")
            else
                # NOT FOUND
                ms_more "$(gettext "======== All Registered Collections ========")"
                for _reg_collection in "${_in_registered_collections[@]}"; do
                    ms_more_i "$(gettext "* Collection Path: <%s>")" \
                        "${_reg_collection}"
                done
                 ms_abort "${_fn}" "$(gettext "Portslist entry: <%s> not found in the registered collections.")" \
                    "${_port_entry}"
            fi
        done
    fi
}


#******************************************************************************************************************************
# Validates a Pkgfile / Port Version: Checks only the version syntax
#
#   ARGUMENTS
#       `_pkgvers`: _pkgvers string
#       `_pkgfile_path`: absolute path to the pkgfile
#
#   USAGE:
#       pk_validate_pkgvers "1.3.5" "${CMK_PKGFILE_PATH}"
#******************************************************************************************************************************
pk_validate_pkgvers() {
    local _pkgvers=${1}
    local _pkgfile_path=${2}

    if [[ -n ${_pkgvers} ]]; then
        if [[ ${_pkgvers} == *[![:alnum:].]* ]]; then
            ms_abort "pk_validate_pkgvers" "$(gettext "'pkgvers' contains invalid characters: '%s' File: <%s>")" \
                "${_pkgvers//[[:alnum:].]}" "${_pkgfile_path}"
        fi
    else
        ms_abort "pk_validate_pkgvers" "$(gettext "Variable 'pkgvers' MUST NOT be empty: <%s>")" "${_pkgfile_path}"
    fi
}


#******************************************************************************************************************************
# Return Pkgfile / Port Version: Checks only the version syntax
#
#   ARGUMENTS
#       `_pkgfile_path`: absolute path to the pkgfile
#
#   USAGE:
#       pk_get_only_pkgvers_abort "${CMK_PKGFILE_PATH}"
#
#   NOTE: Keept this as an subshell
#******************************************************************************************************************************
pk_get_only_pkgvers_abort() {
    (
        local _fn="pk_get_only_pkgvers_abort"
        [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Argument 1 MUST NOT be empty.")" "${_fn}"
        local _pkgfile_path=${1}

        # unset all official related variable
        pk_unset_official_pkgfile_variables

        ut_source_safe_abort "${_pkgfile_path}"

        pk_validate_pkgvers "${pkgvers}" "${_pkgfile_path}"
        printf "%s\n" "${pkgvers}"
    )
}


#******************************************************************************************************************************
# Generate for all `pkgsources` entires corresponding `pkgmd5sums` entries. It is expected that all sources exist already.
#   for protocols: ftp|http|https|local md5sums are generated for all others a SKIP entry.
#
#   ARGUMENTS
#       `_ret_pkgmd5sums`: reference var: will be updated with the final corresponding entries
#       `_in_pkgp_scrmtx`: reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#
#   USAGE
#       local NEW_PKGMD5SUMS=()
#       pk_generate_pkgmd5sums NEW_PKGMD5SUMS SCRMTX
#******************************************************************************************************************************
pk_generate_pkgmd5sums() {
    local _fn="pk_generate_pkgmd5sums"
    local -n _ret_pkgmd5sums=${1}
    local -n _in_pkgp_scrmtx=${2}
    declare -i _n
    local _md5sum _entry _protocol _destpath

    if [[ ! -v _in_pkgp_scrmtx[NUM_IDX] ]]; then
        ms_abort "${_fn}" "$(gettext "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_pkgp_scrmtx[NUM_IDX]}; _n++ )); do
        _entry=${_in_pkgp_scrmtx[${_n}:ENTRY]}
        _destpath=${_in_pkgp_scrmtx[${_n}:DESTPATH]}
        _protocol=${_in_pkgp_scrmtx[${_n}:PROTOCOL]}
        case "${_protocol}" in
            ftp|http|https|local)
                if [[ -f ${_destpath} && -r ${_destpath} ]]; then
                    _md5sum=$(md5sum "${_destpath}")
                    _md5sum=${_md5sum:0:32}
                    if [[ ! -n ${_md5sum} ]]; then
                        ms_abort "${_fn}" "$(gettext "Could not generate a md5sum for _destpath: <%s> Entry: <%s>")" \
                            "${_destpath}" "${_entry}"
                    fi
                else
                    ms_abort "${_fn}" "$(gettext "Not a readable file path: <%s> Entry: <%s>")" "${_destpath}" "${_entry}"
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
#       `_pkgfile_path`: absolute path to the pkgfile: must exist
#       `_reference_pkgfile_name`: A reference name against the _pkgfile_path basename is checked
#
#   USAGE:
#       pk_validate_pkgfile_port_path_name "${CMK_PKGFILE_PATH}" "${CMK_PKGFILE_NAME}"
#******************************************************************************************************************************
pk_validate_pkgfile_port_path_name() {
    local _fn="pk_validate_pkgfile_port_path_name"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Argument 1 MUST NOT be empty.")" "${_fn}"
    [[ -n $2 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Argument 2 MUST NOT be empty.")" "${_fn}"
    local _pkgfile_path=${1}
    local _reference_pkgfile_name=${2}
    local _port_path; ut_dirname _port_path "${_pkgfile_path}"
    local _portname; ut_basename _portname "${_port_path}"
    local _pkgfile_basename; ut_basename _pkgfile_basename "${_pkgfile_path}"
    declare -i _portname_size=${#_portname}

    # Validate: _port_path
    ut_dir_is_rwx_abort "${_port_path}" "yes" "PORT_PATH"
    # Validate: _portname
    if (( ${_portname_size} < 2 || ${_portname_size} > 50 )); then
        ms_abort "${_fn}" "$(gettext "PORTNAME MUST have at least 2 and maximum 50 characters. Got: '%s' PATH: <%s>")" \
            "${_portname_size}" "${_pkgfile_path}"
    fi
    if [[ ${_portname} == *[![:alnum:]-_+]* ]]; then
        ms_abort "${_fn}" "$(gettext "PORTNAME contains invalid characters: '%s' PATH: <%s>")" \
            "${_portname//[[:alnum:]-_+]}" "${_pkgfile_path}"
    fi
    if [[ ${_portname} == [![:alnum:]]* ]]; then
        ms_abort "${_fn}" "$(gettext "PORTNAME MUST start with an alphanumeric character. Got: '%s' PATH: <%s>")" \
            "${_portname:0:1}" "${_pkgfile_path}"
    fi

    # Validate: _pkgfile_path no need to check again for absolute path this is done with the port check above.
    ut_file_is_rw_abort "${_pkgfile_path}" "yes" "PKGFILE_PATH"
    [[ -f ${_pkgfile_path} ]] || ms_abort "${_fn}" "$(gettext "PKGFILE_PATH does not exist: <%s>")" "${_pkgfile_path}"
    [[ -r ${_pkgfile_path} ]] || ms_abort "${_fn}" "$(gettext "PKGFILE_PATH is not readable: <%s>")" "${_pkgfile_path}"

    if [[ ${_pkgfile_basename} != ${_reference_pkgfile_name} ]]; then
        ms_abort "${_fn}" "$(gettext "PKGFILE-Basename: '%s' is not the same as the defined Reference-Pkgfile-Name: '%s'")" \
                "${_pkgfile_basename}" "${_reference_pkgfile_name}"
    fi
}


#******************************************************************************************************************************
# Sources a Pkgfile: Aborts if a basic validate does not pass
#                          IMPORTANT: the pkgsources is more thoroughly validated in the function: so_prepare_src_matrix().
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
#       `_pkgfile_path`: absolute path to the pkgfile: for test purpose it is not required that the path exists
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
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION '%s()': Argument 1 MUST NOT be empty.")" "${_fn}"
    local _pkgfile_path=${1}
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
    pk_unset_official_pkgfile_variables
    ut_unset_functions _in_cmk_required_function_names
    ut_unset_functions2 _in__cmk_groups_default_function_names  # NEED ut_unset_functions2 for associative array

    ut_source_safe_abort "${_pkgfile_path}"

    ##### Pkgfile-Header
    # pkgpackager
    if [[ ! -n ${pkgpackager} ]]; then
        ms_abort "${_fn}" "$(gettext "Variable 'pkgpackager' MUST NOT be empty: <%s>")" "${_pkgfile_path}"
    fi

    # pkgdesc
    _pkgdesc_size=${#pkgdesc}
    if (( ${_pkgdesc_size} < 10 || ${_pkgdesc_size} > 110 )); then
        ms_abort "${_fn}" \
            "$(gettext "'pkgdesc' MUST have at least 10 and a maximum of 110 characters. Got: '%s' File: <%s>")" \
            "${_pkgdesc_size}" "${_pkgfile_path}"
    fi

    # pkgurl: can also be empty
    ut_is_str_var_abort "pkgurl" "${_fn}" "${_pkgfile_path}"

    # pkgdeps
    ut_is_idx_array_abort "pkgdeps" "${_fn}" "${_pkgfile_path}"

    # pkgdepsrun: Optional
    ut_is_idx_array_var "pkgdepsrun" || pkgdepsrun=()

    #### Pkgfile-Variables
    #pkgvers
    pk_validate_pkgvers "${pkgvers}" "${_pkgfile_path}"

    # pkgrel
    if [[ ${pkgrel} != +([[:digit:]]) ]]; then
        ms_abort "${_fn}" "$(gettext "'pkgrel' MUST NOT be empty and only contain digits and not: '%s' File: <%s>")" \
            "${pkgrel//[[:digit:]]}" "${_pkgfile_path}"
    fi
    if (( ${pkgrel} < 1 || ${pkgrel} > 99999999 )); then
        ms_abort "${_fn}" "$(gettext "'pkgrel' MUST be greater than 0 and less than 100000000. File: <%s>")" \
            "${_pkgfile_path}"
    fi

    # pkgsources
    ut_is_idx_array_abort "pkgsources" "${_fn}" "${_pkgfile_path}"

    # pkgmd5sums
    ut_is_idx_array_abort "pkgmd5sums" "${_fn}" "${_pkgfile_path}"

    #### Check CMK_GROUPS function exist
    for _func in "${_in_cmk_groups[@]}"; do
        if ! ut_got_function "${_func}" && [[ ! -v _in__cmk_groups_default_function_names[${_func}] ]]; then
            ms_abort "${_fn}" "$(gettext "CMK_GROUPS Function '%s' not specified in File: <%s>")" "${_func}" "${_pkgfile_path}"
        fi
    done

    ### Check required Pkgfile functions exist
    for _func in "${_in_cmk_required_function_names[@]}"; do
        if ! ut_got_function "${_func}"; then
            ms_abort "${_fn}" "$(gettext "Required Function '%s' not specified in File: <%s>")" "${_func}" "${_pkgfile_path}"
        fi
    done
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
