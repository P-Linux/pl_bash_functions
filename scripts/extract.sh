#******************************************************************************************************************************
#
#   <extract.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
#                   HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Call this once to check for the main commands used by the extract functions: aborts if not found
#******************************************************************************************************************************
e_got_extract_prog_exit() {
    u_no_command_exit "bsdtar"
    u_no_command_exit "gzip"
    u_no_command_exit "bzip2"
    u_no_command_exit "xz"
    u_no_command_exit "git"
    u_no_command_exit "hg"
    u_no_command_exit "bzr"
}



#=============================================================================================================================#
#
#                   PKGFILE SOURCE DOWNLOAD RELATED FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Main extract entry function:     IMPORTANT: for more info see the individual extract functions and the tests folder.
#
#   ARGUMENTS
#       `_in_ex_scrmtx`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#
#   USAGE
#       e_extract_src SCRMTX "BUILD_SRCDIR"
#       e_extract_src SCRMTX "BUILD_SRCDIR" "$KEEP_BUILD_SRCDIR"
#******************************************************************************************************************************
e_extract_src() {
    i_min_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    i_exit_empty_arg ${LINENO} "${2}" 2
    local -n _in_ex_scrmtx=${1}
    local _srcdir=${2}
    local _rm_build_dir=${3:-"yes"}
    declare -i _n

    if [[ ! -v _in_ex_scrmtx[NUM_IDX] ]]; then
        i_exit 1 ${LINENO} "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_ex_scrmtx[NUM_IDX]}; _n++ )); do
        case "${_in_ex_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https) e_extract_file ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
            local) e_extract_copy          ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
            git)   e_extract_git           ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
            svn)   e_extract_svn           ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
            hg)    e_extract_hg            ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
            bzr)   e_extract_bzr           ${_n} _in_ex_scrmtx "${_srcdir}" "${_rm_build_dir}" ;;
        esac
    done
}


#******************************************************************************************************************************
# Handling the *copying* of `File` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_c`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_copy() {
    i_min_args_exit ${LINENO} 3 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_c=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_c[${1}:DESTPATH]}
    local _finalpath="${_srcdir}/${_in_ex_scrmtx_c[${1}:DESTNAME]}"

    [[ -e ${_destpath} ]] || i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                                "$(_g "File copy source not found: <%s>")" "${_destpath}"

    i_msg "$(_g "Copying file: <%s>")" "${_destpath}"
    i_more "$(_g "To work-path: <%s>")" "${_finalpath}"

    cp -f "${_destpath}" "${_finalpath}"
    if (( ${?} )); then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" "$(_g "Failure while copying <%s> to <%s>")" \
            "${_destpath}" "${_finalpath}"
        fi
}


#******************************************************************************************************************************
# Handling the *extract* of `File` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_f`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_file() {
    i_min_args_exit ${LINENO} 3 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_f=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_f[${1}:DESTPATH]}
    local _destname=${_in_ex_scrmtx_f[${1}:DESTNAME]}
    local _destname_no_ext; u_prefix_longest_all _destname_no_ext "${_destname}" "."
    local _ext; u_postfix_shortest_empty _ext "${_destname}" "."
    local _cmd=""
    declare -i _ret
    if [[ -e ${_destpath} ]]; then
        local _file_type=$(file -bizL "${_destpath}")
    else
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" "$(_g "File source  not found: <%s>")" "${_destpath}"
    fi

    if [[ ${_in_ex_scrmtx_f[${1}:NOEXTRACT]} == "NOEXTRACT" ]]; then
        i_more "$(_g "e_extract_file() only copy: noextract: '%s'")" "${_in_ex_scrmtx_f[${1}:NOEXTRACT]}}"
        e_extract_copy ${1}  _in_ex_scrmtx_f "${_srcdir}" "${_rm_build_dir}"
        return 0
    fi

    # do not rely on extension for file type
    case "${_file_type}" in
        *application/x-tar*|*application/zip*|*application/x-zip*| \
        *application/x-cpio*|*application/x-rpm*|*application/vnd.debian.binary-package*)
            _cmd="bsdtar"
            ;;
        *application/x-gzip*)
            case "${_ext}" in
                gz|z|Z) _cmd="gzip" ;;
                *)      return 0   ;;
            esac
            ;;
        *application/x-bzip*)
            case "${_ext}" in
                bz2|bz) _cmd="bzip2" ;;
                *)      return 0    ;;
            esac
            ;;
        *application/x-xz*)
            case "${_ext}" in
                xz) _cmd="xz" ;;
                *)  return 0 ;;
            esac
            ;;
        *)
            # See if bsdtar can recognize the file
            if bsdtar -tf "${_destpath}" -q '*' &> /dev/null; then
                _cmd="bsdtar"
            else
                e_extract_copy ${_n} _in_ex_scrmtx_f "${_srcdir}" "${_rm_build_dir}"
                return 0
            fi
            ;;
    esac

    i_msg "$(_g "Using (%s) to extract file: <%s>")" "${_cmd}" "${_destpath}"
    i_more "$(_g "To build-dir: <%s>")" "${_srcdir}"

    _ret=0
    if [[ ${_cmd} == "bsdtar" ]]; then
        ${_cmd}  -p -C "${_srcdir}" -xf "${_destpath}" || _ret=${?}
    else
        rm -f -- "${_srcdir}/${_destname_no_ext}"
        ${_cmd}  -dcf "${_destpath}" > "${_srcdir}/${_destname_no_ext}" || _ret=${?}
    fi

    if (( ${_ret} )); then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" "$(_g "Failed to extract file <%s> to <%s>")" \
            "${_destpath}" "${_srcdir}"
    fi

    if (( ${EUID} == 0 )); then
        # change perms of all source files to root user & root group
        chown -R 0:0 "${_srcdir}"
    fi
}


#******************************************************************************************************************************
# Handling the *extract* of `Git` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_g`: a reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_git() {
    i_min_args_exit ${LINENO} 3 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_g=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _frag=${_in_ex_scrmtx_g[${1}:FRAGMENT]}
    local _destpath=${_in_ex_scrmtx_g[${1}:DESTPATH]}
    local _uri_name; u_basename _uri_name "${_in_ex_scrmtx_g[${1}:URI]}"
    local _repo; u_prefix_longest_all _repo "${_uri_name}" ".git"
    local _finalpath="${_srcdir}/${_in_ex_scrmtx_g[${1}:DESTNAME]}"
    local _ref="origin/HEAD"
    declare -i _updating
    local _var

    [[ -e ${_destpath} ]] || i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                                "$(_g "Git source  not found: <%s>")" "${_destpath}"

    i_msg "$(_g "Creating working copy of git repo: '%s'")" "${_repo}"
    i_more "$(_g "Path: <%s>")" "${_finalpath}"

    pushd "${_srcdir}" &> /dev/null

    _updating=0
    if [[ -d ${_finalpath} ]]; then
        _updating=1
        u_cd_safe_exit "${_finalpath}"
        git fetch || i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                        "$(_g "Failure while updating working copy of git repo: '%s'")" "${_repo}"
    elif ! git clone "${_destpath}" "${_finalpath}"; then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
            "$(_g "Failure while creating working copy of git repo: '%s'")" "${_repo}"
    fi

    u_cd_safe_exit "${_finalpath}"

    if [[ -n ${_frag} ]]; then
        u_prefix_shortest_all _var "${_frag}" "="
        case "${_var}" in
            commit|tag) u_postfix_shortest_all _ref "${_frag}" "=" ;;
            branch)
                u_postfix_shortest_all _ref "${_frag}" "="
                _ref=origin/${_ref}
                ;;
            *) i_exit 1 ${LINENO} "$(_g "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_frag}" \
                "${_in_ex_scrmtx_g[${1}:ENTRY]}" ;;
        esac
    fi

    if [[ ${_ref} != "origin/HEAD" ]] || (( _updating )); then
        if ! git checkout --force --no-track -B "p-linux-work-branch" "${_ref}"; then
            i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                "$(_g "Failure while creating working copy of git repo: '%s'")" "${_repo}"
        fi
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# Handling the *extract* of `Subversion` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_c`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_svn() {
    i_min_args_exit ${LINENO} 3 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_s=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_s[${1}:DESTPATH]}
    local _repo; u_basename _repo "${_in_ex_scrmtx_s[${1}:URI]}"

    if [[ ! -e ${_destpath} ]]; then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
            "$(_g "Subversion source  not found: <%s>")" "${_destpath}"
    fi

    i_msg "$(_g "Creating working copy of svn repo: '%s'")" "${_repo}"
    i_more "$(_g "Path: <%s>")" "${_srcdir}/${_in_ex_scrmtx_s[${1}:DESTNAME]}"

    if ! cp -au "${_destpath}" "${_srcdir}"; then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
            "$(_g "Failure while creating working copy of svn repo: '%s'")" "${_repo}"
    fi
}


#******************************************************************************************************************************
# Handling the *extract* of `Mercurial` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_h`: a reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_hg() {
    i_min_args_exit ${LINENO} 3 ${#}
    [i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_h=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_h[${1}:DESTPATH]}
    local _frag=${_in_ex_scrmtx_h[${1}:FRAGMENT]}
    local _repo; u_basename _repo "${_in_ex_scrmtx_h[${1}:URI]}"
    local _finalpath="${_srcdir}/${_in_ex_scrmtx_h[${1}:DESTNAME]}"
    local _ref="tip"
    local _tmp

    [[ -e ${_destpath} ]] || i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                                "$(_g "Mercurial source  not found: <%s>")" "${_destpath}"

    i_msg "$(_g "Creating working copy of hg repo: '%s'")" "${_repo}"
    i_more "$(_g "Path: <%s>")" "${_finalpath}"

    pushd "${_srcdir}" &> /dev/null

    if [[ -n ${_frag} ]]; then
        u_prefix_shortest_all _tmp "${_frag}" "="
        case "${_tmp}" in
            branch|revision|tag) u_postfix_shortest_all _ref "${_frag}" "=" ;;
            *) i_exit 1 ${LINENO} "$(_g "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_frag}" \
                "${_in_ex_scrmtx_h[${1}:ENTRY]}" ;;
        esac
    fi

    if [[ -d ${_finalpath} ]]; then
        u_cd_safe_exit "${_finalpath}"
        if ! (hg pull && hg update -C -r "${_ref}"); then
            i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                "$(_g "Failure while updating working copy of hg repo: '%s'")" "${_repo}"
        fi
    elif ! hg clone -u "${_ref}" "${_destpath}" "${_finalpath}"; then
        i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
            "$(_g "Failure while creating working copy of hg repo: '%s'")" "${_repo}"
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# Handling the *extract* of `Bazaar` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_b`: a reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#       `_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_rm_build_dir`: yes/no    if "yes" the '_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
e_extract_bzr() {
    i_min_args_exit ${LINENO} 3 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_ex_scrmtx_b=${2}
    local _srcdir=${3}
    local _rm_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_b[${1}:DESTPATH]}
    local _frag=${_in_ex_scrmtx_b[${1}:FRAGMENT]}
    local _repo; u_basename _repo "${_in_ex_scrmtx_b[${1}:URI]}"
    local _finalpath="${_srcdir}/${_in_ex_scrmtx_b[${1}:DESTNAME]}"
    local _ref="last:1"
    local _tmp

    [[ -e ${_destpath} ]] || i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                                "$(_g "Bazaar source  not found: <%s>")" "${_destpath}"

    i_msg "$(_g "Creating working copy of bzr repo: '%s'")" "${_repo}"
    i_more "$(_g "Path: <%s>")" "${_finalpath}"

    pushd "${_srcdir}" &> /dev/null

    if [[ -n ${_frag} ]]; then
        u_prefix_shortest_all _tmp "${_frag}" "="
        case "${_tmp}" in
            revision) u_postfix_shortest_all _ref "${_frag}" "=" ;;
            *) i_exit 1 ${LINENO} "$(_g "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_frag}" \
                "${_in_ex_scrmtx_h[${1}:ENTRY]}" ;;
        esac
    fi

    if [[ -d ${_finalpath} ]]; then
        u_cd_safe_exit "${_finalpath}"
        if ! (bzr pull "${_destpath}" -q --overwrite -r "${_ref}" && bzr clean-tree -q --detritus --force); then
            i_exit_remove_path ${?} ${LINENO} "${_rm_build_dir}" "${_srcdir}" \
                "$(_g "Failure while updating working copy of bzr repo: '%s'")" "${_repo}"
        fi
    elif ! bzr checkout "${_destpath}" -r "${_ref}"; then
        i_exit_remove_path "e_extract_bzr" "${_rm_build_dir}" "${_srcdir}" \
            "$(_g "Failure while creating working copy of bzr repo: '%s'")" "${_repo}"
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# TODO: UPDATE THIS if there are functions/variables added or removed.
#
# EXPORT:
#   helpful command to get function names: `declare -F` or `compgen -A function`
#******************************************************************************************************************************
e_export() {
    local _func_names _var_names

    _func_names=(
        e_export
        e_extract_bzr
        e_extract_copy
        e_extract_file
        e_extract_git
        e_extract_hg
        e_extract_src
        e_extract_svn
        e_got_extract_prog_exit
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
e_export


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
