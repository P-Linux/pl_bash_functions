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
    i_exact_args_exit ${LINENO} 1 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
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
#       `_in_proto_filter`: a reference var: An associative array with `PROTOCOL` names as keys.
#           Only these protocols sources will be deleted:
#           DEFAULTS TO: declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#
#   USAGE
#       declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       p_remove_downloaded_src SCRMTX FILTER
#******************************************************************************************************************************
p_remove_downloaded_src() {
    i_min_args_exit ${LINENO} 1 ${#}
    local -n _in_p_rds_scrmtx=${1}
    if (( ${#} > 1 )) && [[ -v ${2}[@] ]]; then         # Check var 2 is set and has elements
        local -n _in_proto_filter=${2}
    else
        declare -A _in_proto_filter=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
    fi
    local _tmp
    declare -i _n

    if [[ -v _in_proto_filter[local] ]]; then
        _tmp=${!_in_proto_filter[@]}            # _in_proto_filter_keys_str
        i_exit 1 ${LINENO} "$(_g "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" "${_tmp}"
    fi

    if [[ ! -v _in_p_rds_scrmtx[NUM_IDX] ]]; then
        i_exit 1 ${LINENO} "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_p_rds_scrmtx[NUM_IDX]}; _n++ )); do
        if [[ -v _in_proto_filter[${_in_p_rds_scrmtx[${_n}:PROTOCOL]}] ]]; then
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
    i_exact_args_exit ${LINENO} 1 ${#}
    local _p_backup="${1}.bak"
    if [[ -f "${_p_backup}" ]]; then
        i_more_i "$(_g "Removing existing Backup-Pkgfile: <%s>")" "${_p_backup}"
        rm -f "${_p_backup}"
    fi
}


#******************************************************************************************************************************
# Generate the pkgmd5sums array in the Pkgfile: makes also a backup copy of the original Pkgfile
#
#   ARGUMENTS
#       `_pkgfile`: absolute path to the pkgfile
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

    i_exact_args_exit ${LINENO} 2 ${#}
    local _pkgfile=${1}
    local -n _in_new_md5sums=${2}
    declare -i _new_md5sums_len=${#_in_new_md5sums[@]}
    local _final_str=""
    local _tmpstr=""
    # tests are slightly faster for ints
    declare -i _found=0
    declare -i _add_rest=0
    local _backup_pkgfile="${_pkgfile}.bak"

    # make a bak file
    cp -f "${_pkgfile}" "${_backup_pkgfile}"

    _savedifs=${IFS}
    while IFS= read -r _line; do
        if (( ${_add_rest} )); then
             _final_str+="${_line}\n"
        elif (( ${_found} )); then
            if [[ ${_line} == *")"* ]]; then
                _do_end_of_array
            fi
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
            if (( ${_new_md5sums_len} == 1 )); then
                _final_str+="pkgmd5sums=(\"${_in_new_md5sums[0]}\")\n"
            elif (( ${_new_md5sums_len} > 1 )); then
                _final_str+="pkgmd5sums=(\"${_in_new_md5sums[0]}\"\n"
                for (( _n=1; _n < ${_new_md5sums_len} - 1; _n++ )); do
                    _final_str+="    \"${_in_new_md5sums[${_n}]}\"\n"
                done
                _final_str+="    \"${_in_new_md5sums[${_n}]}\")\n"
            else
                _final_str+="pkgmd5sums=()\n"
            fi

            if [[ ${_line} == *")"* ]]; then
                _do_end_of_array
            fi
            _found=1
        else
            _final_str+="${_line}\n"
        fi
    done < "${_backup_pkgfile}"
    IFS=${_savedifs}

    echo -e "${_final_str}" > "${_pkgfile}"
}


#******************************************************************************************************************************
# Generate a new port-repo-file.
#       The ports Pkgfile MUST have been already sourced. See also function: pk_source_validate_pkgfile().
#
#   ARGUMENTS
#       `_pkgfile`: pkgfile path
#       `$2 (_portname)`: port name
#       `_portpath`: port absolute path
#       `_sysarch`: architecture e.g.: "$(uname -m)"
#       `_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
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
    i_exact_args_exit ${LINENO} 6 ${#}
    local _pkgfile=${1}
    # skip assignment:  _portname=${2}
    local _portpath=${3}
    local _sysarch=${4}
    local _ref_ext=${5}
    # skip assignment:  _in_ref_repo_filename=${6}
    local _repo_file_path="${_portpath}/${6}"
    local _final_str=""
    local _pkgarchives_list=()
    local _pkgfile_name; u_basename _pkgfile_name "${_pkgfile}"
    local _archive_name _archive_buildvers _archive_arch _archive_ext
    local _packager _description _url
    local _archive_filepath _archive_filename _md5sum _f

    # Limited, fast check if we have sourced the Pkgfile beforehand
    if [[ ! -v pkgpackager ]]; then
        i_exit 1 ${LINENO} \
            "$(_g "Could not get expected Pkgfile variable 'pkgpackager'! Hint: did you forget to source the pkgfile: <%s>")" \
            "${_pkgfile}"
    fi

    _pkgarchives_list=()
    a_list_pkgarchives _pkgarchives_list "${2}" "${_portpath}" "${_sysarch}" "${_ref_ext}"

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
            "${_archive_filepath}" "${_sysarch}" "${_ref_ext}"
        _final_str+="${_archive_buildvers}#${_archive_ext}#${pkgvers}#${pkgrel}#${_description}#${_url}#${_packager}\n"

        # Do the individual package archive files
        for _archive_filepath in "${_pkgarchives_list[@]}"; do
            u_basename _archive_filename "${_archive_filepath}"
            u_get_file_md5sum_exit _md5sum "${_archive_filepath}"
            a_get_archive_name_arch _archive_name _archive_arch "${_archive_filepath}" "${_sysarch}" "${_ref_ext}"
            _final_str+="${_md5sum}#${_archive_name}#${_archive_arch}\n"
        done

        # Do all other files
        pushd "${_portpath}" &> /dev/null
        for _f in *; do
            if [[ -f ${_f} ]]; then
                u_get_file_md5sum_exit _md5sum "${_f}"
                if [[ ${_f} != ${_pkgfile_name} ]]; then
                    if ! [[ ${_f} == *"${_sysarch}.${_ref_ext}"* || ${_f} == *"any.${_ref_ext}"* ]]; then
                        _final_str+="${_md5sum}#${_f}\n"
                    fi
                fi
            fi
        done
        popd &> /dev/null
    fi

    u_get_file_md5sum _md5sum "${_pkgfile}"
    _final_str+="${_md5sum}#${_pkgfile_name}"

    echo -e "${_final_str}" > "${_repo_file_path}"
}


#******************************************************************************************************************************
# Generate a new/update a collection-repo-file with the ports entry line.
#
#   ARGUMENTS
#       `_portname`: port name
#       `_portpath`: port absolute path
#       `$3 (_collectionpath)`: port absolute path
#       `$4 (_in_ref_repo_filename)`: The reference repo file name.
#
#   USAGE
#       CM_PORTNAME="hwinfo"
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       p_update_collection_repo_file "${CM_PORTNAME}" "${CM_PORTPATH}" "${CM_PORT_COLLECTION_PATH}" "${CM_REPO}"
#******************************************************************************************************************************
p_update_collection_repo_file() {
    i_exact_args_exit ${LINENO} 4 ${#}
    local _portname=${1}
    local _portpath=${2}
    # skip assignment:  local _collectionpath=${3}
    # skip assignment:  _in_ref_repo_filename=${4}
    local _repo_file_path="${_portpath}/${4}"
    local _col_repo_file_path="${3}/${4}"
    local _md5sum _buildvers _ext _vers _rel _description _url _packager _first_line

    if [[ -f ${_repo_file_path} ]]; then
        read -r _first_line < "${_repo_file_path}"
        if [[ ${_first_line:10:1} = "#" ]]; then
            saveifs=${IFS}
            IFS="#" read _buildvers _ext _vers _rel _description _url _packager <<< "${_first_line}"
            IFS=${saveifs}

            # Remove any existing entry line
            if [[ -f ${_col_repo_file_path} ]]; then
                sed -i "/#${_portname}#/d" "${_col_repo_file_path}"
            fi
            u_get_file_md5sum_exit _md5sum "${_repo_file_path}"

            # Append it
            echo "${_md5sum}#${_buildvers}#${_portname}#${_vers}#${_rel}#${_description}#${_url}#${_packager}#${_ext}" \
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
    i_exact_args_exit ${LINENO} 1 ${#}
    # skip assignment:  _in_dir_path=${1}
    local _f

    pushd "${1}" &> /dev/null
    find . -type f -perm -u+w -print0 2>/dev/null | while read -rd '' _f ; do
        case "$(file -bi "${_f}")" in
            *application/x-executable*)
                strip "--strip-all" "${_f}"              # Binaries
                ;;
            *application/x-sharedlib*)
                strip "--strip-unneeded" "${_f}"         # Libraries (.so)
                ;;
            *application/x-archive*)
                strip "--strip-debug" "${_f}"            # Libraries (.a)
                ;;
            *application/x-object*)
                case "${_f}" in
                    *.ko)
                        strip "--strip-unneeded" "${_f}"  # Kernel modules
                        ;;
                    *) continue;;
                esac;;

            *) continue ;;
        esac
    done
    popd &> /dev/null
}


#******************************************************************************************************************************
# Searches for files in `_in_dir_path` and compresses the files sutiable for man and info pages.
#
#   ARGUMENTS
#       `$1 (_in_dir_path)`: absolute directory path: root dir for filesearch.
#
#   USAGE
#       Compress manpages
#           p_compress_man_info_pages "${_build_pkgdir}/usr/share/man"
#       Compress infopages
#           p_compress_man_info_pages "${_build_pkgdir}/usr/share/info"
#           p_compress_man_info_pages "${_build_pkgdir}/opt/"*"/share/info"
#******************************************************************************************************************************
p_compress_man_info_pages() {
    # skip assignment:  _in_dir_path=${1}
    local _f _link_target _link_target_dir

    shopt -s globstar

    for _f in "${1}/"**; do
        if [[ -f ${_f} && ! -L ${_f} ]]; then
           [[ ${_f} == *".gz" ]] || gzip -9 "${_f}"
        fi
    done

    for _f in "${1}/"**; do
        if [[ -L ${_f} ]]; then
            _link_target=$(readlink -n "${_f}")
            _link_target="${_link_target##*/}"
            _link_target="${_link_target%%.gz}.gz"
            rm -f "${_f}"
            _f="${_f%%.gz}.gz"
            u_dirname _link_target_dir "${_f}"
            if [[ -e "${_link_target_dir}/${_link_target}" ]]; then
                ln -sf "${_link_target}" "${_f}"
            fi
        fi
    done
    shopt -u globstar
}



#******************************************************************************************************************************
# Only builds the ports. Does not pack any pkgarchives
#       The ports Pkgfile MUST have been already sourced. See also function: pk_source_validate_pkgfile().
#
#   ARGUMENTS
#       `_portpath`: port absolute path
#       `_build_srcdir`: Path to a directory where the sources where extracted to.
#
#   USAGE
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       p_build "${CM_PORTPATH}" "${srcdir}"
#******************************************************************************************************************************
p_build() {
    i_exact_args_exit ${LINENO} 2 ${#}
    local _portpath=${1}
    local _build_srcdir=${2}

    i_msg "$(_g "Building Port: <%s>")" "${_portpath}"

    if (( ${EUID} != 0 )); then
        i_warn2 "$(_g "Ports should be built as root.")"
    fi

    u_cd_safe_exit "${_build_srcdir}"

    ### RUN BUILD
    (set -e -x; "build")
}


#******************************************************************************************************************************
# Packs the ports pkgarchives - performs various required tasks: e.g. strip files, crun CM_GROUPS actions etc..
#       The ports Pkgfile MUST have been already sourced. See also function: pk_source_validate_pkgfile().
#       The ports MUST have been already build. See also function: p_build().
#
#   ARGUMENTS
#       `_pkgfile` absolute path to the ports pkgfile
#       `_portname`: port name
#       `_portpath`: port absolute path
#       `_buildvers`: buildversion Unix-Timestamp
#       `_sysarch`: architecture e.g.: "$(uname -m)"
#       `_ref_ext`: The extention name of a package tar archive file withouth any compression specified.
#       `_use_comp`: yes or no use cmopression
#       `_comp_opts`: empty or options to be passed to the *xz* command to compress final produced pkgarchives.
#       `_in_cm_groups`: a reference var: index array typically set in `cmk.conf` and sometimes in a Pkgfile
#       `_in__cm_groups_default_func_names`: a reference var: An associative array with the default `CM_GROUP` function
#           names as keys.
#           e.g. declare -A _in__cm_groups_default_func_names=(["lib"]=0 ["devel"]=0 ["doc"]=0 ["man"]=0 ["service"]=0)
#       `_in_cm_locales`: a reference var: index array typically set in `cmk.conf` and sometimes in a Pkgfile
#       `_strip_files`: yes or no. If set to "yes" then build executable binaries or libraries will be stripped.
#       `_build_pkgdir`: Path to a directory where the build files are temporarly installed/copied to.
#       `_packdir_path`: Path to a directory where the files must be copied to be packed.
#       `_got_pkginfo`: yes/no if the command `pkginfo` (part of the cards package) is found set it to yes
#                                  if yes isee option: _ignore_runtimedeps
#       `_ignore_runtimedeps`: yes/no If set to "no", runtime-dependencies of the newly compiled package are added via the
#                                 `pkginfo --runtimedepfiles` command
#   USAGE
#       CM_PKGFILE_PATH="/usr/ports/p_diverse/hwinfo/Pkgfile"
#       CM_PORTNAME="hwinfo"
#       CM_PORT_PATH="/usr/ports/p_diverse/hwinfo"
#       p_pack_archives "${CM_PKGFILE_PATH}" "${CM_PORTNAME}" "${CM_PORTPATH}" "${CM_BUILDVERS}" "${CM_ARCH}" \
#           "${CM_PKG_EXT}" "${CM_COMPRESS_PKG}" "${CM_COMPRESS_OPTS}" "${CM_STRIP}" CM_GROUPS \
#           CM_GROUPS_DEFAULT_FUNCTION_NAMES CM_LOCALES "${pkgdir}" "${CM_PACK_DIR}" "${CM_GOT_COMMAND_PKGINFO}"
#           "${CM_IGNORE_RUNTIMEDEPS}"
#******************************************************************************************************************************
p_pack_archives() {


    #**************************************************************************************************************************
    # _run_customary_group_func: Helper function
    #**************************************************************************************************************************
    _run_customary_group_func() {
        "${__group}" __final_arch "${_packdir_path}"
        __exc=${?}
        if (( ${__exc} )); then
            i_exit 1 ${LINENO} "$(_g "Customary group function: '%s()' Exit-Status-Code: '%s' Port: <%s>")" "${__group}" \
                ${__exc} "${_portpath}"
        fi
    }

    #**************************************************************************************************************************
    #   ARGUMENTS
    #       `__archive_type`: "main", "locale" or "group"
    #
    #   OPTIONAL ARGUMENTS
    #       `__type_info`: extra info used for locale or group types.
    #                       locale: a locale to process e.g: "de"
    #                       group: the group to process e.g: "devel"
    #                       main: does not use it: defaults to ""
    #**************************************************************************************************************************
    _create_pkgarchive() {
        local __archive_type=${1}
        local __type_info=${2:-""}
        local __meta_str=""
        declare -i __exc=0
        local __packdirname; u_basename __packdirname "${_packdir_path}"
        # NOTE: do NOT use an integer for __size: it is treated as string
        local __size
        local __complete_name __path __archive_path __final_arch __loc __group __dir __grp_refpath_sysarch __grp_refpath_any
        local __pkginfo_out

        mkdir -p "${_packdir_path}" || i_exit 1 ${LINENO}  "$(_g "Packdir should not exist: <%s> Pkgfile: <%s>")" \
                                    "${_packdir_path}" "${_pkgfile}"

        if [[ ${__archive_type} == "main" ]]; then
            __final_arch=${_sysarch}
            __complete_name=${_portname}
            __archive_path="${_portpath}/${__complete_name}${_buildvers}${__final_arch}.${_ref_ext}"
            if [[ -f "${__archive_path}" ]]; then rm -f "${__archive_path}"; fi

            # remove any left locale, doc, default info and man folders
            rm -rf \
                "${_build_pkgdir}/usr/share/locale"     \
                "${_build_pkgdir}/usr/share/doc"        \
                "${_build_pkgdir}/usr/share/gtk-doc"    \
                "${_build_pkgdir}/usr/share/man"        \
                "${_build_pkgdir}/usr/share/info"       \
                "${_build_pkgdir}/opt/"*"/share/locale"   \
                "${_build_pkgdir}/opt/"*"/share/doc"      \
                "${_build_pkgdir}/opt/"*"/share/gtk-doc"  \
                "${_build_pkgdir}/opt/"*"/share/man"      \
                "${_build_pkgdir}/opt/"*"/share/info"

            # remove within the _build_pkgdir any other: */share/man" or "*/share/info"
            shopt -s globstar
            rm -rf -v "${_build_pkgdir}/"**"/share/info" "${_build_pkgdir}/"**"/share/man"
            shopt -u globstar

            # remove some dirs if empty also the parent dirs: always return true as it will fail on none existing folders
            rmdir --ignore-fail-on-non-empty        \
                "${_build_pkgdir}/usr/include"      \
                "${_build_pkgdir}/usr/lib"          \
                "${_build_pkgdir}/usr/lib64"        \
                "${_build_pkgdir}/usr/share"        \
                "${_build_pkgdir}/opt/"*"/include"    \
                "${_build_pkgdir}/opt/"*"/lib"        \
                "${_build_pkgdir}/opt/"*"/lib64"      \
                "${_build_pkgdir}/opt/"*"/share"      \
                "${_build_pkgdir}/bin"              \
                "${_build_pkgdir}/boot"             \
                "${_build_pkgdir}/dev"              \
                "${_build_pkgdir}/etc"              \
                "${_build_pkgdir}/home"             \
                "${_build_pkgdir}/lib"              \
                "${_build_pkgdir}/lib64"            \
                "${_build_pkgdir}/mnt"              \
                "${_build_pkgdir}/proc"             \
                "${_build_pkgdir}/run"              \
                "${_build_pkgdir}/sbin"             \
                "${_build_pkgdir}/srv"              \
                "${_build_pkgdir}/sys"              \
                "${_build_pkgdir}/tmp"              \
                "${_build_pkgdir}/usr"              \
                "${_build_pkgdir}/var" &> /dev/null || true

            ### Copy & rename meta file
            __path="${_portpath}/${_portname}.README"
            if [[ -f ${__path} ]]; then
                cp -f "${__path}" "${_build_pkgdir}/.README"
            fi
            __path="${_portpath}/${_portname}.pre-install"
            if [[ -f ${__path} ]]; then
                cp -f "${__path}" "${_build_pkgdir}/.PRE"
            fi
            __path="${_portpath}/${_portname}.post-install"
            if [[ -f ${__path} ]]; then
                cp -f "${__path}" "${_build_pkgdir}/.POST"
            fi

            # Move all to the: _packdir_path: so we can use one tar command: skip __packdirname
            mv "${_build_pkgdir}/"!("${__packdirname}") "${_packdir_path}"
        elif [[ ${__archive_type} == "locale" ]]; then
            __loc=${__type_info}
            __final_arch="any"
            __complete_name="${_portname}.${__loc}"
            __archive_path="${_portpath}/${__complete_name}${_buildvers}${__final_arch}.${_ref_ext}"
            if [[ -f "${__archive_path}" ]]; then rm -f "${__archive_path}"; fi

            for __dir in "usr/share/locale/${__loc}" "opt/"*"/share/locale/${__loc}"; do
                __path="${_build_pkgdir}/${__dir}"
                if [[ -d ${__path} ]]; then
                    cp -ra --parents "${__dir}" "${_packdir_path}"
                    rm -rf "${__path}"
                fi
            done

        elif [[ ${__archive_type} == "group" ]]; then
            __group=${__type_info}
            __complete_name="${_portname}.${__group}"
            # NOTE: the group path can be changed through the Pkgfile group function: first passed argument: __final_arch
            __grp_refpath_sysarch="${_portpath}/${__complete_name}${_buildvers}${_sysarch}.${_ref_ext}"
            __grp_refpath_any="${_portpath}/${__complete_name}${_buildvers}any.${_ref_ext}"

            if [[ -f "${__grp_refpath_sysarch}" ]]; then rm -f "${__grp_refpath_sysarch}"; fi
            if [[ -f "${__grp_refpath_any}" ]]; then rm -f "${__grp_refpath_any}"; fi

            if [[  ${__group} == "lib" ]]; then
                __final_arch=${_sysarch}
                if u_got_function "${__group}"; then
                    _run_customary_group_func
                else
                    for __dir in "usr/lib" "usr/lib64" "opt/"*"/lib" "opt/"*"/lib64"; do
                        __path="${_build_pkgdir}/${__dir}"
                        if [[ -d ${__path} ]]; then
                            cp -ra --parents "${__dir}" "${_packdir_path}"
                            # Note: pkgconfig folders are excluded from group lib
                            rm -rf "${_packdir_path}/${__dir}/pkgconfig"
                            rm -rf "${__path}/"!("pkgconfig")
                        fi
                    done
                fi
            else
                # Alle these are using the same default architecture
                __final_arch="any"
                if u_got_function "${__group}"; then
                    _run_customary_group_func
                else
                    if [[  ${__group} == "devel" ]]; then
                        for __dir in "usr/include"     "usr/lib/pkgconfig"     "usr/lib64/pkgconfig" \
                                     "opt/"*"/include" "opt/"*"/lib/pkgconfig" "opt/"*"/lib64/pkgconfig"; do
                            __path="${_build_pkgdir}/${__dir}"
                            if [[ -d ${__path} ]]; then
                                cp -ra --parents "${__dir}" "${_packdir_path}"
                                rm -rf "${__path}"
                            fi
                        done
                    elif [[  ${__group} == "doc" ]]; then
                        for __dir in "usr/share/doc" "usr/share/gtk-doc" "opt/"*"/share/doc" "opt/"*"/share/gtk-doc"; do
                            __path="${_build_pkgdir}/${__dir}"
                            if [[ -d ${__path} ]]; then
                                cp -ra --parents "${__dir}" "${_packdir_path}"
                                rm -rf "${__path}"
                            fi
                        done
                    elif [[  ${__group} == "man" ]]; then
                        # Compress manpages
                        p_compress_man_info_pages "${_build_pkgdir}/usr/share/man"
                        p_compress_man_info_pages "${_build_pkgdir}/opt/"*"/share/man"
                        # Compress infopages
                        p_compress_man_info_pages "${_build_pkgdir}/usr/share/info"
                        p_compress_man_info_pages "${_build_pkgdir}/opt/"*"/share/info"

                        for __dir in "usr/share/info" "usr/share/man" "opt/"*"/share/info" "opt/"*"/share/man"; do
                            __path="${_build_pkgdir}/${__dir}"
                            if [[ -d ${__path} ]]; then
                                cp -ra --parents "${__dir}" "${_packdir_path}"
                                rm -rf "${__path}"
                            fi
                        done
                    elif [[  ${__group} == "service" ]]; then
                        __dir="etc/rc.d"
                        __path="${_build_pkgdir}/${__dir}"
                        if [[ -d ${__path} ]]; then
                            cp -ra --parents "${__dir}" "${_packdir_path}"
                            rm -rf "${__path}"
                        fi
                    fi
                fi
            fi

            # get the groups final archive part
            if [[ ${__final_arch} == ${_sysarch} ]]; then
                __archive_path="${__grp_refpath_sysarch}"
            elif [[ ${__final_arch} == "any" ]]; then
                __archive_path="${__grp_refpath_any}"
            else
                i_exit 1 ${LINENO} \
                "$(_g "Group pkgarchive: architecture MUST be 'any' or '%s' Got: '%s' File: <%s>")"  "${_sysarch}" \
                    "${__final_arch}" "${_pkgfile}"
            fi
        else
            i_exit 1 ${LINENO} "$(_g "FUNCTION: p_pack_archives()_create_pkgarchive(): CODE-ERROR")"
        fi

        ##### ONLY DO THIS IF WE GOT any content in _packdir_path

        _content=("${_packdir_path}/"*)
        # Do this much faster check if only 1 item is in the dir instead of 'shopt -s nullglob' in subshell
        if [[ ${_content[0]} != "${_packdir_path}/*" ]]; then
            i_msg_i "$(_g "Creating pkgarchive: '%s'")" "${__complete_name}"
            ### Generate .META file
            i_more_i  "$(_g "Adding meta data for pkgarchive: '%s'")" "${__complete_name}"
            __meta_str+="N${_portname}\nD${pkgdesc}\nU${pkgurl}\nP${pkgpackager}\n"

            u_prefix_shortest_empty __size "$(du -b --summarize "${_packdir_path}")" [[:blank:]]
            __meta_str+="S${__size}\nV${pkgvers}\nr${pkgrel}\nB${_buildvers}\na${__final_arch}"

            if [[ ${_got_pkginfo} == "yes" ]]; then
                if [[ ${_ignore_runtimedeps} == "no" ]]; then
                    # 1. Internally extracted info using command: `pkginfo`
                    __pkginfo_out=$(pkginfo --runtimedepfiles "${_packdir_path}")
                    echo "::::::::::::::<$__pkginfo_out>"
                    if [[ -n ${__pkginfo_out} ]]; then
                        _savedifs=${IFS}
                        while IFS= read -r _rdep; do
                            # TODO: Decide if we want to skip any .devel. dependencies here
                            # the original card code did
                            # We don't want any .devel dependencies here
                            #for dep in `pkginfo --runtimedepfiles $TAR|grep -v ^[A-Z]`; do
                            #    echo "R$dep" >> .META
                            #done
                            # We don't want any .devel dependencies here
                            #sed -i '/^R[[a-z0-9]*[-_+]*]*\.devel/d' .META

                            # add a new line in front instead of the end
                            __meta_str+="\nR${_rdep}"
                        done <<< "$(pkginfo --runtimedepfiles "${_packdir_path}")"
                        IFS=${_savedifs}
                    fi

                    # 2. Pkgfile 'pkgdepsrun' array: always check do not use elif
                    if [[ -v pkgdepsrun[@] &&  ${__archive_type} == "main" ]]; then
                        i_more_i  "$(_g "Adding runtime dependencies from pkgdepsrun array to pkgarchive: '%s'")" \
                            "${__complete_name}"
                        for _rdep in "${pkgdepsrun[@]}"; do
                            _tmpstr=$(pkginfo -b "${_rdep}")
                            if [[ ${_tmpstr} == "0" || ! -n ${_tmpstr} ]]; then
                                i_err2 "$(_g "Could not find runtime dependency: '%s'")" "${_rdep}"
                                a_rm_pkgarchives "${_portname}" "${_portpath}" "${_sysarch}" "${_ref_ext}" "NONE"
                                i_exit 1 ${LINENO} "$(_g "Could not find runtime dependency: '%s'")" "${_rdep}"
                            fi
                            # add a new line in front instead of the end
                            __meta_str+="\nR${_rdep}${_tmpstr}"
                        done
                    fi

                    # 3. Port '.run' Dependency File: always check do not use elif
                    if [[ -f "${_portpath}/${__complete_name}.run" ]]; then
                        i_more_i  "$(_g "Adding runtime dependencies from file to pkgarchive: '%s'")" "${__complete_name}"
                        _savedifs=${IFS}
                        while IFS= read -r _rdep; do
                            _tmpstr=$(pkginfo -b "${_rdep}")
                            if [[ ${_tmpstr} == "0" || ! -n ${_tmpstr} ]]; then
                                i_err2 "$(_g "Could not find runtime dependency: '%s'")" "${_rdep}"
                                a_rm_pkgarchives "${_portname}" "${_portpath}" "${_sysarch}" "${_ref_ext}" "NONE"
                                i_exit 1 ${LINENO} "$(_g "Could not find runtime dependency: '%s'")" "${_rdep}"
                            fi
                            # add a new line in front instead of the end
                            __meta_str+="\nR${_rdep}${_tmpstr}"
                        done < "${_portpath}/${__complete_name}.run"
                        IFS=${_savedifs}
                    fi
                elif [[ ${_ignore_runtimedeps} != "yes" ]]; then
                    i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 16 (_ignore_runtimedeps) MUST be 'yes' or 'no'. Got: '%s'")" \
                        "${_ignore_runtimedeps}"
                fi
            elif [[ ${_got_pkginfo} != "no" ]]; then
                i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 15 (_got_pkginfo) MUST be 'yes' or 'no'. Got: '%s'")" \
                    "${_got_pkginfo}"
            fi

            echo -e "${__meta_str}" > "${_build_pkgdir}/.META" || exit 1

            ### Create the archive
            pushd "${_packdir_path}" &> /dev/null
            LANG=C bsdtar -rf "${__archive_path}" *
            popd &> /dev/null

            #### Generate .MTREE file: use the actual info from the archive: note the size we got from the folder before taring
            bsdtar -tf "${__archive_path}" > "${_build_pkgdir}/.MTREE" || exit 1

            ### Add the .MTREE .META file
            LANG=C bsdtar -rf "${__archive_path}" -C "${_build_pkgdir}" ".META" ".MTREE" || exit 1

            ### Compress if needed
            if [[ ${_use_comp} == "yes" ]]; then
                i_more_i "$(_g "Compressing pkgarchive with xz...")"
                # NOTE _comp_opts should not be in double quotes
                xz -z ${_comp_opts} "${__archive_path}"
            elif [[ ${_use_comp} != "no" ]]; then
                i_exit 1 ${LINENO} "$(_g "FUNCTION Argument 7 (_use_comp) MUST be 'yes' or 'no'. Got: '%s'")" "${_use_comp}"
            fi
        fi

        rm -rf "${_packdir_path}"
    }

    i_exact_args_exit ${LINENO} 16 ${#}
    local _pkgfile=${1}
    local _portname=${2}
    local _portpath=${3}
    local _buildvers=${4}
    local _sysarch=${5}
    local _ref_ext=${6}
    local _use_comp=${7}
    local _comp_opts=${8}
    local _strip_files=${9}
    local -n _in_cm_groups=${10}
    local -n _in__cm_groups_default_func_names=${11}
    local -n _in_cm_locales=${12}
    local _build_pkgdir=${13}
    local _packdir_path=${14}
    local _got_pkginfo=${15}
    local _ignore_runtimedeps=${16}
    local _group _archive_path _cm_locale _tmpstr

    i_msg "$(_g "Packing pkgarchives for Port: <%s>")" "${_portpath}"

    if (( ${EUID} != 0 )); then
        i_warn2 "$(_g "Pkgarchives should be packed as root.")"
    fi

    u_cd_safe_exit "${_build_pkgdir}"  # TODO: check later if we can remove this
    if (( ${?} == 0 )); then
        if [[ "${_strip_files}" == "yes" ]]; then
            p_strip_files "${_build_pkgdir}"
        fi

        echo "TODO: REMOVE THIS LATER: _in_cm_groups=()"
        #_in_cm_groups=(lib devel doc man service)
        _in_cm_groups=(devel)
        ### Process any groups
        if [[ -v _in_cm_groups[@] ]]; then
            for _group in "${_in_cm_groups[@]}"; do
                # Check it is one of the _in__cm_groups_default_func_names
                if [[ ! -v _in__cm_groups_default_func_names[${_group}] ]]; then
                    _tmpstr="${!_in__cm_groups_default_func_names[@]}"
                    i_exit 1 ${LINENO} "$(_g "GROUP '%s' MUST BE one of GROUPS_DEFAULT_FUNCTION_NAMES: <%s> File: <%s>")" \
                        "${_group}" "${_tmpstr}" "${_pkgfile}"
                fi
                _create_pkgarchive "group" "${_group}"
            done
        fi

        ### Process any locale
        echo "TODO: REMOVE THIS LATER: _in_cm_locales=()"
        _in_cm_locales=()
        if [[ -v _in_cm_locales[@] ]]; then
            for _cm_locale in "${_in_cm_locales[@]}"; do
                _create_pkgarchive "locale" "${_cm_locale}"
            done
        fi

        ## Create the main pkgarchive
        _create_pkgarchive "main"
    fi

    echo "UNFINSIHED"
}


#******************************************************************************************************************************
# TODO: UPDATE THIS if there are functions/variables added or removed.
#
# EXPORT:
#   helpful command to get function names: `declare -F` or `compgen -A function`
#******************************************************************************************************************************
p_export() {
    local _func_names _var_names

    _func_names=(
        p_build
        p_compress_man_info_pages
        p_export
        p_make_pkg_build_dir
        p_pack_archives
        p_remove_downloaded_src
        p_remove_pkgfile_backup
        p_strip_files
        p_update_collection_repo_file
        p_update_pkgfile_pkgmd5sums
        p_update_port_repo_file
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
p_export


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
