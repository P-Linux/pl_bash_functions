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

i_general_opt



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
#       | Variable Name | Description                                     |
#       |:--------------|:------------------------------------------------|
#       | `pkgdir`      | build package directory: _pkg_build_dir/pkg     |
#       | `srcdir`      | build sources directory: _pkg_build_dir/src     |
#
#   ARGUMENTS
#       `$1 (_pkg_build_dir)`: Path to the PKG_BUILD_DIR
#******************************************************************************************************************************
p_make_pkg_build_dir() {
    (( ${#} != 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '1' argument. Got '%s'")" "${#}"
    [[ -n ${1} ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
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
#       `_in_p_rds_scrmtx`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   OPTIONAL ARGUMENTS
#       `_in_filter_protocols`: a reference var: An associative array with `PROTOCOL` names as keys.
#           Only these protocols sources will be deleted:
#           DEFAULTS TO: declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#
#   USAGE
#       declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       p_remove_downloaded_src SCRMTX FILTER
#******************************************************************************************************************************
p_remove_downloaded_src() {
    (( ${#} < 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires AT LEAST '1' argument. Got '%s'")" "${#}"
    local -n _in_p_rds_scrmtx=${1}
    if (( ${#} > 1 )) && [[ -v ${2}[@] ]]; then         # Check var 2 is set and has elements
        local -n _in_filter_protocols=${2}
    else
        declare -A _in_filter_protocols=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
    fi
    local _tmp
    declare -i _n

    if [[ -v _in_filter_protocols["local"] ]]; then
        _tmp=${!_in_filter_protocols[@]}            # _in_filter_protocols_keys_str
        i_exit 1 ${LINENO} "$(_g "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" "${_tmp}"
    fi

    if [[ ! -v _in_p_rds_scrmtx[NUM_IDX] ]]; then
        i_exit 1 ${LINENO} "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_p_rds_scrmtx[NUM_IDX]}; _n++ )); do
        if [[ -v _in_filter_protocols[${_in_p_rds_scrmtx[${_n}:PROTOCOL]}] ]]; then
            if [[ -e ${_in_p_rds_scrmtx[${_n}:DESTPATH]} ]]; then
                i_more_i "$(_g "Removing source <%s>")" "${_in_p_rds_scrmtx[${_n}:DESTPATH]}"
                rm -rf "${_in_p_rds_scrmtx[${_n}:DESTPATH]}"
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
#       CM_PKGFILE_PATH="/usr/ports/p_diverse/hwinfo"
#       p_remove_pkgfile_backup "${CM_PKGFILE_PATH}
#******************************************************************************************************************************
p_remove_pkgfile_backup() {
    (( ${#} != 1 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '1' argument. Got '%s'")" "${#}"
    local _in_p_backup_path="${1}.bak"
    if [[ -f "${_in_p_backup_path}" ]]; then
        i_more_i "$(_g "Removing existing Backup-Pkgfile: <%s>")" "${_in_p_backup_path}"
        rm -f "${_in_p_backup_path}"
    fi
}


#******************************************************************************************************************************
# Generate the pkgmd5sums array in the Pkgfile: makes also a backup copy of the original Pkgfile
#
#   ARGUMENTS
#       `_pkgfile_path`: absolute path to the pkgfile
#       `_in_new_md5sums`: a reference var: a index array with the md5sum: the itmes will be written to the Pkgfile: pkgmd5sums
#
#   USAGE
#       NEW_MD5SUM=(1234567896754313
#           564857964
#       )
#       p_update_pkgfile_pkgmd5sums "${CM_PKGFILE_PATH}" NEW_MD5SUM
#******************************************************************************************************************************
p_update_pkgfile_pkgmd5sums() {

    # Helper to consider the end of the original pkgmd5sums: in case code is written on the same line after the closing `)`
    _do_end_of_array() {
        if [[ ${_line} != *"#"*")"* ]]; then
            u_postfix_longest_all _temp_str "${_line}" ")"
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

    (( ${#} != 2 )) && i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '2' argument. Got '%s'")" "${#}"
    local _pkgfile_path=${1}
    local -n _in_new_md5sums=${2}
    declare -i _in_new_md5sums_size=${#_in_new_md5sums[@]}
    local _final_str=""
    local _tmpstr=""
    # tests are slightly faster for ints
    declare -i _found=0
    declare -i _add_rest=0
    local _backup_pkgfile="${_pkgfile_path}.bak"

    # make a bak file
    cp -f "${_pkgfile_path}" "${_backup_pkgfile}"

    _savedifs=${IFS}
    while IFS= read -r _line; do
        if (( ${_add_rest} )); then
             _final_str+="${_line}\n"
        elif (( ${_found} )); then
            [[ ${_line} == *")"* ]] && _do_end_of_array
        elif [[ ${_line} == *"pkgmd5sums=("* ]]; then
            u_prefix_shortest_all _tmpstr "${_line}" "pkgmd5sums=("
            if [[ -n ${_tmpstr} ]]; then
                _tmpstr=${_tmpstr%%+([[:space:]])}
                if [[ ${_tmpstr} != *";" ]]; then
                    _final_str+="${_tmpstr}\n"
                else
                    _final_str+="${_tmpstr:: -1}\n"
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
            _found=1
        else
            _final_str+="${_line}\n"
        fi
    done < "${_backup_pkgfile}"
    IFS=${_savedifs}

    echo -e "${_final_str}" > "${_pkgfile_path}"
}


#******************************************************************************************************************************
# Generate a new port-repo-file.
#       The ports Pkgfile MUST have been already sourced. See also function: pk_source_validate_pkgfile().
#
#   ARGUMENTS
#       `_in_pkgfile_path`: pkgfile path
#       `$2 (_in_portname)`: port name
#       `_in_portpath`: port absolute path
#       `_in_sysarch`: architecture e.g.: "$(uname -m)"
#       `_in_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `$6 (_in_ref_repo_filename)`: The reference repo file name.
#
#   USAGE
#       PORTNAME="hwinfo"
#       PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       CM_ARCH="$(uname -m)"
#       CM_PKG_EXT="cards.tar"
#       p_update_port_repo_file "${PKGFILE_PATH}" "${PORTNAME}" "${PORT_PATH}" "${CM_ARCH}" "${CM_PKG_EXT}" "${CM_REPO}"
#******************************************************************************************************************************
p_update_port_repo_file() {
    local _fn="p_update_port_repo_file"
    (( ${#} != 6 )) &&  i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '6' arguments. Got '%s'")" "${#}"
    local _in_pkgfile_path=${1}
    # skip assignment:  _in_port_name=${2}
    local _in_portpath=${3}
    local _in_sysarch=${4}
    local _in_ref_ext=${5}
    # skip assignment:  _in_ref_repo_filename=${6}
    local _repo_file_path="${_in_portpath}/${6}"
    local _final_str=""
    local _pkgarchives_list=()
    local _pkgfile_name; u_basename _pkgfile_name "${_in_pkgfile_path}"
    local _archive_name _archive_buildvers _archive_arch _archive_ext
    local _packager _description _url
    local _archive_filepath _archive_filename _md5sum _f

    # Limited, fast check if we have sourced the Pkgfile beforehand
    if [[ ! -v pkgpackager ]]; then
        i_exit 1 ${LINENO} \
            "$(_g "Could not get expected Pkgfile variable 'pkgpackager'! Hint: did you forget to source the pkgfile: <%s>")" \
            "${_in_pkgfile_path}"
    fi

    _pkgarchives_list=()
    a_list_pkgarchives _pkgarchives_list "${2}" "${_in_portpath}" "${_in_sysarch}" "${_in_ref_ext}"

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

    # Always delete first any existing: _repo_file_path
    rm -f "${_repo_file_path}"

    if (( ${#_pkgarchives_list[@]} > 0 )); then
        # use the first entry to get general data
        _archive_filepath=${_pkgarchives_list[0]}
        a_get_archive_parts _archive_name _archive_buildvers _archive_arch _archive_ext \
            "${_archive_filepath}" "${_in_sysarch}" "${_in_ref_ext}"
        _final_str+="${_archive_buildvers}#${_archive_ext}#${pkgvers}#${pkgrel}#${_description}#${_url}#${_packager}\n"

        # Do the individual package archive files
        for _archive_filepath in "${_pkgarchives_list[@]}"; do
            u_basename _archive_filename "${_archive_filepath}"
            u_get_file_md5sum_exit _md5sum "${_archive_filepath}"
            a_get_archive_name_arch _archive_name _archive_arch "${_archive_filepath}" "${_in_sysarch}" "${_in_ref_ext}"
            _final_str+="${_md5sum}#${_archive_name}#${_archive_arch}\n"
        done

        # Do all other files
        pushd "${_in_portpath}" &> /dev/null
        for _f in *; do
            if [[ -f ${_f} ]]; then
                u_get_file_md5sum_exit _md5sum "${_f}"
                if [[ ${_f} != ${_pkgfile_name} ]]; then
                    if ! [[ ${_f} == *"${_in_sysarch}.${_in_ref_ext}"* || ${_f} == *"any.${_in_ref_ext}"* ]]; then
                        _final_str+="${_md5sum}#${_f}\n"
                    fi
                fi
            fi
        done
        popd &> /dev/null
    fi

    u_get_file_md5sum _md5sum "${_in_pkgfile_path}"
    _final_str+="${_md5sum}#${_pkgfile_name}"

    echo -e "${_final_str}" > "${_repo_file_path}"
}


#******************************************************************************************************************************
# Generate a new/update a collection-repo-file with the ports entry line.
#
#   ARGUMENTS
#       `_in_portname`: port name
#       `_in_portpath`: port absolute path
#       `_in_collectionpath`: port absolute path
#       `$4 (_in_ref_repo_filename)`: The reference repo file name.
#
#   USAGE
#       CM_PORTNAME="hwinfo"
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       p_update_collection_repo_file "${CM_PORTNAME}" "${CM_PORTPATH}" "${CM_PORT_COLLECTION_PATH}" "${CM_REPO}"
#******************************************************************************************************************************
p_update_collection_repo_file() {
    (( ${#} != 4 )) &&  i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '4' arguments. Got '%s'")" "${#}"
    local _in_portname=${1}
    local _in_portpath=${2}
    local _in_collectionpath=${3}
    # skip assignment:  _in_ref_repo_filename=${4}
    local _repo_file_path="${_in_portpath}/${4}"
    local _col_repo_file_path="${_in_collectionpath}/${4}"
    local  _md5sum _buildvers _ext _vers _rel _description _url _packager _first_line

    if [[ -f ${_repo_file_path} ]]; then
        read -r _first_line < "${_repo_file_path}"
        if [[ ${_first_line:10:1} = "#" ]]; then
            saveifs=${IFS}
            IFS="#" read _buildvers _ext _vers _rel _description _url _packager <<< "${_first_line}"
            IFS=${saveifs}

            # Remove any existing entry line
            [[ -f ${_col_repo_file_path} ]] && sed -i "/#${_in_portname}#/d" "${_col_repo_file_path}"
            u_get_file_md5sum_exit _md5sum "${_repo_file_path}"

            # Append it
            echo "${_md5sum}#${_buildvers}#${_in_portname}#${_vers}#${_rel}#${_description}#${_url}#${_packager}#${_ext}" \
                >> "${_col_repo_file_path}"
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
#       p_strip_files "${pkgdir}"
#******************************************************************************************************************************
p_strip_files() {
    (( ${#} != 1 )) &&  i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '1' arguments. Got '%s'")" "${#}"
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
# Searches for files in `_in_dir_path` and compresses man and info files.
#
#   ARGUMENTS
#       `$1 (_in_dir_path)`: absolute directory path: root dir for filesearch.
#       `_pattern`: pattern to be used in the filesearch.
#
#   USAGE
#       Compress manpages
#           p_compress_man_info_pages "${_build_pkgdir}" "*/share/man*/*"
#       Compress infopages
#           p_compress_man_info_pages "${_build_pkgdir}" "*/share/info/*"
#******************************************************************************************************************************
p_compress_man_info_pages() {
    # skip assignment:  _in_dir_path=${1}
    local _pattern=${_pattern}
    local _file _link_target _link_target_dir

    pushd "${1}" &> /dev/null
    find . -type f -path "${_pattern}" | while read -r _file ; do
        [[ ${_file} != *".gz" ]] && gzip -9 "${_file}"
    done

    find . -type l -path "${_pattern}" | while read _file; do
        _link_target=$(readlink -n "${_file}")
        # TODO recheck if that could be improved
        _link_target="${_link_target##*/}"
        _link_target="${_link_target%%.gz}.gz"
        rm -f "${_file}"
        _file="${_file%%.gz}.gz"
        u_dirname _link_target_dir "${_file}"
        [[ -e "${_link_target_dir}/${_link_target}" ]] && ln -sf "${_link_target}" "${_file}"
    done
    popd &> /dev/null
}


#******************************************************************************************************************************
# Builds the ports pkgarchives.
#       The ports Pkgfile MUST have been already sourced. See also function: pk_source_validate_pkgfile().
#
#   ARGUMENTS
#       `_in_pkgfile_path` absolute path to the ports pkgfile
#       `_in_portname`: port name
#       `_in_portpath`: port absolute path
#       `_in_buildvers`: buildversion Unix-Timestamp
#       `_in_sysarch`: architecture e.g.: "$(uname -m)"
#       `_in_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `_in_use_compression`: yes or no
#       `_in_compress_opts`: empty or options to be passed to the *xz* command to compress final produced pkgarchives.
#       `_in_cm_groups`: a reference var: index array typically set in `cmk.conf` and sometimes in a Pkgfile
#       `_in_cm_locales`: a reference var: index array typically set in `cmk.conf` and sometimes in a Pkgfile
#       `_in_strip_files`: yes or no. If set to "yes" then build executable binaries or libraries will be stripped.
#       `_build_srcdir`: Path to a directory where the sources where extracted to.
#       `_build_pkgdir`: Path to a directory where the build files are temporarly installed/copied to.
#       `_in_got_command_pkginfo`: yes/no if the command `pkginfo` (part of the cards package) is found set it to yes
#                                  if yes isee option: _in_ignore_runtimedeps
#       `_in_ignore_runtimedeps`: yes/no If set to "no", runtime-dependencies of the newly compiled package are added via the
#                                 `pkginfo --runtimedepfiles` command
#   USAGE
#       CM_PKGFILE_PATH="/usr/ports/p_diverse/hwinfo/Pkgfile"
#       CM_PORTNAME="hwinfo"
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       p_build_archives "${CM_PKGFILE_PATH}" "${CM_PORTNAME}" "${CM_PORT_PATH}" "${CM_BUILDVERS}" "${CM_ARCH}" \
#           "${CM_PKG_EXT}" "${CM_COMPRESS_PKG}" "${CM_COMPRESS_OPTS}" "${CM_STRIP}" CM_GROUPS CM_LOCALES \
#           "${srcdir}" "${pkgdir}" "${CM_GOT_COMMAND_PKGINFO}" "${CM_IGNORE_RUNTIMEDEPS}
#******************************************************************************************************************************
p_build_archives() {

    #**************************************************************************************************************************
    #   ARGUMENTS
    #       `__complete_name_part`: 'port-name'
    #                               'port-name.group-name': (only if it is a group pkgarchive.)
    #                               'port-name.locale-name': (only if it is a locale pkgarchive.)
    #       `__arch`:  final used pkgarchive name architecture: any or system-architecture
    #       `__is_main_archive`: yes (for main pkgarchive), no (for group or locale pkgarchive)
    #**************************************************************************************************************************
    _create_pkgarchive() {
        [[ -n $1 ]] || i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 1 (__complete_name_part) MUST NOT be empty.")"

        local __complete_name_part=${1}
        local __arch=${2}
        local __is_main_archive=${3}
        local __archive_path="${_in_portpath}/${__complete_name_part}${_in_buildvers}${__arch}.${_in_ref_ext}"
        local __meta_str=""
        local __size __path

        if [[ ${__is_main_archive} == "yes" ]]; then
            # remove any left locale
            rm -rf "${_build_pkgdir}/usr/share/locale" "${_build_pkgdir}/opt/*/share/locale"
            u_dir_has_content_exit "${_build_pkgdir}"

            ### Copy & rename meta file
            __path="${_in_portpath}/${__complete_name_part}.README"
            if [[ -f ${__path} ]]; then
                cp -f "${__path}" "${_build_pkgdir}/.README"
            fi
            __path="${_in_portpath}/${__complete_name_part}.pre-install"
            [[ -f ${__path} ]] && cp -f "${__path}" "${_build_pkgdir}/.PRE"
            __path="${_in_portpath}/${__complete_name_part}.post-instal"
            [[ -f ${__path} ]] && cp -f "${__path}" "${_build_pkgdir}/.POST"

        else
            echo "_create_pkgarchive(): TODO: GROUP, LOCALE NOT YET DONE"
        fi

        ### Create the Archive
        i_more_i "$(_g "Taring pkgarchive...")"
        LANG=C bsdtar -C "${_build_pkgdir}" -cf "${__archive_path}" *

        ### Generate .META file
        i_more_i  "$(_g "Adding meta data to pkgarchive: '%s'")" "${__complete_name_part}"
        __meta_str+="N${__complete_name_part}\nD${pkgdesc}\nU${pkgurl}\nP${pkgpackager}\n"

        __size=$(du -b "${__archive_path}")
        # NOTE Can not use for this: u_prefix_shortest_empty __size because the inpput is treated as a string
        __size=${__size%%[[:blank:]]*}
        [[ -n ${__size} ]] || i_exit 1 ${LINENO} \
                "$(_g "Could not get the Size of the new pkgarchive: <%s>")" "${__archive_path}"

        __meta_str+="S${__size}\nV${pkgvers}\nr${pkgrel}\nB${_in_buildvers}\na${__arch}"
        # TODO: Add the runtime dependencies to the .META file
        if [[ ${_in_got_command_pkginfo} == "yes" ]]; then
            if [[ ${_in_ignore_runtimedeps} == "no" ]]; then
                echo "_create_pkgarchive(): TODO: Add the runtime dependencies to the .META file"
            elif [[ ${_in_ignore_runtimedeps} != "yes" ]]; then
                i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 15 (_in_ignore_runtimedeps) MUST be 'yes' or 'no'. Got: '%s'")" \
                    "${_in_ignore_runtimedeps}"
            fi
        elif [[ ${_in_got_command_pkginfo} != "no" ]]; then
            i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 14 (_in_got_command_pkginfo) MUST be 'yes' or 'no'. Got: '%s'")" \
                "${_in_got_command_pkginfo}"
        fi

        echo -e "${__meta_str}" > .META || exit 1

        ### Generate .MTREE file
        bsdtar -tf "${__archive_path}" > .MTREE || exit 1

        ### Add the .MTREE .META file
        LANG=C bsdtar -C "${_build_pkgdir}" -rf "${__archive_path}" ".META" ".MTREE" || exit 1

        ### Compress if needed
        if [[ ${_in_use_compression} == "yes" ]]; then
            i_more_i "$(_g "Compressing pkgarchive with xz...")"
            # NOTE _in_compress_opts should not be in double quotes
            xz -z ${_in_compress_opts} "${__archive_path}"
        elif [[ ${_in_use_compression} != "no" ]]; then
            i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 7 (_in_use_compression) MUST be 'yes' or 'no'. Got: '%s'")" \
                "${_in_use_compression}"
        fi
    }

    (( ${#} != 15 )) &&  i_exit 1 ${LINENO} "$(_g "FUNCTION Requires EXACT '15' arguments. Got '%s'")" "${#}"
    local _in_pkgfile_path=${1}
    local _in_portname=${2}
    local _in_portpath=${3}
    local _in_buildvers=${4}
    local _in_sysarch=${5}
    local _in_ref_ext=${6}
    local _in_use_compression=${7}
    local _in_compress_opts=${8}
    local _in_strip_files=${9}
    local -n _in_cm_groups=${10}
    local -n _in_cm_locales=${11}
    local _build_srcdir=${12}
    local _build_pkgdir=${13}
    local _in_got_command_pkginfo=${14}
    local _in_ignore_runtimedeps=${15}
    local _group _archive_path

    i_msg "$(_g "Building pkgarchives for Port: <%s>")" "${_in_portpath}"

    if (( ${EUID} != 0 )); then
        i_warn2 "$(_g "Pkgarchives should be built as root.")"
    fi

    u_cd_safe_exit "${_build_srcdir}"

    ### RUN BUILD
    (set -e -x; "build")
    u_dir_has_content_exit "${_build_pkgdir}"

    u_cd_safe_exit "${_build_pkgdir}"
    if (( ${?} == 0 )); then
        if [[ "${_in_strip_files}" == "yes" ]]; then
            p_strip_files "${_build_pkgdir}"
        fi

        ## Compress manpages
        p_compress_man_info_pages "${_build_pkgdir}" "*/share/man*/*"
        ## Compress infopages
        p_compress_man_info_pages "${_build_pkgdir}" "*/share/info/*"

        echo "TODO: REMOVE THIS LATER: CM_GROUPS=()"
        #CM_GROUPS=()
        ## Process any groups
        #for _group in "${CM_GROUPS[@]}"; do
            #if u_got_function "${_group}"; then
                #(set -e -x; "${group}")
                #(( ${?} )) && i_exit 1 ${LINENO} "$(_g "Building pkgarchives for Port: <%s>")" "${_in_portpath}"
            #else
                #echo "TODO: PACK/REMOVE GROUPS"
            #fi
        #done

        ### Process any locale
        echo "TODO: Process any locale"

        ### Create the main pkgarchive
        _create_pkgarchive "${_in_portname}" "${_in_sysarch}" "yes"

    fi

    echo "UNFINSIHED"
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
