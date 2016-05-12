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
shopt -s extglob dotglob
set +o noclobber


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
#       | Variable Name | Description                                   |
#       |:--------------|:----------------------------------------------|
#       | `pkgdir`      | build package directory: _pkg_build_dir/pkg   |
#       | `srcdir`      | build sources directory: _pkg_build_dir/src   |
#
#   ARGUMENTS
#       `$1 (_pkg_build_dir)`: Path to the PKG_BUILD_DIR
#******************************************************************************************************************************
pr_make_pkg_build_dir() {
    if [[ ! -n $1 ]]; then
        ms_abort "pr_make_pkg_build_dir" "$(gettext "FUNCTION 'pr_make_pkg_build_dir()': Argument 1 MUST NOT be empty.")"
    fi
    # skip assignment:  _pkg_build_dir=${1}
    pkgdir="${1}/pkg"
    srcdir="${1}/src"
    umask 0022

    rm -rf "${1}"
    mkdir -p "${pkgdir}" "${srcdir}"
}


#******************************************************************************************************************************
# Remove downloaded sources.
#
#   ARGUMENTS
#       `_in_pr_rds_scrmtx`: reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   OPTIONAL ARGUMENTS
#       `_in_filter_protocols`: a reference var: An associative array with `PROTOCOL` names as keys.
#           Only these protocols sources will be deleted:
#           DEFAULTS TO: declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#
#   USAGE
#       declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       pr_remove_downloaded_sources SCRMTX FILTER
#******************************************************************************************************************************
pr_remove_downloaded_sources() {
    local -n _in_pr_rds_scrmtx=${1}
    if [[ -n $2 ]]; then
        local -n _in_filter_protocols=${2}
    else
        declare -A _in_filter_protocols=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
    fi
    local _in_filter_protocols_keys_string
    declare -i _n

    if [[ -v _in_filter_protocols["local"] ]]; then
        _in_filter_protocols_keys_string=${!_in_filter_protocols[@]}
        ms_abort "pr_remove_downloaded_sources" \
            "$(gettext "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" \
            "${_in_filter_protocols_keys_string}"
    fi

    if [[ ! -v _in_pr_rds_scrmtx[NUM_IDX] ]]; then
        ms_abort "pr_remove_downloaded_sources" \
            "$(gettext "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_pr_rds_scrmtx[NUM_IDX]}; _n++ )); do
        if [[ -v _in_filter_protocols[${_in_pr_rds_scrmtx[${_n}:PROTOCOL]}] ]]; then
            if [[ -e${_in_pr_rds_scrmtx[${_n}:DESTPATH]} ]]; then
                ms_more "$(gettext "Removing source <%s>")" "${_in_pr_rds_scrmtx[${_n}:DESTPATH]}"
                rm -rf "${_in_pr_rds_scrmtx[${_n}:DESTPATH]}"
            fi
        fi
    done
}


#******************************************************************************************************************************
# Remove existing Pkgfile backup files: xxxx.bak
#
#   ARGUMENTS
#       `$1`: absolute path to the pkgfile
#
#   USAGE
#       CMK_PKGFILE_PATH="/usr/ports/p_diverse/hwinfo"
#       pr_remove_existing_backup_pkgfile "${CMK_PKGFILE_PATH}
#******************************************************************************************************************************
pr_remove_existing_backup_pkgfile() {
    local _backup_pkgfile_fullpath="${1}.bak"
    if [[ -f "${_backup_pkgfile_fullpath}" ]]; then
        ms_more "$(gettext "Removing existing Backup-Pkgfile: <%s>")" "${_backup_pkgfile_fullpath}"
        rm -f "${_backup_pkgfile_fullpath}"
    fi
}


#******************************************************************************************************************************
# Generate the pkgmd5sums array in the Pkgfile: makes also a backup copy of the original Pkgfile
#
#   ARGUMENTS
#       `_in_pkgfile_path`: absolute path to the pkgfile
#       `_in_new_md5sums`: a reference var: a index array with the md5sum: the itmes will be written to the Pkgfile: pkgmd5sums
#
#   USAGE
#       NEW_MD5SUM=(1234567896754313
#           564857964
#       )
#       pr_update_pkgfile_pkgmd5sums "${CMK_PKGFILE_PATH}" NEW_MD5SUM
#******************************************************************************************************************************
pr_update_pkgfile_pkgmd5sums() {

    # Helper to consider the end of the original pkgmd5sums: in case code is written on the same line after the closing `)`
    _do_end_of_array() {
        if [[ ${_line} != *"#"*")"* ]]; then
            ut_get_postfix_longest_all _temp_str "${_line}" ")"
            if [[ -n ${_temp_str} ]]; then
                if [[ ${_temp_str} != ";"* ]]; then
                    _final_str+="${_temp_str}\n"
                else
                    _temp_str="${_temp_str:1}"
                    _temp_str=${_temp_str##+([[:space:]])}
                    _final_str+="${_temp_str}\n"
                fi
            fi
            _add_rest=1
        fi
    }

    local _in_pkgfile_path=${1}
    local -n _in_new_md5sums=${2}
    local _in_new_md5sums_size=${#_in_new_md5sums[@]}
    local _final_str=""
    local _temp_str=""
    # tests are slightly faster for ints
    declare -i _found_start=0
    declare -i _add_rest=0
    local _backup_pkgfile="${_in_pkgfile_path}.bak"

    ms_more "$(gettext "Updating pkgmd5sums array for Pkgfile: <%s>")" "${_in_pkgfile_path}"
    # make a bak file
    cp -f "${_in_pkgfile_path}" "${_backup_pkgfile}"

    _savedifs=${IFS}
    while IFS= read -r _line; do
        if (( ${_add_rest} )); then
             _final_str+="${_line}\n"
        elif (( ${_found_start} )); then
            [[ ${_line} == *")"* ]] && _do_end_of_array
        elif [[ ${_line} == *"pkgmd5sums=("* ]]; then
            ut_get_prefix_shortest_all _temp_str "${_line}" "pkgmd5sums=("
            if [[ -n ${_temp_str} ]]; then
                _temp_str=${_temp_str%%+([[:space:]])}
                if [[ ${_temp_str} != *";" ]]; then
                    _final_str+="${_temp_str}\n"
                else
                    _final_str+="${_temp_str:: -1}\n"
                fi
            fi
            # Insert our new one
            if (( ${_in_new_md5sums_size} == 1 )); then
                _final_str+="pkgmd5sums=(\"${_in_new_md5sums[0]}\")\n"
            elif (( ${_in_new_md5sums_size} > 1 )); then
                _final_str+="pkgmd5sums=(\"${_in_new_md5sums[0]}\"\n"
                for (( _n=1; _n < ${_in_new_md5sums_size} - 1; _n++ )); do
                    _final_str+="    \"${_in_new_md5sums[${_n}]}\"\n"
                done
                _final_str+="    \"${_in_new_md5sums[${_n}]}\")\n"
            else
                _final_str+="pkgmd5sums=()\n"
            fi

            [[ ${_line} == *")"* ]] && _do_end_of_array
            _found_start=1
        else
            _final_str+="${_line}\n"
        fi
    done < "${_backup_pkgfile}"
    IFS=${_savedifs}

    echo -e "${_final_str}" > "${_in_pkgfile_path}"
}


#******************************************************************************************************************************
# Generate a new port-repo-file.
#       The ports Pkgfile MUST have been already sourced. See also function: pkf_source_validate_pkgfile().
#
#   ARGUMENTS
#       `_in_pkgfile_path`: pkgfile path
#       `$2 (_in_port_name)`: port name
#       `_in_port_path`: port absolute path
#       `_in_system_arch`: architecture e.g.: "$(uname -m)"
#       `_in_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `$6 (_in_ref_repo_filename)`: The reference repo file name.
#
#   USAGE
#       PORTNAME="hwinfo"
#       PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CMK_ARCH="$(uname -m)"
#       CMK_PKG_EXT="cards.tar"
#       pr_update_port_repo_file "${PKGFILE_PATH}" "${PORTNAME}" "${PORT_PATH}" "${CMK_ARCH}" "${CMK_PKG_EXT}" "${CMK_REPO}"
#******************************************************************************************************************************
pr_update_port_repo_file() {
    local _fn="pr_update_port_repo_file"
    (( ${#} != 6 )) &&  ms_abort "${_fn}" "$(gettext "FUNCTION Requires EXACT '6' arguments. Got '%s'")" "${#}"
    local _in_pkgfile_path=${1}
    # skip assignment:  _in_port_name=${2}
    local _in_port_path=${3}
    local _in_system_arch=${4}
    local _in_ref_ext=${5}
    # skip assignment:  _in_ref_repo_filename=${6}
    local _repo_file_path="${_in_port_path}/${6}"
    local _final_str=""
    local _existing_pkg_archives=()
    local _pkgfile_basename; ut_basename _pkgfile_basename "${_in_pkgfile_path}"
    local _pkgarchive_name _pkgarchive_buildvers _pkgarchive_arch _pkgarchive_ext
    local _packager _description _url
    local _pkgarchive_path _pkgarchive_basename _md5sum _f

    ms_more "$(gettext "Updating repo file for Port: <%s>")" "${_in_port_path}"

    # Limited, fast check if we have sourced the Pkgfile beforehand
    if [[ ! -n ${pkgpackager} ]]; then
        ms_abort "${_fn}" \
        "$(gettext "Could not get expected Pkgfile variable! Hint: did you forget to source the pkgfile: <%s>")" \
            "${_in_pkgfile_path}"
    fi

    _existing_pkg_archives=()
    pka_get_existing_pkgarchives _existing_pkg_archives "${2}" "${_in_port_path}" "${_in_system_arch}" "${_in_ref_ext}"

    if [[ ${pkgpackager} == *"#"* ]]; then
        _packager=${pkgpackager/"#"/"\#"}
    else
        _packager=${pkgpackager}
    fi

    if [[ ${pkgdesc} == *"#"* ]]; then
        _description=${pkgdesc/"#"/"\#"}
    else
        _description=${pkgdesc}
    fi

    if [[ -n ${pkgurl} ]]; then
        if [[ ${pkgurl} == *"#"* ]]; then
            _url=${pkgurl/"#"/"\#"}
        else
            _url=${pkgurl}
        fi
    else
        _url="n.a."
    fi

    # Always delete first any exiating: _repo_file_path
    rm -f "${_repo_file_path}"

    if (( ${#_existing_pkg_archives[@]} > 0 )); then
        # use the first entry to get general data
        _pkgarchive_path=${_existing_pkg_archives[0]}
        pka_get_pkgarchive_parts _pkgarchive_name _pkgarchive_buildvers _pkgarchive_arch _pkgarchive_ext \
            "${_pkgarchive_path}" "${_in_system_arch}" "${_in_ref_ext}"
        _final_str+="${_pkgarchive_buildvers}#${_pkgarchive_ext}#${pkgvers}#${pkgrel}#${_description}#${_url}#${_packager}\n"

        # Do the individual package archive files
        for _pkgarchive_path in "${_existing_pkg_archives[@]}"; do
			ut_basename _pkgarchive_basename "${_pkgarchive_path}"
            ut_get_file_md5sum_abort _md5sum "${_pkgarchive_path}"
            pka_get_pkgarchive_name_arch _pkgarchive_name _pkgarchive_arch "${_pkgarchive_path}" "${_in_system_arch}" \
                "${_in_ref_ext}"
            _final_str+="${_md5sum}#${_pkgarchive_name}#${_pkgarchive_arch}\n"
		done

        # Do all other files
        pushd "${_in_port_path}" &> /dev/null
		for _f in *; do
			if [[ -f ${_f} ]]; then
                ut_get_file_md5sum_abort _md5sum "${_f}"
                if [[ ${_f} != ${_pkgfile_basename} ]]; then
                    if ! [[ ${_f} == *"${_in_system_arch}.${_in_ref_ext}"* || ${_f} == *"any.${_ref_ext_ge}"* ]]; then
                        _final_str+="${_md5sum}#${_f}\n"
                    fi
                fi
			fi
		done
        popd &> /dev/null
	fi

    ut_get_file_md5sum _md5sum "${_in_pkgfile_path}"
    _final_str+="${_md5sum}#${_pkgfile_basename}"

    echo -e "${_final_str}" > "${_repo_file_path}"
}


#******************************************************************************************************************************
# Generate a new/update a collection-repo-file with the ports entry line.
#
#   ARGUMENTS
#       `_in_port_name`: port name
#       `_in_port_path`: port absolute path
#       `$3 (_in_ref_repo_filename)`: The reference repo file name.
#
#   USAGE
#       CMK_PORTNAME="hwinfo"
#       CMK_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       pr_update_collection_repo_file "${CMK_PORTNAME}" "${CMK_PORT_PATH}" "${CMK_REPO}"
#******************************************************************************************************************************
pr_update_collection_repo_file() {
    local _in_port_name=${1}
    local _in_port_path=${2}
    # skip assignment:  _in_ref_repo_filename=${3}
    local _repo_file_path="${_in_port_path}/${3}"
    local _collection_repo_file_path="${_in_port_path}/../${3}"
    local  _md5sum _buildvers _ext _vers _rel _description _url _packager _first_line

    ms_more "$(gettext "Updating collection repo file for Port: <%s>")" "${_in_port_path}"

    if [[ -f ${_repo_file_path} ]]; then
        read -r _first_line < "${_repo_file_path}"
		if [[ ${_first_line:10:1} = "#" ]]; then
            saveifs=${IFS}
            IFS="#" read _buildvers _ext _vers _rel _description _url _packager <<< "${_first_line}"
            IFS=${saveifs}

            # Remove any existing entry line
            [[ -f ${_collection_repo_file_path} ]] && sed -i "/#${_in_port_name}#/d" "${_collection_repo_file_path}"
            ut_get_file_md5sum_abort _md5sum "${_repo_file_path}"

            # Append it
            echo "${_md5sum}#${_buildvers}#${_in_port_name}#${_vers}#${_rel}#${_description}#${_url}#${_packager}#${_ext}" \
                >> "${_collection_repo_file_path}"
        fi
    fi
}


#******************************************************************************************************************************
# Searches for files in `_in_dir_path` and strips: Binaries, Libraries (*.so) Libraries (*.a) and Kernel modules (*.ko)
#
#   ARGUMENTS
#       `$1 (_in_dir_path)`: absolute directory path: root dir for filesearch.
#
#   USAGE
#       pr_strip_files "${pkgdir}"
#******************************************************************************************************************************
pr_strip_files() {
    # skip assignment:  _in_dir_path=${1}
    local _file

    pushd "${1}" &> /dev/null
    find . -type f -perm -u+w -print0 2>/dev/null | while read -rd '' _file ; do
        case "$(file -bi "${_file}")" in
            *application/x-executable*)
                strip "--strip-all" "${_file}"              # Binaries
                ;;
            *application/x-sharedlib*)
                strip "--strip-unneeded" "${_file}"         # Libraries (.so)
                ;;
            *application/x-archive*)
                strip "--strip-debug" "${_file}"            # Libraries (.a)
                ;;
            *application/x-object*)
                case "${_file}" in
                    *.ko)
                        strip "--strip-unneeded" "${_file}"  # Kernel modules
                        ;;
                    *) continue;;
                esac;;

            *) continue ;;
        esac
    done
    popd &> /dev/null
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
